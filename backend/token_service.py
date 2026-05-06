import time
import uuid
from livekit import api


class TokenService:
    def __init__(self, api_key: str, api_secret: str, room_prefix: str) -> None:
        self.api_key = api_key
        self.api_secret = api_secret
        self.room_prefix = room_prefix

    def _room_name(self, user_id: str) -> str:
        return f"{self.room_prefix}{user_id}"

    def create_participant_token(self, user_id: str, display_name: str) -> dict:
        room_name = self._room_name(user_id)

        token = (
            api.AccessToken(self.api_key, self.api_secret)
            .with_identity(user_id)
            .with_name(display_name)
            .with_grants(
                api.VideoGrants(
                    room_join=True,
                    room=room_name,
                    can_publish=True,
                    can_subscribe=True,
                )
            )
            .to_jwt()
        )

        return {
            "token": token,
            "room_name": room_name,
            "participant_identity": user_id,
            "issued_at": int(time.time()),
            "session_id": str(uuid.uuid4()),
        }
