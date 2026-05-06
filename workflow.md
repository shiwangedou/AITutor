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

中文：
- 将题目拆解为 P0/P1/P2 优先级和明确不做范围。
- 起草中英双语 `README.md`、`plan.md` 和 `workflow.md`。
- 为 UIKit 定义 UI、会话编排、音频 I/O 和后端网络的服务边界。
- 协助定义英语家教 prompt 策略：简短回复、鼓励式纠错、一次只纠正一个重点、一次只追问一个问题。
- 将风险转化为验证项，例如 token 检查、麦克风权限检查和 LiveKit 房间一致性。

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
- Backend local startup scripts exist for setup, API server, agent dev mode, and combined startup; root `start_all.sh` is the reviewer-facing entrypoint, writes API/agent logs to `logs/`, waits for API health and agent `registered worker`, and scripts sync Finder-visible `env` to runtime `.env`.
- Root `check_backend.sh` verifies backend diagnostics and checks `logs/agent.log` for `registered worker`.
- Required planning/docs structure exists: `README.md`, `.env.example`, `plan.md`, `workflow.md`.
- Feature scope is documented in `docs/feature-scope.md`.
- Feature documentation policy is documented in `engineering-standards/FEATURE_DOC_POLICY.md`.
- Backend agent code now follows the LiveKit Agents server/session structure with LiveKit Inference STT/LLM/TTS.

Pending verification:
- Agent dev-mode connection with real LiveKit Cloud credentials.
- Real LiveKit iOS SDK connection.
- Microphone permission and publishing on iOS.
- Agent joining the same room as the iOS client.
- One full realtime voice loop.

中文：
当前已验证：
- Python 后端文件已通过 `python3 -m py_compile backend/*.py` 语法检查；
- 后端依赖可成功安装到 `backend/.venv`；
- LiveKit agent CLI 可加载，并显示 `download-files`、`dev`、`start`、`connect`、`console` 命令；
- LiveKit Silero 和 turn-detector 模型文件可成功下载；
- 本地 smoke test 中，后端 `/health` 返回 `{ "status": "ok" }`；
- 使用 dummy 本地环境变量时，后端 `/session` 返回 `livekit_url`、`token`、`room_name`、`participant_identity` 和 session 元数据；
- 后端诊断脚本已创建在 `backend/tests/diagnose_backend.py`，可输出结构化日志、脱敏 token/secret，并已通过 `--skip-api` 和 dummy env 的完整 localhost API 检查；
- 后端本地启动脚本已创建，覆盖 setup、API server、agent dev mode 和一键联合启动；根目录 `start_all.sh` 是评审入口，会将 API/agent 日志写入 `logs/`，等待 API health 和 agent `registered worker`，脚本会同步 Finder 可见的 `env` 到运行时 `.env`；
- 根目录 `check_backend.sh` 会运行后端诊断，并检查 `logs/agent.log` 中是否出现 `registered worker`；
- 必要规划/文档结构存在：`README.md`、`.env.example`、`plan.md`、`workflow.md`；
- 功能范围已记录在 `docs/feature-scope.md`；
- 功能文档规范已记录在 `engineering-standards/FEATURE_DOC_POLICY.md`。
- 后端 agent 代码已按 LiveKit Agents server/session 结构接入 LiveKit Inference STT/LLM/TTS。

待验证：
- 使用真实 LiveKit Cloud 凭证的 agent dev 模式连接；
- 真实 LiveKit iOS SDK 连接；
- iOS 麦克风权限和音频发布；
- agent 加入与 iOS 客户端相同的房间；
- 一次完整实时语音闭环。

## 9. Debugging Notes
Known debugging approach:
- If a LiveKit API suggested by AI does not compile, return to official docs and SDK examples.
- If token creation fails, inspect `.env` values, backend logs, and `/session` response shape.
- If the iOS app connects but no voice is heard, verify microphone permission, `AVAudioSession`, local track publishing, and agent room membership.
- If AI suggests a broad rewrite, reduce the change back to the P0/P1 scope in `docs/feature-scope.md`.

中文：
已知调试方式：
- 如果 AI 建议的 LiveKit API 无法编译，回到官方文档和 SDK 示例；
- 如果 token 创建失败，检查 `.env`、后端日志和 `/session` 响应结构；
- 如果 iOS 已连接但没有语音，检查麦克风权限、`AVAudioSession`、本地 track 发布和 agent 房间成员关系；
- 如果 AI 建议大范围重写，将改动收敛回 `docs/feature-scope.md` 中的 P0/P1 范围。

## 10. Tradeoffs Made With AI Help
- UIKit instead of SwiftUI: chosen for explicit session-state control and native iOS implementation.
- Simple backend instead of complex backend: chosen to focus on realtime voice and mobile UX.
- English-speaking tutor instead of multi-subject tutor: chosen because voice-first learning is easy to evaluate.
- Local JSON/Codable storage instead of Core Data: planned for first version because only recent summaries and metadata are needed.
- No raw audio persistence: chosen for privacy and scope control.

中文：
- 选择 UIKit 而不是 SwiftUI：因为它便于显式控制会话状态，并满足原生 iOS 实现。
- 选择简单后端而不是复杂后端：为了聚焦实时语音和移动端体验。
- 选择英语口语而不是多学科：因为语音优先学习更容易评估。
- 第一版计划使用本地 JSON/Codable，而不是 Core Data：因为只需要最近总结和元数据。
- 不持久化原始音频：出于隐私和范围控制。

## 11. Known Limitations
- LiveKit SDK APIs may vary by version, so integration must be checked against the installed SDK.
- Simulator microphone behavior may differ from a physical device.
- Network latency can affect turn-taking quality.
- Realtime voice behavior is not fully verified until the real SDK and agent path are wired.
- Current workflow notes should be updated with real debugging results as implementation proceeds.

中文：
- LiveKit SDK API 可能随版本变化，因此集成必须对照已安装 SDK 检查；
- 模拟器麦克风行为可能与真机不同；
- 网络延迟可能影响轮流对话体验；
- 在真实 SDK 和 agent 链路接通前，实时语音行为尚未完全验证；
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
- 未验证的未来工作标记为 pending，不写成已完成；
- 主功能流程变化时，同步更新相关 `FEATURE.md`。

## 13. Final Reflection
AI is used as a productivity multiplier, not as a replacement for engineering judgment.
The goal is to move faster while preserving clear scope, local verification, privacy discipline, and documentation that matches the real project.

中文：
AI 用于提升效率，而不是替代工程判断。
目标是在更快推进的同时，保持清晰范围、本地验证、隐私纪律，以及与真实项目一致的文档。
