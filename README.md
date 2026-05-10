# AITutor (UIKit + LiveKit)

A minimal real-time voice AI tutor with a simple Python backend and a native iOS frontend built with UIKit.

中文：这是一个最小可运行的实时语音 AI 家教项目，包含 Python 后端和 UIKit 原生 iOS 前端。

## 1. What This Project Includes

- Backend (`FastAPI`) for health check and LiveKit session token issuance.
- iOS app (`UIKit` + `SnapKit`) with Home, Learning Profile, AI Chat, History, Diagnostics, Settings, and MVVM session flow.
- LiveKit Swift SDK room connection and microphone publishing.
- Learning profile controls for mode, tutor style, difficulty, and custom goal.
- Lightweight local JSON/Codable transcript and summaries for the latest 20 sessions.
- Environment-driven config (`.env`), no hardcoded secrets.

中文：
- 后端（FastAPI）：健康检查与 LiveKit 会话令牌下发。
- iOS（UIKit + SnapKit）：包含首页、学习配置、AI Chat、History、Diagnostics、Settings 和 MVVM 会话主流程。
- 使用 LiveKit Swift SDK 连接房间并发布麦克风。
- 支持学习模式、tutor 风格、难度和自定义目标。
- 使用轻量 JSON/Codable 本地保存最近 20 条转写和会话总结。
- 所有配置走 `.env`，不硬编码密钥。

## Reviewer Quick Start

Fast path: copy `env.example` to `env`, fill LiveKit keys, run `./start_all.sh`, then run the iOS app from Xcode.

1. Copy `env.example` to `env` and fill LiveKit values.
2. From project root, run `./start_all.sh`.
3. Wait for `Backend API ready`, `Agent registered worker`, and `All backend services ready`.
4. Run the iOS app on a physical iPhone from Xcode.
5. On Home, optionally customize the learning profile.
6. Open `AI Chat`; it connects automatically and, for a fresh empty chat, the tutor gives one short warm-up opener.
7. Tap the mic to enter voice input, speak, then tap send; or send text to continue tutoring.
8. End the session, then review the saved summary in History.

中文：
一句话：复制 `env.example` 为 `env`，填写 LiveKit keys，运行 `./start_all.sh`，然后用 Xcode 运行 iOS App。

1. 复制 `env.example` 为 `env` 并填写 LiveKit 配置；
2. 在项目根目录运行 `./start_all.sh`；
3. 等待 `Backend API ready`、`Agent registered worker`、`All backend services ready`；
4. 用 Xcode 在真机运行 iOS App；
5. 在首页可选择修改学习配置；
6. 进入 `AI Chat`，页面会自动连接；如果是全新空聊天，tutor 会先说一句简短 warm-up；
7. 点击麦克风进入语音输入，说完后点击发送；也可以发送文字继续练习；
8. 结束会话后，在 History 查看保存的 summary。

## V1 Product Flow

- Home: product tagline, learning profile card, AI Chat, Words Practice, Custom Goal, latest summary, History, Diagnostics, Settings.
- Learning Profile: `Daily Conversation`, `Interview English`, `Travel English`, `Pronunciation Practice`; `Gentle`, `Direct`, or `Challenge` coach; difficulty; optional custom goal.
- AI Chat: auto-connects, gives one short warm-up opener for fresh empty chats, stays quiet for History Continue, supports tap-to-record voice with waveform feedback and text fallback, shows chat messages and states.
- Review: saves local transcript text and summary, then History shows recent session details.
- Continue: History can start a new room with the same profile plus short previous-session context. It keeps the original local chat id, restores saved messages when available, falls back to transcript/summary for older records, and updates the same History item when the learner continues.
- Words Practice: starts focused LiveKit-backed target-word speaking sessions without expanding V1 into a full vocabulary system.
- Diagnostics/Settings: keep debug and configuration information away from the main learning screen.

中文：
- 首页：产品定位、学习配置卡片、AI Chat、Words Practice、Custom Goal、最近摘要、History、Diagnostics、Settings；
- 学习配置：日常对话、面试英语、旅行英语、发音练习；温和/直接/挑战型 coach；难度；可选自定义目标；
- AI Chat：自动连接；全新空聊天会由 tutor 简短开场，History Continue 会保持安静等待继续；支持点击式语音输入、音波反馈和文字 fallback，展示聊天消息和状态；
- 复盘：保存本地 transcript 文本和 summary，并在 History 展示；
- 继续学习：History 可以用相同 profile 开启新 room，并带上上一轮短上下文；本地聊天 id 保持不变；如果本地有已保存 messages 会优先恢复，没有则回退到 transcript/summary；继续说话/输入会更新同一条 History item；
- Words Practice：开启基于 LiveKit 的目标词口语练习，但不把 V1 扩展成完整单词系统；
- Diagnostics/Settings：把调试和配置从主学习页中拆出去。

## 2. Architecture Overview

Client (UIKit app) -> learning profile -> Backend API (`/session`) -> LiveKit room/token -> profile-aware LiveKit agent -> realtime voice session.

Separation of concerns:
- App: `AppConfig`, `AppEnvironment`, startup wiring
- Core: `AppLogger`, `AppError`, shared formatting utilities
- Network: `BackendAPIClient` and `SessionConfig` DTO
- Agent: `LiveKitAgentClient` and `AudioSessionManager`
- Feature UI: `HomeViewController`, `LearningProfileEditorViewController`, `SessionViewController`, `HistoryViewController`, `DiagnosticsViewController`, `SettingsViewController`
- Feature MVVM: `SessionViewModel`, `SessionViewState`
- Storage: `SessionStorageManager` saves latest 20 local metadata/summary records
- Layout: SnapKit

中文：
客户端携带学习配置调用后端 `/session` 获取连接配置，再进入 LiveKit 房间，由读取同一 room profile 的 agent 提供实时语音辅导。
当前分层为 App、Core、Network、Agent、Feature UI、Session MVVM、Storage 和 SnapKit 布局；ViewController 只负责渲染和事件转发，主流程由 ViewModel 编排。

## 3. Prerequisites

- macOS + Xcode 15+
- Swift 5.10+
- Python 3.10+
- LiveKit Cloud account
- Xcode Swift Package resolution for LiveKit and SnapKit

中文：
- macOS + Xcode 15+
- Swift 5.10+
- Python 3.10+
- LiveKit Cloud 账号
- Xcode Swift Package 依赖解析能力，用于拉取 LiveKit 和 SnapKit

## 4. Environment Setup

1. Use root `env.example` as the visible template.
2. Copy it to `env`.
3. Fill `LIVEKIT_URL`, `LIVEKIT_API_KEY`, and `LIVEKIT_API_SECRET` in `env`.
4. Backend scripts automatically copy `env` to the runtime `.env` before setup/start.
5. `.env` is ignored by git; `env.example` and `.env.example` are committed as shareable templates. Keep committed `env` placeholder-safe and never commit real secrets.

中文：
1. 使用根目录 `env.example` 作为可见配置模板。
2. 复制为 `env`。
3. 在 `env` 中填写 `LIVEKIT_URL`、`LIVEKIT_API_KEY`、`LIVEKIT_API_SECRET`。
4. 后端脚本会在 setup/start 前自动复制 `env` 到运行时 `.env`。
5. `.env` 会被 git 忽略；`env.example` 和 `.env.example` 作为可提交的配置模板。提交前保持 `env` 为 placeholder，不要提交真实密钥。

## 5. Run Backend

Recommended one-command startup from project root:

```bash
./start_all.sh
```

The script starts the API and agent, waits for `/health`, waits for the agent `registered worker` log, and then prints `All backend services ready`.
After backend readiness, it runs `ios/scripts/start_ios.sh`, which configures the iOS backend URL, opens `AITutor.xcodeproj`, and attempts to trigger Xcode Run with the currently selected destination.

Successful backend/agent startup should include:

```text
[dev] Backend API ready
[dev] Agent registered worker
[dev] All backend services ready
```

If `Agent registered worker` appears, the LiveKit agent has connected to LiveKit Cloud and is waiting for rooms/jobs.

中文：该脚本会启动 API 和 agent，等待 `/health` 可用，等待 agent 日志出现 `registered worker`，然后输出 `All backend services ready`。后端 ready 后，它会运行 `ios/scripts/start_ios.sh`，自动配置 iOS 后端地址、打开 `AITutor.xcodeproj`，并尝试使用 Xcode 当前选中的设备触发 Run。

成功启动后应该看到：

```text
[dev] Backend API ready
[dev] Agent registered worker
[dev] All backend services ready
```

如果出现 `Agent registered worker`，说明 LiveKit agent 已连接到 LiveKit Cloud，并正在等待房间/job。

Check backend health from project root:

```bash
./scripts/check_backend.sh
```

Backend-only scripts are also available:

```bash
cd backend
./scripts/setup.sh
./scripts/start_all.sh
```

Backend endpoints:
- `GET /health`
- `GET /config`
- `POST /session`
- `POST /summary/incremental`
- `POST /summary`

Run backend diagnostics:

```bash
source .venv/bin/activate
python tests/diagnose_backend.py --verbose
```

Manual startup is also available:

```bash
./scripts/start_api.sh
./scripts/start_agent.sh
```

The agent uses automatic dispatch for the MVP, so newly created LiveKit rooms in the same project can trigger the tutor agent without extra app-side dispatch code.

中文：
推荐使用脚本完成本地 setup，并通过 `start_all.sh` 同时启动 API 服务和 LiveKit 语音 agent。当前 MVP 使用自动 dispatch，新建的同一 LiveKit project 房间可以触发 tutor agent，不需要 App 额外发送 dispatch 请求。

## 6. Run iOS App (UIKit)

The existing `ios/AITutor.xcodeproj` already includes the LiveKit Swift SDK and SnapKit package references.

Optional if you have XcodeGen installed:

```bash
cd ios
xcodegen generate
```

For simulator:
- Keep `BACKEND_BASE_URL` as `http://127.0.0.1:8000`.
- Start backend from project root with `./start_all.sh`.
- Open `ios/AITutor.xcodeproj` in Xcode and run the `AITutor` scheme.

For physical iPhone:
- Select the target iPhone in Xcode once if needed.
- Start everything from project root with `./start_all.sh`. This automatically detects the Mac LAN IP, writes `BACKEND_BASE_URL` into `ios/project.yml` and `ios/AITutor.xcodeproj`, opens Xcode, and attempts to run the app.
- If you only want backend services without opening Xcode, run:

```bash
START_IOS_APP=0 ./start_all.sh
```

- If you want Xcode to open but not auto-run, run:

```bash
IOS_AUTO_RUN=0 ./start_all.sh
```

- If you want to configure it manually, run:

```bash
IOS_BACKEND_BASE_URL=http://<mac-lan-ip>:8000 ios/scripts/configure_backend_url.sh
```

- You can also override just the host or port:

```bash
IOS_BACKEND_HOST=<mac-lan-ip> IOS_BACKEND_PORT=8000 ios/scripts/configure_backend_url.sh
```

- Make sure the iPhone and Mac are on the same Wi-Fi and macOS firewall allows incoming connections to Python/Uvicorn.
- If the AppleScript run trigger is blocked by macOS permissions, Xcode will still open; press `Cmd+R` manually.
- The app declares local-network/ATS development support so a physical iPhone can call `http://<mac-lan-ip>:8000`.
- Confirm signing uses team `MKDWSCTD3X` and bundle id `ai.jovida.ha`.
- In Xcode console, filter `[test]` to see secret-safe DEBUG diagnostics for network, LiveKit, audio, storage, and session flow.

Current iOS dependency policy:
- Required third-party libraries: LiveKit Swift SDK and SnapKit.
- Not added for MVP: Alamofire, RxSwift/Combine wrappers, persistence frameworks, analytics SDKs, or custom audio libraries.
- Reason: `URLSession`, UIKit, AVFAudio, LiveKit, and SnapKit cover the P0 voice loop with fewer moving parts.

中文：
当前 `ios/AITutor.xcodeproj` 已包含 LiveKit Swift SDK 和 SnapKit 的 Swift Package 引用。

如果本机安装了 XcodeGen，可以选择执行：

```bash
cd ios
xcodegen generate
```

模拟器运行：
- 保持 `BACKEND_BASE_URL` 为 `http://127.0.0.1:8000`；
- 在根目录运行 `./start_all.sh` 启动后端；
- 用 Xcode 打开 `ios/AITutor.xcodeproj` 并运行 `AITutor` scheme。

真机运行：
- 如有需要，先在 Xcode 中选中目标 iPhone；
- 在根目录运行 `./start_all.sh` 一键启动；脚本会自动检测 Mac 局域网 IP，写入 `ios/project.yml` 和 `ios/AITutor.xcodeproj` 的 `BACKEND_BASE_URL`，打开 Xcode，并尝试运行 App；
- 如果只想启动后端，不打开 Xcode，可以运行：

```bash
START_IOS_APP=0 ./start_all.sh
```

- 如果想打开 Xcode 但不自动 Run，可以运行：

```bash
IOS_AUTO_RUN=0 ./start_all.sh
```

- 如果需要手动配置，可以运行：

```bash
IOS_BACKEND_BASE_URL=http://<mac-lan-ip>:8000 ios/scripts/configure_backend_url.sh
```

- 也可以只覆盖 host 或 port：

```bash
IOS_BACKEND_HOST=<mac-lan-ip> IOS_BACKEND_PORT=8000 ios/scripts/configure_backend_url.sh
```

- 确保 iPhone 和 Mac 在同一 Wi-Fi，macOS 防火墙允许 Python/Uvicorn 入站连接；
- 如果 macOS 权限阻止 AppleScript 自动触发运行，Xcode 仍会打开，此时手动按 `Cmd+R` 即可；
- App 已声明本地网络/ATS 开发支持，真机可以访问 `http://<mac-lan-ip>:8000`；
- 确认签名 team 为 `MKDWSCTD3X`、bundle id 为 `ai.jovida.ha`；
- 在 Xcode console 过滤 `[test]`，可以查看 network、LiveKit、audio、storage、session 的脱敏 DEBUG 诊断日志。

当前 iOS 第三方库策略：
- 必需：LiveKit Swift SDK、SnapKit；
- MVP 暂不引入：Alamofire、RxSwift/Combine 封装、额外持久化框架、统计 SDK、自定义音频库；
- 原因：`URLSession`、UIKit、AVFAudio、LiveKit 和 SnapKit 已覆盖 P0 语音闭环，额外库会增加复杂度。

## iOS Tests

The project includes an `AITutorTests` unit test target for the MVVM/session logic.

Run from the repository root:

```bash
xcodebuild test -project ios/AITutor.xcodeproj -scheme AITutor -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
```

If the requested simulator is not available, choose one listed by:

```bash
xcodebuild -showdestinations -project ios/AITutor.xcodeproj -scheme AITutor
```

Current coverage focuses on:
- `SessionViewModel` connect/start/reconnect/end/transcript state transitions with protocol mocks.
- `SessionStorageManager` JSON/Codable latest-20 behavior and clear-history.
- Backend DTO decoding and summary display formatting.
- Specific user-facing failure state mapping.

中文：项目包含 `AITutorTests` 单元测试 target，用于保护 MVVM/session 逻辑。

在仓库根目录运行：

```bash
xcodebuild test -project ios/AITutor.xcodeproj -scheme AITutor -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
```

如果本机没有该模拟器，可以用下面命令查看可用 destination：

```bash
xcodebuild -showdestinations -project ios/AITutor.xcodeproj -scheme AITutor
```

当前测试覆盖：
- `SessionViewModel` 的 connect/start/reconnect/end/transcript 状态流，并使用协议 mock 隔离 LiveKit、音频和后端。
- `SessionStorageManager` 的 JSON/Codable 最近 20 条保存和清空历史。
- 后端 DTO 解码和 summary 展示格式。
- 具体用户可读失败状态映射。

## Runbook

Operational troubleshooting lives in `docs/RUNBOOK.md`. Use it when backend startup, agent registration, iPhone LAN access, microphone publishing, choppy audio, transcript, summary, or background-mode behavior needs debugging.

中文：运行和排障手册放在 `docs/RUNBOOK.md`。当后端启动、agent 注册、iPhone 局域网访问、麦克风发布、语音卡顿、转写、摘要或后台模式需要排查时，优先查看它。


## Voice Pipeline Profiles

The backend uses one voice profile switch in root `env`:

```bash
VOICE_PIPELINE_PROFILE=smooth
```

Available profiles:
- `smooth` is the default demo-safe profile. It disables interruption and preemptive generation, keeps tutor replies very short, and buffers each short TTS sentence before playback. The tutor may wait longer before speaking, but each sentence should sound most continuous.
- `balanced` uses LiveKit Inference STT/LLM/TTS, enables LLM preemptive generation, disables interruption for a calmer tutor, uses LiveKit's default streaming TTS path, and keeps replies extremely short. It is available for later tuning when lower latency matters more than maximum smoothness.
- `realtime` uses LiveKit's default streaming TTS node with preemptive LLM generation and interruption enabled. It is most responsive and closest to a realtime voice product, but slow TTS flushes can be audible as chunking in some network/model conditions.

To test another mode temporarily:

```bash
VOICE_PIPELINE_PROFILE=balanced ./start_all.sh
VOICE_PIPELINE_PROFILE=smooth ./start_all.sh
VOICE_PIPELINE_PROFILE=realtime ./start_all.sh
```

The agent logs the active profile with `[profile] voice_pipeline`, and `./scripts/check_audio_health.sh` explains audio warnings according to that profile. No raw audio, token, API key, or API secret is logged.

中文：后端现在只通过根目录 `env` 中的 `VOICE_PIPELINE_PROFILE=smooth|balanced|realtime` 切换语音管线。

- `smooth` 是默认演示保底模式：关闭打断和抢跑，tutor 回复更短，并在服务端先合成完整短句再播放。它可能更晚开口，但一句话内部通常最连续。
- `balanced` 仍使用 LiveKit Inference STT/LLM/TTS，开启 LLM 抢跑，关闭打断，使用 LiveKit 默认流式 TTS 路径，并把回复控制得很短。后续如果更重视低延迟，可以继续调这个模式。
- `realtime` 使用 LiveKit 默认流式 TTS 节点，开启 LLM 抢跑和打断，最接近实时语音产品；但在某些网络或模型条件下，slow TTS flush 可能表现为句中分块或轻微卡顿。

agent 会用 `[profile] voice_pipeline` 输出当前 profile，`./scripts/check_audio_health.sh` 会按 profile 解读音频 warning。日志不会输出原始音频、token、API key 或 API secret。

## Demo Script

Use this script for a reviewer-facing walkthrough:

1. Start backend and agent with `./start_all.sh`.
2. Show successful backend signals in terminal.
3. Open the iOS app on Home and explain the current learning profile.
4. Tap `Customize`, change mode/style/difficulty or enter a short custom goal, then save.
5. Tap `AI Chat`; show that it connects automatically and the fresh empty chat gets one short tutor opener.
6. Tap the mic, confirm the waveform appears, say one short English sentence, then tap send.
7. Wait for tutor voice response and show `Tutor Thinking` / `Tutor Speaking` states.
8. Send one text fallback message to prove the demo can continue if audio input is unreliable.
9. Tap `End`, then open History and review the transcript/summary.
10. Open Diagnostics and Settings to show secret-safe debugging and privacy behavior.

中文：
评审演示脚本：

1. 运行 `./start_all.sh` 启动后端和 agent；
2. 展示终端中的成功信号；
3. 打开 iOS 首页，说明当前学习配置；
4. 点击 `Customize` 修改模式/风格/难度或输入短目标并保存；
5. 点击 `AI Chat`，展示自动连接，并且全新空聊天会由 tutor 简短开场；
6. 点击麦克风，确认输入框位置出现音波，说一句英文后点击发送；
7. 等待 tutor 语音回应，并展示 `Tutor Thinking` / `Tutor Speaking` 状态；
8. 发送一条文字 fallback，证明语音异常时 demo 仍可继续；
9. 点击返回结束当前会话，再进入 History 查看 transcript/summary；
10. 打开 Diagnostics 和 Settings，展示脱敏诊断和隐私策略。

## Expected Success Signals

- Terminal shows `Backend API ready`, `Agent registered worker`, and `All backend services ready`.
- `./scripts/check_backend.sh` passes while services are running.
- Xcode console `[test]` logs show backend session creation, LiveKit connect, mic publish/mute, transcript, storage, and summary events.
- App Home shows the selected learning profile and latest summary card.
- Fresh AI Chat connects and gets one short tutor opener; History Continue connects quietly and waits for the learner.
- Voice or text input creates `You` messages and tutor responses create `Tutor` messages when transcription is available.
- Back navigation or End Session saves a local summary and History can open a review detail.
- If the current LiveKit room cannot reconnect, the app requests a fresh `/session` while keeping visible local chat messages.
- History `Continue` sends only short text context from the previous summary/transcript, never raw audio.
- History `Continue` restores saved chat messages in Chat. If an older local record lacks messages, it falls back to transcript text or a compact summary instead of showing a blank page.
- History Continue keeps one local chat id: exiting without new learner/tutor content changes nothing, while new text input or final voice/tutor transcript content updates the same History item instead of creating another list item.

中文：
预期成功信号：
- 终端出现 `Backend API ready`、`Agent registered worker`、`All backend services ready`；
- 服务运行时 `./scripts/check_backend.sh` 通过；
- Xcode console 中 `[test]` 日志能看到后端 session、LiveKit 连接、麦克风发布/静音、转写、存储和摘要事件；
- 首页展示当前学习配置和最近摘要卡片；
- 全新 AI Chat 连接后会有一句简短 tutor 开场；History Continue 会安静等待学习者继续；
- 语音或文字输入会出现 `You` 消息，转写可用时 tutor 回答会出现 `Tutor` 消息；
- 返回或 End Session 会保存本地 summary，History 可打开复盘详情。
- 如果当前 LiveKit room 无法重连，App 会重新请求新的 `/session`，同时保留当前页面上的本地聊天消息；
- History 的 `Continue` 只发送上一轮 summary/transcript 的短文本上下文，不发送 raw audio。
- History 的 `Continue` 会在 Chat 中恢复已保存消息；如果旧本地记录没有 messages，会回退到 transcript 文本或简短 summary，避免空白页面。
- History Continue 保持同一个本地聊天 id：没有新学习者/tutor 内容就退出时不改变历史；有新文字输入或 final 语音/tutor 转写时，会更新同一条 History item，而不是新增列表项。

## Mobile Experience Decisions

- Home first: gives reviewers a clear product frame instead of dropping them into a debug-heavy session screen.
- Profile before practice: mode/style/difficulty/custom goal make the tutor feel intentional and adaptive.
- Fresh-chat warm-up, resume quiet: fresh empty chats get one short opener so the learner is not dropped into silence, while History Continue stays quiet to avoid interrupting an existing learning context.
- Tap-to-record voice plus text fallback: keeps the demo resilient when microphone, network, or transcription behavior varies, while avoiding accidental long presses and leaving a clear cancel path.
- Chat-level voice modes: `Auto Voice` is the default for hands-free, continuous LiveKit turn detection; `Manual Voice` remains available from a long press on the mic button when the learner wants explicit tap-record/send control.
- Chat-style transcript: matches user expectations for conversational learning and enables post-session review.
- Focused Words Practice: gives the app a second learning entry point while keeping vocabulary work narrow enough not to destabilize the core voice demo.
- Continue with context: makes History feel like learning continuity, but keeps context short to protect latency.
- Separate Diagnostics: preserves learning focus while keeping debugging powerful.
- Local-only recent history: enough for review without adding login, cloud sync, or privacy risk.

中文：
移动端产品判断：
- 先首页：让评审先理解产品，而不是直接进入调试味很重的会话页；
- 练习前配置：模式/风格/难度/目标让 tutor 更有意图和适配感；
- 全新空聊天自动开场，历史继续保持安静：降低操作成本，同时避免继续学习时突然打断上下文；
- 点击式语音输入 + 文字 fallback：麦克风、网络或转写不稳定时 demo 仍可继续，也避免长按误操作，并提供清晰的取消路径；
- 可选后台语音自动启动：学习者主动开启后，可支持更长时间的免手持练习；默认路径仍保持保守，并且不在后台弹权限；
- 聊天式 transcript：符合对话学习预期，也支持会后复盘；
- 聚焦版 Words Practice：给 App 一个第二学习入口，但把单词练习控制在目标词口语会话内，避免影响核心语音 demo 稳定性；
- 带上下文继续学习：让 History 像真正的学习连续性，但上下文保持短，以控制延迟；
- Diagnostics 独立：学习页保持专注，排障能力仍保留；
- 本地最近历史：足够评审查看，不引入登录、云同步和隐私风险。

## 7. Key Design Decisions and Tradeoffs

- Decision: Keep backend simple (token + config APIs).
  - Why: challenge scope is 2-3 hours; reliability over feature breadth.
- Decision: Use LiveKit Inference for the first agent path.
  - Why: it avoids introducing an extra model API key for the MVP.
- Decision: UIKit multi-screen but lightweight V1.
  - Why: Home, Chat, History, Diagnostics, and Settings make the demo feel complete without building a full learning platform.
- Decision: Learning profile affects backend prompt.
  - Why: mode/style/difficulty/custom goal must change tutor behavior, not just labels.
- Decision: Separate UI, session orchestration, audio I/O, networking/streaming, and persistence.
  - Why: this keeps rendering, LiveKit room control, microphone behavior, backend calls, and local storage independently testable and replaceable.
- Tradeoff: default `VOICE_PIPELINE_PROFILE=smooth`.
  - Why: it favors clear full-sentence playback over the lowest possible latency because demo reliability matters more than shaving off a second of response time.
- Decision: Keep Words Practice focused instead of building a full vocabulary system.
  - Why: it shows product direction and reuse of the LiveKit chat flow without diluting the core voice tutor.
- Decision: Store text transcripts and summaries locally, but never raw audio.
  - Why: learners need review value, while privacy and scope should stay tight.
- Decision: Save local fallback summary first, then update with AI summary asynchronously.
  - Why: ending a session remains reliable even if generation is slow or temporarily unavailable.
- Decision: Reconnect current room first, then fall back to a fresh session.
  - Why: current-room reconnect preserves continuity when possible; fallback keeps the demo recoverable without losing local messages.
- Decision: Scope background audio to the active Chat session.
  - Why: it supports hands-free practice without claiming unlimited background execution.
- Decision: Use SnapKit for UIKit layout.
  - Why: it keeps constraints readable while staying in UIKit.
- Tradeoff: no extra networking or reactive framework.
  - Why: `URLSession` and simple async/await are enough for one backend session endpoint.

中文：
- 后端保持最简，优先保证可跑通。
- 第一版 agent 使用 LiveKit Inference，避免额外引入模型 API key。
- UIKit 多页面但保持轻量，让 Home、Chat、History、Diagnostics、Settings 形成完整 demo，而不是完整学习平台。
- 学习配置会影响后端 prompt，保证模式、风格、难度和目标不是纯 UI 标签。
- UI、会话编排、音频 I/O、网络/流媒体、持久化明确分层，让渲染、LiveKit 房间控制、麦克风行为、后端调用和本地存储都能独立测试和替换。
- 默认 `VOICE_PIPELINE_PROFILE=smooth`，牺牲一点最低延迟，换取更清楚完整的整句语音播放，因为 demo 稳定性比少一秒响应更重要。
- Words Practice 只做聚焦目标词练习，不做完整单词系统；这样可以展示产品方向，同时复用核心 LiveKit 聊天链路。
- 本地保存文本 transcript 和 summary，但不保存 raw audio；这样既有复盘价值，也控制隐私和范围风险。
- 结束会话时先保存本地 fallback summary，再异步更新 AI summary；即使生成慢或失败，结束流程仍可靠。
- Reconnect 先尝试当前 room，失败后再创建新 session；这样能尽量保留连续性，同时保证 demo 可恢复。
- 后台音频只限定在活跃 Chat 会话内，不声明无限后台执行；这样更安全，也更容易解释。
- 使用 SnapKit 管理 UIKit 约束，让布局代码更清晰。
- 暂不引入额外网络库或响应式框架，因为 `URLSession` 和 async/await 已满足当前单接口需求。

## 8. Engineering Documentation Rules

- Feature-level docs are mandatory. See `engineering-standards/FEATURE_DOC_POLICY.md`.
- Every feature folder must include `FEATURE.md`.
- Any main flow change must update the corresponding `FEATURE.md` in the same commit.

中文：
- 功能级文档是强制要求，详见 `engineering-standards/FEATURE_DOC_POLICY.md`。
- 每个功能目录必须有 `FEATURE.md`。
- 主流程改动必须在同一次提交中同步更新文档。

## 9. Feature Scope

Feature priorities and non-goals are documented in `docs/feature-scope.md`.

中文：
功能优先级和不做范围记录在 `docs/feature-scope.md`。

## 10. Validation Checklist

Final physical-device validation is treated as passed for the submission scope. The remaining known limitations below describe intentional product/engineering scope choices, not blocking verification gaps.

中文：提交范围内的最终真机验证按已通过处理。下面的已知限制描述的是刻意保留的产品/工程范围取舍，不是阻塞验证缺口。

- `./start_all.sh` shows `Backend API ready`, `Agent registered worker`, and `All backend services ready`.
- `./start_all.sh` performs a clean restart by stopping stale local `uvicorn main:app` and `agent.py dev` processes before launching, preventing port conflicts and duplicate tutor voices.
- `./scripts/clear_logs.sh` clears `logs/api.log` and `logs/agent.log` without deleting the files.
- Xcode Debug builds run the `Clear Runtime Logs` build phase, so pressing Cmd+R starts with fresh runtime logs.
- `./scripts/check_audio_health.sh` summarizes the active voice profile, slow TTS generation, stale balanced-buffer evidence, smooth-buffer evidence, and missing microphone-track evidence.
- `./scripts/check_backend.sh` passes when backend services are running.
- Xcode build succeeds for the `AITutor` scheme.
- iOS unit tests pass for the `AITutor` scheme.
- `docs/RUNBOOK.md` exists and covers common startup, network, agent, audio, transcript, summary, and background-mode issues.
- On iPhone, opening `AI Chat` creates a room and connects to LiveKit.
- Fresh auto-connect opens with one short tutor warm-up; resume-context chats stay quiet. Tapping the mic requests microphone permission and publishes audio, the waveform replaces the text field while recording, and send finishes voice input before the tutor responds.
- Voice/text input shows `[test]` audio/LiveKit/session logs.
- Active voice sessions declare iOS background audio support; validate by starting a session, locking the phone or switching apps, speaking/hearing tutor audio, inspecting foreground/background plus interruption/route/LiveKit `[test]` logs, returning foreground, and ending the session.
- Long-press the Chat mic button to switch between `Auto Voice` and `Manual Voice`. `Auto Voice` is the default and can keep the active connected Chat microphone open before background suspension if microphone permission is already granted; LiveKit STT/turn detection auto-submits speech without a foreground send tap. After leaving Chat or ending the session, Auto Voice no longer runs in the background.
- Background support is intentionally scoped to active audio sessions. If iOS suspends or kills the app, reopen it and use `Reconnect`; this demo does not claim unlimited background execution.
- `Reconnect` is visible after failure and retries the current session when available.
- If current-room reconnect fails, the app falls back to a new backend `/session` and keeps local chat messages visible.
- During active sessions, opening the Summary screen shows the latest available summary draft after several final transcript turns.
- History `Continue` starts a new room with the saved learning profile, restores saved text messages in Chat, falls back to transcript/summary for older records, and sends a limited resume context from summary/transcript.
- History Continue keeps the original local record id. Closing without new content is review-only; continuing with new voice/text updates the same record rather than creating a duplicate list item.
- Back navigation or `End Session` disconnects, deactivates audio, saves a local transcript-based summary immediately, and then updates the record if final AI summary generation completes.
- Final AI summary generation can continue after the Chat screen closes, but it writes back only if the saved session record still exists.
- Summary generation is guarded so stale async results are ignored after a new connection starts, history is cleared, or the target session record has been removed.
- Backend diagnostics smoke-check `/summary` and `/summary/incremental` response shape when backend services are running.
- Summary quality control is not part of the current implementation scope.
- No raw audio, LiveKit token, API key, or API secret is stored or logged.

中文：
- `./start_all.sh` 应输出 `Backend API ready`、`Agent registered worker` 和 `All backend services ready`。
- `./start_all.sh` 会在启动前清理旧的本地 `uvicorn main:app` 和 `agent.py dev` 进程，避免端口冲突和旧 LiveKit agent 残留导致两个 tutor 声音。
- `./scripts/clear_logs.sh` 会清空 `logs/api.log` 和 `logs/agent.log` 的内容，但不会删除文件本身。
- Xcode Debug 构建会运行 `Clear Runtime Logs` build phase，所以按 Cmd+R 时会先清理本地 runtime logs。
- `./scripts/check_audio_health.sh` 会汇总当前语音 profile、TTS 生成过慢、旧版 balanced buffer 证据、smooth buffer 证据，以及是否缺少麦克风轨道证据。
- 后端运行时，`./scripts/check_backend.sh` 应通过。
- Xcode `AITutor` scheme 构建应成功。
- iOS 单元测试应通过 `AITutor` scheme。
- `docs/RUNBOOK.md` 已存在，并覆盖常见启动、网络、agent、音频、转写、摘要和后台模式问题。
- 真机进入 `AI Chat` 会创建房间并连接 LiveKit。
- 全新空聊天自动连接后会有一句简短 warm-up；带上下文继续学习时会保持安静。点击麦克风会请求麦克风权限并发布音频，录音时输入框位置显示音波，点击发送结束语音输入后 tutor 再回应。
- 语音/文字输入会输出 `[test]` audio/LiveKit/session 日志。
- 活跃语音会话已声明 iOS 后台音频支持；验证方式是开始会话后锁屏或切到其他 App，确认还能说话/听到 tutor，检查前后台、音频中断、路由变化和 LiveKit `[test]` 日志，回到前台后再结束会话。
- 长按 Chat 麦克风按钮可在 `Auto Voice` 和 `Manual Voice` 间切换。`Auto Voice` 是默认模式：当前活跃且已连接的 Chat 可在后台挂起前打开麦克风；如果麦克风权限已授权，LiveKit STT/turn detection 会自动提交语音，不需要前台点击发送。离开 Chat 或结束会话后，Auto Voice 不会继续在后台生效。
- 后台支持刻意限定为活跃音频会话。如果 iOS 暂停或杀掉 App，需要重新打开并使用 `Reconnect`；这个 demo 不声明无限后台执行能力。
- 失败后显示 `Reconnect`，并优先重试当前会话。
- 如果当前 room 重连失败，App 会 fallback 到新的后端 `/session`，并保留本地聊天消息。
- 活跃会话中，累计几轮 final transcript 后，打开 Summary 页面会显示最新可用的摘要草稿。
- History 的 `Continue` 会使用已保存的学习配置开启新 room，在 Chat 中恢复已保存文本消息；如果旧记录没有 messages，则回退到 transcript/summary，并附带来自 summary/transcript 的有限继续学习上下文。
- History Continue 保持原本地记录 id；没有新内容就退出会被视为只读复盘，有新语音/文字时会更新同一条记录，而不是新增重复列表项。
- 返回或 `End Session` 会断开连接、释放音频、立即保存本地 transcript 摘要，并在最终 AI 摘要完成后更新本地记录。
- 最终 AI 摘要可以在 Chat 页面关闭后继续生成，但只有本地 session record 仍存在时才会写回。
- 摘要生成有保护逻辑：开始新连接、清空历史，或目标 session record 已被移除后，旧的异步摘要结果会被忽略。
- 后端服务运行时，诊断脚本会 smoke-check `/summary` 和 `/summary/incremental` 响应结构。
- 摘要质量控制不属于当前实现范围。
- 不保存或输出原始音频、LiveKit token、API key 或 API secret。

## Known Limitations

- `smooth` prioritizes clear full sentences over lowest latency, so the tutor may wait before speaking.
- Words Practice is intentionally focused on target-word speaking sessions, not a full vocabulary curriculum.
- Summary quality control is not implemented; current summaries focus on a privacy-safe local/AI generation path.
- Backend URL and voice profile are configured by scripts/env, not edited inside the app.
- Background mode is scoped to active Chat audio sessions and does not claim unlimited background execution; `Auto Voice` requires microphone permission to be granted before entering background.

中文：
已知限制：
- `smooth` 优先保证完整清晰，因此 tutor 可能更晚开口；
- Words Practice 聚焦目标词口语会话，不做完整单词课程体系；
- 摘要质量控制未实现，当前重点是隐私安全的本地/AI 生成路径；
- 后端 URL 和 voice profile 由脚本/env 配置，不在 App 内编辑；
- 后台模式只覆盖活跃 Chat 音频会话，不声明无限后台执行；`Auto Voice` 需要先在前台获得麦克风权限。
