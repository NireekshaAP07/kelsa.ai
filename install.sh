#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="${REPO_URL:-https://github.com/notysozu/kelsa.ai}"
REPO_BRANCH="${REPO_BRANCH:-main}"
DEFAULT_DIR_NAME="${DEFAULT_DIR_NAME:-kelsa.ai}"
INSTALL_DIR="${INSTALL_DIR:-}"
START_APP="${START_APP:-1}"
INSTALL_UPDATE="${INSTALL_UPDATE:-0}"
APP_HOST_VALUE="${APP_HOST_VALUE:-0.0.0.0}"
APP_PORT_VALUE="${APP_PORT_VALUE:-8090}"
APP_RELOAD_VALUE="${APP_RELOAD_VALUE:-false}"

log() {
  printf '[kelsa-install] %s\n' "$*"
}

warn() {
  printf '[kelsa-install] warning: %s\n' "$*" >&2
}

fail() {
  printf '[kelsa-install] error: %s\n' "$*" >&2
  exit 1
}

on_error() {
  local line_number="${1:-unknown}"
  fail "installation failed near line ${line_number}"
}

trap 'on_error $LINENO' ERR

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

run_with_optional_sudo() {
  if command_exists sudo && [ "${EUID:-$(id -u)}" -ne 0 ]; then
    sudo "$@"
  else
    "$@"
  fi
}

detect_package_manager() {
  if command_exists apt-get; then
    printf 'apt'
    return
  fi
  if command_exists pacman; then
    printf 'pacman'
    return
  fi
  if command_exists dnf; then
    printf 'dnf'
    return
  fi
  if command_exists brew; then
    printf 'brew'
    return
  fi
  printf 'unknown'
}

python_version_ok() {
  local candidate="${1:?python command required}"
  "$candidate" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)' >/dev/null 2>&1
}

pick_python() {
  local candidate
  for candidate in python3.12 python3.11 python3.10 python3 python; do
    if command_exists "$candidate" && python_version_ok "$candidate"; then
      printf '%s' "$candidate"
      return
    fi
  done
  return 1
}

install_system_dependencies() {
  local package_manager="$1"
  case "$package_manager" in
    apt)
      log "Installing required system packages with apt"
      run_with_optional_sudo apt-get update
      run_with_optional_sudo apt-get install -y git curl wget python3 python3-venv
      ;;
    pacman)
      log "Installing required system packages with pacman"
      run_with_optional_sudo pacman -Sy --noconfirm git curl wget python python-pip
      ;;
    dnf)
      log "Installing required system packages with dnf"
      run_with_optional_sudo dnf install -y git curl wget python3 python3-pip
      ;;
    brew)
      log "Installing required system packages with Homebrew"
      brew install git python wget curl
      ;;
    *)
      fail "no supported package manager detected. Install Git and Python 3.10+ manually, then rerun."
      ;;
  esac
}

ensure_prerequisites() {
  if command_exists git; then
    log "Git is already installed"
  else
    local package_manager
    package_manager="$(detect_package_manager)"
    install_system_dependencies "$package_manager"
  fi

  if pick_python >/dev/null 2>&1; then
    log "A compatible Python interpreter is already available"
    return
  fi

  local package_manager
  package_manager="$(detect_package_manager)"
  install_system_dependencies "$package_manager"

  if ! pick_python >/dev/null 2>&1; then
    fail "Python 3.10+ is still unavailable after dependency installation"
  fi
}

resolve_project_dir() {
  local cwd
  cwd="$(pwd)"
  if [ -f "${cwd}/main.py" ] && [ -f "${cwd}/requirements.txt" ] && [ -f "${cwd}/index.html" ]; then
    printf '%s' "$cwd"
    return
  fi

  if [ -n "$INSTALL_DIR" ]; then
    printf '%s' "$INSTALL_DIR"
    return
  fi

  printf '%s/%s' "$cwd" "$DEFAULT_DIR_NAME"
}

prepare_repo() {
  local project_dir="$1"
  if [ -f "${project_dir}/main.py" ] && [ -f "${project_dir}/requirements.txt" ]; then
    log "Using existing project checkout at ${project_dir}"
    if [ "$INSTALL_UPDATE" = "1" ] && [ -d "${project_dir}/.git" ]; then
      log "Refreshing repository because INSTALL_UPDATE=1"
      git -C "$project_dir" fetch origin "$REPO_BRANCH"
      git -C "$project_dir" pull --ff-only origin "$REPO_BRANCH"
    fi
    return
  fi

  if [ -e "$project_dir" ] && [ ! -d "$project_dir" ]; then
    fail "install target exists but is not a directory: ${project_dir}"
  fi

  log "Cloning repository into ${project_dir}"
  git clone --branch "$REPO_BRANCH" --single-branch "$REPO_URL" "$project_dir"
}

ensure_env_file() {
  local project_dir="$1"
  local python_bin="$2"
  local env_file="${project_dir}/.env"
  local example_file="${project_dir}/.env.example"

  if [ ! -f "$env_file" ]; then
    if [ -f "$example_file" ]; then
      cp "$example_file" "$env_file"
      log "Created .env from .env.example"
    else
      cat >"$env_file" <<EOF
SESSION_SECRET=
APP_HOST=${APP_HOST_VALUE}
APP_PORT=${APP_PORT_VALUE}
APP_RELOAD=${APP_RELOAD_VALUE}
SESSION_COOKIE_SECURE=false
SESSION_COOKIE_SAMESITE=lax
SESSION_COOKIE_MAX_AGE=604800
AUTOMATION_API_KEY=
HINDSIGHT_ENABLED=false
HINDSIGHT_BASE_URL=https://api.hindsight.vectorize.io
HINDSIGHT_API_KEY=
EOF
      log "Created .env with default values"
    fi
  else
    log "Keeping existing .env"
  fi

  local session_secret
  session_secret="$("$python_bin" -c 'import secrets; print(secrets.token_urlsafe(48))')"
  local automation_key
  automation_key="$("$python_bin" -c 'import secrets; print(secrets.token_urlsafe(32))')"

  "$python_bin" - "$env_file" "$session_secret" "$automation_key" "$APP_HOST_VALUE" "$APP_PORT_VALUE" "$APP_RELOAD_VALUE" <<'PY'
from pathlib import Path
import sys

env_path = Path(sys.argv[1])
session_secret = sys.argv[2]
automation_key = sys.argv[3]
app_host = sys.argv[4]
app_port = sys.argv[5]
app_reload = sys.argv[6]

defaults = {
    "SESSION_SECRET": session_secret,
    "APP_HOST": app_host,
    "APP_PORT": app_port,
    "APP_RELOAD": app_reload,
    "SESSION_COOKIE_SECURE": "false",
    "SESSION_COOKIE_SAMESITE": "lax",
    "SESSION_COOKIE_MAX_AGE": "604800",
    "AUTOMATION_API_KEY": automation_key,
    "HINDSIGHT_ENABLED": "false",
    "HINDSIGHT_BASE_URL": "https://api.hindsight.vectorize.io",
    "HINDSIGHT_API_KEY": "",
}

placeholder_values = {
    "replace-with-a-long-random-secret",
    "replace-with-a-shared-secret-for-n8n",
    "replace-this-with-a-long-random-secret",
}

lines = env_path.read_text(encoding="utf-8").splitlines()
updated = []
seen = set()

for raw_line in lines:
    line = raw_line
    stripped = raw_line.strip()
    if not stripped or stripped.startswith("#") or "=" not in raw_line:
      updated.append(raw_line)
      continue

    key, value = raw_line.split("=", 1)
    seen.add(key)
    current = value.strip()
    if key == "SESSION_SECRET" and (not current or current in placeholder_values):
      line = f"{key}={session_secret}"
    elif key == "AUTOMATION_API_KEY" and (not current or current in placeholder_values):
      line = f"{key}={automation_key}"
    elif key in {"APP_HOST", "APP_PORT", "APP_RELOAD"} and not current:
      line = f"{key}={defaults[key]}"
    updated.append(line)

for key, value in defaults.items():
    if key not in seen:
      updated.append(f"{key}={value}")

env_path.write_text("\n".join(updated).rstrip() + "\n", encoding="utf-8")
PY
}

setup_virtualenv() {
  local project_dir="$1"
  local python_bin="$2"
  local venv_dir="${project_dir}/.venv"
  if [ ! -d "$venv_dir" ]; then
    log "Creating virtual environment"
    "$python_bin" -m venv "$venv_dir"
  else
    log "Reusing existing virtual environment"
  fi

  local venv_python="${venv_dir}/bin/python"
  if [ ! -x "$venv_python" ]; then
    fail "virtual environment python was not created correctly"
  fi

  log "Installing Python dependencies"
  "$venv_python" -m pip install --upgrade pip
  "$venv_python" -m pip install -r "${project_dir}/requirements.txt"
}

start_app() {
  local project_dir="$1"
  local venv_python="${project_dir}/.venv/bin/python"
  if [ "$START_APP" != "1" ]; then
    log "Skipping app start because START_APP=${START_APP}"
    return
  fi

  log "Starting kelsa.ai at http://127.0.0.1:${APP_PORT_VALUE}"
  cd "$project_dir"
  exec "$venv_python" main.py
}

main() {
  log "Beginning automated install for ${REPO_URL}"
  ensure_prerequisites

  local project_dir
  project_dir="$(resolve_project_dir)"
  prepare_repo "$project_dir"

  local python_bin
  python_bin="$(pick_python)"
  log "Using Python interpreter: $python_bin"

  ensure_env_file "$project_dir" "$python_bin"
  setup_virtualenv "$project_dir" "$python_bin"

  log "Installation completed successfully"
  log "Project directory: ${project_dir}"
  log "You can rerun without launching by setting START_APP=0"

  start_app "$project_dir"
}

main "$@"
