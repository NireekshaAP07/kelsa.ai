# kelsa.ai
<!-- AUDIT: Header lacks badges and a sharper one-line positioning statement for quick scanning. -->

[![CI](https://github.com/notysozu/kelsa.ai/actions/workflows/ci.yml/badge.svg)](https://github.com/notysozu/kelsa.ai/actions/workflows/ci.yml) ![Python](https://img.shields.io/badge/python-3.10%2B-blue) [![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE) ![Last Commit](https://img.shields.io/github/last-commit/notysozu/kelsa.ai)

Career copilot for students and early-career professionals who want to track skills, applications, resume feedback, and next steps in one self-hosted FastAPI app.

`kelsa.ai` is a FastAPI-based career copilot with a single-page frontend for students and early-career professionals. It helps users track skills, projects, applications, resume feedback, and personalized career guidance in one lightweight app.
<!-- AUDIT: Overview is split across Purpose and Goals, which weakens the opening narrative for first-time readers. -->

## Overview

`kelsa.ai` helps students and early-career professionals organize the information they need for a job search, including skills, projects, applications, resume notes, and advisor conversations. It is built for people who want a lightweight career copilot they can run locally without setting up a separate frontend build system or database on day one. The project exists to make personal career tracking easier to start in a local JSON-backed setup while still leaving room for Hindsight-backed memory when workflows grow more advanced. Its main distinction is that it combines browser-based account flows, structured career records, and automation-friendly endpoints in a small self-hosted FastAPI app.

## Features
<!-- AUDIT: Features are accurate but implementation-leaning rather than benefit-driven. -->

- Sign in through a browser-based account flow and keep each user's records isolated with signed sessions.
- Track skills, projects, applications, resume analysis, dashboard summaries, and advisor chats in one place.
- Review your job-search progress without stitching together separate spreadsheets, notes, and prompts.
- Start with local JSON-backed storage for simple self-hosted setups and internal demos.
- Switch to Hindsight-backed memory when you need richer recall and reflection across user history.
- Send structured updates from n8n or similar automation tools without relying on browser cookies.

## Prerequisites
<!-- AUDIT: This should become a clearer prerequisites section with installation links and exact tooling expectations. -->

- [Python](https://www.python.org/downloads/) 3.10 or newer. Python 3.11 is the recommended local development target.
- `venv`, which ships with standard Python installations on most platforms.
- [Git](https://git-scm.com/downloads) if you plan to clone the repository or use the one-command installers.
- `curl` or `wget` for the optional Linux and macOS one-command installer flow.
- Internet access if you need to install dependencies or connect to Hindsight Cloud.

## Installation
<!-- AUDIT: Installation flow should include a manual end-to-end path, a verification step, and a clearer separation from usage. -->

Choose either the automated installer or the manual setup path below.

### Option 1: one-command install

The project includes auditable install scripts for Linux, macOS, and Windows.

Linux or macOS with `curl`:

```bash
curl -fsSL https://raw.githubusercontent.com/notysozu/kelsa.ai/main/install.sh | bash
```

Linux or macOS with `wget`:

```bash
wget -qO- https://raw.githubusercontent.com/notysozu/kelsa.ai/main/install.sh | bash
```

Windows PowerShell:

```powershell
iwr https://raw.githubusercontent.com/notysozu/kelsa.ai/main/install.ps1 -UseBasicParsing | iex
```

Security notes:

- review pipe-to-shell scripts before running them
- these installers are kept in-repo so they stay readable and auditable
- the scripts generate local development secrets in `.env` and do not print them

Installer behavior:

- detects the current OS and package manager
- installs Git and Python when missing
- clones the repository if you are not already inside it
- creates `.env` from `.env.example`
- creates `.venv`, installs `requirements.txt`, and starts the app

Useful overrides:

```bash
START_APP=0 curl -fsSL https://raw.githubusercontent.com/notysozu/kelsa.ai/main/install.sh | bash
INSTALL_DIR="$HOME/apps/kelsa.ai" curl -fsSL https://raw.githubusercontent.com/notysozu/kelsa.ai/main/install.sh | bash
INSTALL_UPDATE=1 ./install.sh
```

```powershell
$env:START_APP="0"; iwr https://raw.githubusercontent.com/notysozu/kelsa.ai/main/install.ps1 -UseBasicParsing | iex
$env:INSTALL_DIR="$HOME\apps\kelsa.ai"; iwr https://raw.githubusercontent.com/notysozu/kelsa.ai/main/install.ps1 -UseBasicParsing | iex
```

### Option 2: manual setup

Clone the repository and create a local environment:

```bash
git clone https://github.com/notysozu/kelsa.ai
cd kelsa.ai
cp .env.example .env
python -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt -r requirements-dev.txt
```

Start the app locally:

```bash
.venv/bin/python -m uvicorn main:app --reload --port 8090
```

Verify the app responds:

```bash
curl -s http://127.0.0.1:8090/api/status
```

Expected result: a JSON response showing the app name, memory mode, and whether automation or Hindsight are enabled.

## Project structure

```text
.
├── .github/
│   └── workflows/      # GitHub Actions CI definitions
├── tests/              # Pytest coverage for core app behavior
├── main.py             # FastAPI app, auth flow, API routes, and local storage logic
├── index.html          # Single-page frontend served directly by FastAPI
├── requirements.txt    # Runtime Python dependencies
├── requirements-dev.txt# Developer-only dependencies such as pytest
├── .env.example        # Sample environment variables for local and production setup
├── install.sh          # Linux and macOS bootstrap installer
├── install.ps1         # Windows PowerShell bootstrap installer
├── DEPLOYMENT.md       # Deployment-specific guidance
└── N8N_INTEGRATION.md  # n8n payload examples and machine-to-machine workflow notes
```

Runtime data files such as `users.json` and `memory_store.json` are created locally when the app runs in JSON-backed mode.

## Configuration
<!-- AUDIT: Configuration is useful but would be easier to scan as a table with required vs optional values. -->

Start from the example config:

```bash
cp .env.example .env
```

| Variable | Default | Required | Description |
| --- | --- | --- | --- |
| `SESSION_SECRET` | `replace-this-with-a-long-random-secret` | Yes for non-demo deployments | Signs login session cookies. Replace the placeholder before any shared or production use. |
| `APP_HOST` | `0.0.0.0` | No | Host used by `python main.py` or the built-in server entrypoint. |
| `APP_PORT` | `8090` | No | Port used by the built-in server entrypoint. |
| `APP_RELOAD` | `false` | No | Enables reload mode when you run the app through `python main.py`. |
| `SESSION_COOKIE_SECURE` | `false` | No | Set to `true` when you serve the app behind HTTPS. |
| `SESSION_COOKIE_SAMESITE` | `lax` | No | Same-site policy for the session cookie. |
| `SESSION_COOKIE_MAX_AGE` | `604800` | No | Session cookie lifetime in seconds. |
| `AUTOMATION_API_KEY` | `replace-with-a-shared-secret-for-n8n` | Optional | Shared secret for machine-to-machine requests such as n8n workflows. |
| `HINDSIGHT_ENABLED` | `false` | No | Enables Hindsight-backed memory instead of the local JSON fallback mode. |
| `HINDSIGHT_BASE_URL` | `https://api.hindsight.vectorize.io` | Only when Hindsight is enabled | Base URL for the Hindsight API. |
| `HINDSIGHT_API_KEY` | empty | Only when Hindsight is enabled | API key for the Hindsight service. |

Example `.env`:

```env
SESSION_SECRET=replace-this-with-a-long-random-secret
APP_HOST=0.0.0.0
APP_PORT=8090
APP_RELOAD=false
SESSION_COOKIE_SECURE=false
SESSION_COOKIE_SAMESITE=lax
SESSION_COOKIE_MAX_AGE=604800
AUTOMATION_API_KEY=replace-with-a-shared-secret-for-n8n
HINDSIGHT_ENABLED=false
HINDSIGHT_BASE_URL=https://api.hindsight.vectorize.io
HINDSIGHT_API_KEY=
```

## Usage

### Basic browser workflow

1. Start the app locally.
2. Open `http://127.0.0.1:8090` in your browser.
3. Create an account from the `Account` view or log in with an existing account.
4. Use the sidebar to add skills, projects, applications, resume text, and advisor prompts.
5. Return to the dashboard to review a concise summary of what the app has stored for your account.

### Automation example with n8n-compatible endpoints

After setting `AUTOMATION_API_KEY` in your `.env`, you can send structured application updates without a browser session:

```bash
curl -X POST http://127.0.0.1:8090/api/n8n/applications \
  -H "Content-Type: application/json" \
  -H "X-Automation-Key: replace-with-a-shared-secret-for-n8n" \
  -d '{
    "email": "user@example.com",
    "company": "Stripe",
    "role": "Backend Intern",
    "status": "applied",
    "date_applied": "2026-03-20",
    "notes": "Submitted through careers page"
  }'
```

See [N8N_INTEGRATION.md](/home/sonukumar/Documents/projects/kelsa.ai/N8N_INTEGRATION.md) for more payload examples and workflow prompts.

<!-- TODO: add demo GIF or screenshots for the dashboard and account flow -->

## Auth behavior

- Signup creates a user in `users.json`
- Login sets a signed cookie-based session
- Logout clears the session cookie
- Protected routes require authentication
- On page refresh, the frontend tries to restore the session automatically
- If the backend returns `401`, the frontend sends the user back to the login screen

## n8n integration

The app also supports machine-to-machine automation without browser cookies.

- Set `AUTOMATION_API_KEY` in the app environment
- Send `X-Automation-Key` in n8n HTTP Request nodes
- Use `POST /api/n8n/memory` to store structured user data by email
- Use `POST /api/n8n/applications` for direct application tracking
- Use `POST /api/n8n/resume-analysis` for direct resume review
- Use `POST /api/n8n/advisor` to send a prompt and get an advisor response for that user

See [N8N_INTEGRATION.md](/home/sonukumar/Documents/projects/kelsa.ai/N8N_INTEGRATION.md) for example payloads and suggested workflow patterns.

## Data storage

### Local mode

When `HINDSIGHT_ENABLED=false`:

- users are stored in `users.json`
- user data is stored in `memory_store.json`
- data is separated by authenticated `user_id`

### Hindsight mode

When `HINDSIGHT_ENABLED=true` and valid Hindsight credentials are provided:

- the app initializes a Hindsight bank
- memory operations use Hindsight
- user isolation is preserved using user-specific tags
- n8n-triggered advisor prompts also use the same per-user Hindsight-scoped path

## Development notes

- The frontend is a single HTML file with inline CSS and JavaScript.
- The backend serves `index.html` directly from FastAPI.
- Local runtime files like `.env`, `.venv`, `users.json`, `memory_store.json`, and `__pycache__` should stay out of Git.

## Production guidance

This project is deployable, but in its current form it is best suited for demos, prototypes, or small internal use. Before serious production use, review the following carefully.

### Minimum production checklist

- set a strong `SESSION_SECRET`
- run without `--reload`
- serve behind a reverse proxy such as Nginx or Caddy
- use HTTPS
- protect and rotate secrets properly
- back up any persistent JSON files if you stay on local storage

### Start command for production

Use a non-reload command:

```bash
.venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8090
```

You can also see [DEPLOYMENT.md](/home/sonukumar/Documents/projects/problem-statement-4/files/DEPLOYMENT.md) for a shorter deployment-specific checklist.

### Reverse proxy

Recommended:

- terminate TLS at Nginx/Caddy
- proxy requests to the FastAPI app
- keep the app on a private internal port

### Persistence

Current persistence uses JSON files:

- `users.json`
- `memory_store.json`

This is simple and works for local deployments, but it has tradeoffs:

- not ideal for concurrent multi-process writes
- not ideal for horizontal scaling
- no built-in migrations, backups, or admin tooling

For larger production use, move user and memory persistence to a database.

### Session cookies

The app currently uses signed cookies for sessions. For real production deployment, review cookie security settings in [main.py](/home/sonukumar/Documents/projects/kelsa.ai/main.py), especially if you are serving over HTTPS and want stricter cookie behavior.

### Hindsight in production

If you enable Hindsight in production:

- set `HINDSIGHT_ENABLED=true`
- configure `HINDSIGHT_BASE_URL`
- set `HINDSIGHT_API_KEY`
- verify outbound network access from your server

## Troubleshooting

### Port already in use

If port `8090` is busy:

```bash
python -m uvicorn main:app --reload --port 8091
```

### Push rejected by Git

If Git rejects your push because of local runtime files, make sure `.gitignore` is present and those files are not tracked anymore.

### Login does not persist

Check:

- the backend is running
- `SESSION_SECRET` is set
- your browser accepts cookies

### Hindsight is not being used

Check:

- `HINDSIGHT_ENABLED=true`
- `HINDSIGHT_API_KEY` is set
- the configured Hindsight URL is reachable

## Current limitations

- JSON-backed storage is fine for demos but not ideal for large-scale production
- full browser-based automated end-to-end tests are not included
- session cookie behavior may need stricter production hardening depending on deployment setup

## Tech stack

| Area | Tools |
| --- | --- |
| Language and runtime | Python 3.10+ |
| Backend framework | FastAPI, Uvicorn |
| Validation and auth helpers | Pydantic, Passlib, ItsDangerous, `email-validator` |
| Frontend | Single `index.html` file with inline HTML, CSS, and vanilla JavaScript |
| Storage | Local JSON files by default, optional Hindsight-backed memory |
| Developer tooling | Pytest, GitHub Actions CI, cross-platform install scripts |

## Project status
<!-- AUDIT: Status exists, but there is no roadmap section showing current limitations and next steps. -->

Current status: active prototype suitable for demos, internal tools, and incremental hardening.

## Roadmap

- [x] Browser-based account flow for personal career tracking
- [x] Local JSON-backed storage with optional Hindsight support
- [x] n8n-compatible endpoints for machine-to-machine automation
- [ ] Replace JSON persistence with a more production-ready database backend
- [ ] Expand automated tests beyond the current core route and auth coverage
- [ ] Move startup handling from event hooks to FastAPI lifespan handlers

## Contributing

Contributions are welcome. Start with [CONTRIBUTING.md](/home/sonukumar/Documents/projects/kelsa.ai/CONTRIBUTING.md) for local setup, testing expectations, and Conventional Commit guidance.

If you plan to contribute:

- open an issue or discussion if you want to sanity-check a change before implementing it
- fork the repository, create a focused branch, and open a pull request with a short testing summary
- run `.venv/bin/pytest` before submitting your PR

Please also read the [Code of Conduct](/home/sonukumar/Documents/projects/kelsa.ai/CODE_OF_CONDUCT.md).

## Additional documentation
<!-- AUDIT: README should link contributors and license readers more explicitly from dedicated sections, not only this catch-all list. -->

- [DEPLOYMENT.md](/home/sonukumar/Documents/projects/kelsa.ai/DEPLOYMENT.md)
- [N8N_INTEGRATION.md](/home/sonukumar/Documents/projects/kelsa.ai/N8N_INTEGRATION.md)
- [CONTRIBUTING.md](/home/sonukumar/Documents/projects/kelsa.ai/CONTRIBUTING.md)
- [SECURITY.md](/home/sonukumar/Documents/projects/kelsa.ai/SECURITY.md)
