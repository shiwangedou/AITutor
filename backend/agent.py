import os
import json
import logging
import asyncio
from enum import Enum
from pathlib import Path
from dataclasses import dataclass
from collections.abc import AsyncIterable, AsyncGenerator

from dotenv import load_dotenv
from livekit import agents, rtc
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
SERVER = AgentServer()
LOGGER = logging.getLogger("aitutor.agent")


class VoicePipelineProfile(str, Enum):
    BALANCED = "balanced"
    SMOOTH = "smooth"
    REALTIME = "realtime"


@dataclass(frozen=True)
class VoicePipelineConfig:
    profile: VoicePipelineProfile
    stt_model: str
    stt_language: str
    stt_extra_kwargs: dict[str, object]
    llm_model: str
    llm_extra_kwargs: dict[str, object]
    tts_model: str
    tts_voice: str
    tts_extra_kwargs: dict[str, object]
    turn_handling: TurnHandlingOptions
    prompt_level: int
    tts_playback_mode: str
    tts_initial_buffer_seconds: float
    diagnostics_enabled: bool
    tts_ttfb_warn_seconds: float
    llm_ttft_warn_seconds: float
    e2e_warn_seconds: float
    playback_warn_seconds: float


def parse_voice_pipeline_profile() -> VoicePipelineProfile:
    raw_profile = os.getenv("VOICE_PIPELINE_PROFILE", VoicePipelineProfile.SMOOTH.value).strip().lower()
    try:
        return VoicePipelineProfile(raw_profile)
    except ValueError:
        LOGGER.warning(
            "[profile] unknown VOICE_PIPELINE_PROFILE=%s, falling back to smooth",
            raw_profile,
        )
        return VoicePipelineProfile.SMOOTH


def build_voice_pipeline_config(profile: VoicePipelineProfile) -> VoicePipelineConfig:
    shared_stt_extra = {
        "eager_eot_threshold": 0.4,
        "eot_timeout_ms": 700,
    }
    shared_tts_extra = {
        "speed": "normal",
        "volume": 1.0,
    }

    if profile == VoicePipelineProfile.REALTIME:
        return VoicePipelineConfig(
            profile=profile,
            stt_model="deepgram/flux-general",
            stt_language="en",
            stt_extra_kwargs=shared_stt_extra,
            llm_model="openai/gpt-4.1-nano",
            llm_extra_kwargs={"max_tokens": 45, "temperature": 0.2},
            tts_model="cartesia/sonic-turbo",
            tts_voice="f786b574-daa5-4673-aa0c-cbe3e8534c02",
            tts_extra_kwargs={**shared_tts_extra, "max_buffer_delay_ms": 300},
            turn_handling=TurnHandlingOptions(
                turn_detection="stt",
                endpointing={"mode": "fixed", "min_delay": 0.1, "max_delay": 1.0},
                interruption={
                    "enabled": True,
                    "resume_false_interruption": True,
                    "false_interruption_timeout": 2.0,
                },
                preemptive_generation={
                    "enabled": True,
                    "preemptive_tts": False,
                },
            ),
            prompt_level=1,
            tts_playback_mode="streaming",
            tts_initial_buffer_seconds=0.0,
            diagnostics_enabled=True,
            tts_ttfb_warn_seconds=0.75,
            llm_ttft_warn_seconds=2.5,
            e2e_warn_seconds=5.0,
            playback_warn_seconds=1.5,
        )

    if profile == VoicePipelineProfile.SMOOTH:
        return VoicePipelineConfig(
            profile=profile,
            stt_model="deepgram/flux-general",
            stt_language="en",
            stt_extra_kwargs=shared_stt_extra,
            llm_model="openai/gpt-4.1-nano",
            llm_extra_kwargs={"max_tokens": 20, "temperature": 0.2},
            tts_model="cartesia/sonic-turbo",
            tts_voice="f786b574-daa5-4673-aa0c-cbe3e8534c02",
            tts_extra_kwargs=shared_tts_extra,
            turn_handling=TurnHandlingOptions(
                turn_detection="stt",
                endpointing={"mode": "fixed", "min_delay": 0.1, "max_delay": 1.0},
                interruption={
                    "enabled": False,
                    "resume_false_interruption": False,
                    "false_interruption_timeout": None,
                },
                preemptive_generation={
                    "enabled": False,
                    "preemptive_tts": False,
                },
            ),
            prompt_level=2,
            tts_playback_mode="full_sentence",
            tts_initial_buffer_seconds=0.0,
            diagnostics_enabled=True,
            tts_ttfb_warn_seconds=0.75,
            llm_ttft_warn_seconds=2.5,
            e2e_warn_seconds=5.0,
            playback_warn_seconds=1.5,
        )

    return VoicePipelineConfig(
        profile=VoicePipelineProfile.BALANCED,
        stt_model="deepgram/flux-general",
        stt_language="en",
        stt_extra_kwargs=shared_stt_extra,
        llm_model="openai/gpt-4.1-nano",
        llm_extra_kwargs={"max_tokens": 22, "temperature": 0.15},
        tts_model="cartesia/sonic-3",
        tts_voice="f786b574-daa5-4673-aa0c-cbe3e8534c02",
        tts_extra_kwargs=shared_tts_extra,
        turn_handling=TurnHandlingOptions(
            turn_detection="stt",
            endpointing={"mode": "fixed", "min_delay": 0.1, "max_delay": 1.0},
            interruption={
                "enabled": False,
                "resume_false_interruption": False,
                "false_interruption_timeout": None,
            },
            preemptive_generation={
                "enabled": True,
                "preemptive_tts": False,
            },
        ),
        prompt_level=2,
        tts_playback_mode="streaming",
        tts_initial_buffer_seconds=0.0,
        diagnostics_enabled=True,
        tts_ttfb_warn_seconds=0.75,
        llm_ttft_warn_seconds=2.5,
        e2e_warn_seconds=5.0,
        playback_warn_seconds=1.5,
    )


VOICE_PROFILE = parse_voice_pipeline_profile()
VOICE_CONFIG = build_voice_pipeline_config(VOICE_PROFILE)


def build_runtime_turn_handling(config: VoicePipelineConfig) -> TurnHandlingOptions:
    return config.turn_handling


def describe_turn_detection(turn_handling: TurnHandlingOptions, config: VoicePipelineConfig) -> str | None:
    turn_detection = turn_handling.get("turn_detection")
    if turn_detection is None:
        return None
    return str(turn_detection)


def build_agent_session(config: VoicePipelineConfig, turn_handling: TurnHandlingOptions) -> AgentSession:
    kwargs: dict[str, object] = {
        "stt": inference.STT(
            model=config.stt_model,
            language=config.stt_language,
            extra_kwargs=config.stt_extra_kwargs,
        ),
        "llm": inference.LLM(
            model=config.llm_model,
            extra_kwargs=config.llm_extra_kwargs,
        ),
        "tts": inference.TTS(
            model=config.tts_model,
            voice=config.tts_voice,
            extra_kwargs=config.tts_extra_kwargs,
        ),
        "vad": silero.VAD.load(),
        "turn_handling": turn_handling,
    }
    kwargs["aec_warmup_duration"] = 1.0
    return AgentSession(**kwargs)


def log_latency_event(label: str, payload: dict[str, object]) -> None:
    LOGGER.info("[latency] %s %s", label, json.dumps(payload, sort_keys=True, default=str))


def attach_latency_logging(session: AgentSession, diagnostics: "LatencyDiagnostics") -> None:
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
            diagnostics.observe(role=role, metrics=useful_metrics)

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
    return build_system_prompt_for_level(subject, level=0)


def build_system_prompt_for_level(subject: str, level: int) -> str:
    if level >= 2:
        latency_policy = (
            "Latency guard mode is CRITICAL. "
            "Reply with exactly one very short sentence under 8 words. "
            "Use simple words. Skip explanations. "
            "Do not correct unless the learner clearly asks. "
            "Do not ask a follow-up if it makes the sentence longer."
        )
        turn_end_policy = "End with no more than one tiny question only when needed."
    elif level == 1:
        latency_policy = (
            "Latency guard mode is CONSERVATIVE. "
            "Reply with one short sentence under 12 words. "
            "Give at most one micro-correction. "
            "Avoid examples unless asked."
        )
        turn_end_policy = "End with at most one very short follow-up question."
    else:
        latency_policy = (
            "Keep every reply to one or two short sentences, under 18 words total. "
            "Do not give long explanations unless the learner asks for detail."
        )
        turn_end_policy = "End each turn with exactly one clear follow-up question."

    return (
        "You are AITutor, a friendly real-time English speaking coach. "
        f"The lesson focus is {subject}. "
        "Speak clearly at a calm natural pace, like a patient pronunciation coach. "
        "Use short sentences with brief natural pauses. "
        "Avoid long clauses, idioms, and fast explanations. "
        "Prioritize one complete smooth sentence over low latency. "
        "Never start a long answer. "
        f"{latency_policy} "
        "If the learner asks to start the practice, greet briefly and ask one easy warm-up question. "
        "Encourage the learner first, then correct one important issue at a time. "
        "When correcting pronunciation or grammar, say the corrected sentence clearly once. "
        "If the learner gives a short answer, ask an easier follow-up. "
        "If the learner answers confidently, ask a slightly deeper follow-up. "
        f"{turn_end_policy}"
    )


class Assistant(Agent):
    def __init__(self, subject: str, config: VoicePipelineConfig) -> None:
        self.subject = subject
        self.config = config
        super().__init__(
            instructions=build_system_prompt_for_level(subject, level=config.prompt_level),
        )

    def tts_node(self, text: AsyncIterable[str], model_settings):
        if self.config.tts_playback_mode == "full_sentence":
            return self._smooth_tts_node(text, model_settings)
        return Agent.default.tts_node(self, text, model_settings)

    async def _smooth_tts_node(
        self,
        text: AsyncIterable[str],
        model_settings,
    ) -> AsyncGenerator[rtc.AudioFrame, None]:
        """Smooth-profile fallback: prefer complete sentences over lowest latency.

        The realtime profile uses LiveKit's default streaming TTS node. This
        override is only for the demo-safe smooth profile: it buffers the
        already-short tutor sentence, synthesizes it fully, then hands complete
        audio frames to LiveKit for smoother playback.
        """
        del model_settings

        activity = self._get_activity_or_raise()
        if activity.tts is None:
            raise RuntimeError("tts_node called but no TTS node is available")

        pieces: list[str] = []
        async for chunk in text:
            pieces.append(chunk)

        phrase = "".join(pieces).strip()
        if not phrase:
            return

        start_time = asyncio.get_event_loop().time()
        frames: list[rtc.AudioFrame] = []
        LOGGER.info(
            "[latency] smooth_tts_buffer %s",
            json.dumps({"stage": "start", "chars": len(phrase)}, sort_keys=True),
        )

        conn_options = activity.session.conn_options.tts_conn_options
        async with activity.tts.synthesize(text=phrase, conn_options=conn_options) as stream:
            async for audio in stream:
                frames.append(audio.frame)

        synthesize_seconds = asyncio.get_event_loop().time() - start_time
        audio_seconds = sum(frame.duration for frame in frames)
        LOGGER.info(
            "[latency] smooth_tts_buffer %s",
            json.dumps(
                {
                    "stage": "ready",
                    "chars": len(phrase),
                    "frames": len(frames),
                    "audio_seconds": round(audio_seconds, 3),
                    "synthesize_seconds": round(synthesize_seconds, 3),
                },
                sort_keys=True,
            ),
        )

        for frame in frames:
            yield frame

@dataclass(frozen=True)
class SentinelDecision:
    bad: bool
    reasons: list[str]


class LatencyDiagnostics:
    """Read-only diagnostics for slow turns; it never changes profile at runtime."""

    def __init__(self, config: VoicePipelineConfig) -> None:
        self.config = config

    def observe(self, role: str, metrics: dict[str, object]) -> None:
        if not self.config.diagnostics_enabled or role != "assistant":
            return

        decision = self._classify(metrics)
        if decision.bad:
            LOGGER.warning(
                "[profile] slow assistant turn observed %s",
                json.dumps(
                    {
                        "profile": self.config.profile.value,
                        "reasons": decision.reasons,
                        "metrics": metrics,
                    },
                    sort_keys=True,
                    default=str,
                ),
            )

    def _classify(self, metrics: dict[str, object]) -> SentinelDecision:
        reasons: list[str] = []
        if float(metrics.get("tts_node_ttfb") or 0) >= self.config.tts_ttfb_warn_seconds:
            reasons.append("tts_ttfb")
        if float(metrics.get("llm_node_ttft") or 0) >= self.config.llm_ttft_warn_seconds:
            reasons.append("llm_ttft")
        if float(metrics.get("e2e_latency") or 0) >= self.config.e2e_warn_seconds:
            reasons.append("e2e_latency")
        if float(metrics.get("playback_latency") or 0) >= self.config.playback_warn_seconds:
            reasons.append("playback_latency")
        return SentinelDecision(bad=bool(reasons), reasons=reasons)


@SERVER.rtc_session()
async def entrypoint(ctx: agents.JobContext) -> None:
    turn_handling = build_runtime_turn_handling(VOICE_CONFIG)
    LOGGER.info(
        "[profile] voice_pipeline %s",
        json.dumps(
            {
                "profile": VOICE_CONFIG.profile.value,
                "stt_model": VOICE_CONFIG.stt_model,
                "llm_model": VOICE_CONFIG.llm_model,
                "tts_model": VOICE_CONFIG.tts_model,
                "tts_playback_mode": VOICE_CONFIG.tts_playback_mode,
                "tts_initial_buffer_seconds": VOICE_CONFIG.tts_initial_buffer_seconds,
                "turn_detection": describe_turn_detection(turn_handling, VOICE_CONFIG),
                "interruption_enabled": turn_handling.get("interruption", {}).get("enabled"),
                "preemptive_generation_enabled": turn_handling.get("preemptive_generation", {}).get("enabled"),
                "preemptive_tts": turn_handling.get("preemptive_generation", {}).get("preemptive_tts"),
            },
            sort_keys=True,
        ),
    )
    session = build_agent_session(VOICE_CONFIG, turn_handling)
    assistant = Assistant(SUBJECT, config=VOICE_CONFIG)
    diagnostics = LatencyDiagnostics(config=VOICE_CONFIG)
    attach_latency_logging(session, diagnostics)

    await session.start(
        room=ctx.room,
        agent=assistant,
        room_options=room_io.RoomOptions(
            audio_input=room_io.AudioInputOptions(),
        ),
    )


if __name__ == "__main__":
    agents.cli.run_app(SERVER)
