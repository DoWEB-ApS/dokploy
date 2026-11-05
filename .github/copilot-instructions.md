# DoWEB Dokploy fork

This fork stays on upstream Dokploy v0.30.10 with a focused backport of Dokploy/dokploy#5154 and its production WebAssembly packaging fix.

**This repository is public.** Treat source, branches, workflow logs, image layers, build caches, and downloadable artifacts as public. CI receives no production 1Password token, SSH key, registry PAT, or VPS credential. Fixed credentials in the isolated CI test are public fixtures and grant no production access. Checkout credentials must not be persisted. Release publishing uses only the job-scoped, short-lived GitHub token.

- Review compatibility with existing Dokploy database records, Docker secret mounts, encryption keys, and service startup arguments.
- Keep existing migration files and timestamps unchanged. New migrations must follow the latest journal timestamp. Image rollback never implies database rollback.
- Runtime credentials belong in 1Password and must not be embedded in source, image layers, workflow logs, or release artifacts.
- The 1Password SDK and its WebAssembly resource must remain loadable in the final production image.
- CI uses the upstream pnpm lockfile and package manager. The complete test suite, all workspace type checks, and the production image upgrade test are required.
- GitHub Actions builds on GitHub-hosted runners and publishes only to ghcr.io/doweb-aps/dokploy. No workflow connects to or changes the production VPS.
- Copilot review is advisory and requested only after the automated tests pass. Use the normal Balanced review effort.
