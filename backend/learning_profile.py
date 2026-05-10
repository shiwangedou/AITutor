from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class LearningProfile:
    learning_mode: str = "daily_conversation"
    tutor_style: str = "gentle_coach"
    difficulty: str = "intermediate"
    custom_goal: str | None = None

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass(frozen=True)
class ResumeContext:
    source_session_id: str | None = None
    summary: str | None = None
    ai_summary: str | None = None
    transcript_excerpt: str | None = None

    @property
    def has_content(self) -> bool:
        return any([self.summary, self.ai_summary, self.transcript_excerpt])

    def to_dict(self) -> dict[str, Any]:
        return {
            key: value
            for key, value in asdict(self).items()
            if value is not None and str(value).strip()
        }


VALID_LEARNING_MODES = {
    "daily_conversation",
    "interview_english",
    "travel_english",
    "pronunciation_practice",
}
VALID_TUTOR_STYLES = {
    "gentle_coach",
    "direct_coach",
    "challenge_coach",
}
VALID_DIFFICULTIES = {
    "beginner",
    "intermediate",
    "advanced",
}
CUSTOM_GOAL_MAX_LENGTH = 160
RESUME_SESSION_ID_MAX_LENGTH = 120
RESUME_SUMMARY_MAX_LENGTH = 900
RESUME_AI_SUMMARY_MAX_LENGTH = 1200
RESUME_TRANSCRIPT_MAX_LENGTH = 2000


def _normalize_enum(value: str | None, valid_values: set[str], fallback: str) -> str:
    normalized = (value or fallback).strip().lower().replace(" ", "_").replace("-", "_")
    return normalized if normalized in valid_values else fallback


def normalize_learning_profile(data: dict[str, Any] | None = None) -> LearningProfile:
    data = data or {}
    custom_goal = data.get("custom_goal")
    if isinstance(custom_goal, str):
        custom_goal = " ".join(custom_goal.split())[:CUSTOM_GOAL_MAX_LENGTH]
        custom_goal = custom_goal or None
    else:
        custom_goal = None

    return LearningProfile(
        learning_mode=_normalize_enum(
            data.get("learning_mode"),
            VALID_LEARNING_MODES,
            "daily_conversation",
        ),
        tutor_style=_normalize_enum(
            data.get("tutor_style"),
            VALID_TUTOR_STYLES,
            "gentle_coach",
        ),
        difficulty=_normalize_enum(
            data.get("difficulty"),
            VALID_DIFFICULTIES,
            "intermediate",
        ),
        custom_goal=custom_goal,
    )


def _clean_resume_text(value: Any, limit: int) -> str | None:
    if not isinstance(value, str):
        return None
    cleaned = " ".join(value.split())
    return cleaned[:limit] or None


def normalize_resume_context(data: dict[str, Any] | None = None) -> ResumeContext:
    data = data or {}
    return ResumeContext(
        source_session_id=_clean_resume_text(data.get("source_session_id"), RESUME_SESSION_ID_MAX_LENGTH),
        summary=_clean_resume_text(data.get("summary"), RESUME_SUMMARY_MAX_LENGTH),
        ai_summary=_clean_resume_text(data.get("ai_summary"), RESUME_AI_SUMMARY_MAX_LENGTH),
        transcript_excerpt=_clean_resume_text(data.get("transcript_excerpt"), RESUME_TRANSCRIPT_MAX_LENGTH),
    )


def profile_label(profile: LearningProfile) -> str:
    return " / ".join(
        part.replace("_", " ").title()
        for part in [profile.learning_mode, profile.tutor_style, profile.difficulty]
    )


def build_profile_prompt(profile: LearningProfile) -> str:
    mode_prompts = {
        "daily_conversation": "Use everyday conversation topics such as routine, food, work, hobbies, and small talk.",
        "interview_english": "Use job interview practice. Ask concise interview-style questions and help answers sound professional.",
        "travel_english": "Use travel scenarios such as hotels, directions, restaurants, transportation, and polite requests.",
        "pronunciation_practice": "Focus on clear pronunciation, pacing, stress, and one short repeatable phrase at a time.",
    }
    style_prompts = {
        "gentle_coach": "Be warm and encouraging. Correct softly and keep confidence high.",
        "direct_coach": "Be concise and direct. Point out the most important issue clearly without being harsh.",
        "challenge_coach": "Challenge the learner with slightly deeper follow-ups when they answer well.",
    }
    difficulty_prompts = {
        "beginner": "Use simple vocabulary, short questions, and give model sentences the learner can repeat.",
        "intermediate": "Use natural but clear English. Correct one grammar, vocabulary, or phrasing issue per turn.",
        "advanced": "Use more natural phrasing and push for nuance, specificity, and better spoken flow.",
    }

    parts = [
        f"Learning mode: {profile.learning_mode}.",
        mode_prompts[profile.learning_mode],
        f"Tutor style: {profile.tutor_style}.",
        style_prompts[profile.tutor_style],
        f"Difficulty: {profile.difficulty}.",
        difficulty_prompts[profile.difficulty],
    ]
    if profile.custom_goal:
        parts.append(f"Learner's custom goal for this session: {profile.custom_goal}.")
        lower_goal = profile.custom_goal.lower()
        if lower_goal.startswith("words practice:"):
            parts.append(
                "Words practice protocol: ask the learner to say one short sentence using the target word, "
                "then give exactly four lines in this order: "
                "Score: <0-10>; Feedback: <one concise correction>; Better sentence: <one improved sentence>; "
                "Next challenge: <one follow-up prompt>. Include one related expansion word in Feedback or Next challenge."
            )
    return " ".join(parts)


def build_resume_context_prompt(context: ResumeContext) -> str:
    if not context.has_content:
        return ""

    parts = [
        "Previous session context is provided only as background. "
        "Do not recite it. Use it to continue the learner's goal and avoid repeating old corrections."
    ]
    if context.summary:
        parts.append(f"Previous local summary: {context.summary}.")
    if context.ai_summary:
        parts.append(f"Previous AI summary: {context.ai_summary}.")
    if context.transcript_excerpt:
        parts.append(f"Recent previous transcript excerpt: {context.transcript_excerpt}.")
    return " ".join(parts)


class SessionProfileStore:
    def __init__(self, path: Path | None = None) -> None:
        self.path = path or Path(__file__).resolve().parents[1] / ".runtime" / "session_profiles.json"

    def save(
        self,
        room_name: str,
        profile: LearningProfile,
        resume_context: ResumeContext | None = None,
    ) -> None:
        records = self._load_all()
        records[room_name] = {
            "learning_profile": profile.to_dict(),
            "resume_context": (resume_context or ResumeContext()).to_dict(),
        }
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text(json.dumps(records, indent=2, sort_keys=True), encoding="utf-8")

    def load(self, room_name: str | None) -> LearningProfile:
        if not room_name:
            return normalize_learning_profile()
        return normalize_learning_profile(self._profile_data_for_room(room_name))

    def load_resume_context(self, room_name: str | None) -> ResumeContext:
        if not room_name:
            return ResumeContext()
        return normalize_resume_context(self._resume_context_data_for_room(room_name))

    def _profile_data_for_room(self, room_name: str) -> dict[str, Any] | None:
        raw = self._load_all().get(room_name)
        if isinstance(raw, dict) and "learning_profile" in raw:
            profile = raw.get("learning_profile")
            return profile if isinstance(profile, dict) else None
        return raw if isinstance(raw, dict) else None

    def _resume_context_data_for_room(self, room_name: str) -> dict[str, Any] | None:
        raw = self._load_all().get(room_name)
        if isinstance(raw, dict):
            context = raw.get("resume_context")
            return context if isinstance(context, dict) else None
        return None

    def _load_all(self) -> dict[str, Any]:
        if not self.path.exists():
            return {}
        try:
            loaded = json.loads(self.path.read_text(encoding="utf-8"))
            return loaded if isinstance(loaded, dict) else {}
        except Exception:
            return {}
