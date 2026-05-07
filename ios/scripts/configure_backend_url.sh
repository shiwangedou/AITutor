#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$IOS_DIR/.." && pwd)"
PROJECT_YML="$IOS_DIR/project.yml"
PBXPROJ="$IOS_DIR/AITutor.xcodeproj/project.pbxproj"

log() {
  printf '[ios-config] %s\n' "$1"
}

detect_lan_ip() {
  local ip=""

  if command -v ipconfig >/dev/null 2>&1; then
    ip="$(ipconfig getifaddr en0 2>/dev/null || true)"
    if [[ -z "$ip" ]]; then
      ip="$(ipconfig getifaddr en1 2>/dev/null || true)"
    fi
  fi

  if [[ -z "$ip" ]] && command -v ifconfig >/dev/null 2>&1; then
    ip="$(ifconfig | awk '/inet / && $2 != "127.0.0.1" { print $2; exit }')"
  fi

  printf '%s' "$ip"
}

escape_for_perl_replacement() {
  printf '%s' "$1" | sed 's/[&\\/]/\\&/g'
}

BACKEND_PORT="${IOS_BACKEND_PORT:-${BACKEND_PORT:-8000}}"

if [[ -n "${IOS_BACKEND_BASE_URL:-}" ]]; then
  BACKEND_BASE_URL="$IOS_BACKEND_BASE_URL"
else
  BACKEND_HOST="${IOS_BACKEND_HOST:-$(detect_lan_ip)}"
  if [[ -z "$BACKEND_HOST" ]]; then
    BACKEND_HOST="127.0.0.1"
    log "Could not detect LAN IP; falling back to simulator/local URL."
  fi
  BACKEND_BASE_URL="http://${BACKEND_HOST}:${BACKEND_PORT}"
fi

if [[ ! "$BACKEND_BASE_URL" =~ ^https?:// ]]; then
  log "Invalid BACKEND_BASE_URL: $BACKEND_BASE_URL"
  log "Use IOS_BACKEND_BASE_URL=http://<host>:<port> or IOS_BACKEND_HOST=<host>."
  exit 1
fi

if [[ ! -f "$PROJECT_YML" ]]; then
  log "Missing project file: $PROJECT_YML"
  exit 1
fi

if [[ ! -f "$PBXPROJ" ]]; then
  log "Missing Xcode project file: $PBXPROJ"
  exit 1
fi

escaped_url="$(escape_for_perl_replacement "$BACKEND_BASE_URL")"

perl -0pi -e "s#BACKEND_BASE_URL:\\s*[^\\n]+#BACKEND_BASE_URL: $escaped_url#g" "$PROJECT_YML"
perl -0pi -e "s#BACKEND_BASE_URL = \\\"[^\\\"]*\\\";#BACKEND_BASE_URL = \\\"$escaped_url\\\";#g" "$PBXPROJ"

log "Configured BACKEND_BASE_URL=$BACKEND_BASE_URL"
log "Updated ios/project.yml and ios/AITutor.xcodeproj"
