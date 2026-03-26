# Contributing

Thanks for your interest in improving `kelsa.ai`.

## Development setup

1. Fork the repository and clone your fork.
2. Create a virtual environment:

```bash
python -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt -r requirements-dev.txt
```

3. Copy the environment template:

```bash
cp .env.example .env
```

4. Start the app locally:

```bash
.venv/bin/python -m uvicorn main:app --reload --port 8090
```

5. Run tests before opening a pull request:

```bash
.venv/bin/pytest
```

## Coding standards

- Keep changes focused and easy to review.
- Prefer additive changes over risky refactors.
- Preserve the current FastAPI and single-file frontend architecture unless a refactor is clearly justified.
- Add small, purposeful comments only where the logic is otherwise hard to follow.
- Keep secrets, local runtime data, and generated files out of Git.

## Commit message conventions

Use Conventional Commits:

- `feat:`
- `fix:`
- `docs:`
- `refactor:`
- `test:`
- `chore:`

Examples:

- `docs: improve setup and governance documentation`
- `test: add auth and status API coverage`
- `chore: remove tracked macOS metadata file`

## Pull request process

1. Rebase or merge the latest `main` into your branch.
2. Keep pull requests scoped to one concern when possible.
3. Include a short summary of behavior changes and testing performed.
4. Link any relevant issue or discussion.
5. Wait for CI to pass before requesting merge.
