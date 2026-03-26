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

- account signup and login
- cookie-based sessions
- per-user skills, projects, applications, resume analysis, dashboard, and chat
- optional Hindsight-backed memory
- local JSON-backed fallback memory when Hindsight is disabled
- automation endpoints for n8n or similar machine-to-machine workflows

## Requirements
<!-- AUDIT: This should become a clearer prerequisites section with installation links and exact tooling expectations. -->

- Python 3.10+ supported, 3.11+ recommended
- `venv`
- internet access only if you want to install dependencies or use Hindsight Cloud

## One-command install
<!-- AUDIT: Installation flow should include a manual end-to-end path, a verification step, and a clearer separation from usage. -->

The project now includes auditable install scripts for Linux, macOS, and Windows.

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

Security note:

- review pipe-to-shell scripts before running them
- these installers are kept in-repo so they stay readable and auditable
- the scripts generate local development secrets in `.env` and do not print them

Behavior:

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

## Project structure

- [main.py](/home/sonukumar/Documents/projects/kelsa.ai/main.py): FastAPI backend and auth logic
- [index.html](/home/sonukumar/Documents/projects/kelsa.ai/index.html): single-page frontend
- [requirements.txt](/home/sonukumar/Documents/projects/kelsa.ai/requirements.txt): Python dependencies
- [`.env.example`](/home/sonukumar/Documents/projects/kelsa.ai/.env.example): sample environment config
- [DEPLOYMENT.md](/home/sonukumar/Documents/projects/kelsa.ai/DEPLOYMENT.md): deployment-focused notes
- [N8N_INTEGRATION.md](/home/sonukumar/Documents/projects/kelsa.ai/N8N_INTEGRATION.md): machine-to-machine workflow guide for n8n
- [install.sh](/home/sonukumar/Documents/projects/kelsa.ai/install.sh): Linux and macOS bootstrap script
- [install.ps1](/home/sonukumar/Documents/projects/kelsa.ai/install.ps1): Windows bootstrap script
- `users.json`: local user store created at runtime
- `memory_store.json`: local per-user memory store created at runtime

## Configuration
<!-- AUDIT: Configuration is useful but would be easier to scan as a table with required vs optional values. -->

Copy the example config first:

```bash
cp .env.example .env
```

Available environment variables:

- `SESSION_SECRET`
  Used to sign login session cookies. Set this to a long random secret in any non-demo environment.
- `APP_HOST`
  Host for the built-in server entrypoint.
- `APP_PORT`
  Port for the built-in server entrypoint.
- `APP_RELOAD`
  Enables reload mode when running through `python main.py`.
- `SESSION_COOKIE_SECURE`
  Set to `true` behind HTTPS in production.
- `SESSION_COOKIE_SAMESITE`
  Cookie same-site policy. Default is `lax`.
- `SESSION_COOKIE_MAX_AGE`
  Session cookie lifetime in seconds.
- `AUTOMATION_API_KEY`
  Shared secret for machine-to-machine requests such as n8n.
- `HINDSIGHT_ENABLED`
  Set to `true` to enable Hindsight. Default behavior is local JSON fallback mode.
- `HINDSIGHT_BASE_URL`
  Hindsight API base URL.
- `HINDSIGHT_API_KEY`
  Hindsight API key. Leave blank when Hindsight is disabled.

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

## Local setup

Create a virtual environment and install dependencies:

```bash
python -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
```

Manual fallback if you do not want to use the one-command installers:

```bash
git clone https://github.com/notysozu/kelsa.ai
cd kelsa.ai
cp .env.example .env
python -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt
```

## Run locally

Start the app:

```bash
.venv/bin/python -m uvicorn main:app --reload --port 8090
```

Open:

```text
http://127.0.0.1:8090
```

## How to use the app

1. Open the app in your browser.
2. Go to the `Account` screen.
3. Create a new account or log in with an existing one.
4. After login, use the sidebar to access:
   - Dashboard
   - Skills
   - Projects
   - Applications
   - Resume Analysis
   - AI Advisor
5. Add your data and the app will keep it scoped to your logged-in account.

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

## Usage example

1. Start the app locally.
2. Open `http://127.0.0.1:8090`.
3. Create an account from the `Account` screen.
4. Add a few skills, projects, or applications.
5. Open the dashboard and advisor views to see the personalized summaries.

Screenshot placeholders:

- `docs/screenshots/dashboard.png`
- `docs/screenshots/account.png`

## Tech stack

- Python
- FastAPI
- Uvicorn
- Pydantic
- Passlib
- HTML, CSS, and vanilla JavaScript
- Optional Hindsight integration

## Project status
<!-- AUDIT: Status exists, but there is no roadmap section showing current limitations and next steps. -->

Current status: active prototype suitable for demos, internal tools, and incremental hardening.

## Additional documentation
<!-- AUDIT: README should link contributors and license readers more explicitly from dedicated sections, not only this catch-all list. -->

- [DEPLOYMENT.md](/home/sonukumar/Documents/projects/kelsa.ai/DEPLOYMENT.md)
- [N8N_INTEGRATION.md](/home/sonukumar/Documents/projects/kelsa.ai/N8N_INTEGRATION.md)
- [CONTRIBUTING.md](/home/sonukumar/Documents/projects/kelsa.ai/CONTRIBUTING.md)
- [SECURITY.md](/home/sonukumar/Documents/projects/kelsa.ai/SECURITY.md)
