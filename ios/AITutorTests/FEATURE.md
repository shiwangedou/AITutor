# iOS Unit Tests

中文：iOS 单元测试

## Purpose

These tests protect the UIKit/MVVM session flow without requiring a real LiveKit room, microphone, or backend process.

中文：这些测试用于保护 UIKit/MVVM 会话主流程，不依赖真实 LiveKit 房间、麦克风或后端进程。

## Main Logic

- `SessionViewModelTests` verifies connect, start, reconnect, transcript replacement, and local summary save behavior through protocol mocks.
- `SessionStorageManagerTests` verifies JSON/Codable storage keeps only the latest 20 records and supports clear-history.
- `SessionConfigDTOTests` verifies backend payload decoding and summary display formatting.
- `SessionStateTests` verifies specific failure states stay user-readable.

中文：
- `SessionViewModelTests` 通过协议 mock 验证连接、开始、重连、转写替换和本地总结保存。
- `SessionStorageManagerTests` 验证 JSON/Codable 存储只保留最近 20 条，并支持清空历史。
- `SessionConfigDTOTests` 验证后端返回结构解码和 summary 展示格式。
- `SessionStateTests` 验证不同失败状态保持明确可读。

## Update Rule

Update this file whenever the test target changes scope, adds a major test category, or changes the mocked boundaries.

中文：当测试 target 范围、主要测试类别或 mock 边界发生变化时，需要同步更新本文档。
