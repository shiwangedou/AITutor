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
1. User opens the app and sees backend URL, privacy note, local summary, AI summary draft panel, controls, transcript panel, and debug log panel.
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
12. If the app enters background during an active voice session, iOS background audio mode allows the LiveKit audio session to keep running.
13. If a connect/start failure happens, the app shows `Reconnect` and keeps secret-safe `[test]` logs.
14. User taps `End Session`; the app disconnects, deactivates audio, and immediately saves a local metadata/summary record.
15. During longer active sessions, the AI Summary Draft panel can show a running summary generated from finalized transcript text.
16. The latest summary panel shows the local summary plus `AI summary: generating...` while the optional P2 final AI summary method runs.
17. If AI summary succeeds, the local record is updated with the AI result; if it is unavailable, the local summary remains the source of truth.
18. If the app enters background or returns foreground during an active session, the ViewModel logs the current session state, audio diagnostic snapshot, and LiveKit diagnostic snapshot.
19. On foreground return, the UI enables `Reconnect` and shows a recovery hint if the voice session may have stopped.

中文：
1. 用户打开 App，看到后端地址、隐私提示、本地总结、AI 摘要草稿面板、控制按钮、转写面板和 debug 日志面板。
2. 点击 `Connect` 后，ViewModel 通过后端 `/session` 获取 LiveKit 会话配置。
3. Agent 层连接返回的 LiveKit 房间。
4. 点击 `Start Session` 后，音频层检查/请求麦克风权限并记录诊断信息。
5. App 配置轻量语音音频会话，并通过 LiveKit 发布麦克风。
6. 麦克风发布成功后，App 发送 start-conversation 信号，让 tutor 问第一个 warm-up 问题。
7. 用户说话，等待 LiveKit tutor agent 用语音回应。
8. 当 LiveKit 返回转写片段时，App 会把内容合并显示为 `You` 和 `Tutor` 行。
9. 用户手动输入的 fallback 文本会立即显示为 `You` 转写行。
10. 如果 App 在活跃语音会话中进入后台，iOS background audio mode 会允许 LiveKit 音频会话继续运行。
11. 如果连接或启动失败，App 显示 `Reconnect`，并保留脱敏 `[test]` 日志。
12. 点击 `End Session` 后断开连接、释放音频，并立即保存本地元数据/摘要。
13. 在较长的活跃会话中，AI Summary Draft 面板会基于 finalized transcript 文本展示运行中的摘要草稿。
14. 最新摘要面板会先显示本地摘要，同时显示 `AI summary: generating...`，等待可选的 P2 最终 AI 摘要方法执行。
15. 如果 AI 摘要成功，本地记录会更新 AI 结果；如果 AI 摘要不可用，本地摘要仍是事实来源。
16. 如果 App 在活跃会话中进入后台或回到前台，ViewModel 会记录当前会话状态、音频诊断快照和 LiveKit 诊断快照。
17. 回到前台时，UI 会启用 `Reconnect`，并在语音会话可能停止时展示恢复提示。

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
- `SessionViewState`: single render model for status labels, button enablement, summary text, running AI summary draft text, transcript text, log text, and error text.
- `SessionRecord`: local Codable metadata, local summary, optional AI summary status/result; no raw audio.

中文：ViewController 只负责渲染和事件转发；ViewModel 负责主流程和转写更新；ViewState 负责页面渲染状态、本地摘要和运行中的 AI 摘要草稿；SessionRecord 保存本地元数据、本地摘要和可选 AI 摘要状态/结果，不保存原始音频。

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

## 7. Summary Generation
- P0/P1 path: generate a local transcript-based fallback summary immediately at `End Session`.
- The local summary includes duration, subject, learner/tutor turn counts, latest tutor note when available, and a privacy note.
- The latest summary UI can show local summary first while AI summary is generating.
- P2 path: `BackendAPIClientProtocol.generateIncrementalSummary` updates a running draft every few final transcript turns.
- Final P2 path: `BackendAPIClientProtocol.generateSummary` sends transcript text plus the latest running summary to `/summary`.
- The AI Summary Draft panel is intentionally separate from the final summary so reviewers can see progressive generation without blocking `End Session`.
- Summary quality control is intentionally not implemented yet; the current scope focuses on privacy-safe generation flow and UI/state plumbing.
- Final and incremental summary tasks are cancelled or ignored when a new connection starts, history is cleared, or the target session is no longer current.
- Summary status copy distinguishes waiting, updating, final generating, skipped, unavailable, and completed states.
- If P2 is not available yet, the app marks AI summary as unavailable and keeps the local summary.
- Raw audio is never sent to summary generation.

中文：
- P0/P1 路径：点击 `End Session` 时立即生成基于 transcript 的本地 fallback 摘要。
- 本地摘要包含时长、主题、用户/tutor 轮数、可用时的最新 tutor 反馈和隐私说明。
- 最新摘要 UI 会先展示本地摘要，同时显示 AI 摘要生成中。
- P2 路径：`BackendAPIClientProtocol.generateIncrementalSummary` 会每隔几轮 final transcript 更新 running draft。
- 最终 P2 路径：`BackendAPIClientProtocol.generateSummary` 会把 transcript 文本和最新 running summary 发给 `/summary`。
- AI Summary Draft 面板与最终摘要刻意分离，方便评审看到渐进式生成，同时不阻塞 `End Session`。
- 摘要质量控制暂不实现；当前范围聚焦隐私安全的生成流程和 UI/状态接线。
- 当用户开始新连接、清空历史，或目标 session 不再是当前可写对象时，最终/增量摘要任务会被取消或忽略，避免旧摘要写回。
- 摘要状态文案会区分等待、更新中、最终生成中、跳过、不可用和已完成。
- 如果 P2 暂不可用，App 会把 AI 摘要标记为 unavailable，并保留本地摘要。
- 摘要生成不会发送原始音频。

## 8. Error Handling
- Backend request failure -> `backendUnavailable` / `sessionTokenFailed`, state becomes `failed`, reconnect is enabled.
- LiveKit connect failure -> `liveKitConnectFailed`, state becomes `failed`.
- Microphone denied -> `microphonePermissionDenied`, state becomes `failed`, user sees a clear permission message.
- Audio setup failure -> `audioSessionFailed`, with route/category/mode/sample-rate diagnostics.
- Microphone publish failure -> `microphonePublishFailed`, with LiveKit diagnostic context.
- Storage failure -> log error without blocking disconnect cleanup.

中文：后端、LiveKit、麦克风权限、音频配置、麦克风发布和本地存储错误都会映射到明确错误类型；失败后可重连，存储失败不阻塞断开清理。

## 9. Privacy / Local Storage
- Raw audio is never persisted by the app.
- Local storage keeps only recent session metadata and summary text.
- The app stores at most the latest 20 session records using JSON/Codable.
- AI summary status/result is stored only as local JSON/Codable session metadata.
- `Clear History` removes local summary records.
- Tokens and secrets are never logged.

中文：App 不持久化原始音频；只保存最近 20 条本地元数据、本地摘要和可选 AI 摘要状态/结果；`Clear History` 可清空本地记录；日志不输出 token 或密钥。

## 10. Device Notes
- `LaunchScreen.storyboard` is required so the app launches full screen on modern iPhones.
- Simulator can use `BACKEND_BASE_URL=http://127.0.0.1:8000`.
- Physical iPhone must use the Mac LAN IP, for example `http://192.168.x.x:8000`.
- `Info.plist` allows local networking for development backend access.
- `Info.plist` enables `UIBackgroundModes=audio` for active voice-session background support.
- `ios/scripts/configure_backend_url.sh` detects the Mac LAN IP and writes it into both `ios/project.yml` and `ios/AITutor.xcodeproj`.
- `ios/scripts/start_ios.sh` runs the URL config script, opens Xcode, and can trigger Xcode Run with the currently selected destination.
- Root `./start_all.sh` runs the iOS start helper after backend API and agent are ready.

中文：真机需要 Mac 局域网 IP；`Info.plist` 已允许本地网络开发访问并启用后台音频；启动脚本会自动配置 URL、打开 Xcode，并可尝试运行 App。

## 11. Validation
- Generic iOS Debug build succeeds with LiveKit Swift SDK and SnapKit.
- LiveKit transcription delegate integration compiles in the generic iOS Debug build.
- `UIBackgroundModes=audio` is present in `Info.plist`.
- `AudioSessionManager` observes interruption and route-change notifications for background/audio recovery diagnosis.
- `SceneDelegate` and `SessionViewModel` log foreground/background snapshots while a session is active.
- Foreground return enables `Reconnect` and shows a recovery hint if LiveKit connection or microphone state appears inactive.
- `End Session` saves a local transcript-based summary before optional AI summary completion.
- Summary tasks are guarded by a generation ID and session state so stale async results cannot overwrite the visible/latest record after a new flow starts or history is cleared.
- A separate AI Summary Draft panel displays running incremental summary text when final transcript turns are available.
- AI summary is isolated behind P2 network methods and does not block local persistence.
- Incremental AI summary draft generation is triggered during active sessions after enough final transcript turns are collected.
- Real-device voice loop still needs manual validation: connect, microphone permission, publish audio, hear tutor response, end session.
- Real-device transcript behavior still needs manual validation for both learner speech and tutor speech.
- Real-device background behavior still needs manual validation: start a session, lock screen or switch apps, speak/hear tutor, inspect interruption/route logs, return foreground, then end session.

中文：generic iOS Debug 构建已通过；LiveKit 转写 delegate 集成已通过构建；`Info.plist` 已包含后台音频；`AudioSessionManager` 已监听音频中断和路由变化；前后台切换会输出会话、音频和 LiveKit 快照；回前台会启用 `Reconnect` 并在状态异常时提示恢复；`End Session` 会先保存本地摘要，AI 摘要通过独立 P2 方法异步增强，且异步结果有 generation/session guard 防止旧结果写回；独立 AI Summary Draft 面板会在累计足够 final turns 后展示增量摘要；真机语音闭环、双方转写显示和后台行为仍需手动验证。

## 12. Dependencies
- `AppEnvironment`
- `BackendAPIClientProtocol`
- `LiveKitAgentControlling`
- `AudioSessionManaging`
- `SessionStorageManaging`
- LiveKit Swift SDK
- SnapKit

中文：依赖包括环境注入、后端协议、LiveKit agent 协议、音频协议、本地存储协议、LiveKit Swift SDK 和 SnapKit。

## 13. Change Log
- 2026-05-08: Added transcript-based local summary generation and a separate P2 AI summary network method.
- 2026-05-08: Added a separate AI Summary Draft panel for progressive incremental summary display.
- 2026-05-08: Added background/foreground session snapshots and audio interruption/route-change diagnostics.
- 2026-05-08: Added foreground recovery hints, reconnect enablement, and stale-summary write protection.
- 2026-05-08: Added incremental P2 AI summary draft updates during active sessions.
- 2026-05-08: Added a lightweight transcript panel and wired LiveKit transcription segments into `You` / `Tutor` display lines.
- 2026-05-08: Enabled iOS background audio mode and documented the background validation path.
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
