#!/usr/bin/env bash
set -euo pipefail

image=${1:?Usage: verify-image.sh IMAGE}
release=.github/doweb-release.json
base=$(jq -r .upstream_commit "$release")
expected_before=$(jq -r .upstream_migration_count "$release")
expected_after=$(jq -r .release_migration_count "$release")
expected_timestamp=$(jq -r .release_migration_timestamp "$release")
scratch=$(mktemp -d "${RUNNER_TEMP:-/tmp}/dokploy-upgrade.XXXXXX")
prefix="dokploy-ci-${GITHUB_RUN_ID:-local}-$$"
network="$prefix-net"
database="$prefix-db"
application="$prefix-app"

cleanup() {
  status=$?
  if [ "$status" -ne 0 ]; then
    docker logs --tail 100 "$application" 2>/dev/null || true
  fi
  docker rm --force --volumes "$application" "$database" >/dev/null 2>&1 || true
  docker network rm "$network" >/dev/null 2>&1 || true
  rm -rf "$scratch"
  return "$status"
}
trap cleanup EXIT

docker run --rm --network none --entrypoint node "$image" -e \
  'const sdk=require("@1password/sdk"); if(typeof sdk.createClient!=="function") process.exit(1); console.log("1Password SDK and WebAssembly load successfully");'

git archive "$base" apps/dokploy/drizzle | tar -x -C "$scratch"
docker network create "$network" >/dev/null
docker run -d --name "$database" --network "$network" \
  --env POSTGRES_HOST_AUTH_METHOD=trust \
  --env POSTGRES_USER=dokploy_ci --env POSTGRES_DB=dokploy_ci postgres:16 >/dev/null

for attempt in $(seq 1 60); do
  if docker exec "$database" pg_isready -U dokploy_ci -d dokploy_ci >/dev/null 2>&1; then break; fi
  sleep 1
done
docker exec "$database" pg_isready -U dokploy_ci -d dokploy_ci
url="postgres://dokploy_ci@$database:5432/dokploy_ci"

# Public test fixtures; these values grant no access outside this ephemeral CI database.
auth_fixture=public-ci-auth-fixture-with-no-production-access
encryption_fixture=public-ci-encryption-fixture-with-no-production-access
docker run --rm --network "$network" \
  --env DATABASE_URL="$url" --env BETTER_AUTH_SECRET="$auth_fixture" \
  --env ENCRYPTION_KEY="$encryption_fixture" \
  --mount "type=bind,source=$scratch/apps/dokploy/drizzle,target=/app/drizzle,readonly" \
  --entrypoint node "$image" -r dotenv/config dist/migration.mjs

before=$(docker exec "$database" psql -U dokploy_ci -d dokploy_ci -Atc \
  'SELECT count(*) FROM drizzle.__drizzle_migrations')
test "$before" = "$expected_before"
docker exec "$database" psql -U dokploy_ci -d dokploy_ci -v ON_ERROR_STOP=1 -c \
  "CREATE TABLE doweb_ci_upgrade_probe (id text PRIMARY KEY, value text NOT NULL); INSERT INTO doweb_ci_upgrade_probe VALUES ('before-upgrade', 'preserve-existing-data');"

if [ "$(docker info --format '{{.Swarm.LocalNodeState}}')" != active ]; then
  docker swarm init --advertise-addr 127.0.0.1 >/dev/null
fi
docker run -d --name "$application" --network "$network" \
  --publish 127.0.0.1:3000:3000 \
  --env DATABASE_URL="$url" --env BETTER_AUTH_SECRET="$auth_fixture" \
  --env ENCRYPTION_KEY="$encryption_fixture" \
  --env NEXT_TELEMETRY_DISABLED=1 \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock,readonly \
  "$image" >/dev/null

for attempt in $(seq 1 90); do
  if curl --fail --silent http://127.0.0.1:3000/api/trpc/settings.health > "$scratch/health.json"; then break; fi
  sleep 2
done
jq -e '.result.data.json.status == "ok"' "$scratch/health.json" >/dev/null
after=$(docker exec "$database" psql -U dokploy_ci -d dokploy_ci -Atc \
  'SELECT count(*) FROM drizzle.__drizzle_migrations')
timestamp=$(docker exec "$database" psql -U dokploy_ci -d dokploy_ci -Atc \
  'SELECT max(created_at) FROM drizzle.__drizzle_migrations')
provider=$(docker exec "$database" psql -U dokploy_ci -d dokploy_ci -Atc \
  "SELECT enumlabel FROM pg_enum JOIN pg_type ON pg_enum.enumtypid=pg_type.oid WHERE pg_type.typname='VaultProviderType' AND enumlabel='onepassword'")
probe=$(docker exec "$database" psql -U dokploy_ci -d dokploy_ci -Atc \
  "SELECT value FROM doweb_ci_upgrade_probe WHERE id='before-upgrade'")
test "$after" = "$expected_after"
test "$timestamp" = "$expected_timestamp"
test "$provider" = onepassword
test "$probe" = preserve-existing-data
echo "Verified healthy image and upgrade: $before -> $after migrations; existing test data preserved."
