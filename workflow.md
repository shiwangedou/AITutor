# AI Workflow

## 1. Overview
This file is a living engineering record for how AI tools are used to build AITutor.
It documents the workflow, verification habits, tool boundaries, and lessons learned while building the backend, UIKit app, LiveKit integration, and required deliverables (`README.md`, `.env.example`, `plan.md`, `workflow.md`).

中文：
本文档是 AITutor 项目中 AI 工具使用方式的动态工程记录。
它记录后端、UIKit App、LiveKit 集成和必交文件（`README.md`、`.env.example`、`plan.md`、`workflow.md`）开发过程中的工作流、验证习惯、工具边界和经验。

## 2. Tools & Models Used
- Codex: repo-aware implementation planning, code scaffolding, refactoring suggestions, and documentation updates.
- ChatGPT / Claude / Cursor (optional): alternative reasoning, code review, and documentation polishing.
- LiveKit official docs: source of truth for LiveKit Agents and client SDK behavior.
- Xcode and build logs: source of truth for iOS compile/runtime behavior.
- Terminal commands: local validation for backend endpoints, Python syntax, file structure, and git status.

中文：
- Codex：用于结合仓库上下文做实现规划、代码骨架、重构建议和文档更新。
- ChatGPT / Claude / Cursor（可选）：用于方案比较、代码审查和文档润色。
- LiveKit 官方文档：作为 LiveKit Agents 和客户端 SDK 行为的事实来源。
- Xcode 与构建日志：作为 iOS 编译和运行行为的事实来源。
- 终端命令：用于验证后端接口、Python 语法、文件结构和 git 状态。

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

中文：
1. 需求分析：用 AI 将题目拆成具体交付物、评分重点和不做范围。
2. 产品计划：用 AI 起草并完善 `plan.md`，同时保持它和产品范围、工程取舍一致。
3. 后端骨架：用 AI 搭建最小 FastAPI 结构，包括健康检查、配置、会话接口和 LiveKit token 下发。
4. UIKit 骨架：用 AI 定义原生 UIKit App 结构，包括会话控制、状态显示、后端客户端、音频管理和 LiveKit 服务边界。
5. LiveKit 集成：用 AI 辅助实现，但最终 API 用法必须对照官方文档和本地编译/运行结果验证。
6. 验证与文档：每次主要行为变化后，用 AI 维护 README、功能文档、workflow 记录和检查清单。

## 5. Concrete AI Usage
- Decomposed the challenge into P0/P1/P2 priorities and explicit non-goals.
- Drafted bilingual `README.md`, `plan.md`, and `workflow.md`.
- Proposed UIKit service boundaries for UI, session orchestration, audio I/O, and backend networking.
- Helped define the English tutor prompt policy: short replies, encouraging correction, one correction focus, one follow-up question.
- Converted risks into validation items, such as token checks, microphone permission checks, and LiveKit room consistency.
- Used AI to compare iOS dependency needs and keep the MVP dependency set limited to LiveKit Swift SDK plus SnapKit.

中文：
- 将题目拆解为 P0/P1/P2 优先级和明确不做范围。
- 起草中英双语 `README.md`、`plan.md` 和 `workflow.md`。
- 为 UIKit 定义 UI、会话编排、音频 I/O 和后端网络的服务边界。
- 协助定义英语家教 prompt 策略：简短回复、鼓励式纠错、一次只纠正一个重点、一次只追问一个问题。
- 将风险转化为验证项，例如 token 检查、麦克风权限检查和 LiveKit 房间一致性。
- 使用 AI 辅助判断 iOS 依赖边界，并将 MVP 第三方库控制在 LiveKit Swift SDK 和 SnapKit。

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
- Backend diagnostics script exists at `backend/tests/diagnose_backend.py`, prints structured logs, masks tokens/secrets, and passes both `--skip-api` and full localhost API checks with dummy env values.
- Backend local startup scripts exist for setup, API server, agent dev mode, and combined startup; root `start_all.sh` is the reviewer-facing entrypoint, clears and writes API/agent logs to `logs/`, waits for API health and agent `registered worker`, and scripts sync Finder-visible `env` to runtime `.env`.
- Root `clear_logs.sh` truncates runtime logs safely, and the iOS Xcode target runs it in Debug builds before app launch so each Cmd+R starts with fresh API/agent logs.
- Root `check_audio_health.sh` summarizes audio-specific agent log evidence such as slow TTS generation, microphone-track presence, and repeated input-speech warnings.
- Root `check_backend.sh` verifies backend diagnostics and checks `logs/agent.log` for `registered worker`.
- iOS project resolves Swift Package dependencies for LiveKit Swift SDK, SnapKit, SwiftProtobuf, LiveKitWebRTC, and LiveKitUniFFI.
- Generic iOS Debug build succeeds with `xcodebuild -project ios/AITutor.xcodeproj -scheme AITutor -configuration Debug -destination 'generic/platform=iOS' build`.
- `LiveKitAgentClient` now uses the real LiveKit Swift SDK `Room` connection and microphone publishing path.
- Tutor speech no longer starts on room join; iOS sends a start-conversation signal only after `Start Session` publishes the microphone.
- iOS listens for LiveKit transcription segments through `RoomDelegate`, merges partial/final updates by segment ID, and displays lightweight `You` / `Tutor` transcript lines in the Session screen.
- Typed fallback messages are displayed immediately as `You` transcript lines so the UI path can be validated even before voice transcription arrives.
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
- Feature scope is documented in `docs/feature-scope.md`.
- Feature documentation policy is documented in `engineering-standards/FEATURE_DOC_POLICY.md`.
- Backend agent code now follows the LiveKit Agents server/session structure with LiveKit Inference STT/LLM/TTS.
- Tutor latency and voice clarity are tunable through `STT_MODEL`, `STT_EOT_TIMEOUT_MS`, `LLM_MODEL`, `LLM_MAX_TOKENS`, `PREEMPTIVE_TTS`, `TTS_MODEL`, `TTS_VOICE`, `TTS_SPEED`, `TTS_VOLUME`, and `TTS_MAX_BUFFER_DELAY_MS`; defaults prioritize short low-latency spoken replies, and agent logs include `[latency]` metrics for per-turn analysis.

Pending verification:
- Physical iPhone install/run from Xcode after the latest MVVM refactor.
- Microphone permission and publishing on a physical iPhone.
- Agent joining the same room as the iOS client.
- One full realtime voice loop with spoken tutor response.
- Real-device transcript display for both learner speech and tutor speech.
- Reconnect and local summary save behavior on device.

中文：
当前已验证：
- Python 后端文件已通过 `python3 -m py_compile backend/*.py` 语法检查；
- 后端依赖可成功安装到 `backend/.venv`；
- LiveKit agent CLI 可加载，并显示 `download-files`、`dev`、`start`、`connect`、`console` 命令；
- LiveKit Silero 和 turn-detector 模型文件可成功下载；
- 本地 smoke test 中，后端 `/health` 返回 `{ "status": "ok" }`；
- 使用 dummy 本地环境变量时，后端 `/session` 返回 `livekit_url`、`token`、`room_name`、`participant_identity` 和 session 元数据；
- 后端诊断脚本已创建在 `backend/tests/diagnose_backend.py`，可输出结构化日志、脱敏 token/secret，并已通过 `--skip-api` 和 dummy env 的完整 localhost API 检查；
- 后端本地启动脚本已创建，覆盖 setup、API server、agent dev mode 和一键联合启动；根目录 `start_all.sh` 是评审入口，会先清理再将 API/agent 日志写入 `logs/`，等待 API health 和 agent `registered worker`，脚本会同步 Finder 可见的 `env` 到运行时 `.env`；
- 根目录 `clear_logs.sh` 会安全清空 runtime logs；iOS Xcode target 在 Debug 构建/运行前会调用它，所以每次 Cmd+R 都从新的 API/agent 日志开始；
- 根目录 `check_audio_health.sh` 会汇总 agent 音频相关日志证据，例如 TTS 生成过慢、麦克风轨道是否出现、输入语音 warning 是否重复；
- 根目录 `check_backend.sh` 会运行后端诊断，并检查 `logs/agent.log` 中是否出现 `registered worker`；
- iOS 工程已能解析 LiveKit Swift SDK、SnapKit、SwiftProtobuf、LiveKitWebRTC 和 LiveKitUniFFI 的 Swift Package 依赖；
- generic iOS Debug 构建已通过：`xcodebuild -project ios/AITutor.xcodeproj -scheme AITutor -configuration Debug -destination 'generic/platform=iOS' build`；
- `LiveKitAgentClient` 已使用真实 LiveKit Swift SDK 的 `Room` 连接和麦克风发布路径；
- tutor 不再在进入房间时自动说话；iOS 会在 `Start Session` 成功发布麦克风后才发送 start-conversation 信号；
- iOS 现在会通过 `RoomDelegate` 监听 LiveKit transcription segments，按 segment ID 合并 partial/final 更新，并在 Session 页面轻量展示 `You` / `Tutor` 转写行；
- 手动输入 fallback 文本也会立即显示为 `You` 转写行，因此即使语音转写尚未到达，也能验证转写 UI 路径；
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
- 功能范围已记录在 `docs/feature-scope.md`；
- 功能文档规范已记录在 `engineering-standards/FEATURE_DOC_POLICY.md`。
- 后端 agent 代码已按 LiveKit Agents server/session 结构接入 LiveKit Inference STT/LLM/TTS；
- tutor 延迟和语音清晰度可通过 `STT_MODEL`、`STT_EOT_TIMEOUT_MS`、`LLM_MODEL`、`LLM_MAX_TOKENS`、`PREEMPTIVE_TTS`、`TTS_MODEL`、`TTS_VOICE`、`TTS_SPEED`、`TTS_VOLUME`、`TTS_MAX_BUFFER_DELAY_MS` 调整；默认优先使用短句、低延迟的口语反馈，agent 日志会输出 `[latency]` 指标用于逐轮分析。

待验证：
- 最新 MVVM 重构后通过 Xcode 真机安装和运行；
- 真机上的麦克风权限和音频发布；
- agent 加入与 iOS 客户端相同的房间；
- 一次带 tutor 语音回应的完整实时语音闭环；
- 真机上用户语音和 tutor 语音的转写显示；
- 真机上的重连和本地总结保存行为。

## 9. Debugging Notes
Known debugging approach:
- If a LiveKit API suggested by AI does not compile, return to official docs and SDK examples.
- If token creation fails, inspect `.env` values, backend logs, and `/session` response shape.
- If the iOS app connects but no voice is heard, verify microphone permission, `AVAudioSession`, local track publishing, and agent room membership.
- If the tutor speaks but the transcript panel stays empty, check for `[test] Transcript ...` lines in Xcode; if no delegate events arrive, fall back to LiveKit `lk.transcription` text-stream handling.
- If Start Session fails with a generic audio engine error, use the in-app diagnostics to separate microphone permission, `AVAudioSession` route/category/mode, and LiveKit microphone publishing errors.
- Manual `AVAudioSession.setActive(true)` is intentionally avoided before LiveKit publish to reduce WebRTC audio-engine conflicts; LiveKit can activate the session while publishing.
- If the iOS app shows black bars on a physical device, verify `UILaunchStoryboardName=LaunchScreen`, `LaunchScreen.storyboard` resource membership, and reinstall the app after cleaning the old build.
- If the physical iPhone cannot reach backend, replace `127.0.0.1` with the Mac LAN IP in `BACKEND_BASE_URL`, keep backend running with `./start_all.sh`, and check macOS firewall.
- If the auto-detected IP is wrong, rerun `ios/scripts/configure_backend_url.sh` with `IOS_BACKEND_BASE_URL=http://<host>:8000` or `IOS_BACKEND_HOST=<host>`.
- If Xcode opens but does not run automatically, macOS may have blocked AppleScript UI automation; press `Cmd+R` manually or rerun with the required accessibility permission.
- If AI suggests a broad rewrite, reduce the change back to the P0/P1 scope in `docs/feature-scope.md`.

中文：
已知调试方式：
- 如果 AI 建议的 LiveKit API 无法编译，回到官方文档和 SDK 示例；
- 如果 token 创建失败，检查 `.env`、后端日志和 `/session` 响应结构；
- 如果 iOS 已连接但没有语音，检查麦克风权限、`AVAudioSession`、本地 track 发布和 agent 房间成员关系；
- 如果 tutor 已经说话但转写面板为空，先在 Xcode 中检查 `[test] Transcript ...` 日志；如果没有 delegate 事件，再接入 LiveKit `lk.transcription` text-stream fallback；
- 如果 Start Session 只显示笼统的 audio engine error，使用 App 内诊断日志区分麦克风权限、`AVAudioSession` 路由/category/mode 和 LiveKit 麦克风发布问题；
- 在 LiveKit 发布前刻意避免手动调用 `AVAudioSession.setActive(true)`，以减少 WebRTC audio engine 冲突；LiveKit 可在发布麦克风时激活音频会话；
- 如果真机显示上下黑边，检查 `UILaunchStoryboardName=LaunchScreen`、`LaunchScreen.storyboard` 是否在资源中，并清理旧构建后重装 App；
- 如果真机无法访问后端，将 `BACKEND_BASE_URL` 从 `127.0.0.1` 改成 Mac 局域网 IP，保持 `./start_all.sh` 运行，并检查 macOS 防火墙；
- 如果自动检测到的 IP 不正确，可以用 `IOS_BACKEND_BASE_URL=http://<host>:8000` 或 `IOS_BACKEND_HOST=<host>` 重新运行 `ios/scripts/configure_backend_url.sh`；
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
- Realtime voice behavior is not fully verified until the latest iOS build is run on a physical iPhone with the backend agent active.
- Current workflow notes should be updated with real debugging results as implementation proceeds.

中文：
- LiveKit SDK API 可能随版本变化，因此集成必须对照已安装 SDK 检查；
- 模拟器麦克风行为可能与真机不同；
- 网络延迟可能影响轮流对话体验；
- 在最新 iOS 构建、真机和后端 agent 同时运行前，实时语音行为尚未完全验证；
- 随着实现推进，当前 workflow 需要补充真实调试结果。

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
