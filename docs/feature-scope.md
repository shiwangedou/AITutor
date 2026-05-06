# Feature Scope and Priorities

This document defines what AITutor should build first, what should come later, and what is intentionally out of scope.

中文：
本文档定义 AITutor 应该优先实现什么、后续增强什么，以及明确不做什么。

## P0: Must-Have

These items are required for a working submission.

中文：这些是可运行提交的基础要求。

1. Backend `.env` config loading
- All secrets and runtime config must be loaded from the root `.env`.
- Required values include `LIVEKIT_URL`, `LIVEKIT_API_KEY`, and `LIVEKIT_API_SECRET`.

2. Backend health check
- Provide `GET /health` so local development and reviewers can verify that the backend is running.

3. Backend session creation API
- Provide `POST /session`.
- Return `livekit_url`, `token`, `room_name`, `participant_identity`, and `tutor_subject`.

4. LiveKit token generation
- Use LiveKit API key and secret to issue a room-scoped participant token.

5. iOS session fetch
- UIKit app calls backend `/session` through `BackendClient`.

6. iOS LiveKit room connection
- `LiveKitService` connects to the room using backend-provided `livekit_url` and `token`.

7. Microphone permission handling
- Request microphone permission.
- Show a clear user-facing message when permission is denied or restricted.

8. Microphone audio publishing
- After connection, publish local microphone audio to the LiveKit room.

9. Tutor agent joins the same room
- Backend or agent process joins the room and behaves as an English-speaking tutor.

10. Minimal realtime tutoring loop
- User speaks.
- Tutor responds by voice.
- At least one full question-and-answer loop works end to end.

11. UIKit session screen
- Provide `Connect`, `Start Session`, and `End Session`.
- Show visible session state.

12. Session state machine
- Minimum states: `idle`, `connecting`, `connected`, `inSession`, `failed`, `ended`.

13. Basic error UX
- Show visible errors for network failure, token failure, LiveKit connection failure, and microphone permission failure.

14. Session cleanup
- `End Session` disconnects LiveKit and deactivates audio.
- User can start a new session afterward.

15. Required documentation
- Keep `README.md`, `.env.example`, `plan.md`, and `workflow.md` complete and aligned with the real implementation.

## P1: Strongly Recommended

These items make the project feel more complete without changing the core architecture.

中文：这些功能能明显提升完整度，但不改变核心架构。

1. English tutor prompt policy
- Keep replies short.
- Give encouraging correction.
- Correct one major issue at a time.
- End with one follow-up question.

2. Transcription or event log panel
- Show recent user/tutor messages or connection events.
- Make the demo observable even when voice output is hard to inspect.

3. Reconnect entry point
- Show `Reconnect` after disconnect.
- Allow the user to recreate or recover a session.

4. Local session storage
- Store recent session summaries locally.
- Do not store raw audio.
- Recommended storage: `Codable` plus JSON file.

5. Basic post-session summary
- Save structured feedback after the session.
- Suggested fields: fluency, grammar, vocabulary, pronunciation, and next practice goal.

6. Privacy note
- README should explain that raw audio is not persisted.
- Session summaries are local and can be cleared.

7. Feature-level documentation coverage
- Add `FEATURE.md` for major feature/service folders.
- Recommended folders: `Session`, `LiveKit`, `Audio`, and `Storage`.

8. Runbook
- Add `RUNBOOK.md`.
- Cover token failure, connection failure, microphone silence, and agent non-response.

## P2: Bonus

These items are useful after P0 and P1 are stable.

中文：这些属于核心稳定后的加分项。

1. Session history screen
- Show the latest 20 sessions.
- Include date, duration, topic, and summary.

2. Clear history
- Provide a local delete action for saved session records.

3. Practice mode selection
- Example modes: `Daily Conversation`, `Interview English`, `Travel English`.
- Implement as prompt variants first.

4. More detailed error categories
- Distinguish backend error, auth error, timeout, LiveKit disconnect, and audio route issue.

5. Background and foreground recovery
- Keep state coherent when the app moves between background and foreground.

6. Backend tests
- Cover `/health`, `/session`, and missing config behavior.

7. iOS state machine tests
- Cover success, failure, and end-session paths.

8. CI
- Run backend tests, Python lint, and basic required-file checks.

## P3: Optional Enhancements

These can polish the product, but they should not delay the voice loop.

中文：这些可以提升体验，但不应阻塞实时语音主链路。

1. More polished UIKit UI
2. Voice activity indicator
3. Session timer
4. User display name input
5. Latest summary card
6. Simple settings screen

## Non-Goals

These are intentionally out of scope for this project.

中文：以下内容明确不做，避免范围失控。

1. User registration or login
2. Cloud database or cloud sync
3. Complex backend business system
4. Multi-user social features or multi-party rooms
5. Payment, subscription, or membership
6. Admin dashboard
7. Full curriculum, lesson library, question bank, or long-term learning plan
8. Raw audio persistence
9. Complex analytics dashboard
10. Multi-language localization
11. Heavy visual effects or landing-page-style packaging
12. Core Data as the first storage layer
13. Custom STT, TTS, or LLM pipeline
14. Complex permission or security system beyond `.env` secrets and basic safety notes

## Recommended Lock

For the first complete version, lock scope to:

1. All P0 items.
2. P1 items that directly improve demo quality: tutor prompt policy, reconnect entry, local summary storage, and runbook.

中文：
第一版建议锁定：全部 P0，以及 P1 中最提升演示质量的部分：tutor prompt 策略、重连入口、本地总结存储、Runbook。
