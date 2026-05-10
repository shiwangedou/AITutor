# Product Plan

## 1. Prompt Interpretation
I interpret this challenge as building a reliable, end-to-end realtime voice tutoring experience on mobile, not a feature-heavy learning platform.
The deliverable should prove working software, mobile craft, clean architecture, and clear tradeoff reasoning.

中文：
我将这个题目理解为：交付一个稳定、可端到端运行的移动端实时语音家教体验，而不是做一个功能很多但不稳定的学习平台。
交付重点是可运行软件、移动端体验、清晰架构和明确取舍。

## 2. V1 Product Direction
V1 is an English speaking AI tutor with a complete but intentionally lightweight learning loop:
`Home -> Customize Learning Profile -> AI Chat -> voice/text practice -> back/end session -> local summary -> History review`.
`Words Practice` is included as a focused target-word speaking path that reuses the AI Chat/LiveKit flow, without becoming a full vocabulary curriculum.

中文：
V1 是一个英语口语 AI Tutor，提供完整但不过度的学习链路：
`首页 -> 自定义学习配置 -> AI Chat -> 语音/文字练习 -> 返回/结束会话 -> 本地摘要 -> 历史复盘`。
`Words Practice` 作为聚焦目标词的口语练习路径，复用 AI Chat/LiveKit 链路，但不扩展成完整单词课程体系。

## 3. Tutor Focus: English Speaking Practice
I choose English speaking because realtime voice is the core interaction mode and the learning outcome is easy to observe in a short demo.
The tutor should feel like a focused speaking coach, not a generic chatbot.

中文：
我选择英语口语，因为实时语音正是题目的核心交互方式，而且短时间演示中学习效果更容易观察。
这个 tutor 应该像一个专注的口语教练，而不是普通聊天机器人。

## 4. Target User and Use Cases
Target user:
- English learners who want short, low-friction speaking practice.

Primary use cases:
1. Daily conversation warm-up.
2. Interview English rehearsal.
3. Travel English role play.
4. Pronunciation and clarity practice.
5. Review the session transcript and summary after practice.

中文：
目标用户：
- 希望低门槛、短时间练习英语口语的学习者。

核心场景：
1. 日常对话热身；
2. 面试英语演练；
3. 旅行英语角色扮演；
4. 发音和表达清晰度练习；
5. 练习后查看 transcript 和 summary 复盘。

## 5. Learning Profile
V1 supports a lightweight learning profile that affects the backend agent prompt, not only UI labels.

Supported fields:
- Learning mode: `Daily Conversation`, `Interview English`, `Travel English`, `Pronunciation Practice`
- Tutor style: `Gentle Coach`, `Direct Coach`, `Challenge Coach`
- Difficulty: `Beginner`, `Intermediate`, `Advanced`
- Custom goal: limited-length session goal, such as `I want to practice ordering coffee.`

Default profile:
- `Daily Conversation`
- `Gentle Coach`
- `Intermediate`
- no custom goal

中文：
V1 支持轻量学习配置，并且该配置会真正影响后端 agent prompt，而不只是 UI 展示。

支持字段：
- 学习模式：`Daily Conversation`、`Interview English`、`Travel English`、`Pronunciation Practice`
- Tutor 风格：`Gentle Coach`、`Direct Coach`、`Challenge Coach`
- 难度：`Beginner`、`Intermediate`、`Advanced`
- 自定义目标：限制长度的本次会话目标，例如 `I want to practice ordering coffee.`

默认配置：
- `Daily Conversation`
- `Gentle Coach`
- `Intermediate`
- 无自定义目标

## 6. Tutor Behavior Principles
The tutor should:
1. Use short, spoken-friendly replies.
2. Give encouraging correction before pointing out mistakes.
3. Focus on one major correction per turn.
4. Ask one follow-up question at the end of each turn.
5. Adapt difficulty based on the selected profile and learner response.
6. For a fresh empty chat, give one short warm-up opener after connection; for History Continue or resume-context reconnects, stay quiet until the learner speaks or sends text.

中文：
Tutor 应遵循：
1. 使用简短、适合口语交流的回复；
2. 先鼓励，再纠错；
3. 每轮只聚焦一个主要纠错点；
4. 每轮最后只问一个追问；
5. 根据学习配置和学习者回答动态调整难度；
6. 全新空聊天连接后先给一句简短 warm-up；History Continue 或带 resume context 的重连会保持安静，直到学习者说话或发送文字。

## 7. First Session Flow
1. Learner opens the app and lands on Home.
2. Learner reviews or customizes the learning profile.
3. Learner opens `AI Chat`.
4. App automatically creates a backend `/session` and connects to the LiveKit room.
5. For a fresh empty chat, tutor gives one short warm-up opener; for History Continue, tutor waits quietly.
6. Learner taps the microphone to enter voice input, sees waveform feedback, taps send to finish, or sends text.
7. If no speech was captured, voice mode exits without creating an empty message; otherwise the app shows `Listening`, `Tutor Thinking`, and `Tutor Speaking` states.
8. Transcript/chat messages appear as `You`, `Tutor`, and `System` rows.
9. Learner ends the session.
10. App saves local transcript text, metadata, and fallback summary immediately.
11. AI summary can update asynchronously when available.
12. Learner reviews the session in History.
13. Learner can continue from History with the same learning profile plus short previous-session context.

中文：
1. 学习者打开 App，进入首页；
2. 查看或修改学习配置；
3. 进入 `AI Chat`；
4. App 自动创建后端 `/session` 并连接 LiveKit 房间；
5. 全新空聊天连接后 tutor 给一句简短 warm-up；History Continue 会安静等待学习者继续；
6. 学习者点击麦克风进入语音输入，看到音波反馈，说完点击发送，或直接发送文字；
7. 如果没有捕获到语音，则只退出语音模式，不创建空消息；否则 App 展示 `Listening`、`Tutor Thinking`、`Tutor Speaking` 状态；
8. 聊天/转写列表展示 `You`、`Tutor`、`System` 消息；
9. 学习者结束会话；
10. App 立即保存本地 transcript 文本、元数据和 fallback summary；
11. AI summary 可用时异步更新；
12. 学习者在 History 中复盘；
13. 学习者可以从 History 用相同学习配置和上一轮短上下文继续学习。

## 8. Mobile UX Principles
The mobile app should prioritize:
1. A clear Home that explains what to do next.
2. Large, thumb-friendly voice and session controls.
3. Visible connection, audio, and tutor states.
4. Text fallback so the demo can continue if microphone behavior fails.
5. A chat-style transcript because learners expect conversation history.
6. Recoverable errors with `Reconnect` and clear state labels.
7. Reconnect fallback to a new room when the current room/token cannot recover.
8. Separate Diagnostics so debug information does not clutter the learning screen.
9. No complex app-side setup; backend URL and voice profile remain script/env driven.

中文：
移动端体验应优先保证：
1. 首页清楚告诉用户下一步做什么；
2. 大且适合拇指操作的语音和会话按钮；
3. 明确显示连接、音频和 tutor 状态；
4. 保留文字 fallback，麦克风异常时 demo 仍可继续；
5. 使用聊天列表，因为学习者天然预期能看到对话历史；
6. 通过 `Reconnect` 和清晰状态文案恢复错误；
7. 当前 room/token 无法恢复时，可 fallback 到新 room；
8. 将 Diagnostics 独立出来，避免调试信息污染学习页；
9. App 内不做复杂配置，后端 URL 和语音 profile 仍由脚本/env 控制。

## 9. V1 Must-Have Scope
1. Home with product positioning, AI Chat entry, focused Words Practice entry, profile card, latest summary, History, Diagnostics, and Settings.
2. Learning profile editor with mode/style/difficulty/custom goal.
3. AI Chat that auto-connects, opens fresh empty chats with one short tutor warm-up, and keeps resume-context chats quiet.
4. Tap-to-record microphone input with waveform feedback, explicit cancel, send-to-finish, and text fallback.
5. Chat-style message list with user/tutor/system messages and message statuses.
6. Specific session states and failure states.
7. Reconnect and back/end-session actions.
8. Local JSON/Codable storage for latest 20 session records.
9. Local transcript text and summary storage, no raw audio persistence.
10. Incremental/final AI summary paths as optional enhancement over local fallback.
11. History review, simplified detail page, and continue-with-context entry.
12. Diagnostics and Settings pages with secret-safe information.
13. Complete README, plan, workflow, todo, runbook, and feature docs.

中文：
V1 必须范围：
1. 首页包含产品定位、AI Chat 入口、聚焦版 Words Practice 入口、学习配置卡片、最近摘要、History、Diagnostics、Settings；
2. 学习配置编辑：模式、风格、难度、自定义目标；
3. AI Chat 自动连接；全新空聊天会有一句简短 tutor warm-up，带 resume context 的聊天会保持安静；
4. 点击式语音输入、音波反馈、显式取消、发送结束和文字 fallback；
5. 常规聊天列表，包含 user/tutor/system 消息和消息状态；
6. 具体会话状态和失败状态；
7. Reconnect 和返回/结束会话；
8. 本地 JSON/Codable 保存最近 20 条 session；
9. 保存 transcript 文本和 summary，不保存 raw audio；
10. 增量/最终 AI summary 作为本地 fallback 之上的增强；
11. History 复盘、简化详情页和带上下文继续学习入口；
12. Diagnostics 和 Settings 页面展示脱敏信息；
13. README、plan、workflow、todo、runbook 和 feature docs 完整。

## 10. Not In V1
V1 intentionally does not include:
- login
- cloud sync
- full vocabulary curriculum
- full curriculum system
- long-term learning plans
- complex learning reports
- payment or membership
- multi-language localization
- raw audio storage
- admin dashboard
- full CI, unless the core demo is already stable

中文：
V1 明确不做：
- 登录；
- 云同步；
- 完整单词课程体系；
- 完整课程体系；
- 长期学习计划；
- 复杂学习报告；
- 支付或会员；
- 多语言本地化；
- 原始音频存储；
- 后台管理；
- 完整 CI，除非核心 demo 已稳定。

## 11. Architecture Direction
- iOS App layer: app startup, config, dependency assembly.
- Core layer: logging, errors, date formatting, common utilities.
- Network layer: backend HTTP client and DTOs.
- Agent layer: LiveKit room/client abstraction and audio session management.
- Feature layer: Home, profile editing, AI Chat, History, Diagnostics, Settings.
- Business logic: `SessionViewModel` owns session orchestration, transcript, summary, reconnect, and local persistence.
- Backend: FastAPI `/health`, `/config`, `/session`, `/summary`, `/summary/incremental`.
- Agent: LiveKit Agents + LiveKit Inference STT/LLM/TTS.

中文：
架构方向：
- iOS App 层：启动、配置、依赖组装；
- Core 层：日志、错误、日期格式和通用工具；
- Network 层：后端 HTTP client 和 DTO；
- Agent 层：LiveKit room/client 抽象和音频会话管理；
- Feature 层：首页、学习配置、AI Chat、History、Diagnostics、Settings；
- 业务逻辑：`SessionViewModel` 负责会话编排、转写、摘要、重连和本地持久化；
- 后端：FastAPI `/health`、`/config`、`/session`、`/summary`、`/summary/incremental`；
- Agent：LiveKit Agents + LiveKit Inference STT/LLM/TTS。

## 12. Privacy and Local Data Policy
1. Raw audio is not persisted.
2. Local storage keeps text transcript, summaries, and metadata only.
3. The app keeps the latest 20 sessions by default.
4. `Clear History` removes local records.
5. Summary generation uses transcript text, not raw audio.
6. Continue from History sends only short text context: previous summary, optional AI summary, and a limited transcript excerpt.
7. Tokens, API keys, and API secrets must never appear in UI, logs, or committed docs.
8. Runtime secrets/config come from ignored root `.env`; committed `env` / `env.example` / `.env.example` files are placeholder templates only.

中文：
1. 不持久化原始音频；
2. 本地只保存文本 transcript、summary 和元数据；
3. 默认只保留最近 20 次会话；
4. `Clear History` 可删除本地记录；
5. 摘要生成只使用 transcript 文本，不使用 raw audio；
6. 从 History 继续时，只发送短文本上下文：上一轮 summary、可选 AI summary 和有限 transcript 摘录；
7. token、API key、API secret 不能出现在 UI、日志或提交文档中；
8. 运行时密钥/配置来自被 git 忽略的根目录 `.env`；已提交的 `env`、`env.example`、`.env.example` 只作为 placeholder 模板。

## 13. Key Tradeoffs
- Prioritize stable demo flow over feature breadth.
- Default `VOICE_PIPELINE_PROFILE=smooth` prioritizes clear, complete tutor speech over fastest response time.
- Keep backend simple and focus product effort on the iOS learning loop.
- Use UIKit + SnapKit to keep native iOS control explicit and layout readable.
- Use local JSON/Codable instead of Core Data because V1 only needs recent sessions.
- Keep Words Practice focused on target-word speaking sessions to show product direction without diluting the AI Chat implementation.
- Keep Diagnostics separate from Chat to preserve learner focus while still supporting debugging.

中文：
关键取舍：
- 稳定 demo 链路优先于功能数量；
- 默认 `VOICE_PIPELINE_PROFILE=smooth` 优先保证 tutor 语音清楚完整，而不是最快响应；
- 后端保持简单，把产品精力放在 iOS 学习闭环；
- 使用 UIKit + SnapKit，让原生 iOS 控制清晰、布局可读；
- 使用本地 JSON/Codable 而不是 Core Data，因为 V1 只需要最近会话；
- Words Practice 聚焦目标词口语会话，用来展示产品方向，但不稀释 AI Chat 主链路；
- Diagnostics 独立于 Chat，既保证学习页聚焦，也方便排障。

## 14. Risks and Mitigations
1. LiveKit SDK version differences
- Mitigation: keep SDK calls isolated in Agent/Network boundaries and verify with local build.

2. Microphone permission or simulator behavior
- Mitigation: request permission explicitly and validate on a physical iPhone.

3. Token or `.env` configuration mistakes
- Mitigation: provide templates, `/health`, `check_backend.sh`, and masked diagnostics.

4. Agent not joining the same room
- Mitigation: backend stores the learning profile by room and iOS/agent use the same backend-issued room name.

5. Speech latency or choppy TTS
- Mitigation: default to `smooth`, keep replies short, and use `check_audio_health.sh` for evidence.

6. Transcript availability varies by SDK/runtime behavior
- Mitigation: keep text fallback and support both LiveKit delegate transcription and `lk.transcription` data-message fallback.

7. Async summary writes can become stale
- Mitigation: guard summary writes by session/generation ID.

8. Current LiveKit room cannot recover
- Mitigation: try current-room reconnect first, then request a fresh `/session` while keeping visible local chat messages.

中文：
1. LiveKit SDK 版本差异
- 缓解：SDK 调用隔离在 Agent/Network 边界，并通过本地构建验证。

2. 麦克风权限或模拟器行为差异
- 缓解：显式请求权限，并在真机验证。

3. token 或 `.env` 配置错误
- 缓解：提供模板、`/health`、`check_backend.sh` 和脱敏诊断。

4. agent 没有加入同一房间
- 缓解：后端按 room 保存学习配置，iOS 和 agent 使用同一个后端下发 room name。

5. 语音延迟或 TTS 卡顿
- 缓解：默认使用 `smooth`，控制回复长度，并用 `check_audio_health.sh` 收集证据。

6. transcript 可用性受 SDK/runtime 影响
- 缓解：保留文字 fallback，同时支持 LiveKit delegate transcription 与 `lk.transcription` data-message fallback。

7. 异步 summary 可能写回旧 session
- 缓解：用 session/generation ID 保护摘要写入。

8. 当前 LiveKit room 无法恢复
- 缓解：先尝试重连当前 room，失败后请求新的 `/session`，同时保留页面上已有的本地聊天消息。

## 15. Validation / Definition of Done
1. A fresh clone can follow `README.md` to configure env and run `./start_all.sh`.
2. Backend API and agent show ready signals.
3. iOS Debug build succeeds.
4. iOS unit tests pass.
5. Home, Customize, AI Chat, History, Diagnostics, and Settings are reachable.
6. Learning profile is sent to `/session`, returned normalized, saved locally, and used by agent prompt.
7. AI Chat auto-connects; fresh empty chats get one short tutor opener, while History Continue waits for learner input.
8. One full voice loop works on a physical iPhone.
9. Text fallback works when voice is unavailable.
10. Back navigation or End Session disconnects, releases audio, saves transcript text and local summary.
11. History can show saved session review.
12. History Continue can start a new room with short previous-session context.
13. No raw audio, token, API key, or API secret is stored or logged.
14. Required deliverables exist: `README.md`, `.env.example`, `plan.md`, and `workflow.md`.

中文：
验收标准：
1. 全新克隆后可按 `README.md` 配置 env 并运行 `./start_all.sh`；
2. 后端 API 和 agent 输出 ready 信号；
3. iOS Debug build 成功；
4. iOS 单元测试通过；
5. Home、Customize、AI Chat、History、Diagnostics、Settings 可进入；
6. 学习配置会发送到 `/session`，后端标准化返回，本地保存，并用于 agent prompt；
7. AI Chat 自动连接；全新空聊天会有一句简短 tutor 开场，History Continue 会等待学习者输入；
8. 真机完成一次完整语音闭环；
9. 语音不可用时文字 fallback 可用；
10. 返回离开 Chat 或 End Session 会断开连接、释放音频、保存 transcript 文本和本地摘要；
11. History 可查看保存的会话复盘；
12. History Continue 可以用上一轮短上下文开启新 room；
13. 不保存或输出 raw audio、token、API key、API secret；
14. 必交文件完整：`README.md`、`.env.example`、`plan.md`、`workflow.md`。
