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

ANALYSIS_LOG="$(mktemp "${TMPDIR:-/tmp}/aitutor-audio-health.XXXXXX")"
cleanup() {
  rm -f "$ANALYSIS_LOG"
}
trap cleanup EXIT

python3 - "$AGENT_LOG" "$ANALYSIS_LOG" <<'PY'
import sys
from pathlib import Path

source = Path(sys.argv[1])
target = Path(sys.argv[2])
text = source.read_text(encoding="utf-8", errors="replace")
marker = "[profile] voice_pipeline"
index = text.rfind(marker)
if index >= 0:
    text = text[index:]
target.write_text(text, encoding="utf-8")
PY

slow_tts_count="$(grep -c "flush audio emitter due to slow" "$ANALYSIS_LOG" || true)"
smooth_tts_count="$(grep -c "\\[latency\\] smooth_tts_buffer" "$ANALYSIS_LOG" || true)"
balanced_tts_count="$(grep -c "\\[latency\\] balanced_tts_buffer" "$ANALYSIS_LOG" || true)"
profile_slow_count="$(grep -c "\\[profile\\] slow assistant" "$ANALYSIS_LOG" || true)"
voice_profile="$(
  python3 - "$ANALYSIS_LOG" <<'PY'
import json
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
matches = re.findall(r"\[profile\]\s+voice_pipeline\s+(\{.*?\})", text, flags=re.S)
for payload in reversed(matches):
    try:
        print(json.loads(re.sub(r"\s+", " ", payload)).get("profile", "unknown"))
        break
    except Exception:
        continue
else:
    print("unknown")
PY
)"
if [[ "$voice_profile" == "unknown" && -f "$ROOT_DIR/env" ]]; then
  voice_profile="$(grep -E '^VOICE_PIPELINE_PROFILE=' "$ROOT_DIR/env" | tail -n 1 | cut -d '=' -f 2- || true)"
  voice_profile="${voice_profile:-unknown}"
fi
input_not_started_count="$(grep -c "input speech hasn't started yet" "$ANALYSIS_LOG" || true)"
stt_timeout_count="$(grep -c "failed to recognize speech:.*timed out\\|LiveKit Inference STT connection timed out" "$ANALYSIS_LOG" || true)"
interruption_timeout_count="$(grep -c "interruption inference timed out\\|adaptive interruption disabled" "$ANALYSIS_LOG" || true)"
uninterruptible_input_count="$(grep -c "This generation handle does not allow interruptions" "$ANALYSIS_LOG" || true)"
mic_track_count="$(grep -c "SOURCE_MICROPHONE" "$ANALYSIS_LOG" || true)"
worker_count="$(grep -c "registered worker" "$AGENT_LOG" || true)"
transcript_stats="$(
  python3 - "$ANALYSIS_LOG" <<'PY'
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
  python3 - "$ANALYSIS_LOG" <<'PY'
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
log "STT timeout warnings: $stt_timeout_count"
log "adaptive interruption timeout/error lines: $interruption_timeout_count"
log "input-during-uninterruptible-speech lines: $uninterruptible_input_count"
log "voice pipeline profile: $voice_profile"
log "slow-TTS flush lines: $slow_tts_count"
log "balanced-TTS buffer lines in latest profile section: $balanced_tts_count"
log "smooth-TTS buffer lines in latest profile section: $smooth_tts_count"
log "profile slow-turn diagnostic lines: $profile_slow_count"
log "transcript delay stats: $transcript_stats"
log "latency metrics: $latency_stats"

if [[ "$voice_profile" == "balanced" && "$balanced_tts_count" -gt 0 ]]; then
  log "Balanced profile should now use LiveKit's default streaming TTS path, not balanced_tts_buffer. Restart ./start_all.sh and make sure no old agent process is still running."
fi

if (( slow_tts_count > 0 )); then
  if [[ "$voice_profile" == "balanced" ]]; then
    log "Balanced now uses SDK streaming TTS with a short-reply prompt. Slow flushes here usually point to provider/network chunking rather than custom buffering."
    log "If this is audible, use VOICE_PIPELINE_PROFILE=smooth for the demo-safe full-sentence fallback, or keep balanced and test again after a clean restart."
  elif [[ "$voice_profile" == "smooth" && "$smooth_tts_count" -gt 0 ]]; then
    log "Slow TTS flushes happened during server-side buffering. In smooth mode, this should add wait time but should not be audible as mid-sentence stutter."
    log "If the iPhone still sounds choppy, inspect audio route/network/device output next."
  elif [[ "$voice_profile" == "smooth" ]]; then
    log "Smooth profile is configured, but no smooth_tts_buffer evidence was found. Restart ./start_all.sh so the latest agent code and env are active."
  elif [[ "$voice_profile" == "realtime" ]]; then
    log "Realtime profile uses LiveKit's streaming TTS path. Slow-TTS flushes can be audible as chunking; switch VOICE_PIPELINE_PROFILE=balanced first, or smooth for maximum demo stability."
  else
    log "Likely cause: TTS generation is too slow, so LiveKit flushes audio in audible chunks. Confirm VOICE_PIPELINE_PROFILE in env and restart services."
  fi
else
  log "No slow TTS generation warnings found in current logs."
fi

if (( profile_slow_count > 0 )); then
  log "Profile diagnostics observed slow assistant turns. This is informational only; the agent no longer changes profile dynamically during a session."
fi

if (( stt_timeout_count > 0 )); then
  log "STT timeout warnings were found. This can delay turn recognition and make feedback feel uneven even when TTS itself is not flushing."
fi

if (( interruption_timeout_count > 0 )); then
  log "Adaptive interruption timeout/errors were found. Balanced and smooth disable interruption to prioritize smooth playback over barge-in."
fi

if (( uninterruptible_input_count > 0 )); then
  log "Input arrived while tutor speech was marked uninterruptible. For smooth demo playback, wait until the tutor finishes before speaking or sending text."
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
grep -E "\\[latency\\]|\\[profile\\]|balanced_tts_buffer|smooth_tts_buffer|registered worker|SOURCE_MICROPHONE|flush audio emitter due to slow|slow audio generation|input speech hasn't started yet|failed to recognize speech|interruption inference timed out|adaptive interruption disabled|does not allow interruptions|transcript|error|ERROR|WARNING" "$ANALYSIS_LOG" | tail -n 40 || true
