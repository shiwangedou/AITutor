# AITutor (UIKit + LiveKit)

A minimal real-time voice AI tutor with a simple Python backend and a native iOS frontend built with UIKit.

中文：这是一个最小可运行的实时语音 AI 家教项目，包含 Python 后端和 UIKit 原生 iOS 前端。

## 1. What This Project Includes

- Backend (`FastAPI`) for health check and LiveKit session token issuance.
- iOS app (`UIKit`) with connect/start/end session flow.
- Environment-driven config (`.env`), no hardcoded secrets.

中文：
- 后端（FastAPI）：健康检查与 LiveKit 会话令牌下发。
- iOS（UIKit）：连接、开始、结束会话主流程。
- 所有配置走 `.env`，不硬编码密钥。

## 2. Architecture Overview

Client (UIKit app) -> Backend API (`/session`) -> LiveKit room/token -> Realtime voice session.

Separation of concerns:
- UI layer: `SessionViewController`
- Session orchestration: `LiveKitService`
- Audio I/O setup: `AudioSessionManager`
- Networking: `BackendClient`

中文：
客户端通过后端 `/session` 获取连接配置，再进入 LiveKit 房间进行实时语音。
分层为：UI、会话编排、音频 I/O、网络请求。

## 3. Prerequisites

- macOS + Xcode 15+
- Swift 5.10+
- Python 3.10+
- LiveKit Cloud account

中文：
- macOS + Xcode 15+
- Swift 5.10+
- Python 3.10+
- LiveKit Cloud 账号

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

Successful backend/agent startup should include:

```text
[dev] Backend API ready
[dev] Agent registered worker
[dev] All backend services ready
```

If `Agent registered worker` appears, the LiveKit agent has connected to LiveKit Cloud and is waiting for rooms/jobs.

中文：该脚本会启动 API 和 agent，等待 `/health` 可用，等待 agent 日志出现 `registered worker`，然后输出 `All backend services ready`。

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

Generate project (recommended):

```bash
cd ios
xcodegen generate
```

Then open `ios/AITutor.xcodeproj` in Xcode and run on simulator/device.

中文：
先在 `ios/` 执行 `xcodegen generate` 生成工程，再用 Xcode 打开并运行。

## 7. Key Design Decisions and Tradeoffs

- Decision: Keep backend simple (token + config APIs).
  - Why: challenge scope is 2-3 hours; reliability over feature breadth.
- Decision: Use LiveKit Inference for the first agent path.
  - Why: it avoids introducing an extra model API key for the MVP.
- Decision: UIKit single-screen interaction.
  - Why: fast, explicit control of voice session states.
- Tradeoff: current `LiveKitService` is scaffolded and should be wired to the exact SDK APIs in your environment.
  - Why: LiveKit iOS SDK integration details may vary by version.

中文：
- 后端保持最简，优先保证可跑通。
- 第一版 agent 使用 LiveKit Inference，避免额外引入模型 API key。
- UIKit 单页更利于会话状态控制。
- `LiveKitService` 是骨架，需要按你本地 SDK 版本对接具体 API。

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

## 10. Next Steps

- Integrate official LiveKit iOS SDK APIs in `LiveKitService`.
- Replace mock session logs with real transcription events.
- Add reconnect + post-session summary persistence.

中文：
- 把 `LiveKitService` 接成真实 SDK。
- 显示实时转写。
- 增加断线恢复和会后总结持久化。
