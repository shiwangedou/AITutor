import os
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
from livekit.plugins.turn_detector.multilingual import MultilingualModel


ROOT_ENV = Path(__file__).resolve().parents[1] / ".env"
load_dotenv(ROOT_ENV)
load_dotenv()

SUBJECT = os.getenv("TUTOR_SUBJECT", "english-speaking")
SERVER = AgentServer()


def build_system_prompt(subject: str) -> str:
    return (
        "You are AITutor, a friendly real-time English speaking coach. "
        f"The lesson focus is {subject}. "
        "Keep every reply short and natural for spoken conversation. "
        "Encourage the learner first, then correct one important issue at a time. "
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
        stt=inference.STT(model="deepgram/nova-3", language="en"),
        llm=inference.LLM(model="openai/gpt-5.2-chat-latest"),
        tts=inference.TTS(
            model="cartesia/sonic-3",
            voice="f786b574-daa5-4673-aa0c-cbe3e8534c02",
        ),
        vad=silero.VAD.load(),
        turn_handling=TurnHandlingOptions(
            turn_detection=MultilingualModel(),
        ),
    )

    await session.start(
        room=ctx.room,
        agent=Assistant(SUBJECT),
        room_options=room_io.RoomOptions(
            audio_input=room_io.AudioInputOptions(),
        ),
    )
    await session.generate_reply(
        instructions=(
            "Greet the learner in English. Ask one easy warm-up question "
            "that can be answered in one or two sentences."
        )
    )


if __name__ == "__main__":
    agents.cli.run_app(SERVER)
