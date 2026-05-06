# Session Feature

## 1. Purpose
Handle the user-facing realtime tutoring session lifecycle in UIKit.

中文：负责 UIKit 中用户可见的实时辅导会话生命周期。

## 2. Entry Points
- UI entry: `SessionViewController`
- User actions: `Connect`, `Start Session`, `End Session`

## 3. Main Flow / Logic
1. User taps `Connect`.
2. App requests session config/token from backend `/session`.
3. App calls `LiveKitService.connect(using:)`.
4. On success, state changes to `connected`.
5. User taps `Start Session`, audio session is configured.
6. App starts microphone publishing.
7. User taps `End Session`, app disconnects and deactivates audio session.

中文：
1. 点击 Connect 获取后端会话配置。
2. 连接 LiveKit 成功后进入 connected。
3. Start Session 后启用语音会话并发布麦克风。
4. End Session 后断开连接并释放音频会话。

## 4. State Model
- `idle`
- `connecting`
- `connected`
- `inSession`
- `ended`
- `failed`

## 5. Error Handling
- Backend request failure -> set state to `failed`, append log.
- Connect/start failure -> set state to `failed`, append log.

## 6. Dependencies
- `BackendClient`
- `LiveKitService`
- `AudioSessionManager`

## 7. Change Log
- 2026-05-06: Initial session feature documentation.
