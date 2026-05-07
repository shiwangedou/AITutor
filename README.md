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


## Voice Clarity Tuning

If the tutor feels slow or the voice sounds unclear, tune these values in root `env`, then restart `./start_all.sh`:

```bash
STT_MODEL=deepgram/flux-general
STT_EOT_TIMEOUT_MS=700
LLM_MODEL=openai/gpt-4.1-nano
LLM_MAX_TOKENS=60
PREEMPTIVE_TTS=true
TTS_MODEL=cartesia/sonic-turbo
TTS_VOICE=f786b574-daa5-4673-aa0c-cbe3e8534c02
TTS_SPEED=normal
TTS_VOLUME=1.0
TTS_MAX_BUFFER_DELAY_MS=300
```

Recommended first adjustment for slow feedback: keep `STT_MODEL=deepgram/flux-general`, `LLM_MODEL=openai/gpt-4.1-nano`, `LLM_MAX_TOKENS=60`, `PREEMPTIVE_TTS=true`, and `TTS_MAX_BUFFER_DELAY_MS=300`. If the voice is smooth but still unclear, try `TTS_SPEED=slow`; if slow speech becomes choppy again, return to `normal`.

中文：如果 tutor 反馈慢或声音卡顿，优先在根目录 `env` 保持 `STT_MODEL=deepgram/flux-general`、`LLM_MODEL=openai/gpt-4.1-nano`、`LLM_MAX_TOKENS=60`、`PREEMPTIVE_TTS=true`、`TTS_MAX_BUFFER_DELAY_MS=300`，然后重启 `./start_all.sh`。如果声音已经流畅但仍不清楚，可以再尝试 `TTS_SPEED=slow`；如果慢速再次卡顿，就改回 `normal`。

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
- `./clear_logs.sh` clears `logs/api.log` and `logs/agent.log` without deleting the files.
- Xcode Debug builds run the `Clear Runtime Logs` build phase, so pressing Cmd+R starts with fresh runtime logs.
- `./check_audio_health.sh` summarizes agent audio warnings such as slow TTS generation and missing microphone-track evidence.
- `./check_backend.sh` passes when backend services are running.
- Xcode build succeeds for the `AITutor` scheme.
- On iPhone, `Connect` creates a room and connects to LiveKit.
- `Connect` stays quiet; `Start Session` requests microphone permission, publishes audio, sends the start signal, and then the tutor speaks.
- `Start Session` shows `[test]` audio/LiveKit logs.
- `Reconnect` is visible after failure and retries the current session when available.
- `End Session` disconnects, deactivates audio, and saves local metadata/summary.
- No raw audio, LiveKit token, API key, or API secret is stored or logged.

中文：
- `./start_all.sh` 应输出 `Backend API ready`、`Agent registered worker` 和 `All backend services ready`。
- `./clear_logs.sh` 会清空 `logs/api.log` 和 `logs/agent.log` 的内容，但不会删除文件本身。
- Xcode Debug 构建会运行 `Clear Runtime Logs` build phase，所以按 Cmd+R 时会先清理本地 runtime logs。
- `./check_audio_health.sh` 会汇总 agent 音频相关 warning，例如 TTS 生成过慢或缺少麦克风轨道证据。
- 后端运行时，`./check_backend.sh` 应通过。
- Xcode `AITutor` scheme 构建应成功。
- 真机点击 `Connect` 能创建房间并连接 LiveKit。
- `Connect` 阶段保持安静；`Start Session` 会请求麦克风权限、发布音频、发送开始信号，然后 tutor 才开始说话。
- `Start Session` 会输出 `[test]` audio/LiveKit 日志。
- 失败后显示 `Reconnect`，并优先重试当前会话。
- `End Session` 会断开连接、释放音频并保存本地元数据/总结。
- 不保存或输出原始音频、LiveKit token、API key 或 API secret。
