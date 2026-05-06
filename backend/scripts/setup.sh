#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$BACKEND_DIR/.." && pwd)"
VENV_DIR="$BACKEND_DIR/.venv"

source "$SCRIPT_DIR/env_utils.sh"

log() {
  printf '[setup] %s\n' "$1"
}

cd "$BACKEND_DIR"

sync_visible_env "$ROOT_DIR" "setup"

if [[ ! -d "$VENV_DIR" ]]; then
  log "Creating Python virtual environment"
  python3 -m venv "$VENV_DIR"
fi

log "Installing backend dependencies"
"$VENV_DIR/bin/pip" install -r requirements.txt

log "Downloading LiveKit agent model files"
"$VENV_DIR/bin/python" agent.py download-files

log "Setup complete"
