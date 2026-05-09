#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$BACKEND_DIR/.." && pwd)"
LOG_DIR="$ROOT_DIR/logs"
API_LOG="$LOG_DIR/api.log"
AGENT_LOG="$LOG_DIR/agent.log"
IOS_START_SCRIPT="$ROOT_DIR/ios/scripts/start_ios.sh"
CLEAR_LOGS_SCRIPT="$ROOT_DIR/clear_logs.sh"

API_PID=""
AGENT_PID=""
API_READY_TIMEOUT="${API_READY_TIMEOUT:-30}"
AGENT_READY_TIMEOUT="${AGENT_READY_TIMEOUT:-60}"
START_IOS_APP="${START_IOS_APP:-1}"

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

stop_existing_agent_processes() {
  local existing_agents
  existing_agents="$(pgrep -fl "agent.py dev" 2>/dev/null || true)"
  if [[ -n "$existing_agents" ]]; then
    log "Existing LiveKit agent process found; stopping it to avoid duplicate tutor voices"
    printf '%s\n' "$existing_agents" >&2
    pkill -TERM -f "agent.py dev" 2>/dev/null || true
    sleep 1
    existing_agents="$(pgrep -fl "agent.py dev" 2>/dev/null || true)"
    if [[ -n "$existing_agents" ]]; then
      log "Existing agent did not stop after TERM; forcing shutdown"
      printf '%s\n' "$existing_agents" >&2
      pkill -KILL -f "agent.py dev" 2>/dev/null || true
      sleep 1
      existing_agents="$(pgrep -fl "agent.py dev" 2>/dev/null || true)"
      if [[ -n "$existing_agents" ]]; then
        printf '%s\n' "$existing_agents" >&2
        fail "Could not stop existing LiveKit agent process. Stop it manually, then rerun ./start_all.sh."
      fi
    fi
  fi
}

stop_existing_api_processes() {
  local port="${BACKEND_PORT:-8000}"
  local existing_apis
  existing_apis="$(pgrep -fl "uvicorn main:app.*--port ${port}" 2>/dev/null || true)"
  if [[ -n "$existing_apis" ]]; then
    log "Existing backend API process found on port $port; stopping it before clean restart"
    printf '%s\n' "$existing_apis" >&2
    pkill -TERM -f "uvicorn main:app.*--port ${port}" 2>/dev/null || true
    sleep 1
    existing_apis="$(pgrep -fl "uvicorn main:app.*--port ${port}" 2>/dev/null || true)"
    if [[ -n "$existing_apis" ]]; then
      log "Existing backend API did not stop after TERM; forcing shutdown"
      printf '%s\n' "$existing_apis" >&2
      pkill -KILL -f "uvicorn main:app.*--port ${port}" 2>/dev/null || true
      sleep 1
      existing_apis="$(pgrep -fl "uvicorn main:app.*--port ${port}" 2>/dev/null || true)"
      if [[ -n "$existing_apis" ]]; then
        printf '%s\n' "$existing_apis" >&2
        fail "Could not stop existing backend API process. Stop it manually, then rerun ./start_all.sh."
      fi
    fi
  fi
}

cd "$BACKEND_DIR"
stop_existing_api_processes
stop_existing_agent_processes

if [[ -x "$CLEAR_LOGS_SCRIPT" ]]; then
  "$CLEAR_LOGS_SCRIPT"
else
  mkdir -p "$LOG_DIR"
  : > "$API_LOG"
  : > "$AGENT_LOG"
fi

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
if [[ "$START_IOS_APP" == "1" && -x "$IOS_START_SCRIPT" ]]; then
  log "Starting iOS helper"
  "$IOS_START_SCRIPT" || log "iOS helper failed; backend services are still running"
elif [[ "$START_IOS_APP" != "1" ]]; then
  log "START_IOS_APP=$START_IOS_APP; skipping iOS helper"
fi

log "Press Ctrl+C to stop both services"
log "Optional: run ./check_backend.sh from project root for a full diagnostic pass"

wait -n "$API_PID" "$AGENT_PID"
