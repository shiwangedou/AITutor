#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT_DIR/logs"
CLEAR_RUNTIME_LOGS="${CLEAR_RUNTIME_LOGS:-1}"

log() {
  printf '[logs] %s\n' "$1"
}

if [[ "$CLEAR_RUNTIME_LOGS" != "1" ]]; then
  log "CLEAR_RUNTIME_LOGS=$CLEAR_RUNTIME_LOGS; skipping runtime log clear"
  exit 0
fi

mkdir -p "$LOG_DIR"

# Truncate instead of deleting so running tee processes and Finder-visible files keep working.
: > "$LOG_DIR/api.log"
: > "$LOG_DIR/agent.log"
date '+%Y-%m-%d %H:%M:%S %z' > "$LOG_DIR/.last_cleared"

log "Cleared logs/api.log and logs/agent.log"
