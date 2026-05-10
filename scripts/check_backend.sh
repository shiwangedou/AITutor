#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
LOG_DIR="$ROOT_DIR/logs"
AGENT_LOG="$LOG_DIR/agent.log"
LAST_CLEARED="$LOG_DIR/.last_cleared"

log() {
  printf '[check] %s\n' "$1"
}

fail() {
  printf '[check] FAIL: %s\n' "$1"
  exit 1
}

if [[ ! -x "$BACKEND_DIR/.venv/bin/python" ]]; then
  fail "backend virtual environment missing. Run ./start_all.sh first."
fi

log "Running backend diagnostics"
"$BACKEND_DIR/.venv/bin/python" "$BACKEND_DIR/tests/diagnose_backend.py" --verbose

if [[ ! -f "$AGENT_LOG" ]]; then
  fail "missing $AGENT_LOG. Start services with ./start_all.sh first."
fi

if grep -q "registered worker" "$AGENT_LOG"; then
  log "OK: agent registered worker found in logs/agent.log"
else
  if [[ -f "$LAST_CLEARED" ]]; then
    fail "agent registered worker not found in logs/agent.log. Logs were last cleared at $(cat "$LAST_CLEARED"); restart ./start_all.sh or wait for a new agent registration line."
  fi
  fail "agent registered worker not found in logs/agent.log"
fi

log "All backend checks passed"
