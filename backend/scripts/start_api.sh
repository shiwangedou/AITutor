#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$BACKEND_DIR/.." && pwd)"
VENV_DIR="$BACKEND_DIR/.venv"
HOST="${BACKEND_HOST:-0.0.0.0}"
PORT="${BACKEND_PORT:-8000}"

source "$SCRIPT_DIR/env_utils.sh"

log() {
  printf '[api] %s\n' "$1"
}

cd "$BACKEND_DIR"

sync_visible_env "$ROOT_DIR" "api"

if [[ ! -x "$VENV_DIR/bin/python" ]]; then
  log "ERROR: virtual environment not found. Run ./scripts/setup.sh first."
  exit 1
fi

log "Starting FastAPI server on $HOST:$PORT"
exec "$VENV_DIR/bin/python" -m uvicorn main:app --host "$HOST" --port "$PORT"
