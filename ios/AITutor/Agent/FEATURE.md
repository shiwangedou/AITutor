# Agent Layer Feature

## 1. Purpose
Own realtime voice infrastructure on iOS: LiveKit room connection, microphone publishing, transcription updates, background audio support, audio session preparation, and audio interruption/route diagnostics.

中文：负责 iOS 侧实时语音基础能力，包括 LiveKit 房间连接、麦克风发布、转写更新、后台音频支持、音频会话准备，以及音频中断/路由变化诊断。

## 2. Main Flow / Logic
1. Receive `SessionConfig` from the Session feature.
2. `LiveKitAgentClient` connects to the backend-created LiveKit room with the returned URL/token.
3. `AudioSessionManager` checks and requests microphone permission.
4. `AudioSessionManager` applies a lightweight voice-chat category/mode without manually forcing activation before LiveKit publishing.
5. `LiveKitAgentClient` starts local microphone publishing through LiveKit.
6. After microphone publishing succeeds, `LiveKitAgentClient` sends a start-conversation signal so the tutor speaks only after the user taps `Start Session`.
7. `LiveKitAgentClient` listens for LiveKit transcription segments and forwards `You` / `Tutor` transcript updates to the Session ViewModel.
8. `Info.plist` declares `UIBackgroundModes=audio` so an active voice session can continue when the app moves to the background.
9. `LiveKitAgentClient` keeps a secret-safe diagnostic snapshot for connection, microphone, room, and participant identity.
10. `AudioSessionManager` observes interruption and route-change notifications so background, lock-screen, Bluetooth, speaker, and headset behavior can be diagnosed from `[test]` logs.
11. Disconnect releases the LiveKit room and deactivates the audio session.

中文：
1. 从 Session 功能接收 `SessionConfig`。
2. `LiveKitAgentClient` 使用后端返回的 URL/token 连接 LiveKit 房间。
3. `AudioSessionManager` 检查并请求麦克风权限。
4. `AudioSessionManager` 配置轻量语音通话 category/mode，不在 LiveKit 发布前强制激活音频会话。
5. `LiveKitAgentClient` 通过 LiveKit 发布本地麦克风。
6. 麦克风发布成功后，`LiveKitAgentClient` 发送 start-conversation 信号，确保 tutor 只在用户点击 `Start Session` 后开始说话。
7. `LiveKitAgentClient` 监听 LiveKit transcription segments，并把 `You` / `Tutor` 转写更新转发给 Session ViewModel。
8. `Info.plist` 声明 `UIBackgroundModes=audio`，让活跃语音会话在 App 进入后台后可以继续。
9. `LiveKitAgentClient` 会保留脱敏诊断快照，包括连接、麦克风、房间和 participant identity 状态。
10. `AudioSessionManager` 会监听中断和路由变化通知，便于通过 `[test]` 日志诊断后台、锁屏、蓝牙、扬声器和耳机场景。
11. 断开时释放 LiveKit 房间并停用音频会话。

## 3. Debugging
- DEBUG logs include room name, participant identity, connection step, microphone permission, route, category, mode, sample rate, and publish result.
- Transcription DEBUG logs include speaker role, final/partial status, and text length for local diagnosis.
- Scene lifecycle DEBUG logs include background/foreground transitions for background-audio validation.
- Audio interruption DEBUG logs include interruption begin/end and whether iOS suggests resuming.
- Audio route-change DEBUG logs include route-change reason and current output route.
- Foreground recovery DEBUG logs include LiveKit connection/microphone state without token or secret values.
- Tokens and secrets are not logged.

中文：DEBUG 日志会记录房间、身份、连接步骤、麦克风权限、路由、category、mode、采样率、发布结果、转写状态、文本长度、前后台切换、音频中断开始/结束、是否建议恢复、路由变化原因，以及前台恢复时的 LiveKit 连接/麦克风状态；不会记录 token、密钥或完整转写文本。

## 4. Change Log
- 2026-05-08: Added secret-safe LiveKit diagnostic state for foreground recovery prompts.
- 2026-05-08: Added `AVAudioSession` interruption and route-change diagnostics for background and audio recovery validation.
- 2026-05-08: Enabled iOS background audio mode and added scene lifecycle diagnostics for background session validation.
- 2026-05-08: Added LiveKit transcription segment handling and forwarded transcript updates to the Session feature.
- 2026-05-08: Moved tutor conversation start from backend room join to the iOS `Start Session` action.
- 2026-05-07: Split LiveKit and audio startup into the Agent layer and reduced manual `AVAudioSession` activation risk.
