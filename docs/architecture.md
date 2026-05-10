# Architecture (MVVM + Layered)

```text
UIKit App
  App
    |- AppConfig (Info.plist-backed backend URL)
    |- AppEnvironment (dependency assembly)
    |- SceneDelegate / AppDelegate
    |- Info.plist (local networking + background audio)

  Core
    |- AppLogger ([test] DEBUG-only diagnostics)
    |- AppError (shared error taxonomy)
    |- AppDateFormatter (shared timestamp formatting)

  Network
    |- BackendAPIClientProtocol
    |- BackendAPIClient (POST /session, /summary, /summary/incremental)
    |- SessionConfig (backend response DTO with normalized learning profile and optional resume context)

  Agent
    |- LiveKitAgentControlling
    |- LiveKitAgentClient (LiveKit Swift SDK Room + secret-safe connection diagnostics)
    |- AudioSessionManaging
    |- AudioSessionManager (microphone permission + AVAudioSession diagnostics + interruption/route observers)

  Features / Session
    |- View / HomeViewController (product entry + latest summary)
    |- View / LearningProfileEditorViewController (mode/style/difficulty/goal)
    |- View / SessionViewController (AI Chat UIKit + SnapKit rendering only)
    |- View / HistoryViewController + SessionDetailViewController
    |- View / DiagnosticsViewController + SettingsViewController
    |- ViewModel / SessionViewModel (connect/voice/text/reconnect/end orchestration)
    |- ViewModel / SessionViewState (profile/button/status/messages/summary rendering state)
    |- Domain / LearningProfile, ChatMessage, SessionState, SessionRecord, SessionLogItem
    |- Storage / SessionStorageManager + LearningProfileStore (latest 20 local sessions, JSON/Codable)
    |- ResumeContext / short previous-session summary + transcript excerpt
    |- FEATURE.md

FastAPI Backend
  |- /health
  |- /config
  |- /session (normalize learning profile/resume context, issue LiveKit token and room)
  |- /summary/incremental (optional running AI summary draft)
  |- /summary (optional final AI summary)

LiveKit Agent
  |- agent.py (English speaking tutor prompt + room learning profile)
  |- LiveKit Inference STT / LLM / TTS
  |- Silero VAD + turn detector
```

中文：
- iOS 端采用 MVVM + 分层结构。
- 首页负责产品入口和最近摘要；学习配置页负责模式/风格/难度/目标。
- `SessionViewController` 只负责 AI Chat 的 UIKit/SnapKit 渲染和用户事件转发。
- `SessionViewModel` 负责连接、语音/文字输入、重连、结束、日志、错误和本地总结保存。
- `Network` 负责后端 `/session`、`/summary`、`/summary/incremental` HTTP 请求和响应解析。
- `Agent` 只负责 LiveKit 房间、麦克风发布和音频会话诊断。
- `Core` 提供通用日志、错误和时间工具。
- 后端负责配置读取与 token 下发。
- LiveKit agent 负责英语口语家教 prompt 和实时语音响应。
- 凭证统一来自根目录 `env` / 运行时 `.env`。

## Runtime Flow

```text
Open app
  -> Home
  -> customize Learning Profile if needed
  -> AI Chat
  -> POST /session with learning profile
  -> receive LiveKit URL/token/room/normalized profile
  -> connect LiveKit room
  -> fresh empty chat gets one short tutor warm-up; resume-context chat waits quietly
  -> tap microphone for voice input or send text
  -> request microphone permission if voice input
  -> configure voice audio session
  -> publish microphone while the waveform input is active
  -> tap send to finish voice input or tap x to cancel
  -> tutor agent loads room profile and responds
  -> chat list shows You/Tutor/System messages
  -> optional transcript-driven running AI summary draft
  -> optional background audio continuation while session is active
  -> foreground return logs diagnostics and exposes Reconnect if recovery may be needed
  -> End Session
  -> disconnect + deactivate audio
  -> save local transcript/summary/metadata
  -> optional final AI summary updates the saved record if the generation/session guard still matches
  -> History review
  -> optional Continue with Context
  -> POST /session with same profile + short resume context
```

中文：运行时流程是：打开 App 到首页，必要时修改学习配置，进入 AI Chat 后携带 profile 请求 `/session` 并连接 LiveKit 房间；全新空聊天由 tutor 先给一句简短 warm-up，带 resume context 的聊天则安静等待学习者继续；学习者点击麦克风进入语音输入或发送文字后开始互动，语音输入时输入框位置显示音波，点击发送结束输入或点击 `x` 取消；agent 读取同一 room 的 profile 和可选短上下文并回应；聊天列表展示 You/Tutor/System 消息；会话中可基于 transcript 生成运行中的 AI 摘要草稿；活跃会话可通过 iOS background audio 在后台继续；回前台时记录诊断并在需要时展示 Reconnect；如果旧 room 无法恢复，会重新请求新 `/session` 但保留本地消息；结束时断开并保存本地 transcript/summary/metadata，并在 generation/session guard 仍匹配时用最终 AI 摘要更新本地记录；最后可在 History 复盘，也可用相同 profile 加短上下文继续学习。

## Privacy Boundary

- Raw audio is not stored locally.
- Local persistence stores only metadata, learning profile, text transcript/messages, and summary text.
- AI summaries send transcript text only; raw audio is never sent to summary generation.
- History Continue sends only a short text resume context: previous summary, optional AI summary, and a limited transcript excerpt.
- Only the latest 20 local session records are retained.
- LiveKit tokens and API secrets are never printed in app logs.

中文：不本地保存原始音频；本地只保存元数据、学习配置、文本 transcript/messages 和总结；AI 摘要只发送 transcript 文本，不发送原始音频；默认最多保留最近 20 条；日志不输出 LiveKit token 或 API secret。
