#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_LOG="$ROOT_DIR/logs/agent.log"

log() {
  printf '[audio-check] %s\n' "$1"
}

fail() {
  printf '[audio-check] FAIL: %s\n' "$1"
  exit 1
}

if [[ ! -f "$AGENT_LOG" ]]; then
  fail "missing logs/agent.log. Start services with ./start_all.sh first."
fi

if [[ ! -s "$AGENT_LOG" ]]; then
  fail "logs/agent.log is empty. Run the app once, connect/start or send text, then run this check again."
fi

slow_tts_count="$(grep -c "flush audio emitter due to slow" "$AGENT_LOG" || true)"
input_not_started_count="$(grep -c "input speech hasn't started yet" "$AGENT_LOG" || true)"
mic_track_count="$(grep -c "SOURCE_MICROPHONE" "$AGENT_LOG" || true)"
worker_count="$(grep -c "registered worker" "$AGENT_LOG" || true)"
transcript_stats="$(
  python3 - "$AGENT_LOG" <<'PY'
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
values = [float(value) for value in re.findall(r'"transcript_delay": ([0-9.]+)', text)]
if not values:
    print("none")
else:
    print(f"count={len(values)} avg={sum(values)/len(values):.2f}s max={max(values):.2f}s")
PY
)"
latency_stats="$(
  python3 - "$AGENT_LOG" <<'PY'
import json
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
metrics: dict[str, list[float]] = {}
for payload in re.findall(r"\[latency\] conversation_item\s+(\{.*?\})\s+\{\"pid\"", text, flags=re.S):
    payload = re.sub(r"\s+", " ", payload)
    try:
        data = json.loads(payload)
    except Exception:
        continue
    for key in ["e2e_latency", "llm_node_ttft", "tts_node_ttfb", "playback_latency", "end_of_turn_delay"]:
        value = data.get(key)
        if isinstance(value, int | float):
            metrics.setdefault(key, []).append(float(value))

if not metrics:
    print("none")
else:
    parts = []
    for key in sorted(metrics):
        values = metrics[key]
        parts.append(f"{key}: count={len(values)} avg={sum(values)/len(values):.2f}s max={max(values):.2f}s")
    print(" | ".join(parts))
PY
)"

log "registered worker lines: $worker_count"
log "microphone track lines: $mic_track_count"
log "input-not-started warnings: $input_not_started_count"
log "slow-TTS flush lines: $slow_tts_count"
log "transcript delay stats: $transcript_stats"
log "latency metrics: $latency_stats"

if (( slow_tts_count > 0 )); then
  log "Likely cause: TTS generation is too slow, so LiveKit flushes audio in chunks."
  log "Try: keep TTS_MODEL=cartesia/sonic-turbo, TTS_SPEED=normal, and shorten tutor replies."
else
  log "No slow TTS generation warnings found in current logs."
fi

if [[ "$transcript_stats" != "none" ]]; then
  max_delay="$(printf '%s' "$transcript_stats" | sed -E 's/.*max=([0-9.]+)s.*/\1/')"
  if awk "BEGIN { exit !($max_delay > 1.5) }"; then
    log "Likely cause: STT/endpointing delay is sometimes high. Flux STT plus STT-based turn detection should improve this after restart."
  fi
fi

if (( mic_track_count == 0 )); then
  log "No SOURCE_MICROPHONE line found. If voice input fails, press Start and confirm microphone publish logs in Xcode."
fi

if (( input_not_started_count > 5 && mic_track_count == 0 )); then
  log "Likely cause: agent is waiting for user speech but no stable microphone track reached the room."
elif (( input_not_started_count > 5 )); then
  log "Input warnings exist. This can be normal before speaking, but repeated warnings during speech suggest mic/audio route instability."
fi

log "Recent useful lines:"
grep -E "\\[latency\\]|registered worker|SOURCE_MICROPHONE|flush audio emitter due to slow|slow audio generation|input speech hasn't started yet|transcript|error|ERROR|WARNING" "$AGENT_LOG" | tail -n 40 || true
