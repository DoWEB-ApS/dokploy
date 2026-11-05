# DoWEB Dokploy

DoWEB's maintained fork of Dokploy **v0.30.10**, with the 1Password Environments provider from [upstream PR #5154](https://github.com/Dokploy/dokploy/pull/5154) and a production WebAssembly packaging fix. Owner: **Nicklas Kramer / Engineering**.

The upstream license and attribution remain in this repository. The upstream README follows below.

## What this release contains

- 1Password service-account authentication and Environment ID configuration in Settings → Secrets Providers.
- References such as `API_KEY=${{vault.op-prod.API_KEY}}`, with project/environment assignments and masked provider tokens.
- A new ORM-managed migration, `0196_rainy_gamora`, adding the `onepassword` provider enum value.
- Next.js external package configuration and an application dependency that keep the SDK's WebAssembly file available in the final image.

This provider reads **1Password Environments**. Ordinary `op://vault/item/field` references and 1Password Connect are outside this release.

The previous fork heads are preserved under `archive/2026-11-05/main`, `archive/2026-11-05/canary`, and `archive/2026-11-05/onepassword`. The code reset preserves both the old fork history and the upstream v0.30.10 commit as parents. Historical branches remain available; active work uses `develop` and `main`.

## Local development and validation

Use Node **24.22.1 or newer within Node 24** and pnpm **10.22.0**. Follow [CONTRIBUTING.md](CONTRIBUTING.md) for the upstream local Docker/PostgreSQL setup. Use local test credentials and a test 1Password Environment; production credentials do not belong in a development instance.

```sh
pnpm install --frozen-lockfile
pnpm --filter=dokploy run test --run
pnpm -r run typecheck
```

CI runs the complete test suite and type checks, builds a Linux AMD64 production image, loads the 1Password SDK/WebAssembly from that image, and verifies startup plus an upgrade from the stock v0.30.10 migration history. The upgrade test uses an isolated CI database and checks that existing test data survives. Live 1Password connectivity is verified manually with a test account.

## Review and releases

1. Open a feature pull request to `develop`. Required checks are the tests/type checks and production image build/upgrade test. Copilot is requested only after tests pass, and its review is advisory.
2. A person squash-merges completed work into `develop` after considering the review.
3. Open the release pull request from `develop` to `main`. A person merges it with a merge commit.
4. The release version and upstream migration baseline are committed in [.github/doweb-release.json](.github/doweb-release.json). Create the matching release tag on the reviewed `main` revision, initially `v0.30.10-onepassword.1`.
5. The **Publish DoWEB Dokploy image** workflow validates the release, builds and tests the image, then publishes the tested bytes to `ghcr.io/doweb-aps/dokploy`. It also creates a `sha-<full-git-commit>` image tag and records the deployment digest in the run summary. It refuses to reuse an existing version tag. A manual workflow run is also allowed from `main`.

GitHub Actions uses its short-lived `GITHUB_TOKEN` for GHCR publishing. No Docker Hub publishing token or production SSH credential is needed. New GHCR packages are private by default; VPS pull access is configured separately with a least-privilege `read:packages` credential maintained in 1Password.

All Docker builds run on GitHub-hosted Ubuntu runners. These workflows do not connect to or update the production VPS.

## Manual production rollout

The operator pulls the exact published `ghcr.io/doweb-aps/dokploy@sha256:...` image and updates the existing `dokploy` Swarm service. The operator preserves its existing volumes/bind mounts, Docker secrets, environment, command arguments, ports, placement constraints, and update policy.

Before the swap, verify a current successful backup, record the old image digest and a secret-safe service configuration summary, and record the project/application/Compose counts. After the swap, verify health, authentication, those counts, routing, and the 1Password provider. Record the change in the host's deployment log.

The first start applies the committed migration. Rolling back the image does not undo database migrations. Before enabling new 1Password-backed references in customer applications, validate the new image and the deployment's recovery procedure. Retain the previous image digest for recovery.

The built-in upstream Dokploy updater selects upstream images. Use this repository's reviewed release images for updates to this fork, and reconcile custom migration numbering and timestamps before adopting a newer upstream release.

## Deviations from DoWEB standards

**Owner:** Nicklas Kramer / Engineering. **Review date:** 2027-02-05.

This repository builds the Dokploy control plane itself. Its release images are built and published by GitHub Actions, and a person performs the production image replacement. This is an infrastructure exception to the normal DoWEB application flow in which a push to `main` makes Dokploy build and deploy the application from Git. Publishing an image never performs a VPS deployment.

The upstream pnpm workspace/lockfile and Node version remain authoritative instead of replacing them with the default npm CI commands. The fork retains upstream `canary` and historical branches for reference; DoWEB integration/release work uses protected `develop` and `main` branches.

References: [GitHub repository workflow](https://docs.doweb.dk/engineering/github-repositories/), [Pipelines](https://docs.doweb.dk/engineering/devops/pipelines/), [Deployment](https://docs.doweb.dk/engineering/devops/deployment/), and [Secrets and environment variables](https://docs.doweb.dk/engineering/devops/secrets-and-environment-variables/).

---

<div align="center">
  <a href="https://dokploy.com">
    <img src=".github/sponsors/logo.png" alt="Dokploy - Open Source Alternative to Vercel, Heroku and Netlify." width="100%"  />
  </a>
  </br>
  </br>
  <p>Join us on Discord for help, feedback, and discussions!</p>
  <a href="https://discord.gg/2tBnJ3jDJc">
    <img src="https://discordapp.com/api/guilds/1234073262418563112/widget.png?style=banner2" alt="Discord Shield"/>
  </a>
</div>
<br />


Dokploy is a free, self-hostable Platform as a Service (PaaS) that simplifies the deployment and management of applications and databases.

## ✨ Features

Dokploy includes multiple features to make your life easier.

- **Applications**: Deploy any type of application (Node.js, PHP, Python, Go, Ruby, etc.).
- **Databases**: Create and manage databases with support for MySQL, PostgreSQL, MongoDB, MariaDB, libsql, and Redis.
- **Backups**: Automate backups for databases to an external storage destination.
- **Docker Compose**: Native support for Docker Compose to manage complex applications.
- **Multi Node**: Scale applications to multiple nodes using Docker Swarm to manage the cluster.
- **Templates**: Deploy open-source templates (Plausible, Pocketbase, Calcom, etc.) with a single click.
- **Traefik Integration**: Automatically integrates with Traefik for routing and load balancing.
- **Real-time Monitoring**: Monitor CPU, memory, storage, and network usage for every resource.
- **Docker Management**: Easily deploy and manage Docker containers.
- **CLI/API**: Manage your applications and databases using the command line or through the API.
- **Notifications**: Get notified when your deployments succeed or fail (via Slack, Discord, Telegram, Email, etc.).
- **Multi Server**: Deploy and manage your applications remotely to external servers.
- **Self-Hosted**: Self-host Dokploy on your VPS.

## 🚀 Getting Started

To get started, run the following command on a VPS:

Want to skip the installation process? [Try the Dokploy Cloud](https://app.dokploy.com).

```bash
curl -sSL https://dokploy.com/install.sh | bash
```

For detailed documentation, visit [docs.dokploy.com](https://docs.dokploy.com).


[Github Sponsors](https://github.com/sponsors/Siumauricio)

### Contributors 🤝

<a href="https://github.com/dokploy/dokploy/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=dokploy/dokploy" alt="Contributors" />
</a>

## 📺 Video Tutorial

<a href="https://youtu.be/mznYKPvhcfw">
  <img src="https://dokploy.com/banner.png" alt="Watch the video" width="400"/>
</a>

## 🤝 Contributing

Check out the [Contributing Guide](CONTRIBUTING.md) for more information.
