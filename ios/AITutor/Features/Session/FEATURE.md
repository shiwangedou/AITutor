# Session Feature

## 1. Purpose
Handle the user-facing realtime English speaking tutoring session lifecycle in UIKit using MVVM.

中文：用 UIKit + MVVM 负责用户可见的实时英语口语辅导会话生命周期。

## 2. Entry Points
- UI entry: `View/SessionViewController`
- Business entry: `ViewModel/SessionViewModel`
- User actions: `Connect`, `Start Session`, `Reconnect`, `End Session`, `Clear History`

中文：入口包括 UIKit 页面、Session ViewModel，以及连接、开始、重连、结束和清空历史动作。

## 3. Main Flow / Logic
1. User opens the app and sees backend URL, privacy note, local summary, controls, transcript panel, and debug log panel.
2. User taps `Connect`.
3. `SessionViewModel` requests session config/token from backend `/session` through `BackendAPIClientProtocol`.
4. `LiveKitAgentControlling` connects to the returned LiveKit room.
5. User taps `Start Session`.
6. `AudioSessionManaging` checks/requests microphone permission and records diagnostics.
7. The app configures a lightweight voice audio session and publishes the microphone through LiveKit.
8. After microphone publishing succeeds, the app sends a start-conversation signal so the tutor asks the first warm-up question.
9. User speaks and waits for the LiveKit tutor agent to respond by voice.
10. LiveKit transcription segments are merged into the transcript panel as `You` and `Tutor` lines when available.
11. Typed fallback messages are shown immediately as `You` transcript lines.
12. If a connect/start failure happens, the app shows `Reconnect` and keeps secret-safe `[test]` logs.
13. User taps `End Session`; the app disconnects, deactivates audio, and saves a local metadata/summary record.

中文：
1. 用户打开 App，看到后端地址、隐私提示、本地总结、控制按钮、转写面板和 debug 日志面板。
2. 点击 `Connect` 后，ViewModel 通过后端 `/session` 获取 LiveKit 会话配置。
3. Agent 层连接返回的 LiveKit 房间。
4. 点击 `Start Session` 后，音频层检查/请求麦克风权限并记录诊断信息。
5. App 配置轻量语音音频会话，并通过 LiveKit 发布麦克风。
6. 麦克风发布成功后，App 发送 start-conversation 信号，让 tutor 问第一个 warm-up 问题。
7. 用户说话，等待 LiveKit tutor agent 用语音回应。
8. 当 LiveKit 返回转写片段时，App 会把内容合并显示为 `You` 和 `Tutor` 行。
9. 用户手动输入的 fallback 文本会立即显示为 `You` 转写行。
10. 如果连接或启动失败，App 显示 `Reconnect`，并保留脱敏 `[test]` 日志。
11. 点击 `End Session` 后断开连接、释放音频并保存本地元数据/总结。

## 4. State Model
- `idle`
- `connecting`
- `connected`
- `inSession`
- `ended`
- `backendFailed`
- `liveKitFailed`
- `microphonePermissionFailed`
- `audioSessionFailed`
- `microphonePublishFailed`
- `textSendFailed`
- `storageFailed`
- `unknownFailed`

中文：会话状态包括空闲、连接中、已连接、会话中、已结束，以及后端、LiveKit、麦克风权限、音频会话、麦克风发布、文字发送、存储和未知错误等具体失败类型。

## 5. MVVM Responsibilities
- `SessionViewController`: render `SessionViewState`, forward button taps, and own UIKit/SnapKit layout only.
- `SessionViewModel`: orchestrate backend session creation, LiveKit connection, microphone permission, start/end/reconnect, local summaries, transcript updates, logs, and errors.
- `SessionViewState`: single render model for status labels, button enablement, summary text, transcript text, log text, and error text.
- `SessionRecord`: local Codable metadata/summary model; no raw audio.

中文：ViewController 只负责渲染和事件转发；ViewModel 负责主流程和转写更新；ViewState 负责页面渲染状态；SessionRecord 只保存本地元数据/总结，不保存原始音频。

## 6. Transcript Display
- The transcript panel is display-only and lightweight; it is not a full chat product.
- Voice transcript updates come from LiveKit transcription segments through the Agent layer.
- Partial transcription updates replace the same segment by ID; final segments remain visible.
- Agent speech is displayed as `Tutor` when LiveKit marks the participant as an agent.
- Learner speech is displayed as `You` when transcription segments are available.
- Typed fallback input is displayed immediately as `You` so reviewers can verify the UI path even before voice transcription arrives.
- Tokens, secrets, and raw audio are never displayed or stored.

中文：
- 转写面板只做轻量展示，不做完整聊天产品。
- 语音转写来自 Agent 层接收到的 LiveKit transcription segments。
- partial 转写会按相同 segment ID 替换，final 转写会保留显示。
- 当 LiveKit 标记 participant 为 agent 时，agent 语音显示为 `Tutor`。
- 用户语音在转写可用时显示为 `You`。
- 手动输入 fallback 文本会立即显示为 `You`，方便在语音转写到达前验证 UI 路径。
- token、密钥和原始音频不会展示或存储。

## 7. Error Handling
- Backend request failure -> `backendUnavailable` / `sessionTokenFailed`, state becomes `failed`, reconnect is enabled.
- LiveKit connect failure -> `liveKitConnectFailed`, state becomes `failed`.
- Microphone denied -> `microphonePermissionDenied`, state becomes `failed`, user sees a clear permission message.
- Audio setup failure -> `audioSessionFailed`, with route/category/mode/sample-rate diagnostics.
- Microphone publish failure -> `microphonePublishFailed`, with LiveKit diagnostic context.
- Storage failure -> log error without blocking disconnect cleanup.

中文：后端、LiveKit、麦克风权限、音频配置、麦克风发布和本地存储错误都会映射到明确错误类型；失败后可重连，存储失败不阻塞断开清理。

## 8. Privacy / Local Storage
- Raw audio is never persisted by the app.
- Local storage keeps only recent session metadata and summary text.
- The app stores at most the latest 20 session records using JSON/Codable.
- `Clear History` removes local summary records.
- Tokens and secrets are never logged.

中文：App 不持久化原始音频；只保存最近 20 条本地元数据和总结；`Clear History` 可清空本地记录；日志不输出 token 或密钥。

## 9. Device Notes
- `LaunchScreen.storyboard` is required so the app launches full screen on modern iPhones.
- Simulator can use `BACKEND_BASE_URL=http://127.0.0.1:8000`.
- Physical iPhone must use the Mac LAN IP, for example `http://192.168.x.x:8000`.
- `Info.plist` allows local networking for development backend access.
- `ios/scripts/configure_backend_url.sh` detects the Mac LAN IP and writes it into both `ios/project.yml` and `ios/AITutor.xcodeproj`.
- `ios/scripts/start_ios.sh` runs the URL config script, opens Xcode, and can trigger Xcode Run with the currently selected destination.
- Root `./start_all.sh` runs the iOS start helper after backend API and agent are ready.

中文：真机需要 Mac 局域网 IP；`Info.plist` 已允许本地网络开发访问；启动脚本会自动配置 URL、打开 Xcode，并可尝试运行 App。

## 10. Validation
- Generic iOS Debug build succeeds with LiveKit Swift SDK and SnapKit.
- LiveKit transcription delegate integration compiles in the generic iOS Debug build.
- Real-device voice loop still needs manual validation: connect, microphone permission, publish audio, hear tutor response, end session.
- Real-device transcript behavior still needs manual validation for both learner speech and tutor speech.

中文：generic iOS Debug 构建已通过；LiveKit 转写 delegate 集成也已通过构建；真机语音闭环和双方转写显示仍需手动验证连接、权限、发布音频、听到 tutor 回应、显示转写和结束会话。

## 11. Dependencies
- `AppEnvironment`
- `BackendAPIClientProtocol`
- `LiveKitAgentControlling`
- `AudioSessionManaging`
- `SessionStorageManaging`
- LiveKit Swift SDK
- SnapKit

中文：依赖包括环境注入、后端协议、LiveKit agent 协议、音频协议、本地存储协议、LiveKit Swift SDK 和 SnapKit。

## 12. Change Log
- 2026-05-08: Added a lightweight transcript panel and wired LiveKit transcription segments into `You` / `Tutor` display lines.
- 2026-05-07: Refactored Session into MVVM with View, ViewModel, Domain, Storage, protocol-driven Network and Agent dependencies.
- 2026-05-07: Expanded `SessionState` into specific failure states so the UI can show backend, LiveKit, microphone permission, audio session, microphone publish, text send, storage, or unknown failure directly.
- 2026-05-07: Added explicit microphone permission flow, reconnect action, local JSON/Codable session summaries, privacy note, and Clear History.
- 2026-05-07: Added local-network/ATS development support for physical iPhone backend access.
- 2026-05-07: Added `AppLogger` for DEBUG-only Xcode console logs with `[test]` filtering across session, audio, LiveKit, network, and storage paths.
- 2026-05-07: Added staged audio diagnostics and reduced manual `AVAudioSession` activation before LiveKit microphone publishing.
- 2026-05-07: Added `ios/scripts/start_ios.sh` and wired it into backend readiness so root `start_all.sh` can start backend and iOS together.
- 2026-05-07: Added a full-screen launch storyboard and window background setup to remove iPhone letterbox black bars.
- 2026-05-07: Replaced mock LiveKit service with real LiveKit Swift SDK room connection and moved session layout constraints to SnapKit.
- 2026-05-08: Changed conversation start behavior so `Connect` stays quiet and the tutor speaks only after `Start Session` succeeds.
- 2026-05-06: Initial session feature documentation.
