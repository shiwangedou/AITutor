#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$IOS_DIR/.." && pwd)"
PROJECT_PATH="$IOS_DIR/AITutor.xcodeproj"
CONFIG_SCRIPT="$SCRIPT_DIR/configure_backend_url.sh"
CLEAR_LOGS_SCRIPT="$ROOT_DIR/scripts/clear_logs.sh"

IOS_OPEN_XCODE="${IOS_OPEN_XCODE:-1}"
IOS_AUTO_RUN="${IOS_AUTO_RUN:-1}"
IOS_RUN_DELAY_SECONDS="${IOS_RUN_DELAY_SECONDS:-5}"

log() {
  printf '[ios-start] %s\n' "$1"
}

if [[ ! -x "$CONFIG_SCRIPT" ]]; then
  log "Missing or non-executable config script: $CONFIG_SCRIPT"
  exit 1
fi

"$CONFIG_SCRIPT"

if [[ -x "$CLEAR_LOGS_SCRIPT" ]]; then
  "$CLEAR_LOGS_SCRIPT"
else
  log "Missing clear logs script: $CLEAR_LOGS_SCRIPT"
fi

if [[ "$IOS_OPEN_XCODE" != "1" ]]; then
  log "IOS_OPEN_XCODE=$IOS_OPEN_XCODE; skipping Xcode open/run."
  exit 0
fi

if [[ ! -d "$PROJECT_PATH" ]]; then
  log "Missing Xcode project: $PROJECT_PATH"
  exit 1
fi

log "Opening Xcode project: $PROJECT_PATH"
open "$PROJECT_PATH"

if [[ "$IOS_AUTO_RUN" != "1" ]]; then
  log "IOS_AUTO_RUN=$IOS_AUTO_RUN; opened Xcode without starting the app."
  exit 0
fi

if ! command -v osascript >/dev/null 2>&1; then
  log "osascript not available; open Xcode and press Cmd+R manually."
  exit 0
fi

log "Waiting ${IOS_RUN_DELAY_SECONDS}s for Xcode to finish opening"
sleep "$IOS_RUN_DELAY_SECONDS"

log "Triggering Xcode Run with Cmd+R using the currently selected destination"
if ! osascript <<'APPLESCRIPT'
tell application "Xcode"
  activate
end tell

delay 1

tell application "System Events"
  if exists process "Xcode" then
    keystroke "r" using command down
  end if
end tell
APPLESCRIPT
then
  log "Could not trigger Cmd+R automatically. Open Xcode and press Cmd+R manually."
fi
