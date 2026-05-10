# Feature Scope and Priorities

This document defines the V1 scope for AITutor: complete AI Chat learning loop first, product direction second, and no over-engineering.

中文：本文档定义 AITutor V1 范围：先完成 AI Chat 学习闭环，再展示产品方向，避免过度工程化。

## V1 Core Business Chain

`Home -> Learning Profile -> AI Chat -> voice/text practice -> End Session -> local summary -> History review`

中文：V1 核心业务链路是 `首页 -> 学习配置 -> AI Chat -> 语音/文字练习 -> 结束会话 -> 本地摘要 -> 历史复盘`。

## P0: Must-Have Working Demo

1. Backend `.env` config loading
- All secrets and runtime config load from root `.env`.
- If `.env` is missing, scripts may create it from the committed placeholder `env`, but existing `.env` always wins to avoid overwriting local secrets.
- Required values include `LIVEKIT_URL`, `LIVEKIT_API_KEY`, and `LIVEKIT_API_SECRET`.

2. Backend health/session APIs
- `GET /health`
- `GET /config`
- `POST /session`
- `/session` returns `livekit_url`, `token`, `room_name`, `participant_identity`, `tutor_subject`, and normalized `learning_profile`.

3. Learning profile affects tutor prompt
- iOS sends learning mode, tutor style, difficulty, and optional custom goal.
- Backend normalizes and stores the profile by room name.
- Agent loads the profile and injects it into the tutor prompt.

4. iOS Home and AI Chat
- Home shows product tagline, current profile, AI Chat, focused Words Practice, Custom Goal/Customize, latest summary, History, Diagnostics, Settings.
- AI Chat auto-connects; fresh empty chats get one short tutor warm-up, while History Continue and resume-context reconnects stay quiet until learner input.

5. Voice and text interaction
- Tap-to-record voice input with waveform feedback, explicit cancel, and send-to-finish.
- Auto/Manual Voice mode selection from the Chat microphone button.
- Text fallback.
- Visible connection/audio/tutor states.
- Reconnect and End Session.

6. LiveKit integration
- iOS connects to the LiveKit room using backend config.
- iOS publishes microphone audio.
- Agent joins the same project/room and responds by voice.

7. Local transcript and summary storage
- Store text transcript, messages, metadata, learning profile, local summary, and optional AI summary state.
- Keep latest 20 sessions.
- Never store raw audio.

8. Required documentation
- `README.md`
- `.env.example`
- `plan.md`
- `workflow.md`
- `RUNBOOK.md`
- feature-level `FEATURE.md` files

中文：P0 是必须可演示的基础：后端配置/接口、学习配置影响 prompt、首页和 AI Chat、语音/文字输入、LiveKit 连接、本地 transcript/summary 存储和完整文档。

## P1: Demo Quality

1. Learning Profile editor
- Modes: `Daily Conversation`, `Interview English`, `Travel English`, `Pronunciation Practice`.
- Styles: `Gentle Coach`, `Direct Coach`, `Challenge Coach`.
- Difficulty: `Beginner`, `Intermediate`, `Advanced`.
- Custom goal with length limit.

2. Chat-style transcript
- Messages: user, tutor, system.
- Status: sending, sent, failed, transcribing, streaming.
- Text fallback should show immediately even if voice transcription is unavailable.

3. History and review
- Show latest 20 sessions.
- Detail page shows summary and transcript.
- Continue this goal starts a new session with the same profile plus short previous-session context.

4. Diagnostics and Settings
- Diagnostics shows safe runtime info and no secrets.
- Settings shows config/privacy, Clear History, and Reset Learning Profile.

5. Summary flow
- Save local fallback summary immediately at End Session.
- Incremental AI summary draft can update during longer sessions.
- Final AI summary can update asynchronously.
- Local summary remains valid if AI summary fails.

6. Tests and runbook
- iOS unit tests for ViewModel, DTO, state mapping, and storage.
- Runbook covers startup, networking, audio, transcript, summary, and background recovery.

中文：P1 提升 demo 完整度：学习配置编辑、聊天式转写、历史复盘、诊断/设置、摘要链路、单元测试和运行手册。

## P2: Bonus / Later

1. Background-mode polish beyond the current active Chat audio scope.
2. Voice activity indicator.
3. Session timer or speaking timer.
4. More robust LiveKit transcription fallback using text streams if needed.
5. Summary quality control and scoring rubric.
6. Backend pytest/CI.
7. More polished visual design.
8. Full vocabulary curriculum beyond focused target-word sessions.
9. Long-term study plan or curriculum.

中文：P2 是后续加分：当前活跃 Chat 音频范围之外的后台 polish、语音活动指示、计时器、转写 fallback、摘要质量控制、后端测试/CI、视觉 polish、完整单词课程体系和长期学习计划。

## Non-Goals for V1

1. Login or account system.
2. Cloud database or sync.
3. Full vocabulary curriculum.
4. Full curriculum system.
5. Long-term learning plan.
6. Complex learning report.
7. Payment or membership.
8. Multi-language localization.
9. Raw audio storage.
10. Admin dashboard.
11. Custom STT/TTS/LLM pipeline.
12. Core Data as first storage layer.
13. Heavy analytics or tracking SDK.

中文：V1 明确不做登录、云同步、完整单词课程/课程系统、长期计划、复杂报告、支付、多语言、raw audio 存储、后台管理、自定义模型管线、Core Data 和重型 analytics。

## Recommended Lock

For submission quality, lock the implementation to P0 + P1. P2 should only be added when it does not destabilize the voice loop.

中文：为了提交质量，实现范围锁定为 P0 + P1。P2 只有在不破坏语音闭环稳定性的情况下再做。
