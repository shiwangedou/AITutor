# Temporary Implementation Order

## Phase 1: Must-Have (Build a usable core first)

1. End-to-end realtime voice path
- iOS gets session config from backend (URL + token + room).
- iOS connects to LiveKit room.
- Microphone audio can be published.
- Tutor responses/events can be received.

2. Minimal backend availability
- `GET /health` works.
- `POST /session` returns valid token payload.
- Config is loaded from `.env` only (no hardcoded secrets).

3. UIKit core interaction
- Clear actions: `Connect` / `Start Session` / `End Session`.
- Visible session states: `idle`, `connecting`, `connected`, `inSession`, `ended`, `failed`.
- User-visible error messages (not console-only).

4. Audio and permissions baseline
- Request microphone permission.
- Configure `AVAudioSession` for voice chat.
- Properly deactivate/release audio session on end.

5. Reproducible documentation
- `README.md` can reproduce setup/run from scratch.
- `.env.example` is complete.
- `plan.md` and `workflow.md` match actual implementation.

---

## Phase 2: Bonus (After core is stable)

1. Reconnect and recovery (highest bonus priority)
- Detect disconnect.
- Show reconnect prompt/action.
- Recover to talk-ready state after reconnect.

2. Post-session summary
- Generate 3-5 concise learning points after session.
- Persist at least latest summary locally.

3. Background behavior (optional)
- Keep or gracefully recover session when app background/foreground changes.

---

## Recommended Build Order (Dependency-aware)

1. Backend `/session` token issuance.
2. iOS `BackendClient` session fetch.
3. Real LiveKit SDK integration in `LiveKitService`.
4. Microphone publish + `AVAudioSession` setup.
5. UIKit state machine + error UX.
6. README validation run.
7. Bonus items (reconnect, summary, background).

---

## Step-by-Step Decomposition (Execution Checklist)

1. Clarify scope
- Pick one tutor subject (recommended: English speaking).
- Set target: stable core flow first, then bonus.

2. Write `plan.md` before coding
- Prompt interpretation.
- What to build / not build.
- Feature priorities.

3. Initialize repo structure
- `backend/`, `ios/`, root docs (`README.md`, `workflow.md`, `.env.example`).

4. Define environment variables
- Include all required keys in `.env.example`.
- Ensure runtime reads from `.env` only.

5. Build minimal backend
- Implement `/health` and `/session`.
- Validate via curl or Postman.

6. Build UIKit main screen
- Single `SessionViewController`.
- `Connect`, `Start Session`, `End Session` buttons.
- Status + log panel.

7. Integrate LiveKit iOS SDK
- Connect room using backend token.
- Enable microphone publishing.
- Handle connect/disconnect callbacks.

8. Add basic reliability
- Microphone permission handling.
- Disconnect/failure prompt.
- Resource cleanup on session end.

9. Finalize docs
- `README.md`: setup/run + architecture + tradeoffs.
- `workflow.md`: tools/models + usage + validation method.

10. End-to-end validation
- Run from clean setup using only README.
- Verify backend + iOS flow + env-based secret loading.

11. Submission readiness
- Confirm required files exist.
- Confirm no hardcoded secrets.
- Confirm docs match implementation.

---

## Core Acceptance Criteria

1. From cold start: `Connect` -> `Start Session` enters voice session.
2. Failure cases are visible and understandable to user.
3. `End Session` cleans resources and allows a new session.
4. Reviewer can reproduce flow using `README.md`.

---

## 中文速览

### 第一阶段：必须可用
1. 先打通端到端实时语音。
2. 后端最小可用（`/health`、`/session`、`.env` 配置）。
3. UIKit 主交互完整（Connect/Start/End + 状态可见）。
4. 音频权限与会话配置正确。
5. 文档可复现。

### 第二阶段：加分项
1. 断线恢复（优先）。
2. 会后总结。
3. 后台模式（可选）。

### 分步拆解执行顺序
1. 明确范围与主题。
2. 先写 `plan.md`。
3. 初始化目录结构。
4. 先定义 `.env.example`。
5. 后端接口先跑通。
6. UIKit 主界面完成。
7. 接入 LiveKit SDK。
8. 增加基础稳定性。
9. 完成 README/workflow 文档。
10. 全链路验收。
11. 提交前检查。
