import os
import json
import logging
from pathlib import Path

from dotenv import load_dotenv
from livekit import agents
from livekit.agents import (
    Agent,
    AgentServer,
    AgentSession,
    TurnHandlingOptions,
    inference,
    room_io,
)
from livekit.plugins import silero


ROOT_ENV = Path(__file__).resolve().parents[1] / ".env"
load_dotenv(ROOT_ENV)
load_dotenv()

SUBJECT = os.getenv("TUTOR_SUBJECT", "english-speaking")
STT_MODEL = os.getenv("STT_MODEL", "deepgram/flux-general")
STT_LANGUAGE = os.getenv("STT_LANGUAGE", "en")
STT_EAGER_EOT_THRESHOLD = float(os.getenv("STT_EAGER_EOT_THRESHOLD", "0.4"))
STT_EOT_TIMEOUT_MS = int(os.getenv("STT_EOT_TIMEOUT_MS", "700"))
LLM_MODEL = os.getenv("LLM_MODEL", "openai/gpt-4.1-nano")
LLM_MAX_TOKENS = int(os.getenv("LLM_MAX_TOKENS", "60"))
LLM_TEMPERATURE = float(os.getenv("LLM_TEMPERATURE", "0.2"))
TTS_MODEL = os.getenv("TTS_MODEL", "cartesia/sonic-turbo")
TTS_VOICE = os.getenv("TTS_VOICE", "f786b574-daa5-4673-aa0c-cbe3e8534c02")
TTS_SPEED = os.getenv("TTS_SPEED", "normal")
TTS_VOLUME = float(os.getenv("TTS_VOLUME", "1.0"))
TTS_MAX_BUFFER_DELAY_MS = os.getenv("TTS_MAX_BUFFER_DELAY_MS", "300")
PREEMPTIVE_TTS = os.getenv("PREEMPTIVE_TTS", "true").lower() in {"1", "true", "yes"}
SERVER = AgentServer()
LOGGER = logging.getLogger("aitutor.agent")


def build_stt_extra_kwargs() -> dict[str, object]:
    return {
        "eager_eot_threshold": STT_EAGER_EOT_THRESHOLD,
        "eot_timeout_ms": STT_EOT_TIMEOUT_MS,
    }


def build_llm_extra_kwargs() -> dict[str, object]:
    return {
        "max_tokens": LLM_MAX_TOKENS,
        "temperature": LLM_TEMPERATURE,
    }


def build_tts_extra_kwargs() -> dict[str, object]:
    extra_kwargs: dict[str, object] = {
        "speed": TTS_SPEED,
        "volume": TTS_VOLUME,
    }
    if TTS_MAX_BUFFER_DELAY_MS:
        extra_kwargs["max_buffer_delay_ms"] = int(TTS_MAX_BUFFER_DELAY_MS)
    return extra_kwargs


def log_latency_event(label: str, payload: dict[str, object]) -> None:
    LOGGER.info("[latency] %s %s", label, json.dumps(payload, sort_keys=True, default=str))


def attach_latency_logging(session: AgentSession) -> None:
    @session.on("conversation_item_added")
    def on_conversation_item_added(event) -> None:
        item = getattr(event, "item", None)
        role = getattr(item, "role", None)
        metrics = getattr(item, "metrics", None)
        if not role or not metrics:
            return

        useful_metrics = {
            key: value
            for key, value in metrics.items()
            if key
            in {
                "transcription_delay",
                "end_of_turn_delay",
                "on_user_turn_completed_delay",
                "llm_node_ttft",
                "tts_node_ttfb",
                "playback_latency",
                "e2e_latency",
            }
        }
        if useful_metrics:
            log_latency_event("conversation_item", {"role": role, **useful_metrics})

    @session.on("agent_state_changed")
    def on_agent_state_changed(event) -> None:
        log_latency_event(
            "agent_state",
            {
                "old_state": event.old_state,
                "new_state": event.new_state,
            },
        )


def build_system_prompt(subject: str) -> str:
    return (
        "You are AITutor, a friendly real-time English speaking coach. "
        f"The lesson focus is {subject}. "
        "Speak clearly at a calm natural pace, like a patient pronunciation coach. "
        "Use short sentences with brief natural pauses. "
        "Avoid long clauses, idioms, and fast explanations. "
        "Keep every reply to one or two short sentences, under 18 words total. "
        "Do not give long explanations unless the learner asks for detail. "
        "If the learner asks to start the practice, greet briefly and ask one easy warm-up question. "
        "Encourage the learner first, then correct one important issue at a time. "
        "When correcting pronunciation or grammar, say the corrected sentence clearly once. "
        "If the learner gives a short answer, ask an easier follow-up. "
        "If the learner answers confidently, ask a slightly deeper follow-up. "
        "End each turn with exactly one clear follow-up question."
    )


class Assistant(Agent):
    def __init__(self, subject: str) -> None:
        super().__init__(
            instructions=build_system_prompt(subject),
        )


@SERVER.rtc_session()
async def entrypoint(ctx: agents.JobContext) -> None:
    session = AgentSession(
        stt=inference.STT(
            model=STT_MODEL,
            language=STT_LANGUAGE,
            extra_kwargs=build_stt_extra_kwargs(),
        ),
        llm=inference.LLM(
            model=LLM_MODEL,
            extra_kwargs=build_llm_extra_kwargs(),
        ),
        tts=inference.TTS(
            model=TTS_MODEL,
            voice=TTS_VOICE,
            extra_kwargs=build_tts_extra_kwargs(),
        ),
        vad=silero.VAD.load(),
        turn_handling=TurnHandlingOptions(
            turn_detection="stt",
            endpointing={
                "min_delay": 0.1,
                "max_delay": 1.0,
            },
            preemptive_generation={
                "enabled": True,
                "preemptive_tts": PREEMPTIVE_TTS,
            },
        ),
        aec_warmup_duration=1.0,
    )
    attach_latency_logging(session)

    await session.start(
        room=ctx.room,
        agent=Assistant(SUBJECT),
        room_options=room_io.RoomOptions(
            audio_input=room_io.AudioInputOptions(),
        ),
    )


if __name__ == "__main__":
    agents.cli.run_app(SERVER)
