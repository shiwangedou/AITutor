# AITutor (UIKit + LiveKit)

A minimal real-time voice AI tutor with a simple Python backend and a native iOS frontend built with UIKit.

中文：这是一个最小可运行的实时语音 AI 家教项目，包含 Python 后端和 UIKit 原生 iOS 前端。

## 1. What This Project Includes

- Backend (`FastAPI`) for health check and LiveKit session token issuance.
- iOS app (`UIKit` + `SnapKit`) with MVVM connect/start/reconnect/end session flow.
- LiveKit Swift SDK room connection and microphone publishing.
- Lightweight local JSON/Codable summaries for the latest 20 sessions.
- Environment-driven config (`.env`), no hardcoded secrets.

中文：
- 后端（FastAPI）：健康检查与 LiveKit 会话令牌下发。
- iOS（UIKit + SnapKit）：通过 MVVM 执行连接、开始、重连、结束会话主流程。
- 使用 LiveKit Swift SDK 连接房间并发布麦克风。
- 使用轻量 JSON/Codable 本地保存最近 20 条会话总结。
- 所有配置走 `.env`，不硬编码密钥。

## 2. Architecture Overview

Client (UIKit app) -> Backend API (`/session`) -> LiveKit room/token -> Realtime voice session.

Separation of concerns:
- App: `AppConfig`, `AppEnvironment`, startup wiring
- Core: `AppLogger`, `AppError`, shared formatting utilities
- Network: `BackendAPIClient` and `SessionConfig` DTO
- Agent: `LiveKitAgentClient` and `AudioSessionManager`
- Feature MVVM: `SessionViewController`, `SessionViewModel`, `SessionViewState`
- Storage: `SessionStorageManager` saves latest 20 local metadata/summary records
- Layout: SnapKit

中文：
客户端通过后端 `/session` 获取连接配置，再进入 LiveKit 房间进行实时语音。
当前分层为 App、Core、Network、Agent、Session MVVM、Storage 和 SnapKit 布局；ViewController 只负责渲染，主流程由 ViewModel 编排。

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
2. Copy or rename it to `env`.
3. Fill `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET` in `env`.
4. Backend scripts automatically copy `env` to `.env` before setup/start.
5. `.env` is ignored by git; `env.example` and `.env.example` are committed as shareable templates.

中文：
1. 使用根目录 `env.example` 作为可见配置模板。
2. 复制或重命名为 `env`。
3. 在 `env` 中填写 `LIVEKIT_URL`、`LIVEKIT_API_KEY`、`LIVEKIT_API_SECRET`。
4. 后端脚本会在 setup/start 前自动复制 `env` 到 `.env`。
5. `.env` 会被 git 忽略；`env.example` 和 `.env.example` 作为可提交的配置模板。

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
./check_backend.sh
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

Operational troubleshooting lives in `RUNBOOK.md`. Use it when backend startup, agent registration, iPhone LAN access, microphone publishing, choppy audio, transcript, summary, or background-mode behavior needs debugging.

中文：运行和排障手册放在 `RUNBOOK.md`。当后端启动、agent 注册、iPhone 局域网访问、麦克风发布、语音卡顿、转写、摘要或后台模式需要排查时，优先查看它。


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

The agent logs the active profile with `[profile] voice_pipeline`, and `./check_audio_health.sh` explains audio warnings according to that profile. No raw audio, token, API key, or API secret is logged.

中文：后端现在只通过根目录 `env` 中的 `VOICE_PIPELINE_PROFILE=smooth|balanced|realtime` 切换语音管线。

- `smooth` 是默认演示保底模式：关闭打断和抢跑，tutor 回复更短，并在服务端先合成完整短句再播放。它可能更晚开口，但一句话内部通常最连续。
- `balanced` 仍使用 LiveKit Inference STT/LLM/TTS，开启 LLM 抢跑，关闭打断，使用 LiveKit 默认流式 TTS 路径，并把回复控制得很短。后续如果更重视低延迟，可以继续调这个模式。
- `realtime` 使用 LiveKit 默认流式 TTS 节点，开启 LLM 抢跑和打断，最接近实时语音产品；但在某些网络或模型条件下，slow TTS flush 可能表现为句中分块或轻微卡顿。

agent 会用 `[profile] voice_pipeline` 输出当前 profile，`./check_audio_health.sh` 会按 profile 解读音频 warning。日志不会输出原始音频、token、API key 或 API secret。

## 7. Key Design Decisions and Tradeoffs

- Decision: Keep backend simple (token + config APIs).
  - Why: challenge scope is 2-3 hours; reliability over feature breadth.
- Decision: Use LiveKit Inference for the first agent path.
  - Why: it avoids introducing an extra model API key for the MVP.
- Decision: UIKit single-screen interaction.
  - Why: fast, explicit control of voice session states.
- Decision: Use SnapKit for UIKit layout.
  - Why: it keeps constraints readable while staying in UIKit.
- Tradeoff: no extra networking or reactive framework.
  - Why: `URLSession` and simple async/await are enough for one backend session endpoint.

中文：
- 后端保持最简，优先保证可跑通。
- 第一版 agent 使用 LiveKit Inference，避免额外引入模型 API key。
- UIKit 单页更利于会话状态控制。
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

- `./start_all.sh` shows `Backend API ready`, `Agent registered worker`, and `All backend services ready`.
- `./start_all.sh` performs a clean restart by stopping stale local `uvicorn main:app` and `agent.py dev` processes before launching, preventing port conflicts and duplicate tutor voices.
- `./clear_logs.sh` clears `logs/api.log` and `logs/agent.log` without deleting the files.
- Xcode Debug builds run the `Clear Runtime Logs` build phase, so pressing Cmd+R starts with fresh runtime logs.
- `./check_audio_health.sh` summarizes the active voice profile, slow TTS generation, stale balanced-buffer evidence, smooth-buffer evidence, and missing microphone-track evidence.
- `./check_backend.sh` passes when backend services are running.
- Xcode build succeeds for the `AITutor` scheme.
- iOS unit tests pass for the `AITutor` scheme.
- `RUNBOOK.md` exists and covers common startup, network, agent, audio, transcript, summary, and background-mode issues.
- On iPhone, `Connect` creates a room and connects to LiveKit.
- `Connect` stays quiet; `Start Session` requests microphone permission, publishes audio, sends the start signal, and then the tutor speaks.
- `Start Session` shows `[test]` audio/LiveKit logs.
- Active voice sessions declare iOS background audio support; validate by starting a session, locking the phone or switching apps, speaking/hearing tutor audio, inspecting foreground/background plus interruption/route/LiveKit `[test]` logs, returning foreground, and ending the session.
- Background support is intentionally scoped to active audio sessions. If iOS suspends or kills the app, reopen it and use `Reconnect`; this demo does not claim unlimited background execution.
- `Reconnect` is visible after failure and retries the current session when available.
- During active sessions, the AI Summary Draft panel can update after several final transcript turns.
- `End Session` disconnects, deactivates audio, saves a local transcript-based summary immediately, and then updates the record if final AI summary generation completes.
- Summary generation is guarded so stale async results are ignored after a new connection starts, history is cleared, or the target session is no longer current.
- Backend diagnostics smoke-check `/summary` and `/summary/incremental` response shape when backend services are running.
- Summary quality control is not part of the current implementation scope.
- No raw audio, LiveKit token, API key, or API secret is stored or logged.

中文：
- `./start_all.sh` 应输出 `Backend API ready`、`Agent registered worker` 和 `All backend services ready`。
- `./start_all.sh` 会在启动前清理旧的本地 `uvicorn main:app` 和 `agent.py dev` 进程，避免端口冲突和旧 LiveKit agent 残留导致两个 tutor 声音。
- `./clear_logs.sh` 会清空 `logs/api.log` 和 `logs/agent.log` 的内容，但不会删除文件本身。
- Xcode Debug 构建会运行 `Clear Runtime Logs` build phase，所以按 Cmd+R 时会先清理本地 runtime logs。
- `./check_audio_health.sh` 会汇总当前语音 profile、TTS 生成过慢、旧版 balanced buffer 证据、smooth buffer 证据，以及是否缺少麦克风轨道证据。
- 后端运行时，`./check_backend.sh` 应通过。
- Xcode `AITutor` scheme 构建应成功。
- iOS 单元测试应通过 `AITutor` scheme。
- `RUNBOOK.md` 已存在，并覆盖常见启动、网络、agent、音频、转写、摘要和后台模式问题。
- 真机点击 `Connect` 能创建房间并连接 LiveKit。
- `Connect` 阶段保持安静；`Start Session` 会请求麦克风权限、发布音频、发送开始信号，然后 tutor 才开始说话。
- `Start Session` 会输出 `[test]` audio/LiveKit 日志。
- 活跃语音会话已声明 iOS 后台音频支持；验证方式是开始会话后锁屏或切到其他 App，确认还能说话/听到 tutor，检查前后台、音频中断、路由变化和 LiveKit `[test]` 日志，回到前台后再结束会话。
- 后台支持刻意限定为活跃音频会话。如果 iOS 暂停或杀掉 App，需要重新打开并使用 `Reconnect`；这个 demo 不声明无限后台执行能力。
- 失败后显示 `Reconnect`，并优先重试当前会话。
- 活跃会话中，AI Summary Draft 面板会在累计几轮 final transcript 后更新。
- `End Session` 会断开连接、释放音频、立即保存本地 transcript 摘要，并在最终 AI 摘要完成后更新本地记录。
- 摘要生成有保护逻辑：开始新连接、清空历史，或目标 session 不再是当前可写对象后，旧的异步摘要结果会被忽略。
- 后端服务运行时，诊断脚本会 smoke-check `/summary` 和 `/summary/incremental` 响应结构。
- 摘要质量控制不属于当前实现范围。
- 不保存或输出原始音频、LiveKit token、API key 或 API secret。
