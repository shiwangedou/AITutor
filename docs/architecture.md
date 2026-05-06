# Architecture (Short)

```text
UIKit App
  |- SessionViewController (UI + user actions)
  |- BackendClient (session config API)
  |- LiveKitService (room/session orchestration)
  |- AudioSessionManager (AVAudioSession)

FastAPI Backend
  |- /health
  |- /config
  |- /session (issue LiveKit token)

LiveKit Agent
  |- agent.py (English tutor prompt)
  |- LiveKit Inference STT / LLM / TTS
  |- Silero VAD + turn detector
```

中文：
- iOS 端负责 UI、会话状态与音频配置。
- 后端负责配置读取与 Token 下发。
- LiveKit agent 负责英语口语家教 prompt 和实时语音响应。
- 凭证统一来自 `.env`。
