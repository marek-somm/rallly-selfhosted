# Rallly Self-Hosted Community Fork

This is an independently maintained fork of [Rallly](https://github.com/lukevella/rallly),
not an official release or a claim to an upstream commercial license.

Changes made on **2026-11-01**, based on upstream commit
`78bc44572e7bd4fa3f1907d8afc87c3c1a4c6188`:

- Self-hosted account and space seat limits are removed without issuing or
  fabricating license keys.
- Commercial license warnings, activation screens and purchase prompts are replaced
  by a source/license information page. Legacy self-hosted validation calls fail
  locally without contacting a licensing service.
- Instance branding is available without a paid white-label entitlement.
- The UI always offers the corresponding source of the running installation.
- Original AGPLv3 and copyright notices are preserved. The original project and
  contributors remain credited. Fork modifications are also AGPL-3.0-or-later.
- Self-hosted Docker packaging does not enable upstream telemetry or update calls.
  Authentication, authorization, rate limits, email verification and privacy
  controls are preserved.

Cloud-only API, webhook scheduling and third-party integrations still depend on
their actual infrastructure and provider configuration. Removing commercial
licensing does not supply third-party accounts, API credentials or services.

## Run it

See [deployment instructions](deploy/nas/README.md). Runtime credentials and user
data are deliberately outside this repository and outside the public source
download. The application is built from a clean, identifiable Git commit using
the upstream dependency lockfile.
