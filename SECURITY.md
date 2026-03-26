# Security Policy

## Supported versions

This project currently supports security fixes on the latest `main` branch.

## Reporting a vulnerability

Please do not open public GitHub issues for security reports.

Instead, report vulnerabilities privately to `security@example.com` with:

- a clear description of the issue
- reproduction steps or a proof of concept
- impact assessment
- any suggested remediation if you have one

We will acknowledge receipt as soon as practical, investigate the report, and
coordinate disclosure once a fix is available.

## Security expectations for contributors

- Never commit secrets or production credentials.
- Treat `.env` values, automation keys, and session secrets as sensitive.
- Prefer least-privilege configuration for deployments and integrations.
- Review authentication and cookie changes carefully before merging.
