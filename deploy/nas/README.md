# NAS deployment

This community build uses one Docker Compose stack with the app, PostgreSQL,
Garage object storage and an Nginx ingress. HTTPS is terminated by an existing
Caddy server. Database, S3 and RPC ports are not published.

## Source and releases

- Repository: https://github.com/marek-somm/rallly-selfhosted
- Branch: `codex/selfhosted`; original remote: `upstream`.
- Local working copy: `S:\X\Git Projects\Rallly`.
- NAS release root: `/volume1/docker/rallly`.
- Compose: `/volume1/docker/rallly/compose.yaml` with `--env-file release.env`.
- `current` points to a clean Git commit in `releases/<commit>`.
- Private runtime files: `/volume1/@rallly-secrets/`, root-only, outside Git.

The live deployment is available at `https://termine.marek-sommerfeld.de`.
Its public source download is `/source/rallly-current.tar.gz`. It contains the
same Git revision as the deployed image, including build instructions and the
modification notice in `COMMUNITY-FORK.md`, without runtime credentials or data.

## Initial configuration

Use `deploy.ps1` from Windows with working `ssh nas` access. The bootstrap
generates private application, database and storage secrets on the NAS. In this
installation it reuses the previously configured SMTP mailbox from the private
Pollaris configuration without printing its credentials.

The admin email is configured with `INITIAL_ADMIN_EMAIL`. Sign in to Rallly
using that email and its emailed verification code. Admin rights can then be
claimed in `/control-panel`. There is no shared admin password.

Garage stores uploads persistently in `rallly_garage_data` and
`rallly_garage_meta`; the DB uses `rallly_database`. All are on the NAS SSD.
This single NAS is not redundant storage and is not an external backup.

## Operate and update

```sh
cd /volume1/docker/rallly
sudo docker compose --env-file release.env ps
sudo docker compose --env-file release.env logs --tail=50 app
```

Automatic restarts use `unless-stopped`. The application applies Prisma
migrations before serving requests. Its built-in scheduler handles queued email.
Source updates are manual: fetch upstream, review and merge, run the fork tests
and type check, commit, deploy a clean revision, and verify a real poll and login.

Before schema changes make a root-only `pg_dump -Fc` backup and back up Garage
metadata/data. Do not assume a prior image can undo a database migration. Retain
older releases and volumes. Never use `docker compose down --volumes` to roll back.

## Proxy and DNS

Cloudflare proxied CNAME for the public hostname points to the existing public
Berry hostname. Full (strict) TLS remains enabled. Caddy forwards to NAS port
18151. Nginx accepts only Berry and container-local health checks. The app keeps
its authentication, authorization, rate limiting and email verification.

Pollaris was replaced at the user's request. Its repository, secrets, database
and Docker volumes are retained for rollback; its services are stopped. No data
is migrated between these unrelated applications.
