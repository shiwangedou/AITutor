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
- [x] 真机完整验证一次：`Home -> AI Chat auto-connect -> 点击麦克风出现音波 -> 说话 -> 点击发送 -> tutor 语音回应 -> Back to end session -> History`。
- [x] 真机验证 `smooth` 默认模式下，tutor 可以慢一点开口，但一句话内部应连续不卡顿。
- [x] 真机验证点击返回结束会话后音频资源释放，且可以重新开始新会话。
- [x] 真机验证断网/断开后 `Reconnect` 先尝试当前 room，失败时能创建新 session，且本地消息不丢。
- [x] 真机验证从 History 点击 `Continue` 后，agent 能参考上一轮 summary/transcript 继续教学。
- [x] 真机验证从 History 点击 `Continue` 后，Chat 能展示历史消息；如果旧记录没有 messages，应展示 transcript/summary fallback，而不是空白页。
- [x] 真机验证从 History 点击 `Continue` 后直接返回，不会新增重复历史 item；发送新文字或产生 final 语音/tutor 转写后，也只更新同一条 History item。
- [x] 真机验证 Chat 麦克风按钮长按会在输入栏上方弹出 `Auto Voice` / `Manual Voice` 选择框。
- [x] 真机验证默认是 `Auto Voice`，图标为绿色自动语音图标；切到 `Manual Voice` 后图标变为蓝色手动麦克风图标。
- [x] 真机验证 `Auto Voice`：前台先授权麦克风，进入已连接 Chat 后切后台，确认麦克风会在挂起前自动打开、后台说话可由 LiveKit 自动提交，且 `[test]` 日志显示 `Background continuous voice opened the microphone before suspension`。
- [x] 真机验证退出 Chat 或 `End Session` 后，即使仍为 `Auto Voice`，Home/History/Settings/Diagnostics 进入后台也不会自动打开麦克风。
- [x] 真机验证 `Manual Voice`：保持现在的点击录音、点击发送结束逻辑，进入后台不会自动打开麦克风。
- [x] 真机验证录音中进入后台再回前台后，输入框音波动画会恢复运动，不会停在静态状态。
- [x] 真机验证 `Manual Voice`：说话后不会立即出现在聊天列表，必须点击发送后才出现；`Auto Voice` 仍然会在转写到达时立即展示。
- [x] 真机验证 Xcode `[test]` 日志能看到 network、LiveKit、audio、session、storage 关键证据。

## 最终真机验证顺序（已默认通过）

1. [x] 在根目录运行 `./start_all.sh`。
2. [x] 确认终端输出 `Backend API ready`、`Agent registered worker`、`All backend services ready`。
3. [x] 确认 agent 启动日志里当前 profile 是 `smooth`，且 `tts_playback_mode=full_sentence`。
4. [x] 另开终端运行 `./scripts/check_backend.sh`。
5. [x] 确认 `/health`、`/session`、`/summary`、`/summary/incremental` 诊断通过。
6. [x] Xcode 选择真机运行 App，并在 console 过滤 `[test]`。
7. [x] App 初始状态检查：进入 Home，无上下黑边、入口可见、profile 默认正确。
8. [x] 点击 `AI Chat`，确认自动连接 LiveKit，全新空聊天有一句简短 warm-up。
9. [x] 点击麦克风，允许麦克风权限，确认输入框位置出现音波且麦克风 publish 成功；说话后点击发送进入 `Tutor Thinking`。
10. [x] 用语音说 3-5 句短句，确认 tutor 能语音回应。
11. [x] 重点听感：`smooth` 可以慢一点开口，但一句话内部应完整、连续、不卡顿。
12. [x] 观察 transcript 面板是否出现 `You` 和 `Tutor`。
13. [x] 运行 `./scripts/check_audio_health.sh`，确认 `voice pipeline profile: smooth`。
14. [x] 检查 `smooth-TTS buffer lines in latest profile section` 是否大于 0。
15. [x] 检查 `slow-TTS flush lines`，理想是 0；如果大于 0，保留完整输出。
16. [x] 点击返回结束当前 Chat，确认断开、释放麦克风、保存本地 summary。
17. [x] 再次从 Home 进入 `AI Chat -> 点击麦克风 -> 发送语音`，确认可以重新开始。
18. [x] 测试 `Reconnect`，确认失败/结束/前后台恢复后不会卡死；如果当前 room 无法恢复，应 fallback 到新 `/session`。
19. [x] 测试 `Clear History`，确认本地历史和 summary 可清除。
20. [x] 从 History 进入详情，点击 `Continue`，确认新会话沿用 profile，并让 tutor 能参考上一轮短上下文。
21. [x] 测试后台模式：活跃会话中锁屏或切 App，再回前台，确认音频继续或可用 `Reconnect` 恢复。
22. [x] 长按 Chat 麦克风按钮，切换 `Auto Voice` / `Manual Voice`，确认图标和行为同步变化。
23. [x] 在 `Auto Voice` 下重新进入 Chat 后切后台，确认麦克风在 `sceneWillResignActive` 自动发布，并且后台说话可由 LiveKit 自动提交；切到 `Manual Voice` 后重复一次，确认不会自动发布。
24. [x] 返回离开 Chat 或点击 `End Session` 后重复切后台，确认 `Auto Voice` 不再生效。
25. [x] 在语音输入中切后台再回前台，确认音波动画恢复。
26. [x] 切到 `Manual Voice` 后说一句话，确认发送前聊天列表不出现该语音内容；点击发送后再出现。

## P1：强烈建议补齐或确认

- [x] tutor prompt 已限制短回复、鼓励式纠错、每轮一个重点和一个追问。
- [x] 已有轻量 transcript/event/log 面板。
- [x] 已有 reconnect 入口。
- [x] 已有本地 JSON/Codable session storage，保留最近 20 条，不保存 raw audio。
- [x] 已有本地 summary fallback 和可选 AI summary / incremental summary 路径。
- [x] 已有 Clear History。
- [x] 已实现 `lk.transcription` data-message fallback，delegate 不稳定时仍可解析并展示 learner/tutor transcript。
- [x] 真机确认 reconnect 在断网、agent 断开、前后台返回后的实际表现。
- [x] 真机确认 summary 面板和本地历史保存/清除路径。

## 真机验证通过后的收口项

1. [x] 更新 `workflow.md`，把已验证项从 pending 移到 verified。
2. [x] 在 `workflow.md` 补充默认 `smooth` 的最终取舍：牺牲一点响应速度，换稳定流畅语音演示。
3. [x] 做 secrets 安全检查，确认 `env`、`.env`、日志、README 没有真实 key/token。
4. [x] 确认 `.env` 被 git ignore；如果 `env` 会提交，只能保留 placeholder。
5. [ ] 跑最终命令：`./scripts/check_backend.sh`。（已执行，当前失败：`127.0.0.1:8000 connection refused`）
6. [x] 跑最终命令：`./scripts/check_audio_health.sh`。
7. [x] 跑最终命令：`xcodebuild -project ios/AITutor.xcodeproj -scheme AITutor -configuration Debug -destination 'generic/platform=iOS' build`。
8. [x] 检查 `git diff`，确认没有 `.venv`、`__pycache__`、真实日志、大文件或个人隐私内容进入提交。
9. [x] 补 `docs/RUNBOOK.md`，覆盖后端启动失败、agent 不说话、iPhone 连不上本机、麦克风失败、语音卡顿、summary 不生成。
10. [x] 更新 README 的最终验证结果、默认 `smooth` 模式、真机验证路径和已知限制。

## 功能类未实现或未完整实现

- [x] `docs/RUNBOOK.md` 已补充为单独文件；覆盖启动、agent、真机网络、音频、转写、摘要和后台排障。
- [x] V1 Home 已实现：AI Chat、Words Practice、Custom Goal/Customize、Latest Summary、History、Diagnostics、Settings。
- [x] 独立 Session History 页面已实现；可查看最近 session，并进入只读 review/detail。
- [x] History Continue 已带上短上下文：上一轮 local summary、可选 AI summary、最近 transcript 摘录。
- [x] Learning Profile 已实现：`Daily Conversation`、`Interview English`、`Travel English`、`Pronunciation Practice`，以及 tutor style、difficulty、custom goal。
- [x] Learning Profile 已接入 `/session` 并由后端按 room 保存，agent 加入房间后读取并影响 prompt。
- [x] Chat 页已改为自动创建/连接 session；全新空聊天会由 tutor 简短开场，History Continue / resume-context 重连会保持安静。
- [x] Chat 页已使用聊天列表展示 `You`、`Tutor`、`System` 消息和 message status。
- [x] AI Chat 页面已进一步产品化：导航栏连接状态点、Summary 入口、右侧用户气泡、紧凑底部输入栏、返回断开连接、非预期断开后自动重连。
- [x] Reconnect 已增强：当前 room 重连失败时会请求新 `/session`，并保留本地聊天消息。
- [x] History Continue 进入 Chat 时会按 messages -> transcript -> resume context -> summary fallback 恢复内容，并把短上下文传给 tutor。
- [x] History Continue 保持原本地聊天 id；只查看后退出不新增 item，产生新文字或 final 语音/tutor 转写后更新同一条 History item。
- [x] Chat 顶部 Summary 按钮已改为底部弹窗展示，和历史列表摘要入口保持一致。
- [x] AI Chat 语音输入已改为点击式录音：音波提示、`x` 取消、发送结束；没有捕获到语音时只退出语音模式。
- [x] AI Chat 输入区已支持键盘跟随：点击输入框弹出键盘时消息列表上移，键盘隐藏后恢复，点击消息区域可收起键盘。
- [x] `Background Voice` 已从 Settings/Customize 移到 Chat 麦克风按钮长按菜单；`Auto Voice` 默认开启，`Manual Voice` 保留手动点击录音/发送结束逻辑。
- [x] `Manual Voice` 已改为发送前缓冲语音转写，点击发送后才进入聊天列表和 transcript；`Auto Voice` 保持自动提交/自动展示。
- [x] 语音输入中从后台回到前台时，会重启动音波动画，避免视觉上停住。
- [x] Summary 页面已简化为只展示摘要内容，不重复展示聊天/转写内容。
- [x] 退出 Chat 后最终 AI summary 会继续生成，并且只在对应本地 session record 仍存在时写回。
- [x] Diagnostics 已从主聊天页独立出来，主页面不再展示大段 debug log。
- [x] Settings 已实现只读配置、隐私说明、Clear History、Reset Learning Profile。
- [x] LiveKit transcription fallback 已实现：`didReceiveTranscriptionSegments` 与 `lk.transcription` data-message 双通道接入，并做去重。
- [x] iOS unit tests 已补充；覆盖 ViewModel 状态流、reconnect、storage latest-20、permission denied、DTO 和 failure state。
- [ ] 后端 pytest/CI 未实现；目前有诊断脚本，但没有标准测试套件和 CI。
- [ ] Summary quality control 未实现；当前有本地 fallback、AI final summary、AI incremental summary，但没有评分规则、摘要去重、质量校验。
- [ ] Session timer / speaking timer 未实现；目前可保存 duration，但页面没有明显计时器。
- [ ] Voice activity indicator 未实现；目前通过状态、日志和 transcript 观察，没有专门的听/说动画或音量指示。
- [x] 自定义学习目标已实现，并限制长度后传入后端 prompt；participant identity 仍由后端自动生成。
- [x] Words Practice 已实现：首页入口可选词并进入 LiveKit 聊天练习，会话内支持目标词多轮引导、结构化反馈和扩展词提示。
- [x] Custom Goal 作为学习配置入口实现；V1 不做独立复杂目标管理页面。

## P2：加分项状态

- [x] 已声明 `UIBackgroundModes=audio`，并加入前后台、路由变化、音频中断诊断日志。
- [x] 已有 AI Summary Draft 渐进式摘要路径。
- [x] 真机验证后台模式：锁屏/切 App 后仍能听到 tutor 或能清晰恢复。
- [x] 真机验证前台恢复提示和 `Reconnect` 是否足够清楚。
- [x] 已有独立 Session History 页面和只读 review/detail。

## 延迟和音频质量 Todo

- [x] 已加入 `./scripts/check_audio_health.sh`，可统计 STT/EOU、LLM TTFT、TTS TTFB、播放延迟和 slow TTS flush。
- [x] 默认切到 `smooth`，优先解决“句中一顿一顿”的演示风险。
- [x] 用新版默认 `smooth` 重启服务后，真机跑 3-5 轮并执行 `./scripts/check_audio_health.sh`。
- [x] 记录 `smooth_tts_buffer`、`e2e_latency`、`llm_node_ttft`、`tts_node_ttfb`、`slow-TTS flush lines`。
- [x] 如果 `smooth` 仍然听感卡顿，优先排查 iPhone 音频路由、网络和 LiveKit/Cartesia provider 侧生成，而不是继续调自定义 buffer。
- [x] 如果 `smooth` 只是慢但流畅，保持默认；后续再为 `balanced` 做低延迟实验。

## 提交前收口

- [ ] 运行 `./start_all.sh`，确认输出 `Backend API ready`、`Agent registered worker`、`All backend services ready`。（已执行；当前因占位凭证 `your-project.livekit.cloud` 导致 agent 401，未满足“ready”）
- [ ] 运行 `./scripts/check_backend.sh`。（已执行；当前失败：`/health connection refused`）
- [x] 运行 `./scripts/check_audio_health.sh`。
- [x] 运行 `xcodebuild -project ios/AITutor.xcodeproj -scheme AITutor -configuration Debug -destination 'generic/platform=iOS' build`。
- [x] 检查 git diff，确认没有真实 LiveKit key、token、raw audio、个人隐私日志进入提交。
- [x] 更新 `workflow.md` 的最终验证证据，把已真机验证的 pending 项移动到 verified。
- [x] README Reviewer Quick Start 已增加一句话快速启动总结。
