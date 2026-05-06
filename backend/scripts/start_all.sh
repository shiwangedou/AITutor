#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$BACKEND_DIR/.." && pwd)"
LOG_DIR="$ROOT_DIR/logs"
API_LOG="$LOG_DIR/api.log"
AGENT_LOG="$LOG_DIR/agent.log"

API_PID=""
AGENT_PID=""
API_READY_TIMEOUT="${API_READY_TIMEOUT:-30}"
AGENT_READY_TIMEOUT="${AGENT_READY_TIMEOUT:-60}"

log() {
  printf '[dev] %s\n' "$1"
}

fail() {
  printf '[dev] FAIL: %s\n' "$1"
  exit 1
}

cleanup() {
  log "Stopping services"
  if [[ -n "$API_PID" ]] && kill -0 "$API_PID" 2>/dev/null; then
    kill "$API_PID" 2>/dev/null || true
  fi
  if [[ -n "$AGENT_PID" ]] && kill -0 "$AGENT_PID" 2>/dev/null; then
    kill "$AGENT_PID" 2>/dev/null || true
  fi
}

trap cleanup EXIT INT TERM

wait_for_api() {
  local deadline=$((SECONDS + API_READY_TIMEOUT))
  while (( SECONDS < deadline )); do
    if curl -fsS "http://127.0.0.1:8000/health" >/dev/null 2>&1; then
      log "Backend API ready"
      return 0
    fi
    sleep 1
  done
  fail "Backend API did not become ready within ${API_READY_TIMEOUT}s"
}

wait_for_agent() {
  local deadline=$((SECONDS + AGENT_READY_TIMEOUT))
  while (( SECONDS < deadline )); do
    if grep -q "registered worker" "$AGENT_LOG" 2>/dev/null; then
      log "Agent registered worker"
      return 0
    fi
    sleep 1
  done
  fail "Agent did not register worker within ${AGENT_READY_TIMEOUT}s. Check $AGENT_LOG"
}

cd "$BACKEND_DIR"
mkdir -p "$LOG_DIR"
: > "$API_LOG"
: > "$AGENT_LOG"

log "Writing API logs to $API_LOG"
log "Writing agent logs to $AGENT_LOG"

log "Starting API server"
"$SCRIPT_DIR/start_api.sh" > >(tee -a "$API_LOG") 2> >(tee -a "$API_LOG" >&2) &
API_PID="$!"

wait_for_api

log "Starting LiveKit agent"
"$SCRIPT_DIR/start_agent.sh" > >(tee -a "$AGENT_LOG") 2> >(tee -a "$AGENT_LOG" >&2) &
AGENT_PID="$!"

wait_for_agent

log "API PID: $API_PID"
log "Agent PID: $AGENT_PID"
log "All backend services ready"
log "Press Ctrl+C to stop both services"
log "Optional: run ./check_backend.sh from project root for a full diagnostic pass"

wait -n "$API_PID" "$AGENT_PID"
