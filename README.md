# kelsa.ai

kelsa.ai is a career copilot built with FastAPI and a single-page frontend.

## Setup

```bash
python -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
cp .env.example .env
```

Set at least:

- `SESSION_SECRET` to a long random value for signed login sessions
- `HINDSIGHT_ENABLED=true` only if you want to use Hindsight
- `HINDSIGHT_API_KEY` only when Hindsight is enabled

## Run locally

```bash
.venv/bin/python -m uvicorn main:app --reload --port 8090
```

Open `http://127.0.0.1:8090`.

## Auth flow

- Users can sign up, log in, log out, and restore sessions from a secure cookie.
- Protected routes require authentication and return `401` when the session is missing or invalid.
- The frontend automatically restores the session on page load and redirects back to the account screen if the session expires.

## Multi-user behavior

- Each user has a separate account stored in `users.json`.
- Skills, projects, applications, resume analysis, dashboard data, and chat history are scoped per authenticated user.
- Local fallback memory is stored in `memory_store.json`.

## Config

Available environment variables:

- `SESSION_SECRET`
- `HINDSIGHT_ENABLED`
- `HINDSIGHT_BASE_URL`
- `HINDSIGHT_API_KEY`

The app works without Hindsight by default and falls back to local JSON-backed storage.
