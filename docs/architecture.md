# Architecture (MVVM + Layered)

```text
UIKit App
  App
    |- AppConfig (Info.plist-backed backend URL)
    |- AppEnvironment (dependency assembly)
    |- SceneDelegate / AppDelegate

  Core
    |- AppLogger ([test] DEBUG-only diagnostics)
    |- AppError (shared error taxonomy)
    |- AppDateFormatter (shared timestamp formatting)

  Network
    |- BackendAPIClientProtocol
    |- BackendAPIClient (POST /session)
    |- SessionConfig (backend response DTO)

  Agent
    |- LiveKitAgentControlling
    |- LiveKitAgentClient (LiveKit Swift SDK Room)
    |- AudioSessionManaging
    |- AudioSessionManager (microphone permission + AVAudioSession diagnostics)

  Features / Session
    |- View / SessionViewController (UIKit + SnapKit rendering only)
    |- ViewModel / SessionViewModel (connect/start/reconnect/end orchestration)
    |- ViewModel / SessionViewState (button/status/log rendering state)
    |- Domain / SessionState, SessionRecord, SessionLogItem
    |- Storage / SessionStorageManager (latest 20 local summaries, JSON/Codable)
    |- FEATURE.md

FastAPI Backend
  |- /health
  |- /config
  |- /session (issue LiveKit token and room)

LiveKit Agent
  |- agent.py (English speaking tutor prompt)
  |- LiveKit Inference STT / LLM / TTS
  |- Silero VAD + turn detector
```

中文：
- iOS 端采用 MVVM + 分层结构。
- `SessionViewController` 只负责 UIKit/SnapKit 渲染和用户事件转发。
- `SessionViewModel` 负责连接、开始、重连、结束、日志、错误和本地总结保存。
- `Network` 只负责后端 `/session` HTTP 请求和响应解析。
- `Agent` 只负责 LiveKit 房间、麦克风发布和音频会话诊断。
- `Core` 提供通用日志、错误和时间工具。
- 后端负责配置读取与 token 下发。
- LiveKit agent 负责英语口语家教 prompt 和实时语音响应。
- 凭证统一来自根目录 `env` / 运行时 `.env`。

## Runtime Flow

```text
Open app
  -> Connect
  -> POST /session
  -> receive LiveKit URL/token/room
  -> connect LiveKit room
  -> Start Session
  -> request microphone permission
  -> configure voice audio session
  -> publish microphone
  -> tutor agent joins/responds
  -> End Session
  -> disconnect + deactivate audio
  -> save local summary/metadata
```

中文：运行时流程是：打开 App，连接后端获取 LiveKit 会话，加入房间，开始会话时请求麦克风权限并发布音频，结束时断开并保存本地总结/元数据。

## Privacy Boundary

- Raw audio is not stored locally.
- Local persistence stores only metadata and summary text.
- Only the latest 20 local session records are retained.
- LiveKit tokens and API secrets are never printed in app logs.

中文：不本地保存原始音频；本地只保存元数据和总结；默认最多保留最近 20 条；日志不输出 LiveKit token 或 API secret。
