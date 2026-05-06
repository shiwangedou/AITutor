from dataclasses import dataclass
import os


@dataclass
class Settings:
    livekit_url: str
    livekit_api_key: str
    livekit_api_secret: str
    room_prefix: str
    tutor_subject: str
    log_level: str
    host: str
    port: int



def load_settings() -> Settings:
    return Settings(
        livekit_url=os.getenv("LIVEKIT_URL", ""),
        livekit_api_key=os.getenv("LIVEKIT_API_KEY", ""),
        livekit_api_secret=os.getenv("LIVEKIT_API_SECRET", ""),
        room_prefix=os.getenv("LIVEKIT_ROOM_PREFIX", "aitutor-"),
        tutor_subject=os.getenv("TUTOR_SUBJECT", "english-speaking"),
        log_level=os.getenv("LOG_LEVEL", "info"),
        host=os.getenv("BACKEND_HOST", "0.0.0.0"),
        port=int(os.getenv("BACKEND_PORT", "8000")),
    )
