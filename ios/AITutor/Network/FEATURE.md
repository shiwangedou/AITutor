# Network Layer Feature

## 1. Purpose
Own backend API communication for session creation and keep HTTP details out of UI and business logic.

中文：负责后端 API 通信和会话创建，避免 UI 与业务逻辑直接处理 HTTP 细节。

## 2. Main Flow / Logic
1. `SessionViewModel` asks `BackendAPIClientProtocol` to create a session.
2. `BackendAPIClient` sends `POST /session` to the configured backend URL.
3. The response is decoded into `SessionConfig`.
4. Tokens are passed to the Agent layer but never printed in logs.

中文：
1. `SessionViewModel` 通过 `BackendAPIClientProtocol` 创建会话。
2. `BackendAPIClient` 向配置的后端地址发送 `POST /session`。
3. 响应解析为 `SessionConfig`。
4. token 只传给 Agent 层使用，不写入日志。

## 3. Error Handling
- Missing HTTP response -> `backendUnavailable`.
- Non-2xx response -> `sessionTokenFailed` with status/body summary.
- Transport or decode failure -> `backendUnavailable` with diagnostic details.

中文：缺少 HTTP 响应、非 2xx、网络或解析失败都会转成明确错误，方便 UI 和日志展示。

## 4. Change Log
- 2026-05-07: Split backend session creation into a protocol-driven Network layer.
