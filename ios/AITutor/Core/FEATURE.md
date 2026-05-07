# Core Layer Feature

## 1. Purpose
Shared app utilities that are not tied to a specific screen, backend endpoint, or LiveKit implementation.

中文：提供不绑定具体页面、后端接口或 LiveKit 实现的通用能力。

## 2. Main Flow / Logic
- `AppLogger` centralizes DEBUG-only Xcode logs and prefixes important diagnostics with `[test]`.
- `AppError` normalizes backend, LiveKit, microphone, audio, storage, and unknown failures into user-readable categories.
- `AppDateFormatter` keeps timestamp formatting consistent across logs and summaries.

中文：
- `AppLogger` 集中管理 DEBUG-only Xcode 日志，并为关键诊断添加 `[test]` 前缀。
- `AppError` 将后端、LiveKit、麦克风、音频、存储和未知错误统一成可读分类。
- `AppDateFormatter` 统一日志和总结中的时间格式。

## 3. Privacy / Safety
- Logs must never include LiveKit tokens, API secrets, or raw private learner content.
- Release builds do not emit `AppLogger` debug/error output.

中文：日志不得包含 LiveKit token、API secret 或用户私密原文；Release 构建不输出 `AppLogger` debug/error 日志。

## 4. Change Log
- 2026-05-07: Added Core layer for logging, app errors, and date formatting.
