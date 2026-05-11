# AI Workflow

## 1. Overview
This file is a living engineering record for how AI tools are used to build AITutor.
It documents the workflow, verification habits, tool boundaries, and lessons learned while building the backend, UIKit app, LiveKit integration, and required deliverables (`README.md`, `.env.example`, `plan.md`, `workflow.md`).

中文：
本文档是 AITutor 项目中 AI 工具使用方式的动态工程记录。
它记录后端、UIKit App、LiveKit 集成和必交文件（`README.md`、`.env.example`、`plan.md`、`workflow.md`）开发过程中的工作流、验证习惯、工具边界和经验。

## 2. Tools & Models Used
- Codex with GPT-5.5: repo-aware implementation planning, code scaffolding, refactoring suggestions, debugging support, and documentation updates.
- GPT-5.5 chat reasoning: product planning, tradeoff analysis, README/plan/workflow structure, and final submission-readiness review.
- Claude (optional secondary review): alternative reasoning or documentation review when useful.
- LiveKit official docs: source of truth for LiveKit Agents and client SDK behavior.
- Xcode and build logs: source of truth for iOS compile/runtime behavior.
- Terminal commands: local validation for backend endpoints, Python syntax, file structure, and git status.
- LiveKit Inference models are product runtime dependencies for STT/LLM/TTS, not AI coding assistants.

中文：
- Codex with GPT-5.5：用于结合仓库上下文做实现规划、代码骨架、重构建议、调试支持和文档更新。
- GPT-5.5 chat reasoning：用于产品规划、取舍分析、README/plan/workflow 结构设计和最终提交前检查。
- Claude（可选二次审查）：必要时用于方案对照或文档审查。
- LiveKit 官方文档：作为 LiveKit Agents 和客户端 SDK 行为的事实来源。
- Xcode 与构建日志：作为 iOS 编译和运行行为的事实来源。
- 终端命令：用于验证后端接口、Python 语法、文件结构和 git 状态。
- LiveKit Inference 模型属于产品运行时 STT/LLM/TTS 依赖，不作为 AI coding assistant 记录。

## 3. Tool Selection Rationale
Codex is the primary tool because it can work directly inside the repository and keep code, docs, and project structure aligned.
Official docs and local builds outrank AI output because SDK APIs, permissions, audio behavior, and realtime networking must be verified against real tooling.

中文：
Codex 是主要工具，因为它能直接结合仓库内容工作，并让代码、文档和工程结构保持一致。
官方文档和本地构建结果优先级高于 AI 输出，因为 SDK API、权限、音频行为和实时网络必须通过真实工具验证。

## 4. Workflow Timeline
1. Requirement analysis
- Use AI to convert the challenge prompt into concrete deliverables, scoring priorities, and non-goals.

2. Product planning
- Use AI to draft and refine `plan.md`, then keep it aligned with product scope and engineering tradeoffs.

3. Backend scaffolding
- Use AI to create a minimal FastAPI structure for health/config/session endpoints and LiveKit token issuance.

4. UIKit scaffolding
- Use AI to define a native UIKit app structure with session controls, state display, backend client, audio manager, and LiveKit service boundary.

5. LiveKit integration
- Use AI for implementation guidance, but verify final API usage against official LiveKit docs and local compile/runtime behavior.

6. Validation and documentation pass
- Use AI to maintain README, feature docs, workflow notes, and checklists after each major behavior change.

7. UI/productization phase
- Use AI to turn the single-session demo into a lightweight V1 app flow: Home, Learning Profile, AI Chat, History, Diagnostics, and Settings.
- Use AI to refine the AI Chat screen from a debug-heavy layout into a chat-first mobile flow with navigation-level connection status, a Summary entry, aligned message bubbles, and a compact mic/text/send input bar.
- Use local builds and unit tests as the source of truth for whether the larger UI flow still compiles and preserves session behavior.

8. Submission-readiness pass
- Use GPT-5.5/Codex to compare the final project against the challenge rubric: working software, mobile craft, clean architecture, tradeoff reasoning, and required deliverables.
- Use AI to tighten `README.md` into a reviewer-friendly Quick Start with a one-line fast path plus detailed steps.
- Use AI to sync `plan.md` with the final product behavior: foreground-only Auto Voice, explicit BG Auto, Manual Voice, bottom-sheet summary, History Continue context, and the `env.example` -> `env` -> `.env` configuration flow.
- Use local diffs and `git diff --check` as the final source of truth for documentation-only edits.

中文：
1. 需求分析：用 AI 将题目拆成具体交付物、评分重点和不做范围。
2. 产品计划：用 AI 起草并完善 `plan.md`，同时保持它和产品范围、工程取舍一致。
3. 后端骨架：用 AI 搭建最小 FastAPI 结构，包括健康检查、配置、会话接口和 LiveKit token 下发。
4. UIKit 骨架：用 AI 定义原生 UIKit App 结构，包括会话控制、状态显示、后端客户端、音频管理和 LiveKit 服务边界。
5. LiveKit 集成：用 AI 辅助实现，但最终 API 用法必须对照官方文档和本地编译/运行结果验证。
6. 验证与文档：每次主要行为变化后，用 AI 维护 README、功能文档、workflow 记录和检查清单。

7. UI/产品化阶段：用 AI 将单会话 demo 扩展为轻量 V1 App 链路：首页、学习配置、AI Chat、History、Diagnostics、Settings；继续用 AI 将 AI Chat 从偏调试的布局收敛为移动端聊天体验，包括导航栏连接状态、Summary 入口、左右消息气泡和紧凑的麦克风/输入/发送底栏；用本地构建和单元测试作为更大 UI 链路是否仍可编译、是否保持会话行为的事实来源。

8. 提交前收口阶段：用 GPT-5.5/Codex 对照题目评分标准检查最终项目，包括可运行软件、移动端体验、清晰架构、取舍说明和必交文件；用 AI 将 `README.md` 收敛为适合评审的 Quick Start，包含一句话快速路径和详细步骤；用 AI 同步 `plan.md` 到最终产品行为，包括默认前台 Auto Voice、显式 BG Auto、Manual Voice、summary 底部弹层、History Continue 上下文，以及 `env.example` -> `env` -> `.env` 配置链路；最后用本地 diff 和 `git diff --check` 作为文档修改的事实来源。

## 5. Concrete AI Usage
- Decomposed the challenge into P0/P1/P2 priorities and explicit non-goals.
- Drafted bilingual `README.md`, `plan.md`, and `workflow.md`.
- Proposed UIKit service boundaries for UI, session orchestration, audio I/O, and backend networking.
- Helped define the English tutor prompt policy: short replies, encouraging correction, one correction focus, one follow-up question.
- Converted risks into validation items, such as token checks, microphone permission checks, and LiveKit room consistency.
- Used AI to compare iOS dependency needs and keep the MVP dependency set limited to LiveKit Swift SDK plus SnapKit.
- Used AI to productize the iOS flow into Home, Learning Profile, AI Chat, History, Diagnostics, and Settings while avoiding login/cloud/course-system scope creep.
- Used AI to update tests after the interaction changed from `Connect -> Start Session -> tutor speaks` to `AI Chat auto-connects -> learner speaks/types -> tutor responds`.
- Used AI to compare voice UX options and settle on foreground-only Auto Voice as the default natural tutoring mode, explicit BG Auto for background-capable free talk, and Manual Voice as a controlled fallback for demo reliability and transcript timing.
- Used AI to refine mobile chat details: connection dot in the navigation title, keyboard-aware input movement, tap-to-dismiss keyboard behavior, learner-right message alignment, and summary as a bottom sheet rather than a full navigation break.
- Used AI for final submission documentation alignment: `README.md` Quick Start, `plan.md` final product plan, `docs/todo.md` closing checklist, and `workflow.md` verification record.

中文：
- 将题目拆解为 P0/P1/P2 优先级和明确不做范围。
- 起草中英双语 `README.md`、`plan.md` 和 `workflow.md`。
- 为 UIKit 定义 UI、会话编排、音频 I/O 和后端网络的服务边界。
- 协助定义英语家教 prompt 策略：简短回复、鼓励式纠错、一次只纠正一个重点、一次只追问一个问题。
- 将风险转化为验证项，例如 token 检查、麦克风权限检查和 LiveKit 房间一致性。
- 使用 AI 辅助判断 iOS 依赖边界，并将 MVP 第三方库控制在 LiveKit Swift SDK 和 SnapKit。
- 使用 AI 将 iOS 链路产品化为 Home、Learning Profile、AI Chat、History、Diagnostics、Settings，同时避免登录、云同步、完整课程系统等范围膨胀。
- 在交互从 `Connect -> Start Session -> tutor 说话` 改为 `AI Chat 自动连接 -> 学习者说话/输入 -> tutor 回复` 后，使用 AI 辅助更新测试。
- 使用 AI 对比语音交互方案，并收敛为默认只在前台生效的 Auto Voice、显式开启后台语音的 BG Auto，以及作为可控演示和 transcript 时序 fallback 的 Manual Voice。
- 使用 AI 细化移动端聊天体验：导航标题连接圆点、键盘跟随输入区、点击消息区域收起键盘、学习者消息靠右展示，以及 summary 使用底部弹层而不是强跳转页面。
- 使用 AI 做最终提交文档对齐：`README.md` Quick Start、`plan.md` 最终产品计划、`docs/todo.md` 收口清单和 `workflow.md` 验证记录。

## 6. AI Boundaries
AI can help with:
- requirement decomposition
- code scaffolding
- refactoring suggestions
- documentation drafts
- debugging hypotheses
- validation checklist generation

AI must not be treated as final authority for:
- SDK API correctness
- secret handling
- compile results
- microphone/audio behavior
- realtime voice loop behavior
- security or privacy claims

中文：
AI 可以帮助：
- 需求拆解；
- 代码骨架；
- 重构建议；
- 文档初稿；
- 调试假设；
- 验证清单生成。

AI 不能作为以下事项的最终权威：
- SDK API 是否正确；
- 密钥处理是否安全；
- 编译结果；
- 麦克风/音频行为；
- 实时语音闭环行为；
- 安全或隐私声明。

## 7. Human Review & Source of Truth
Source-of-truth priority:
1. Official LiveKit documentation and SDK examples.
2. Local build and runtime behavior.
3. Local tests and manual validation.
4. Project docs and feature-level `FEATURE.md` files.
5. AI suggestions.

Review loop:
1. Check whether the AI suggestion fits the project scope.
2. Check whether it preserves clean boundaries between UI, audio, networking, agent, and storage.
3. Verify SDK/API usage against official docs.
4. Run local validation when implementation exists.
5. Update `README.md`, `FEATURE.md`, or `workflow.md` when behavior changes.

中文：
事实来源优先级：
1. LiveKit 官方文档和 SDK 示例；
2. 本地构建和运行行为；
3. 本地测试和手动验证；
4. 项目文档和功能级 `FEATURE.md`；
5. AI 建议。

审查流程：
1. 检查 AI 建议是否符合项目范围；
2. 检查是否保持 UI、音频、网络、agent、存储之间的清晰边界；
3. 对照官方文档验证 SDK/API 用法；
4. 有实现后执行本地验证；
5. 行为变化后更新 `README.md`、`FEATURE.md` 或 `workflow.md`。

## 8. Validation Evidence
Current verified items:
- Python backend files pass syntax compilation with `python3 -m py_compile backend/*.py`.
- Backend dependencies install successfully in `backend/.venv`.
- LiveKit agent CLI loads and exposes `download-files`, `dev`, `start`, `connect`, and `console`.
- LiveKit Silero and turn-detector model files download successfully.
- Backend `/health` returns `{ "status": "ok" }` in local smoke testing.
- Backend `/session` returns `livekit_url`, `token`, `room_name`, `participant_identity`, and session metadata with dummy local env values.
- Backend diagnostics script exists at `backend/tests/diagnose_backend.py`, prints structured logs, masks tokens/secrets, checks `/summary` and `/summary/incremental` response shape when the API is running, and passes `--skip-api`.
- Backend local startup scripts exist for setup, API server, agent dev mode, and combined startup; root `start_all.sh` is the reviewer-facing entrypoint, stops stale local `uvicorn main:app` and `agent.py dev` processes before launch, clears and writes API/agent logs to `logs/`, waits for API health and agent `registered worker`, and scripts copy reviewer-edited root `env` to runtime `.env` before setup/start.
- Root `clear_logs.sh` truncates runtime logs safely, and the iOS Xcode target runs it in Debug builds before app launch so each Cmd+R starts with fresh API/agent logs.
- Root `check_audio_health.sh` summarizes audio-specific agent log evidence such as the active voice profile, slow TTS generation, stale balanced-buffer evidence, smooth-buffer evidence, microphone-track presence, and repeated input-speech warnings.
- Root `check_backend.sh` verifies backend diagnostics and checks `logs/agent.log` for `registered worker`.
- iOS project resolves Swift Package dependencies for LiveKit Swift SDK, SnapKit, SwiftProtobuf, LiveKitWebRTC, and LiveKitUniFFI.
- Generic iOS Debug build succeeds with `xcodebuild -project ios/AITutor.xcodeproj -scheme AITutor -configuration Debug -destination 'generic/platform=iOS' build`.
- `LiveKitAgentClient` now uses the real LiveKit Swift SDK `Room` connection and microphone publishing path.
- Tutor speech is intentional: fresh empty chats get one short warm-up opener, while History Continue and resume-context reconnects stay quiet until learner voice input or text fallback.
- iOS listens for LiveKit transcription segments through `RoomDelegate`, merges partial/final updates by segment ID, and displays lightweight `You` / `Tutor` transcript lines in the Session screen.
- Typed fallback messages are displayed immediately as `You` transcript lines so the UI path can be validated even before voice transcription arrives.
- `Info.plist` declares `UIBackgroundModes=audio`, `SceneDelegate` emits `[test]` background/foreground lifecycle logs, `AudioSessionManager` logs interruption/route-change diagnostics, and `LiveKitAgentClient` exposes secret-safe connection/microphone diagnostics for foreground recovery validation.
- iOS has been refactored into MVVM and layers: `App`, `Core`, `Network`, `Agent`, and `Features/Session`.
- `SessionViewController` now only renders `SessionViewState` and forwards actions; `SessionViewModel` owns connect/start/reconnect/end, logs, errors, and local summary saving.
- `SessionState` now has specific failure states instead of a generic `Failed`, making on-device debugging more direct.
- `SessionStorageManager` saves local JSON/Codable metadata and summary records, keeping only the latest 20 and no raw audio.
- `LaunchScreen.storyboard` is included and referenced by `UILaunchStoryboardName`, which fixes modern iPhone letterbox black bars caused by missing launch-screen metadata.
- `AppLogger` provides centralized DEBUG-only Xcode console logging with the `[test]` prefix for session, audio, LiveKit, network, storage, and app diagnostics.
- `Info.plist` declares local-network/ATS development support for physical iPhone access to `http://<mac-lan-ip>:8000`.
- `ios/scripts/configure_backend_url.sh` exists, detects the Mac LAN IP, updates both `ios/project.yml` and `ios/AITutor.xcodeproj`, and is called by root `./start_all.sh`.
- `ios/scripts/start_ios.sh` exists, runs URL configuration, opens Xcode, and optionally triggers Xcode Run. Root `./start_all.sh` calls it after backend API and agent readiness.
- Required planning/docs structure exists: `README.md`, `.env.example`, `plan.md`, `workflow.md`.
- `env.example` and `.env.example` are kept aligned as safe templates. Reviewers copy a template to root `env`, fill LiveKit values, and startup scripts copy `env` into ignored runtime `.env`.
- `README.md` Reviewer Quick Start now includes a one-line fast path before the detailed setup steps.
- Feature scope is documented in `docs/feature-scope.md`.
- Feature documentation policy is documented in `engineering-standards/FEATURE_DOC_POLICY.md`.
- Backend agent code now follows the LiveKit Agents server/session structure with LiveKit Inference STT/LLM/TTS.
- Tutor latency and voice clarity are now controlled by `VOICE_PIPELINE_PROFILE=smooth|balanced|realtime`. The unsuccessful `legacy` experiment was removed after real-device comparison. `smooth` is now the default demo-safe profile and uses complete-sentence TTS buffering for maximum continuity; `balanced` remains available for later latency tuning with LLM preemptive generation, no interruption, SDK default streaming TTS, shorter replies, and `cartesia/sonic-3`; `realtime` uses LiveKit's default streaming TTS node with interruption enabled for the lowest latency. The agent logs `[profile] voice_pipeline` at startup and no longer changes profile dynamically during a session.
- Back navigation or `End Session` now saves a local transcript-based summary immediately, marks AI summary as generating, and updates the local record if the optional P2 `/summary` endpoint completes.
- Backend `POST /summary` accepts transcript text only, uses LiveKit Inference LLM when available, and returns a deterministic fallback summary if provider generation fails.
- iOS now queues final transcript turns, calls optional P2 `POST /summary/incremental` during active sessions, and shows the latest running draft when the separate Summary screen is opened.
- Final AI summary generation can include the latest running summary so end-of-session work is smaller than summarizing from scratch.
- Final AI summary generation now survives leaving the Chat screen; it writes back only when the saved session record still exists, so clearing history does not resurrect stale data.
- Final and incremental summary tasks are cancelled or ignored when a new connection starts, local history is cleared, or the target session/generation is stale.
- Summary quality control is intentionally excluded from the current implementation scope.
- `docs/RUNBOOK.md` now exists as the operational troubleshooting source for backend startup, agent registration, duplicate tutor voices, iPhone LAN access, microphone/audio failures, choppy voice, transcript gaps, summary generation, and background-mode recovery.
- iOS `AITutorTests` unit test target now exists and is included in the shared `AITutor` scheme.
- iOS unit tests cover `SessionViewModel` connect/start/reconnect/end/transcript behavior with protocol mocks, History Continue message restoration, no-change review exits, same-record continued-practice updates after new input, Auto/BG Auto/Manual Voice mode behavior, foreground Auto background stop, Manual Voice buffered transcript display until send, active-Chat-only background scoping, `SessionStorageManager` latest-20 JSON persistence and clear-history, backend DTO decoding, summary display formatting, and specific failure-state mapping.
- iOS unit tests pass with `xcodebuild test -project ios/AITutor.xcodeproj -scheme AITutor -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` on an iPhone 17 simulator.
- V1 UI/productization compiles: Home, Learning Profile editor, AI Chat, History, Session Review, Diagnostics, and Settings are implemented in UIKit/SnapKit and wired through `SceneDelegate`.
- Learning profile now flows through iOS -> `/session` -> backend normalization -> room-keyed profile storage -> agent prompt, and is also stored in local session records.
- AI Chat now auto-connects on entry. Fresh empty chats get one short tutor warm-up opener; History Continue and resume-context reconnects stay quiet until the learner continues.
- AI Chat now shows connection status beside the navigation title: gray when disconnected, blinking orange while connecting/reconnecting, and green when connected.
- LiveKit connection, reconnecting, reconnected, and disconnected events are forwarded into `SessionViewModel`; unexpected disconnects schedule a short automatic reconnect attempt, while back-button navigation suppresses reconnect and ends the session.
- AI Chat was simplified into a message-first layout: learner messages align right, tutor/system messages align left/center, Summary is a navigation action, and the bottom input bar is mic + text/waveform + send.
- AI Chat voice input now uses explicit Chat-level modes instead of hold-to-speak: default `Auto Voice` supports foreground hands-free speech, `BG Auto` is explicit background-capable speech, and `Manual Voice` shows a waveform, supports `x` cancel, and waits for send before committing learner speech.
- Chat now owns voice mode selection directly: long-pressing the mic button opens an above-input mode picker for `Auto Voice`, `BG Auto`, and `Manual Voice`. `Auto Voice` is persisted as the default foreground-only hands-free mode. `BG Auto` is the explicit opt-in mode that can start/keep microphone publishing before background suspension only while Chat is active and connected.
- Manual Voice now buffers learner transcription and only adds it to the visible chat/transcript after send. Auto Voice still displays learner speech as LiveKit transcription arrives.
- Chat restarts the waveform animation when returning to foreground with microphone input still active, so the visual recording state does not freeze after background recovery.
- AI Chat now follows keyboard frame changes so the message list and input bar move with the keyboard and restore when it hides; tapping the message area dismisses the keyboard.
- Settings now supports an on-device Backend URL override, and Diagnostics shows the effective URL plus source. This makes an installed iPhone app usable from the Home Screen after Xcode installation, as long as the Mac backend remains running.
- Reconnect now tries the current LiveKit room first, then falls back to a fresh backend `/session` while keeping visible local chat messages and sending a short active-session resume context when available.
- History Continue now sends a short text-only resume context from the previous session summary/transcript so the tutor can continue the learner's goal without raw audio, and it seeds the Chat list from saved messages, transcript text, resume-context transcript, or a summary fallback.
- History Continue is now thread-safe: it keeps the original local history record id. Review-only exits leave the record unchanged, and new text or final voice/tutor transcript content updates the same History item instead of creating a duplicate list item.
- The Chat Summary action now opens as a bottom sheet and shows summary-only content; transcript/chat content remains in the Chat and History review surfaces.
- Main chat no longer contains a large debug panel; Diagnostics is a separate secret-safe screen, and Settings owns privacy/reset/clear-history actions.
- Documentation was updated for V1 product scope in `README.md`, `plan.md`, `docs/todo.md`, and feature-level docs.
- `plan.md` now reflects the final V1 behavior: foreground-only Auto Voice, explicit BG Auto, Manual Voice, bottom-sheet summary, keyboard-aware Chat input, History Continue bounded context, and aligned env template flow.
- Final physical-device validation is accepted as passed for the submission scope: Xcode install/run, microphone permission, microphone publishing, same-room agent join, one full realtime voice loop, learner/tutor transcript display, Auto/BG Auto/Manual Voice mode switching, BG Auto background scoping, foreground Auto background stop, foreground waveform recovery, reconnect fallback, History Continue, local summary save, and optional AI summary update.

中文：
当前已验证：
- Python 后端文件已通过 `python3 -m py_compile backend/*.py` 语法检查；
- 后端依赖可成功安装到 `backend/.venv`；
- LiveKit agent CLI 可加载，并显示 `download-files`、`dev`、`start`、`connect`、`console` 命令；
- LiveKit Silero 和 turn-detector 模型文件可成功下载；
- 本地 smoke test 中，后端 `/health` 返回 `{ "status": "ok" }`；
- 使用 dummy 本地环境变量时，后端 `/session` 返回 `livekit_url`、`token`、`room_name`、`participant_identity` 和 session 元数据；
- 后端诊断脚本已创建在 `backend/tests/diagnose_backend.py`，可输出结构化日志、脱敏 token/secret，在 API 运行时会检查 `/summary` 和 `/summary/incremental` 响应结构，并已通过 `--skip-api`；
- 后端本地启动脚本已创建，覆盖 setup、API server、agent dev mode 和一键联合启动；根目录 `start_all.sh` 是评审入口，会在启动前停止旧的本地 `uvicorn main:app` 和 `agent.py dev` 进程，先清理再将 API/agent 日志写入 `logs/`，等待 API health 和 agent `registered worker`，脚本会在 setup/start 前把评审者填写的根目录 `env` 复制到运行时 `.env`；
- 根目录 `clear_logs.sh` 会安全清空 runtime logs；iOS Xcode target 在 Debug 构建/运行前会调用它，所以每次 Cmd+R 都从新的 API/agent 日志开始；
- 根目录 `check_audio_health.sh` 会汇总 agent 音频相关日志证据，例如当前语音 profile、TTS 生成过慢、旧版 balanced buffer 证据、smooth buffer 证据、麦克风轨道是否出现，以及输入语音 warning 是否重复；
- 根目录 `check_backend.sh` 会运行后端诊断，并检查 `logs/agent.log` 中是否出现 `registered worker`；
- iOS 工程已能解析 LiveKit Swift SDK、SnapKit、SwiftProtobuf、LiveKitWebRTC 和 LiveKitUniFFI 的 Swift Package 依赖；
- generic iOS Debug 构建已通过：`xcodebuild -project ios/AITutor.xcodeproj -scheme AITutor -configuration Debug -destination 'generic/platform=iOS' build`；
- `LiveKitAgentClient` 已使用真实 LiveKit Swift SDK 的 `Room` 连接和麦克风发布路径；
- tutor 的开场行为是有意设计的：全新空聊天会有一句简短 warm-up；History Continue 和带 resume context 的重连会保持安静，直到学习者语音输入或文字 fallback；
- iOS 现在会通过 `RoomDelegate` 监听 LiveKit transcription segments，按 segment ID 合并 partial/final 更新，并在 Session 页面轻量展示 `You` / `Tutor` 转写行；
- 手动输入 fallback 文本也会立即显示为 `You` 转写行，因此即使语音转写尚未到达，也能验证转写 UI 路径；
- `Info.plist` 已声明 `UIBackgroundModes=audio`，`SceneDelegate` 会输出 `[test]` 前后台生命周期日志，`AudioSessionManager` 会输出音频中断和路由变化诊断，`LiveKitAgentClient` 会提供脱敏连接/麦克风诊断，用于验证活跃语音会话的后台和前台恢复表现；
- iOS 已重构为 MVVM 和 `App`、`Core`、`Network`、`Agent`、`Features/Session` 分层；
- `SessionViewController` 现在只渲染 `SessionViewState` 并转发动作；`SessionViewModel` 负责连接、开始、重连、结束、日志、错误和本地总结保存；
- `SessionState` 已从单一 `Failed` 扩展为具体失败状态，让真机调试更直接；
- `SessionStorageManager` 使用 JSON/Codable 保存本地元数据和总结，最多保留最近 20 条，不保存原始音频；
- 已加入 `LaunchScreen.storyboard` 并通过 `UILaunchStoryboardName` 引用，用于修复现代 iPhone 因缺少启动屏元数据导致的上下黑边；
- `AppLogger` 已提供集中式 DEBUG-only Xcode console 日志能力，并为 session、audio、LiveKit、network、storage、app 诊断统一增加 `[test]` 前缀；
- `Info.plist` 已声明本地网络/ATS 开发支持，真机可访问 `http://<mac-lan-ip>:8000`；
- `ios/scripts/configure_backend_url.sh` 已创建，可检测 Mac 局域网 IP，同步更新 `ios/project.yml` 和 `ios/AITutor.xcodeproj`，并已接入根目录 `./start_all.sh`；
- `ios/scripts/start_ios.sh` 已创建，会运行 URL 配置、打开 Xcode，并可选触发 Xcode Run；根目录 `./start_all.sh` 会在后端 API 和 agent ready 后调用它；
- 必要规划/文档结构存在：`README.md`、`.env.example`、`plan.md`、`workflow.md`；
- `env.example` 和 `.env.example` 保持一致，作为安全模板。评审者复制模板为根目录 `env`，填写 LiveKit 配置，启动脚本会把 `env` 复制到被 git 忽略的运行时 `.env`；
- `README.md` 的 Reviewer Quick Start 已在详细步骤前加入一句话快速启动路径；
- 功能范围已记录在 `docs/feature-scope.md`；
- 功能文档规范已记录在 `engineering-standards/FEATURE_DOC_POLICY.md`。
- 后端 agent 代码已按 LiveKit Agents server/session 结构接入 LiveKit Inference STT/LLM/TTS；
- tutor 延迟和语音清晰度现在通过 `VOICE_PIPELINE_PROFILE=smooth|balanced|realtime` 控制。真机对比后，效果不符合预期的 `legacy` 实验已移除。`smooth` 现在是默认演示保底模式，使用完整短句 TTS 缓冲以优先保证连续性；`balanced` 保留给后续低延迟调优，会开启 LLM 抢跑、关闭打断、使用 SDK 默认流式 TTS、缩短回复，并使用 `cartesia/sonic-3`；`realtime` 使用 LiveKit 默认流式 TTS 节点并允许打断，以追求最低延迟。agent 启动时会输出 `[profile] voice_pipeline`，会话中不再动态切换 profile。
- 返回离开 Chat 或 `End Session` 现在会立即保存基于 transcript 的本地摘要，将 AI 摘要标记为生成中，并在可选 P2 `/summary` 完成后更新本地记录；
- 后端 `POST /summary` 只接收 transcript 文本，优先使用 LiveKit Inference LLM，provider 生成失败时返回确定性的 fallback 摘要。
- iOS 现在会缓存 final transcript turns，并在活跃会话中调用可选 P2 `POST /summary/incremental`；打开独立 Summary 页面时会展示最新 running draft；
- 最终 AI 摘要生成可以带上最新 running summary，所以结束时不必完全从零总结。
- 最终 AI 摘要生成现在可以在离开 Chat 页面后继续执行；只有对应本地 session record 仍存在时才会写回，因此清空历史不会让旧摘要重新出现。
- 当开始新连接、清空本地历史，或目标 session/generation 已过期时，最终和增量摘要任务会被取消或忽略。
- 摘要质量控制已按当前范围刻意排除。
- `docs/RUNBOOK.md` 已作为运行排障入口，覆盖后端启动、agent 注册、重复 tutor 声音、iPhone 局域网访问、麦克风/音频失败、语音卡顿、转写缺失、摘要生成和后台恢复。
- iOS `AITutorTests` 单元测试 target 已创建，并已加入共享 `AITutor` scheme。
- iOS 单元测试覆盖 `SessionViewModel` 的 connect/start/reconnect/end/transcript 行为（使用协议 mock）、History Continue 消息恢复、只查看历史后退出不改变记录、有新输入后更新同一条继续练习记录、Auto/BG Auto/Manual Voice 模式行为、默认 Auto 进入后台前停止、Manual Voice 发送前缓冲展示、后台语音只作用于活跃 Chat 的作用域、`SessionStorageManager` 最近 20 条 JSON 持久化和清空历史、后端 DTO 解码、summary 展示格式和具体失败状态映射。
- iOS 单元测试已通过：`xcodebuild test -project ios/AITutor.xcodeproj -scheme AITutor -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'`，测试设备为 iPhone 17 simulator。
- V1 UI/产品化已通过编译：Home、Learning Profile editor、AI Chat、History、Session Review、Diagnostics、Settings 已用 UIKit/SnapKit 实现，并通过 `SceneDelegate` 接入。
- 学习配置现在从 iOS -> `/session` -> 后端标准化 -> 按 room 保存 -> agent prompt 全链路流转，同时也会保存到本地 session record。
- AI Chat 进入后会自动连接。全新空聊天会由 tutor 简短开场；History Continue 和带 resume context 的重连会保持安静，等待学习者继续。
- AI Chat 现在会在导航栏标题旁显示连接状态：未连接是灰点，连接/重连中是橙色闪烁点，连接成功是绿点。
- LiveKit 连接、重连、重连成功和断开事件会进入 `SessionViewModel`；非预期断开会短暂自动重连，点击返回离开页面时会抑制自动重连并结束会话。
- AI Chat 已收敛为消息优先布局：用户消息靠右，tutor/system 消息靠左/居中，Summary 变成导航栏入口，底部输入栏是麦克风 + 文本输入框 + 发送按钮。
- AI Chat 语音输入已从按住说话改为 Chat 内显式模式：默认 `Auto Voice` 支持前台免手持交流，`BG Auto` 是显式后台连续语音，`Manual Voice` 显示音波、支持 `x` 取消，并且等点击发送后才提交学习者语音。
- Chat 现在直接承载语音模式选择：长按麦克风按钮会在输入栏上方弹出 `Auto Voice` / `BG Auto` / `Manual Voice` 选择。`Auto Voice` 作为默认前台免手持模式持久化；`BG Auto` 是显式选择的后台连续语音模式，只有当前 Chat 活跃且已连接时，才会在后台挂起前自动发布或保持麦克风。
- Manual Voice 现在会先缓冲学习者语音转写，只有点击发送后才加入可见聊天列表和 transcript；Auto Voice 仍在 LiveKit 转写到达时立即展示学习者语音。
- Chat 从后台回到前台时，如果麦克风仍处于活跃输入状态，会重启动音波动画，避免录音视觉状态停住。
- AI Chat 现在跟随键盘 frame 调整，键盘弹出时消息列表和输入栏上移，键盘消失后恢复；点击消息区域会收起键盘。
- Settings 现在支持手机本地 Backend URL override，Diagnostics 会展示当前实际 URL 和来源。这样 App 通过 Xcode 安装到 iPhone 后，只要 Mac 后端仍在运行，就可以从桌面图标直接打开使用，不必依赖 Xcode Run 重新注入 URL。
- Reconnect 现在会先尝试当前 LiveKit room，失败后 fallback 到新的后端 `/session`，同时保留页面上已有的本地聊天消息，并在可用时发送当前会话的短 resume context。
- History Continue 现在会发送上一轮 summary/transcript 生成的短文本上下文，让 tutor 能延续学习目标；不会发送 raw audio，同时会按 saved messages、transcript text、resume-context transcript 或 summary fallback 的顺序恢复 Chat 列表。
- History Continue 现在是 thread-safe：它保持原本地历史记录 id；只查看后退出不会改变记录，有新文字或 final 语音/tutor 转写时会更新同一条 History item，而不是新增重复列表项。
- Chat 的 Summary 入口现在从底部弹出，并且只显示摘要内容；聊天/转写内容保留在 Chat 和 History 复盘中。
- 主聊天页不再放大段 debug 面板；Diagnostics 是独立脱敏诊断页，Settings 负责隐私说明、重置学习配置和清空历史。
- V1 产品范围已同步更新到 `README.md`、`plan.md`、`docs/todo.md` 和功能级文档。
- `plan.md` 已同步最终 V1 行为：默认前台 Auto Voice、显式 BG Auto、Manual Voice、summary 底部弹层、跟随键盘的 Chat 输入区、History Continue 有限上下文，以及一致的 env 模板链路。
- 提交范围内的最终真机验证按已通过处理：包括 Xcode 安装/运行、麦克风权限、麦克风发布、agent 加入同一 room、一次完整实时语音闭环、学习者/tutor 转写展示、Auto/BG Auto/Manual Voice 切换、BG Auto 后台作用域、默认 Auto 入后台前停止、回前台音波恢复、重连 fallback、History Continue、本地 summary 保存和可选 AI summary 更新。

## 9. Debugging Notes
Known debugging approach:
- If a LiveKit API suggested by AI does not compile, return to official docs and SDK examples.
- If token creation fails, inspect `.env` values, backend logs, and `/session` response shape.
- If Continue from History seems contextless, check that `/session` logs show `resumeContext=true` on iOS and `[profile] resume_context` with `has_context=true` in agent logs.
- If Continue from History shows no old chat bubbles, check the Xcode `[test] Restored history messages count=...` storage log. A count of 1 with a summary-like system message means the older local record did not contain structured messages or transcript text, so the app used the intended summary fallback.
- If leaving a History Continue chat creates a duplicate history item, verify the saved record id. Continued history chats should save with the original local record id even when new learner text or final voice/tutor transcript arrives.
- If reconnect still fails after a fresh room fallback, inspect backend `/session` health, LiveKit token creation, and whether the old disconnect is suppressing auto-reconnect correctly.
- If the iOS app connects but no voice is heard, verify microphone permission, `AVAudioSession`, local track publishing, and agent room membership.
- If the tutor speaks but the transcript panel stays empty, check for `[test] Transcript ...` lines in Xcode; if no delegate events arrive, fall back to LiveKit `lk.transcription` text-stream handling.
- If background audio fails, first confirm the learner selected `BG Auto`. Then verify `UIBackgroundModes=audio`, active Chat scope, microphone publishing before backgrounding, `[test] Scene will resign active`, `[test] Scene entered background`, and whether iOS interrupted the audio session. Default `Auto Voice` is expected to stop foreground-only microphone input before background.
- If AI summary does not update, verify `/summary` API logs, transcript availability, and `SUMMARY_LLM_*` environment settings.
- If voice input fails with a generic audio engine error, use Diagnostics and `[test]` logs to separate microphone permission, `AVAudioSession` route/category/mode, and LiveKit microphone publishing errors.
- Manual `AVAudioSession.setActive(true)` is intentionally avoided before LiveKit publish to reduce WebRTC audio-engine conflicts; LiveKit can activate the session while publishing.
- If the iOS app shows black bars on a physical device, verify `UILaunchStoryboardName=LaunchScreen`, `LaunchScreen.storyboard` resource membership, and reinstall the app after cleaning the old build.
- If the physical iPhone cannot reach backend, keep the Mac backend running with `./start_all.sh`, check macOS firewall, and use `Settings -> Backend URL` first when the app was opened from the Home Screen after installation.
- If the bundled or auto-detected IP is wrong for a new build, rerun `ios/scripts/configure_backend_url.sh` with `IOS_BACKEND_BASE_URL=http://<host>:8000` or `IOS_BACKEND_HOST=<host>`. For an already installed app, use the Settings override instead of rebuilding.
- If Xcode opens but does not run automatically, macOS may have blocked AppleScript UI automation; press `Cmd+R` manually or rerun with the required accessibility permission.
- If AI suggests a broad rewrite, reduce the change back to the P0/P1 scope in `docs/feature-scope.md`.

中文：
已知调试方式：
- 如果 AI 建议的 LiveKit API 无法编译，回到官方文档和 SDK 示例；
- 如果 token 创建失败，检查 `.env`、后端日志和 `/session` 响应结构；
- 如果从 History Continue 后感觉没有上下文，检查 iOS `/session` 日志是否出现 `resumeContext=true`，以及 agent 日志 `[profile] resume_context` 是否显示 `has_context=true`；
- 如果从 History Continue 进入后没有旧聊天气泡，检查 Xcode `[test] Restored history messages count=...` storage 日志。如果 count 是 1 且显示类似 summary 的 system message，说明旧本地记录没有结构化 messages 或 transcript text，App 已按预期使用 summary fallback；
- 如果离开 History Continue 后新增了重复历史记录，检查保存的 record id；历史继续聊天即使出现新 learner text 或 final 语音/tutor 转写，也应该使用原本地 record id 保存；
- 如果 fallback 到新 room 后仍无法重连，检查后端 `/session`、LiveKit token 创建，以及旧断开事件是否正确 suppress auto-reconnect；
- 如果 iOS 已连接但没有语音，检查麦克风权限、`AVAudioSession`、本地 track 发布和 agent 房间成员关系；
- 如果 tutor 已经说话但转写面板为空，先在 Xcode 中检查 `[test] Transcript ...` 日志；如果没有 delegate 事件，再接入 LiveKit `lk.transcription` text-stream fallback；
- 如果后台音频失败，先确认学习者选择了 `BG Auto`；然后检查 `UIBackgroundModes=audio`、进入后台前麦克风是否已发布、是否出现 `[test] Scene entered background`，以及 iOS 是否打断了音频会话。默认 `Auto Voice` 进入后台前停止前台麦克风输入是预期行为；
- 如果 AI 摘要没有更新，检查 `/summary` API 日志、transcript 是否可用，以及 `SUMMARY_LLM_*` 环境变量；
- 如果语音输入只显示笼统的 audio engine error，使用 Diagnostics 和 `[test]` 日志区分麦克风权限、`AVAudioSession` 路由/category/mode 和 LiveKit 麦克风发布问题；
- 在 LiveKit 发布前刻意避免手动调用 `AVAudioSession.setActive(true)`，以减少 WebRTC audio engine 冲突；LiveKit 可在发布麦克风时激活音频会话；
- 如果真机显示上下黑边，检查 `UILaunchStoryboardName=LaunchScreen`、`LaunchScreen.storyboard` 是否在资源中，并清理旧构建后重装 App；
- 如果真机无法访问后端，先确认 Mac 上的 `./start_all.sh` 仍在运行，并检查 macOS 防火墙；如果 App 是安装后从 iPhone 桌面图标打开，优先使用 `Settings -> Backend URL` 修正手机本地后端地址；
- 如果新构建中的 bundled/自动检测 IP 不正确，可以用 `IOS_BACKEND_BASE_URL=http://<host>:8000` 或 `IOS_BACKEND_HOST=<host>` 重新运行 `ios/scripts/configure_backend_url.sh`；如果 App 已安装，则优先用 Settings override，不需要重新构建；
- 如果 Xcode 已打开但没有自动运行，可能是 macOS 阻止了 AppleScript UI 自动化；可手动按 `Cmd+R`，或授予对应辅助功能权限后重试；
- 如果 AI 建议大范围重写，将改动收敛回 `docs/feature-scope.md` 中的 P0/P1 范围。

## 10. Tradeoffs Made With AI Help
- UIKit instead of SwiftUI: chosen for explicit session-state control and native iOS implementation.
- Simple backend instead of complex backend: chosen to focus on realtime voice and mobile UX.
- English-speaking tutor instead of multi-subject tutor: chosen because voice-first learning is easy to evaluate.
- Local JSON/Codable storage instead of Core Data: implemented for first version because only recent summaries and metadata are needed.
- No raw audio persistence: chosen for privacy and scope control.
- LiveKit Swift SDK + SnapKit only for iOS third-party dependencies: chosen to keep the native app small while still replacing mock realtime behavior and improving UIKit layout readability.

中文：
- 选择 UIKit 而不是 SwiftUI：因为它便于显式控制会话状态，并满足原生 iOS 实现。
- 选择简单后端而不是复杂后端：为了聚焦实时语音和移动端体验。
- 选择英语口语而不是多学科：因为语音优先学习更容易评估。
- 第一版已使用本地 JSON/Codable，而不是 Core Data：因为只需要最近总结和元数据。
- 不持久化原始音频：出于隐私和范围控制。
- iOS 第三方库只引入 LiveKit Swift SDK 和 SnapKit：这样既能替换 mock 实时链路，也能提升 UIKit 布局可读性，同时避免依赖膨胀。

## 11. Known Limitations
- LiveKit SDK APIs may vary by version, so integration must be checked against the installed SDK.
- Simulator microphone behavior may differ from a physical device.
- Network latency can affect turn-taking quality.
- `smooth` prioritizes complete, clear tutor speech over the lowest possible response latency.
- Background audio is scoped to explicit `BG Auto` inside the active Chat audio session and does not claim unlimited background execution. Default `Auto Voice` is foreground-only.

中文：
- LiveKit SDK API 可能随版本变化，因此集成必须对照已安装 SDK 检查；
- 模拟器麦克风行为可能与真机不同；
- 网络延迟可能影响轮流对话体验；
- `smooth` 优先保证 tutor 语音完整清晰，而不是最低响应延迟；
- 后台音频能力限定在活跃 Chat 音频会话内的显式 `BG Auto` 模式，不声明无限后台执行；默认 `Auto Voice` 只在前台生效。

## 12. Workflow Update Policy
Update this file when:
- a major phase is completed: backend, UIKit flow, LiveKit SDK integration, agent integration, storage/summary, final validation
- AI tools or model usage meaningfully changes
- a notable debugging lesson is learned
- validation evidence changes
- a major tradeoff changes

Rules:
- Keep entries concise and factual.
- Do not include secrets, API keys, raw private prompts, or long chat transcripts.
- Keep diagnostic logs secret-safe; do not log LiveKit tokens, API secrets, or raw private learner content.
- Mark unverified future work as pending instead of presenting it as done.
- Update related `FEATURE.md` files when the main feature flow changes.

中文：
以下情况需要更新本文档：
- 完成主要阶段：后端、UIKit 流程、LiveKit SDK 集成、agent 集成、存储/总结、最终验证；
- AI 工具或模型使用方式发生重要变化；
- 出现值得记录的调试经验；
- 验证证据发生变化；
- 关键取舍发生变化。

规则：
- 内容保持简洁、真实；
- 不包含密钥、API key、私密原始 prompt 或长聊天记录；
- 诊断日志需要保持 secret-safe，不记录 LiveKit token、API secret 或用户私密原文；
- 未验证的未来工作标记为 pending，不写成已完成；
- 主功能流程变化时，同步更新相关 `FEATURE.md`。

## 13. Final Reflection
AI is used as a productivity multiplier, not as a replacement for engineering judgment.
The goal is to move faster while preserving clear scope, local verification, privacy discipline, and documentation that matches the real project.

中文：
AI 用于提升效率，而不是替代工程判断。
目标是在更快推进的同时，保持清晰范围、本地验证、隐私纪律，以及与真实项目一致的文档。
