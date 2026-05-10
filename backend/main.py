import json
import os
from uuid import uuid4
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from dotenv import load_dotenv
from livekit.agents import inference, llm

from config import load_settings
from learning_profile import SessionProfileStore, normalize_learning_profile, normalize_resume_context
from token_service import TokenService


load_dotenv()
settings = load_settings()

app = FastAPI(title="AITutor Backend", version="0.1.0")


def _validate_config() -> None:
    if not settings.livekit_url or not settings.livekit_api_key or not settings.livekit_api_secret:
        raise HTTPException(
            status_code=500,
            detail="Server not configured. Missing LIVEKIT_URL/API_KEY/API_SECRET in .env",
        )


class SessionCreateRequest(BaseModel):
    display_name: str = "Learner"
    learning_mode: str | None = None
    tutor_style: str | None = None
    difficulty: str | None = None
    custom_goal: str | None = None
    resume_context: dict | None = None


class SummaryRequest(BaseModel):
    session_id: str
    tutor_subject: str
    duration_seconds: float
    transcript: str
    running_summary: str | None = None
    learning_profile: dict | None = None


class IncrementalSummaryRequest(BaseModel):
    session_id: str
    tutor_subject: str
    previous_summary: str | None = None
    new_turns: list[str]
    finalize: bool = False
    learning_profile: dict | None = None


class SummaryResponse(BaseModel):
    summary: str
    strengths: list[str]
    corrections: list[str]
    next_steps: list[str]


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.get("/config")
def config() -> dict:
    _validate_config()
    return {
        "livekit_url": settings.livekit_url,
        "tutor_subject": settings.tutor_subject,
    }


def _fallback_summary(payload: SummaryRequest) -> SummaryResponse:
    lines = [line for line in payload.transcript.splitlines() if line.strip()]
    learner_turns = sum(1 for line in lines if line.startswith("You:"))
    tutor_turns = sum(1 for line in lines if line.startswith("Tutor:"))
    minutes = max(0, int(payload.duration_seconds)) // 60
    seconds = max(0, int(payload.duration_seconds)) % 60
    duration = f"{minutes}m {seconds}s" if minutes else f"{seconds}s"

    return SummaryResponse(
        summary=(
            f"The learner completed a {duration} {payload.tutor_subject} practice session. "
            f"The transcript included {learner_turns} learner turns and {tutor_turns} tutor turns."
        ),
        strengths=["Completed the practice loop and responded during the session."],
        corrections=["Review the transcript for one focused grammar or pronunciation improvement."],
        next_steps=["Practice one short answer again with clearer pacing and one complete sentence."],
    )


def _fallback_incremental_summary(payload: IncrementalSummaryRequest) -> SummaryResponse:
    previous = payload.previous_summary.strip() if payload.previous_summary else ""
    lines = [line for line in payload.new_turns if line.strip()]
    learner_turns = sum(1 for line in lines if line.startswith("You:"))
    tutor_turns = sum(1 for line in lines if line.startswith("Tutor:"))
    prefix = "Final draft" if payload.finalize else "Running draft"
    summary = (
        f"{prefix}: {payload.tutor_subject} practice has {learner_turns} new learner turns "
        f"and {tutor_turns} new tutor turns."
    )
    if previous:
        summary = f"{previous}\n{summary}"

    return SummaryResponse(
        summary=summary,
        strengths=["The learner continues the practice and provides responses."],
        corrections=["Keep one focused correction from the latest tutor feedback."],
        next_steps=["Continue with one short answer and one clear follow-up."],
    )


def _summary_prompt(payload: SummaryRequest) -> str:
    running_summary = payload.running_summary or "No previous running summary."
    profile = normalize_learning_profile(payload.learning_profile)
    custom_goal = profile.custom_goal or "No custom goal."
    return (
        "You are summarizing an English-speaking tutoring session for a mobile app. "
        "Return only valid JSON with these keys: summary, strengths, corrections, next_steps. "
        "Each value except summary must be an array of 1-3 short strings. "
        "Keep it supportive and useful for an intermediate English learner. "
        "Do not mention raw audio. Do not invent details not present in the transcript.\n\n"
        f"Session id: {payload.session_id}\n"
        f"Subject: {payload.tutor_subject}\n"
        f"Learning mode: {profile.learning_mode}\n"
        f"Tutor style: {profile.tutor_style}\n"
        f"Difficulty: {profile.difficulty}\n"
        f"Custom goal: {custom_goal}\n"
        f"Duration seconds: {payload.duration_seconds:.0f}\n"
        f"Existing running summary:\n{running_summary[:2500]}\n\n"
        f"Transcript:\n{payload.transcript[:6000]}"
    )


def _incremental_summary_prompt(payload: IncrementalSummaryRequest) -> str:
    previous_summary = payload.previous_summary or "No previous summary yet."
    turns = "\n".join(payload.new_turns)
    mode = "finalize the session summary" if payload.finalize else "update the running summary"
    profile = normalize_learning_profile(payload.learning_profile)
    return (
        "You maintain a concise running summary for an English-speaking tutor session. "
        f"Task: {mode}. "
        "Return only valid JSON with these keys: summary, strengths, corrections, next_steps. "
        "The summary should merge previous context with only the new turns. "
        "Do not repeat long transcript text. Do not mention raw audio.\n\n"
        f"Session id: {payload.session_id}\n"
        f"Subject: {payload.tutor_subject}\n"
        f"Learning mode: {profile.learning_mode}\n"
        f"Tutor style: {profile.tutor_style}\n"
        f"Difficulty: {profile.difficulty}\n"
        f"Custom goal: {profile.custom_goal or 'No custom goal.'}\n"
        f"Previous summary:\n{previous_summary[:3000]}\n\n"
        f"New turns:\n{turns[:4000]}"
    )


async def generate_ai_summary(payload: SummaryRequest) -> SummaryResponse:
    model = os.getenv("SUMMARY_LLM_MODEL", os.getenv("LLM_MODEL", "openai/gpt-4.1-nano"))
    max_tokens = int(os.getenv("SUMMARY_LLM_MAX_TOKENS", "260"))
    temperature = float(os.getenv("SUMMARY_LLM_TEMPERATURE", "0.2"))

    chat_ctx = llm.ChatContext.empty()
    chat_ctx.add_message(
        role="system",
        content="You create concise JSON summaries for an English speaking tutor app.",
    )
    chat_ctx.add_message(role="user", content=_summary_prompt(payload))

    summary_llm = inference.LLM(
        model=model,
        extra_kwargs={
            "max_tokens": max_tokens,
            "temperature": temperature,
        },
    )
    try:
        collected = await summary_llm.chat(chat_ctx=chat_ctx).collect()
    finally:
        await summary_llm.aclose()

    try:
        parsed = json.loads(collected.text)
        response = SummaryResponse(
            summary=str(parsed.get("summary", "")).strip(),
            strengths=[str(item).strip() for item in parsed.get("strengths", []) if str(item).strip()],
            corrections=[
                str(item).strip() for item in parsed.get("corrections", []) if str(item).strip()
            ],
            next_steps=[
                str(item).strip() for item in parsed.get("next_steps", []) if str(item).strip()
            ],
        )
        if response.summary:
            return response
        return _fallback_summary(payload)
    except Exception:
        fallback = _fallback_summary(payload)
        fallback.summary = collected.text.strip() or fallback.summary
        return fallback


async def generate_incremental_ai_summary(payload: IncrementalSummaryRequest) -> SummaryResponse:
    model = os.getenv("SUMMARY_LLM_MODEL", os.getenv("LLM_MODEL", "openai/gpt-4.1-nano"))
    max_tokens = int(os.getenv("SUMMARY_LLM_MAX_TOKENS", "260"))
    temperature = float(os.getenv("SUMMARY_LLM_TEMPERATURE", "0.2"))

    chat_ctx = llm.ChatContext.empty()
    chat_ctx.add_message(
        role="system",
        content="You update concise running summaries for an English speaking tutor app.",
    )
    chat_ctx.add_message(role="user", content=_incremental_summary_prompt(payload))

    summary_llm = inference.LLM(
        model=model,
        extra_kwargs={
            "max_tokens": max_tokens,
            "temperature": temperature,
        },
    )
    try:
        collected = await summary_llm.chat(chat_ctx=chat_ctx).collect()
    finally:
        await summary_llm.aclose()

    try:
        parsed = json.loads(collected.text)
        response = SummaryResponse(
            summary=str(parsed.get("summary", "")).strip(),
            strengths=[str(item).strip() for item in parsed.get("strengths", []) if str(item).strip()],
            corrections=[
                str(item).strip() for item in parsed.get("corrections", []) if str(item).strip()
            ],
            next_steps=[
                str(item).strip() for item in parsed.get("next_steps", []) if str(item).strip()
            ],
        )
        if response.summary:
            return response
        return _fallback_incremental_summary(payload)
    except Exception:
        fallback = _fallback_incremental_summary(payload)
        fallback.summary = collected.text.strip() or fallback.summary
        return fallback


@app.post("/session")
def create_session(payload: SessionCreateRequest) -> dict:
    _validate_config()
    learning_profile = normalize_learning_profile(payload.model_dump())
    resume_context = normalize_resume_context(payload.resume_context)

    service = TokenService(
        api_key=settings.livekit_api_key,
        api_secret=settings.livekit_api_secret,
        room_prefix=settings.room_prefix,
    )

    user_id = f"user-{uuid4().hex[:8]}"
    token_bundle = service.create_participant_token(user_id, payload.display_name)
    SessionProfileStore().save(token_bundle["room_name"], learning_profile, resume_context)

    return {
        "livekit_url": settings.livekit_url,
        "tutor_subject": settings.tutor_subject,
        "learning_profile": learning_profile.to_dict(),
        "resume_context": resume_context.to_dict(),
        **token_bundle,
    }


@app.post("/summary", response_model=SummaryResponse)
async def create_summary(payload: SummaryRequest) -> SummaryResponse:
    _validate_config()
    if not payload.transcript.strip():
        return _fallback_summary(payload)

    try:
        return await generate_ai_summary(payload)
    except Exception as exc:
        # Keep the endpoint reliable for demos even if the inference provider is unavailable.
        fallback = _fallback_summary(payload)
        fallback.next_steps.append(f"AI summary fallback used: {type(exc).__name__}")
        return fallback


@app.post("/summary/incremental", response_model=SummaryResponse)
async def create_incremental_summary(payload: IncrementalSummaryRequest) -> SummaryResponse:
    _validate_config()
    if not payload.new_turns:
        return _fallback_incremental_summary(payload)

    try:
        return await generate_incremental_ai_summary(payload)
    except Exception as exc:
        fallback = _fallback_incremental_summary(payload)
        fallback.next_steps.append(f"Incremental AI summary fallback used: {type(exc).__name__}")
        return fallback


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host=settings.host, port=settings.port, reload=True)
