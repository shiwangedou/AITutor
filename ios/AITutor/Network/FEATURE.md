# Network Layer Feature

## 1. Purpose
Own backend API communication for session creation and optional AI summary generation, keeping HTTP details out of UI and business logic.

中文：负责后端 API 通信、会话创建和可选 AI 摘要生成，避免 UI 与业务逻辑直接处理 HTTP 细节。

## 2. Main Flow / Logic
1. `SessionViewModel` asks `BackendAPIClientProtocol` to create a session.
2. `BackendAPIClient` sends `POST /session` to the configured backend URL.
3. The response is decoded into `SessionConfig`.
4. Tokens are passed to the Agent layer but never printed in logs.
5. During a session, `SessionViewModel` can call the separate P2 `generateIncrementalSummary` method after enough final transcript turns.
6. `BackendAPIClient` sends `POST /summary/incremental` with previous summary and new transcript turns only.
7. After a session ends, `SessionViewModel` can call the separate P2 `generateSummary` method.
8. `BackendAPIClient` sends `POST /summary` with transcript text and latest running summary, never raw audio.
9. If AI summary calls are not available yet, the app keeps the local summary and marks AI summary as unavailable.

中文：
1. `SessionViewModel` 通过 `BackendAPIClientProtocol` 创建会话。
2. `BackendAPIClient` 向配置的后端地址发送 `POST /session`。
3. 响应解析为 `SessionConfig`。
4. token 只传给 Agent 层使用，不写入日志。
5. 会话中，`SessionViewModel` 可以在累计足够 final transcript turns 后调用单独的 P2 `generateIncrementalSummary` 方法。
6. `BackendAPIClient` 向 `/summary/incremental` 发送 previous summary 和新增 transcript turns。
7. 会话结束后，`SessionViewModel` 可以调用单独的 P2 `generateSummary` 方法。
8. `BackendAPIClient` 向 `/summary` 发送 transcript 文本和最新 running summary，不发送原始音频。
9. 如果 AI 摘要调用暂不可用，App 会保留本地摘要，并把 AI 摘要标记为 unavailable。

## 3. Error Handling
- Missing HTTP response -> `backendUnavailable`.
- Non-2xx response -> `sessionTokenFailed` with status/body summary.
- Transport or decode failure -> `backendUnavailable` with diagnostic details.
- Incremental or final summary generation failure does not block local summary persistence.

中文：缺少 HTTP 响应、非 2xx、网络或解析失败都会转成明确错误，方便 UI 和日志展示；增量或最终 AI 摘要失败不会阻塞本地摘要保存。

## 4. Change Log
- 2026-05-08: Added a separate P2 `generateSummary` network method for future AI summaries.
- 2026-05-08: Added P2 `generateIncrementalSummary` for running summary draft updates.
- 2026-05-07: Split backend session creation into a protocol-driven Network layer.
