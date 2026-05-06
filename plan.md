# Product Plan

## 1. Prompt Interpretation
I interpret this challenge as building a reliable, end-to-end realtime voice tutoring experience on mobile, not a feature-heavy app.
The core is a simple backend for LiveKit session orchestration, a LiveKit voice agent for tutoring behavior, and a native UIKit iOS app for natural voice interaction.

中文：
我将这个题目理解为：交付一个稳定、可端到端运行的移动端实时语音家教体验，而不是功能堆砌的应用。
核心是：简单后端负责 LiveKit 会话编排，LiveKit 语音 agent 负责教学行为，UIKit 原生 iOS 负责自然语音交互。

## 2. Tutor Focus: English Speaking Practice
I choose English speaking as the tutoring domain because:
- Voice is the primary interaction mode.
- Learning outcomes are easy to observe in a short demo.
- A conversational loop (prompt -> response -> feedback) fits realtime tutoring well.

中文：
我选择英语口语作为教学方向，因为：
- 语音是主要交互方式；
- 短时间演示中学习效果更容易观察；
- “提问-回答-反馈”的闭环非常适合实时家教。

## 3. Product Goal
Deliver a mobile tutor that helps learners practice spoken English through short, adaptive voice conversations.
The experience should feel closer to a focused speaking coach than a general chatbot.

中文：
交付一个通过短回合、自适应语音对话来帮助用户练习英语口语的移动端家教。
体验上应更像一个专注的口语教练，而不是普通聊天机器人。

## 4. Target User and Use Cases
Target user:
- Intermediate learners who want daily speaking practice.

Primary use cases:
1. Quick speaking warm-up (3-5 minutes).
2. Topic-based conversation practice.
3. Pronunciation and clarity feedback at session end.

中文：
目标用户：
- 需要日常练习口语的中级学习者。

核心场景：
1. 3-5 分钟快速开口热身；
2. 主题对话练习；
3. 会话结束后给出发音和表达清晰度反馈。

## 5. Tutor Experience Principles
The tutor should:
1. Use short, spoken-friendly replies.
2. Give encouraging correction before pointing out mistakes.
3. Focus on one major correction per turn.
4. Ask one follow-up question at the end of each turn.
5. Adapt difficulty based on learner response length and confidence.

中文：
家教应遵循：
1. 使用简短、适合口语交流的回复；
2. 先鼓励，再纠错；
3. 每轮只聚焦一个主要纠错点；
4. 每轮最后只问一个追问；
5. 根据学习者回答长度和自信程度调整难度。

## 6. First Session Flow
1. Learner opens the app.
2. Learner taps `Connect`.
3. App requests a LiveKit session from the backend.
4. Learner taps `Start Session`.
5. Tutor greets the learner and asks a warm-up question.
6. Learner answers by voice.
7. Tutor gives quick feedback and asks one follow-up question.
8. Learner taps `End Session`.
9. A summary is generated or saved when that feature is available.

中文：
1. 学习者打开 App；
2. 点击 `Connect`；
3. App 向后端请求 LiveKit 会话；
4. 点击 `Start Session`；
5. 家教问候并提出热身问题；
6. 学习者用语音回答；
7. 家教给出快速反馈并追问一个问题；
8. 学习者点击 `End Session`；
9. 当会后总结功能可用时，生成或保存总结。

## 7. Mobile UX Principles
The mobile app should prioritize:
1. Large, clear session controls.
2. Visible connection, audio, and session states.
3. Lightweight transcript or event logging for observability.
4. Recoverable errors with clear next actions.
5. No complex setup inside the app.

中文：
移动端体验应优先保证：
1. 清晰的大按钮会话控制；
2. 连接、音频和会话状态可见；
3. 轻量转写或事件日志，便于观察演示；
4. 错误可恢复，并给出明确下一步；
5. App 内不放复杂配置流程。

## 8. MVP Scope (Must-Have First)
1. Realtime voice session works end-to-end.
2. Clear UIKit session controls: `Connect`, `Start Session`, `End Session`.
3. Visible session states and basic error handling.
4. Backend token/session API with `.env`-based config only.
5. Reproducible setup/run docs.

中文：
MVP（必须先完成）：
1. 端到端实时语音可用；
2. UIKit 会话控制清晰：`Connect`、`Start Session`、`End Session`；
3. 状态可见并有基础错误处理；
4. 后端通过 `.env` 配置并提供 token/session 接口；
5. 文档可复现运行。

## 9. Bonus Scope (After MVP is Stable)
1. Reconnect and session recovery on network drop.
2. Post-session summary with actionable speaking tips.
3. Basic background/foreground transition resilience.

中文：
加分项（在 MVP 稳定后）：
1. 断线重连和会话恢复；
2. 会后总结与可执行口语建议；
3. 前后台切换的基础恢复能力。

## 10. Architecture Direction
- iOS (UIKit): UI state, user actions, microphone permission, audio session, LiveKit room connection, and local session state.
- Backend (FastAPI): health/config/session endpoints and LiveKit token issuance.
- Agent: English tutor prompt, realtime teaching behavior, and spoken response strategy.
- Config/Security: all secrets and runtime config load from root `.env`; no hardcoded keys.

中文：
- iOS（UIKit）：负责界面状态、用户交互、麦克风权限、音频会话、LiveKit 房间连接和本地会话状态；
- 后端（FastAPI）：负责健康检查、配置下发、会话创建和 LiveKit token 生成；
- Agent：负责英语家教 prompt、实时教学行为和语音响应策略；
- 配置/安全：所有密钥和运行配置都从根目录 `.env` 读取，禁止硬编码。

## 11. Privacy and Local Data Policy
1. Raw audio will not be persisted.
2. Local storage should keep only session metadata and summaries.
3. The default history limit is the latest 20 sessions.
4. A clear-history action can be added after summary storage exists.
5. Secrets and configuration must come from `.env`.

中文：
1. 不持久化原始音频；
2. 本地只保存会话元数据和总结；
3. 默认只保留最近 20 次会话；
4. 会话总结存储完成后，可增加清空历史入口；
5. 密钥和配置必须来自 `.env`。

## 12. Non-Goals
1. User registration or login.
2. Cloud database or cloud sync.
3. Full curriculum or lesson system.
4. Custom STT/TTS/LLM pipeline.
5. Raw audio storage.

中文：
明确不做：
1. 用户注册或登录；
2. 云数据库或云同步；
3. 完整课程或课程库系统；
4. 自研 STT/TTS/LLM 管线；
5. 原始音频存储。

## 13. Key Tradeoffs
- Prioritize reliability over feature breadth.
- Keep backend intentionally simple to focus effort on mobile voice UX.
- Use UIKit for explicit session-state control and a native iOS implementation.
- Start with single-subject tutoring before multi-mode expansion.
- Prefer lightweight local JSON/Codable storage over Core Data for the first version.

中文：
关键取舍：
- 稳定性优先于功能广度；
- 后端刻意保持简洁，把精力放在移动端语音体验；
- 使用 UIKit，便于显式控制会话状态，并满足原生 iOS 实现；
- 先单主题家教，后续再扩展多模式；
- 第一版优先使用轻量 JSON/Codable 本地存储，而不是 Core Data。

## 14. Risks and Mitigations
1. LiveKit SDK version differences
- Mitigation: keep LiveKit integration isolated in `LiveKitService`.

2. Microphone permission or simulator behavior
- Mitigation: show user-facing permission errors and verify on a real device when possible.

3. Token or `.env` configuration mistakes
- Mitigation: provide `.env.example`, backend `/health`, and clear backend error messages.

4. Agent not joining the same room
- Mitigation: use backend-issued room names consistently across client and agent.

5. Speech latency impacting UX
- Mitigation: keep tutor responses short and show visible connection/listening state.

中文：
1. LiveKit SDK 版本差异
- 缓解：将 LiveKit 集成隔离在 `LiveKitService` 中。

2. 麦克风权限或模拟器行为差异
- 缓解：展示用户可理解的权限错误，并尽量在真机验证。

3. token 或 `.env` 配置错误
- 缓解：提供 `.env.example`、后端 `/health` 和清晰的后端错误信息。

4. agent 未加入同一房间
- 缓解：客户端和 agent 统一使用后端下发的 room name。

5. 语音延迟影响体验
- 缓解：保持 tutor 回复简短，并显示明确的连接/收听状态。

## 15. Validation / Definition of Done
1. A fresh clone can follow `README.md` to run the backend.
2. The iOS app builds and runs.
3. User can complete one full voice loop: connect, speak, receive tutor response, end session.
4. `End Session` disconnects and cleans audio resources.
5. Required deliverables exist: `README.md`, `.env.example`, `plan.md`, and `workflow.md`.
6. No secrets or API keys are hardcoded or committed.

中文：
验收标准：
1. 全新克隆后可按 `README.md` 跑起后端；
2. iOS App 可构建并运行；
3. 用户可完成一次完整语音闭环：连接、说话、收到家教回应、结束会话；
4. `End Session` 能断开连接并清理音频资源；
5. 必交文件完整：`README.md`、`.env.example`、`plan.md`、`workflow.md`；
6. 没有硬编码或提交任何密钥/API key。
