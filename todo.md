# Todo

## 当前默认策略

- [x] 默认语音模式改为 `VOICE_PIPELINE_PROFILE=smooth`。
- [x] `smooth` 优先保证每句话完整、连续、清晰，代价是 tutor 开口会更慢。
- [ ] 后续如需降低延迟，再单独调 `balanced` 或 `realtime`，不要影响默认演示路径。

## P0：提交前必须确认

- [x] 后端使用真实 LiveKit Agents voice pipeline（STT -> LLM -> TTS）。
- [x] iOS 使用真实 LiveKit Swift SDK 连接 room 并发布麦克风。
- [x] 后端 `/health`、`/session`、`/summary`、`/summary/incremental` 已有实现和诊断脚本。
- [x] UIKit + SnapKit 工程可 generic iOS Debug build。
- [x] `README.md`、`.env.example`、`plan.md`、`workflow.md` 存在。
- [ ] 真机完整验证一次：`Connect -> Start Session -> 说话 -> tutor 语音回应 -> End Session`。
- [ ] 真机验证 `smooth` 默认模式下，tutor 可以慢一点开口，但一句话内部应连续不卡顿。
- [ ] 真机验证 `End Session` 后音频资源释放，且可以重新开始新会话。
- [ ] 真机验证 Xcode `[test]` 日志能看到 network、LiveKit、audio、session、storage 关键证据。

## 待会逐步验证顺序

1. [ ] 在根目录运行 `./start_all.sh`。
2. [ ] 确认终端输出 `Backend API ready`、`Agent registered worker`、`All backend services ready`。
3. [ ] 确认 agent 启动日志里当前 profile 是 `smooth`，且 `tts_playback_mode=full_sentence`。
4. [ ] 另开终端运行 `./check_backend.sh`。
5. [ ] 确认 `/health`、`/session`、`/summary`、`/summary/incremental` 诊断通过。
6. [ ] Xcode 选择真机运行 App，并在 console 过滤 `[test]`。
7. [ ] App 初始状态检查：无上下黑边、按钮可见、默认不是 failed、tutor 不自动说话。
8. [ ] 点击 `Connect`，确认能连接 LiveKit，但 tutor 仍不说话。
9. [ ] 点击 `Start Session`，允许麦克风权限，确认麦克风 publish 成功。
10. [ ] 用语音说 3-5 句短句，确认 tutor 能语音回应。
11. [ ] 重点听感：`smooth` 可以慢一点开口，但一句话内部应完整、连续、不卡顿。
12. [ ] 观察 transcript 面板是否出现 `You` 和 `Tutor`。
13. [ ] 运行 `./check_audio_health.sh`，确认 `voice pipeline profile: smooth`。
14. [ ] 检查 `smooth-TTS buffer lines in latest profile section` 是否大于 0。
15. [ ] 检查 `slow-TTS flush lines`，理想是 0；如果大于 0，保留完整输出。
16. [ ] 点击 `End Session`，确认断开、释放麦克风、保存本地 summary。
17. [ ] 再次 `Connect -> Start Session`，确认可以重新开始。
18. [ ] 测试 `Reconnect`，确认失败/结束/前后台恢复后不会卡死。
19. [ ] 测试 `Clear History`，确认本地历史和 summary 可清除。
20. [ ] 测试后台模式：活跃会话中锁屏或切 App，再回前台，确认音频继续或可用 `Reconnect` 恢复。

## P1：强烈建议补齐或确认

- [x] tutor prompt 已限制短回复、鼓励式纠错、每轮一个重点和一个追问。
- [x] 已有轻量 transcript/event/log 面板。
- [x] 已有 reconnect 入口。
- [x] 已有本地 JSON/Codable session storage，保留最近 20 条，不保存 raw audio。
- [x] 已有本地 summary fallback 和可选 AI summary / incremental summary 路径。
- [x] 已有 Clear History。
- [ ] 真机确认 learner/tutor 双方 transcript 是否稳定展示；如果 LiveKit transcription delegate 不稳定，需要补 `lk.transcription` text-stream fallback。
- [ ] 真机确认 reconnect 在断网、agent 断开、前后台返回后的实际表现。
- [ ] 真机确认 summary 面板和本地历史保存/清除路径。

## 假设真机验证通过后的下一步

1. [ ] 更新 `workflow.md`，把已验证项从 pending 移到 verified。
2. [ ] 在 `workflow.md` 补充默认 `smooth` 的最终取舍：牺牲一点响应速度，换稳定流畅语音演示。
3. [ ] 做 secrets 安全检查，确认 `env`、`.env`、日志、README 没有真实 key/token。
4. [ ] 确认 `.env` 被 git ignore；如果 `env` 会提交，只能保留 placeholder。
5. [ ] 跑最终命令：`./check_backend.sh`。
6. [ ] 跑最终命令：`./check_audio_health.sh`。
7. [ ] 跑最终命令：`xcodebuild -project ios/AITutor.xcodeproj -scheme AITutor -configuration Debug -destination 'generic/platform=iOS' build`。
8. [ ] 检查 `git diff`，确认没有 `.venv`、`__pycache__`、真实日志、大文件或个人隐私内容进入提交。
9. [x] 补 `RUNBOOK.md`，覆盖后端启动失败、agent 不说话、iPhone 连不上本机、麦克风失败、语音卡顿、summary 不生成。
10. [ ] 更新 README 的最终验证结果、默认 `smooth` 模式、真机验证路径和已知限制。

## 功能类未实现或未完整实现

- [x] `RUNBOOK.md` 已补充为单独文件；覆盖启动、agent、真机网络、音频、转写、摘要和后台排障。
- [ ] 独立 Session History 页面未实现；目前只有主页面上的 latest summary / local record 相关展示。
- [ ] Practice mode selection 未实现；目前固定为 English speaking，没有 `Daily Conversation`、`Interview English`、`Travel English` 等模式入口。
- [ ] LiveKit transcription 的 fallback 还没实现；目前依赖 SDK transcription delegate，如果真机没有稳定收到 `You/Tutor` transcript，需要补 `lk.transcription` text-stream 处理。
- [x] iOS unit tests 已补充；覆盖 ViewModel 状态流、reconnect、storage latest-20、permission denied、DTO 和 failure state。
- [ ] 后端 pytest/CI 未实现；目前有诊断脚本，但没有标准测试套件和 CI。
- [ ] Summary quality control 未实现；当前有本地 fallback、AI final summary、AI incremental summary，但没有评分规则、摘要去重、质量校验。
- [ ] Session timer / speaking timer 未实现；目前可保存 duration，但页面没有明显计时器。
- [ ] Voice activity indicator 未实现；目前通过状态、日志和 transcript 观察，没有专门的听/说动画或音量指示。
- [ ] 设置页未实现；profile、backend URL、practice mode 等仍通过 env/build setting/scripts 控制。
- [ ] 用户名或学习目标输入未实现；当前 participant identity 自动生成，目标固定为英语口语练习。

## P2：加分项状态

- [x] 已声明 `UIBackgroundModes=audio`，并加入前后台、路由变化、音频中断诊断日志。
- [x] 已有 AI Summary Draft 渐进式摘要路径。
- [ ] 真机验证后台模式：锁屏/切 App 后仍能听到 tutor 或能清晰恢复。
- [ ] 真机验证前台恢复提示和 `Reconnect` 是否足够清楚。
- [ ] 当前没有独立 Session History 页面，只是在主页面展示 latest summary/history 相关内容；如时间允许可加一个简单历史列表。

## 延迟和音频质量 Todo

- [x] 已加入 `./check_audio_health.sh`，可统计 STT/EOU、LLM TTFT、TTS TTFB、播放延迟和 slow TTS flush。
- [x] 默认切到 `smooth`，优先解决“句中一顿一顿”的演示风险。
- [ ] 用新版默认 `smooth` 重启服务后，真机跑 3-5 轮并执行 `./check_audio_health.sh`。
- [ ] 记录 `smooth_tts_buffer`、`e2e_latency`、`llm_node_ttft`、`tts_node_ttfb`、`slow-TTS flush lines`。
- [ ] 如果 `smooth` 仍然听感卡顿，优先排查 iPhone 音频路由、网络和 LiveKit/Cartesia provider 侧生成，而不是继续调自定义 buffer。
- [ ] 如果 `smooth` 只是慢但流畅，保持默认；后续再为 `balanced` 做低延迟实验。

## 提交前收口

- [ ] 运行 `./start_all.sh`，确认输出 `Backend API ready`、`Agent registered worker`、`All backend services ready`。
- [ ] 运行 `./check_backend.sh`。
- [ ] 运行 `./check_audio_health.sh`。
- [ ] 运行 `xcodebuild -project ios/AITutor.xcodeproj -scheme AITutor -configuration Debug -destination 'generic/platform=iOS' build`。
- [ ] 检查 git diff，确认没有真实 LiveKit key、token、raw audio、个人隐私日志进入提交。
- [ ] 更新 `workflow.md` 的最终验证证据，把已真机验证的 pending 项移动到 verified。
