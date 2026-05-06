from uuid import uuid4
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from dotenv import load_dotenv

from config import load_settings
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


@app.post("/session")
def create_session(payload: SessionCreateRequest) -> dict:
    _validate_config()

    service = TokenService(
        api_key=settings.livekit_api_key,
        api_secret=settings.livekit_api_secret,
        room_prefix=settings.room_prefix,
    )

    user_id = f"user-{uuid4().hex[:8]}"
    token_bundle = service.create_participant_token(user_id, payload.display_name)

    return {
        "livekit_url": settings.livekit_url,
        "tutor_subject": settings.tutor_subject,
        **token_bundle,
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host=settings.host, port=settings.port, reload=True)
