# Session / Product Experience Feature

## 1. Purpose
Own the V1 mobile learning experience for the English-speaking AI tutor: Home, learning profile, AI Chat, History, Diagnostics, Settings, local transcript storage, and summary review.

中文：负责 V1 英语口语 AI Tutor 的移动端学习体验：首页、学习配置、AI Chat、历史、诊断、设置、本地转写存储和摘要复盘。

## 2. Entry Points
- App entry: `HomeViewController`
- Learning profile entry: `LearningProfileEditorViewController`
- Chat entry: `SessionViewController`
- History entry: `HistoryViewController` and `SessionDetailViewController`
- Diagnostics entry: `DiagnosticsViewController`
- Settings entry: `SettingsViewController`
- Business entry: `SessionViewModel`

中文：入口包括首页、学习配置编辑、聊天页、历史页、诊断页、设置页，以及负责业务编排的 `SessionViewModel`。

## 3. V1 Product Flow
1. Learner opens Home.
2. Home shows AI Chat, Custom Goal, Words Practice, recent History, and drawer entries for Customize, Diagnostics, Privacy, Clear History, and Reset Learning Profile.
3. Learner can customize learning mode, tutor style, difficulty, and custom goal. Voice mode is selected directly from the Chat mic button.
4. Learner opens AI Chat.
5. Chat automatically requests `/session` with the selected learning profile and connects to LiveKit.
6. For a fresh empty chat, the tutor gives one short warm-up opener after connection; for History Continue or resume-context reconnects, the tutor waits for learner input.
7. Learner taps the microphone to start voice input. In `Auto Voice`, LiveKit continuously listens, auto-submits turns, and shows learner speech in chat as transcription arrives; tapping again or send stops it. In `Manual Voice`, the learner sees a waveform, taps `x` to cancel, and taps send to finish voice input; learner speech is buffered and only appears in chat/transcript after send. Text fallback remains available.
8. If captured speech/transcript exists, the UI moves from `Listening` to `Tutor Thinking`; if no speech was captured, send exits voice mode without creating an empty message.
9. The UI shows `Listening`, `Tutor Thinking`, `Tutor Speaking`, reconnect, end-session, and specific failure states.
10. Chat list displays `You`, `Tutor`, and minimal `System` messages with statuses; non-error progress prompts stay out of the message list.
11. Back navigation or `End Session` disconnects LiveKit, deactivates audio, saves local transcript text and fallback summary immediately.
12. Incremental/final AI summary can update the record asynchronously when available.
13. If LiveKit reconnect to the current room fails, Chat requests a fresh `/session` and keeps the visible local chat messages.
14. History Continue seeds the Chat list from saved messages, then transcript text, then resume-context transcript excerpt, and finally a summary fallback if older records do not contain full chat text.
15. History shows recent sessions and review details.
16. `Continue` from History starts a new room with the same learning profile plus short previous-session context for the tutor.
17. History Continue keeps the original local chat id. Closing without new learner/tutor content leaves the record unchanged; new text or final voice/tutor transcript content updates the same History item instead of creating a duplicate list item.
18. The Chat microphone button supports a long-press mode picker above the input bar. `Auto Voice` is the default and keeps LiveKit continuous microphone input active so STT/turn detection can auto-submit speech, including when the active Chat page enters background. `Manual Voice` keeps the current tap-record/send-to-finish behavior.
19. Drawer actions can clear history or reset the default learning profile.
20. Diagnostics shows secret-safe runtime information outside the main learning page.
21. Words Practice opens a dedicated vocabulary list from Home and each selected word launches a LiveKit chat practice session with voice/text turns.
22. Words Practice sessions inject target-word coaching rules through learning profile + resume context so tutor feedback is structured, multi-turn, and includes word expansion.

中文：
1. 学习者打开首页；
2. 首页展示 AI Chat、Custom Goal、Words Practice、History，以及抽屉中的 Customize、Diagnostics、Privacy、Clear History、Reset Learning Profile；
3. 学习者可修改学习模式、tutor 风格、难度和自定义目标；语音模式直接在 Chat 麦克风按钮上选择；
4. 进入 AI Chat；
5. Chat 自动携带学习配置请求 `/session` 并连接 LiveKit；
6. 全新空聊天连接后 tutor 给一句简短 warm-up；History Continue 或 resume-context 重连会保持安静等待学习者继续；
7. 学习者点击麦克风开始语音输入；`Auto Voice` 会持续监听、由 LiveKit 自动提交轮次，并在转写到达时立即把学习者语音展示到聊天列表；再次点击或点击发送会停止；`Manual Voice` 会显示音波，点击 `x` 取消，点击发送结束语音输入；学习者语音会先缓冲，只有点击发送后才进入聊天列表和 transcript；文字 fallback 仍可用；
8. 如果已捕获语音/转写，UI 从 `Listening` 进入 `Tutor Thinking`；如果没有说话，点击发送只退出语音模式，不创建空消息；
9. UI 展示 `Listening`、`Tutor Thinking`、`Tutor Speaking`、重连、结束和具体失败状态；
10. 聊天列表展示 `You`、`Tutor` 和少量 `System` 消息及状态；非错误类进度提示不进入消息列表；
11. 返回离开 Chat 或 `End Session` 会断开 LiveKit、释放音频，并立即保存本地 transcript 文本和 fallback summary；
12. AI 增量/最终摘要可用时异步更新本地记录；
13. 如果 LiveKit 无法重连当前 room，Chat 会重新请求新的 `/session`，同时保留页面上已有的本地聊天消息；
14. 从 History Continue 进入 Chat 时，会按“已保存消息 -> transcript 文本 -> resume-context transcript 摘录 -> summary fallback”的顺序恢复聊天内容；
15. History 展示最近会话和复盘详情；
16. 从 History 点击 `Continue` 会用相同学习配置开启新 room，并把上一轮短上下文传给 tutor；
17. History Continue 保持原本地聊天 id；如果只是查看并退出，没有产生新的学习者/tutor 内容，原记录不变；有新文字或 final 语音/tutor 转写时，更新同一条 History item，而不是新增重复列表项；
18. Chat 麦克风按钮支持长按，在输入栏上方弹出模式选择；`Auto Voice` 是默认模式，会保持 LiveKit 持续麦克风输入，让 STT/turn detection 自动提交语音，包括当前活跃 Chat 页进入后台时；`Manual Voice` 保留现在的点击录音、发送结束逻辑；
19. Settings 可清空历史或重置默认学习配置；
20. Diagnostics 在主学习页之外展示脱敏运行信息。

## 4. Learning Profile
V1 profile fields:
- learning mode: `Daily Conversation`, `Interview English`, `Travel English`, `Pronunciation Practice`
- tutor style: `Gentle Coach`, `Direct Coach`, `Challenge Coach`
- difficulty: `Beginner`, `Intermediate`, `Advanced`
- custom goal: trimmed and length-limited before use

The profile is stored locally as the default, sent to backend `/session`, returned as normalized config, saved in each `SessionRecord`, and used by the backend agent prompt.

中文：V1 学习配置包含学习模式、tutor 风格、难度和自定义目标。配置会本地保存为默认值，发送到后端 `/session`，由后端标准化返回，保存到每条 `SessionRecord`，并用于后端 agent prompt。

## 5. State Model
- `idle`
- `connecting`
- `connected`
- `listening`
- `tutorThinking`
- `tutorSpeaking`
- `reconnecting`
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

中文：状态覆盖空闲、连接中、已连接、收听中、tutor 思考中、tutor 说话中、重连中、会话中、结束，以及后端、LiveKit、麦克风权限、音频会话、麦克风发布、文字发送、存储和未知错误。

## 6. MVVM Responsibilities
- `HomeViewController`: renders product entry points and loads latest local profile/summary.
- `WordsPracticeViewController`: shows target-word cards and starts LiveKit-backed word practice chat with structured coaching context.
- `SessionViewController`: renders `SessionViewState`, forwards mic/text/reconnect/end actions, and owns UIKit/SnapKit layout only.
- `SessionViewModel`: owns backend session creation, LiveKit connection, microphone permission, voice/text input flow, reconnect, transcript, summaries, errors, and local persistence.
- `SessionViewState`: single render model for profile text, status, button enablement, chat messages, transcript, summary draft, latest summary, and errors.
- `SessionRecord`: Codable local record with metadata, learning profile, messages, transcript text, local summary, and optional AI summary.
- `SessionResumeContext`: short Codable context generated from a previous local record for History Continue.
- `SessionViewController` now tracks in-flight UI action tasks with same-kind mutual exclusion (`sessionControl` / `voiceControl` / `textSend`) and cancels active tasks when leaving Chat to reduce overlapping async actions.
- `SessionViewModel` scopes Auto Voice background behavior to the active Chat lifecycle and avoids restarting an already-active microphone.
- Chat failures are surfaced as transient top banner notifications (instead of persistent inline red text), while failure details still go into system messages and logs.

中文：Home 负责入口展示；Session VC 只负责渲染和事件转发；ViewModel 负责会话编排、语音/文字输入、转写、摘要、错误和持久化；ViewState 是统一渲染模型；SessionRecord 是本地 Codable 记录；SessionResumeContext 用于从历史记录生成短上下文，让 Continue 能延续学习目标。

## 7. Transcript And Messages
- Voice transcript updates come from LiveKit transcription segments when available.
- Text fallback is appended immediately as a `You` message.
- Messages are stored with id, session id, speaker, text, created time, input type, and status.
- History restoration prefers stored structured messages. If older records lack messages, the app reconstructs display text from `transcriptText` or resume context; if neither exists, it shows a compact previous-session summary instead of an empty chat.
- Stored speakers are `learner`, `tutor`, and `system`.
- Stored statuses include `sending`, `sent`, `failed`, `transcribing`, and `streaming`.
- Raw audio is never stored.

中文：语音转写来自 LiveKit transcription segments；文字 fallback 会立即显示为 `You`；每条消息保存 id、session id、speaker、text、created time、input type 和 status；历史恢复优先使用结构化 messages，如果旧记录没有 messages，会从 `transcriptText` 或 resume context 重建展示内容；如果仍没有可用文本，则展示上一轮 summary fallback，避免空白聊天页；不保存原始音频。

## 8. Summary Generation
- Back navigation or `End Session` immediately saves a local fallback summary from transcript text and metadata.
- During longer sessions, incremental AI summary draft can update after several final transcript turns.
- Final AI summary can continue after leaving the Chat screen and update the saved record asynchronously.
- If the session record is deleted or history is cleared before final generation completes, the stale result is ignored.
- If AI summary fails or is unavailable, local summary remains the source of truth.
- Summary generation uses transcript text only, never raw audio.
- Summary quality control is not part of V1.

中文：结束会话时立即保存本地 fallback summary；较长会话中可增量更新 AI 摘要草稿；最终 AI 摘要即使离开 Chat 页面也可以继续生成，并在成功后异步更新本地记录；如果生成完成前该 session 被删除或历史被清空，则忽略过期结果；失败时保留本地摘要；摘要只使用 transcript 文本，不使用 raw audio；摘要质量控制不属于 V1。

## 9. Privacy / Local Storage
- Local storage keeps latest 20 sessions.
- Stored data: metadata, learning profile, text messages, transcript text, local summary, optional AI summary status/result.
- Not stored: raw audio, LiveKit token, API key, API secret.
- `Clear History` removes local records.

中文：本地只保留最近 20 条 session，保存元数据、学习配置、文本消息、transcript、本地摘要和可选 AI 摘要状态/结果；不保存 raw audio、token、API key、API secret；`Clear History` 可清空本地记录。

## 10. Device Notes
- The app uses UIKit + SnapKit, no SwiftUI.
- `LaunchScreen.storyboard` is required for full-screen launch on modern iPhones.
- Simulator can use `127.0.0.1`; physical iPhone needs the Mac LAN IP.
- `Info.plist` allows local-network HTTP development access and background audio for active voice sessions.
- `Auto Voice` never asks for microphone permission while already in background. The learner must grant microphone access in the foreground first.
- The background Auto Voice path is scoped to the active Chat page only; it does not run after back navigation, `End Session`, Home, History, Settings, or Diagnostics.
- The main background path starts microphone publishing on `sceneWillResignActive`; `sceneDidEnterBackground` remains only a fallback diagnostic path.
- When returning from background with microphone input still active, Chat restarts the waveform animation so the visual state matches the active voice state.
- Background mode is scoped to active audio sessions, not unlimited background execution.

中文：App 使用 UIKit + SnapKit，不使用 SwiftUI；现代 iPhone 全屏启动依赖 `LaunchScreen.storyboard`；模拟器可用 `127.0.0.1`，真机需要 Mac 局域网 IP；`Info.plist` 支持本地 HTTP 开发访问和活跃语音会话后台音频；`Auto Voice` 不会在后台弹出麦克风权限请求，学习者必须先在前台授权；后台自动语音只作用于当前活跃 Chat 页，返回、`End Session`、Home、History、Settings 或 Diagnostics 都不会触发；后台主路径会在 `sceneWillResignActive` 提前发布麦克风，`sceneDidEnterBackground` 只作为兜底诊断；如果回到前台时麦克风仍处于活跃输入状态，Chat 会重启动音波动画，保证视觉状态和语音状态一致；后台能力不是无限后台执行。

## 11. Validation
Verified:
- Generic iOS Debug build succeeds.
- iOS unit tests pass on iPhone 17 simulator.
- ViewModel connect/start/reconnect/end/transcript behavior is covered by tests.
- Storage latest-20 and clear-history behavior are covered by tests.
- History Continue message restoration and no-duplicate-save-on-review-exit behavior are covered by tests.
- Auto/Manual Voice behavior, Manual Voice buffered display-until-send, pre-background Auto Voice start, did-enter-background fallback, already-active microphone preservation, and active-Chat-only scoping are covered by ViewModel tests.
- DTO decoding and failure state mapping are covered by tests.
- Full voice loop: auto-connect, tap mic to show waveform, send voice input, tutor voice reply, end session.
- AI Chat polish: title plus connection dot, tap message area to dismiss keyboard, auto reconnect after connection loss, back-button disconnect, bottom-sheet summary, right-aligned learner bubbles, compact input bar, foreground-resumed waveform, and keyboard-following message list.
- Learner/tutor transcript stability.
- Background audio behavior, including Auto Voice from the Chat mic mode picker and continuous LiveKit speech auto-submit on a physical device.
- Reconnect behavior after real network/audio interruptions.
- Reconnect fallback to a new `/session` while keeping local messages visible.
- History Continue with previous summary/transcript context.
- Summary update after real transcript availability.

中文：已验证 generic iOS Debug build、iPhone 17 simulator 单元测试，以及提交范围内的真机最终验证；测试覆盖 ViewModel、存储、DTO、失败状态、History Continue 消息恢复、只查看历史后退出不新增重复记录、Manual Voice 发送前缓冲展示，以及后台语音自动启动开关的开启/关闭行为。真机验证范围包括完整语音闭环、双方转写、后台音频、前台恢复音波动画、真实中断后的重连和真实 transcript 后的摘要更新。

## 12. Dependencies
- `AppEnvironment`
- `BackendAPIClientProtocol`
- `LiveKitAgentControlling`
- `AudioSessionManaging`
- `SessionStorageManaging`
- `LearningProfileStoring`
- `AppSettingsStoring`
- LiveKit Swift SDK
- SnapKit

中文：依赖包括环境注入、后端协议、LiveKit agent 协议、音频协议、本地存储协议、学习配置存储、App 设置存储、LiveKit Swift SDK 和 SnapKit。

## 13. Change Log
- 2026-05-11: Marked final physical-device validation as passed for the submission scope and moved the AI Chat / background / transcript / History Continue checks into verified documentation.
- 2026-05-11: Fixed foreground recovery for active voice input by restarting the waveform animation when Chat returns from background.
- 2026-05-11: Changed `Manual Voice` transcript display so learner speech is buffered and only appears in chat/transcript after send, while `Auto Voice` still displays speech as transcription arrives.
- 2026-05-11: Replaced persistent inline Chat error text with transient top-banner notifications to reduce visual noise while preserving failure details in system messages/logs.
- 2026-05-11: Added UI action task ownership/cancellation in Chat VC and deduped background auto-start async flow in ViewModel to improve thread/lifecycle stability.
- 2026-05-11: Added same-kind task mutual exclusion in Chat VC so repeated taps on reconnect/end/mic/send replace older in-flight tasks of the same action kind.
- 2026-05-11: Upgraded Words Practice to LiveKit-based sessions with target-word context injection, structured score/correction/better-sentence/next-challenge feedback, and expansion-word guidance.
- 2026-05-11: Moved voice mode control out of Settings/Customize into the Chat mic button long-press picker. `Auto Voice` is now the default; `Manual Voice` preserves the tap-record/send-to-finish flow.
- 2026-05-11: Scoped Auto Voice background behavior to the active Chat page only and moved automatic microphone publishing to pre-background `sceneWillResignActive`, with `sceneDidEnterBackground` kept as a fallback diagnostic path.
- 2026-05-11: Enabled Words Practice as a real Home entry (not Coming Soon) with dedicated list/detail practice pages and local sentence feedback.
- 2026-05-11: Updated Home/Drawer product flow to current IA (Customize, Diagnostics, Privacy, Clear History, Reset Learning Profile) and removed the old Settings text-page narrative.
- 2026-05-11: Fixed History Continue restoration to fall back through saved messages, transcript text, resume-context transcript, and summary; also made continued practice update the original local history record instead of creating duplicate list items.
- 2026-05-11: Restored the AI Chat navigation title, added tap-to-dismiss keyboard on the message area, simplified Summary to summary-only content, and changed fresh empty chats to get a short tutor opener while resume-context chats stay quiet.
- 2026-05-11: Updated Chat Summary bottom sheet to prioritize live draft summary while a session is active, and show saved local/history summary after session end.
- 2026-05-11: Expanded History Continue resume-context transcript window so the backend receives a longer recent conversation slice, reducing context loss after entering chat from history.
- 2026-05-11: Added a one-time microphone publish warmup retry when no learner transcript appears shortly after first voice start, reducing first-entry voice no-response cases.
- 2026-05-11: Changed final AI summary generation so it can continue after leaving Chat and write back only if the saved session record still exists.
- 2026-05-11: Made History Continue restore saved chat messages in the Chat list and changed the Chat Summary action to a bottom sheet.
- 2026-05-11: Added reconnect fallback to a fresh backend session and History Continue with short previous-session context.
- 2026-05-11: Updated AI Chat voice input to tap-to-record with waveform feedback, `x` cancel, send-to-finish, keyboard-following message list, and fewer non-error system prompts.
- 2026-05-11: Polished AI Chat into a chat-first layout with navigation title connection status, Summary button, right-aligned learner bubbles, compact mic/text/send input bar, back-button disconnect, and SDK-driven auto reconnect.
- 2026-05-09: Added V1 Home, Learning Profile, History, Diagnostics, Settings, chat-style message list, profile-aware session creation, and profile-aware local records.
- 2026-05-09: Changed Chat to auto-connect while keeping the tutor quiet until learner voice/text input.
- 2026-05-09: Added learning profile defaults and reset behavior through local storage.
- 2026-05-08: Added transcript-based local summary generation and P2 AI summary network methods.
- 2026-05-08: Added Summary screen and background/foreground diagnostics.
- 2026-05-07: Refactored Session into MVVM with protocol-driven Network, Agent, Audio, and Storage dependencies.
- 2026-05-07: Added specific failure states, microphone permission flow, reconnect, local summaries, privacy note, and Clear History.
