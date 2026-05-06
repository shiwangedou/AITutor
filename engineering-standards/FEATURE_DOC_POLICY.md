# Feature Documentation Policy

This repository requires **feature-level documentation**.

## Mandatory Rule
For every feature folder, a markdown file must exist and stay up to date:
- Required filename: `FEATURE.md`
- Required location: inside that feature folder

Example:
- `ios/AITutor/Features/Session/FEATURE.md`

中文：每个功能目录必须包含一个 `FEATURE.md`，并保持最新。

## When to Update
You must update the related `FEATURE.md` whenever any main flow changes, including:
- state transitions
- user interaction flow
- network call sequence
- error handling / retry logic
- dependency changes that affect behavior

中文：凡是主流程变化（状态、交互、网络时序、异常处理、依赖行为变化），都必须同步更新功能文档。

## Minimum Required Sections
Every `FEATURE.md` must include:
1. Purpose
2. Entry points
3. Main flow / logic
4. State model
5. Error handling
6. Dependencies
7. Change log (short)

## Pull Request Gate (Recommended)
Before merge, verify:
- [ ] Feature code changed
- [ ] Corresponding `FEATURE.md` updated
- [ ] Flow description still matches implementation

中文：建议将“代码改动但文档未更新”视为不可合并项。
