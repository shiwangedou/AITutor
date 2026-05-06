#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"

log() {
  printf '[root] %s\n' "$1"
}

log "Preparing backend environment"
"$BACKEND_DIR/scripts/setup.sh"

log "Starting backend API and LiveKit agent"
exec "$BACKEND_DIR/scripts/start_all.sh"
