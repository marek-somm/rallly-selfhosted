# Community fork

- Upstream remote: `https://github.com/lukevella/rallly.git`.
- Fork remote: `https://github.com/marek-somm/rallly-selfhosted.git`.
- Local work branch: `codex/selfhosted`; `upstream-main` preserves the original.
- Read `COMMUNITY-FORK.md` before changing the fork policy. Preserve AGPL/copyright
  notices, upstream credit and the visible corresponding-source download.
- This fork removes commercial licensing for self-hosting, not access controls.
  Do not fake purchased keys or weaken login, permissions, CSRF or rate limits.
- Production secrets and SMTP settings live outside this repository. Never print
  environment dumps, tokens, passwords, database URLs or full Docker inspect data.
- See `deploy/nas/README.md` for operational details. Check active Compose labels
  before changes, back up affected configuration and retain rollback releases.
- Do not restart unrelated services, clean up unrelated images/data, or touch RAID.
