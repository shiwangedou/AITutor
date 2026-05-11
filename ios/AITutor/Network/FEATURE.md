# Network Layer Feature

## 1. Purpose
Own backend API communication for session creation and optional AI summary generation, keeping HTTP details out of UI and business logic.

中文：负责后端 API 通信、会话创建和可选 AI 摘要生成，避免 UI 与业务逻辑直接处理 HTTP 细节。

## 2. Main Flow / Logic
1. `SessionViewModel` asks `BackendAPIClientProtocol` to create a session with the selected `LearningProfile` and optional `SessionResumeContext`.
2. `BackendAPIClient` resolves the current backend URL from `AppConfig` for each request. The bundled build setting is the default, and `Settings -> Backend URL` can store an on-device override for installed-app launches.
3. `BackendAPIClient` sends `POST /session` to the configured backend URL with `display_name`, `learning_mode`, `tutor_style`, `difficulty`, optional `custom_goal`, and optional `resume_context`.
4. The response is decoded into `SessionConfig`, including the backend-normalized `learning_profile` and optional `resume_context`.
5. Tokens are passed to the Agent layer but never printed in logs.
6. During a session, `SessionViewModel` can call the separate P2 `generateIncrementalSummary` method after enough final transcript turns.
7. `BackendAPIClient` sends `POST /summary/incremental` with previous summary, new transcript turns, and learning profile.
8. After a session ends, `SessionViewModel` can call the separate P2 `generateSummary` method.
9. `BackendAPIClient` sends `POST /summary` with transcript text, latest running summary, and learning profile, never raw audio.
10. If AI summary calls are not available yet, the app keeps the local summary and marks AI summary as unavailable.

中文：
1. `SessionViewModel` 通过 `BackendAPIClientProtocol` 携带选中的 `LearningProfile` 和可选 `SessionResumeContext` 创建会话。
2. `BackendAPIClient` 每次请求都会从 `AppConfig` 读取当前后端地址；默认使用构建时写入的 bundled URL，`Settings -> Backend URL` 可保存手机本地 override，方便已安装 App 不通过 Xcode Run 启动时继续使用。
3. `BackendAPIClient` 向配置的后端地址发送 `POST /session`，包含 `display_name`、`learning_mode`、`tutor_style`、`difficulty`、可选 `custom_goal` 和可选 `resume_context`。
4. 响应解析为 `SessionConfig`，其中包含后端标准化后的 `learning_profile` 和可选 `resume_context`。
5. token 只传给 Agent 层使用，不写入日志。
6. 会话中，`SessionViewModel` 可以在累计足够 final transcript turns 后调用单独的 P2 `generateIncrementalSummary` 方法。
7. `BackendAPIClient` 向 `/summary/incremental` 发送 previous summary、新增 transcript turns 和学习配置。
8. 会话结束后，`SessionViewModel` 可以调用单独的 P2 `generateSummary` 方法。
9. `BackendAPIClient` 向 `/summary` 发送 transcript 文本、最新 running summary 和学习配置，不发送原始音频。
10. 如果 AI 摘要调用暂不可用，App 会保留本地摘要，并把 AI 摘要标记为 unavailable。

## 3. Error Handling
- Missing HTTP response -> `backendUnavailable`.
- Non-2xx response -> `sessionTokenFailed` with status/body summary.
- Transport or decode failure -> `backendUnavailable` with diagnostic details.
- Incremental or final summary generation failure does not block local summary persistence.
- Reconnect fallback can call `/session` again to create a new room while keeping local chat state in the ViewModel.

中文：缺少 HTTP 响应、非 2xx、网络或解析失败都会转成明确错误，方便 UI 和日志展示；增量或最终 AI 摘要失败不会阻塞本地摘要保存。

## 4. Change Log
- 2026-05-11: Added optional `resume_context` to `/session` creation and DTO decoding for History Continue.
- 2026-05-09: Added learning-profile payload support for `/session`, `/summary`, and `/summary/incremental`.
- 2026-05-08: Added a separate P2 `generateSummary` network method for future AI summaries.
- 2026-05-08: Added P2 `generateIncrementalSummary` for running summary draft updates.
- 2026-05-07: Split backend session creation into a protocol-driven Network layer.
