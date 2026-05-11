# Architecture (MVVM + Layered)

```text
UIKit App
  App
    |- AppConfig (Info.plist-backed backend URL + on-device override)
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
- `AppConfig` 默认读取构建时写入的 backend URL，也支持手机本地 override，方便已安装 App 从桌面图标打开时修正 Mac 局域网 IP。
- LiveKit agent 负责英语口语家教 prompt 和实时语音响应。
- 凭证统一来自根目录 `env` / 运行时 `.env`。

## Runtime Flow

```text
Open app
  -> Home
  -> optional Settings -> Backend URL override if installed app cannot reach Mac backend
  -> customize Learning Profile if needed
  -> AI Chat
  -> POST /session with learning profile
  -> receive LiveKit URL/token/room/normalized profile
  -> connect LiveKit room
  -> fresh empty chat gets one short tutor warm-up; resume-context chat waits quietly
  -> use default Auto Voice, switch to Manual Voice, or send text
  -> request microphone permission if voice input
  -> configure voice audio session
  -> Auto Voice publishes foreground microphone and lets LiveKit auto-submit turns
  -> Manual Voice shows waveform and waits for send, or x to cancel
  -> tutor agent loads room profile and responds
  -> chat list shows You/Tutor/System messages
  -> optional transcript-driven running AI summary draft
  -> optional BG Auto background audio only when explicitly selected in active Chat
  -> foreground return logs diagnostics and exposes Reconnect if recovery may be needed
  -> End Session
  -> disconnect + deactivate audio
  -> save local transcript/summary/metadata
  -> optional final AI summary updates the saved record if the generation/session guard still matches
  -> History review
  -> optional Continue with Context
  -> POST /session with same profile + short resume context
```

中文：运行时流程是：打开 App 到首页；如果已安装 App 无法访问 Mac 后端，可先在 Settings 的 Backend URL 中设置手机本地 override；必要时修改学习配置；进入 AI Chat 后携带 profile 请求 `/session` 并连接 LiveKit 房间；全新空聊天由 tutor 先给一句简短 warm-up，带 resume context 的聊天则安静等待学习者继续；学习者可用默认 `Auto Voice` 前台直接说话、切到 `Manual Voice` 后点击发送提交语音，或发送文字开始互动；`Auto Voice` 由 LiveKit STT/turn detection 自动提交前台语音，`Manual Voice` 在输入框位置显示音波并等待发送或点击 `x` 取消；agent 读取同一 room 的 profile 和可选短上下文并回应；聊天列表展示 You/Tutor/System 消息；会话中可基于 transcript 生成运行中的 AI 摘要草稿；只有在活跃 Chat 中显式选择 `BG Auto` 时，才允许通过 iOS background audio 继续后台语音；默认 `Auto Voice` 进入后台前会停止麦克风输入；回前台时记录诊断并在需要时展示 Reconnect；如果旧 room 无法恢复，会重新请求新 `/session` 但保留本地消息；结束时断开并保存本地 transcript/summary/metadata，并在 generation/session guard 仍匹配时用最终 AI 摘要更新本地记录；最后可在 History 复盘，也可用相同 profile 加短上下文继续学习。

## Privacy Boundary

- Raw audio is not stored locally.
- Local persistence stores only metadata, learning profile, text transcript/messages, and summary text.
- AI summaries send transcript text only; raw audio is never sent to summary generation.
- History Continue sends only a short text resume context: previous summary, optional AI summary, and a limited transcript excerpt.
- Only the latest 20 local session records are retained.
- LiveKit tokens and API secrets are never printed in app logs.

中文：不本地保存原始音频；本地只保存元数据、学习配置、文本 transcript/messages 和总结；AI 摘要只发送 transcript 文本，不发送原始音频；默认最多保留最近 20 条；日志不输出 LiveKit token 或 API secret。
