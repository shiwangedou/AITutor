# Todo

## Plan 补充项

- [ ] 明确 STT/LLM/TTS 使用哪家服务（LiveKit Inference vs OpenAI/Deepgram 等），以及选择原因
- [ ] 说明 Agent dispatch 机制：agent 用 WorkerOptions 监听新 room 自动 dispatch，还是由 backend 主动触发
- [ ] 说明 iOS BackendClient 的 URL 策略：127.0.0.1:8000 是 local dev 默认值，真机测试需要通过 build setting 或配置项指定

## 实现补充项

- [ ] agent.py：实现真实 livekit-agents voice pipeline（STT → LLM → TTS）
- [ ] LiveKitService.swift：接入真实 LiveKit iOS SDK（Room / LocalAudioTrack / 事件回调）
- [ ] requirements.txt：添加 livekit-agents 及对应 plugin
- [ ] ios/project.yml：添加 LiveKit iOS SDK SPM 依赖
- [ ] README：补充 agent 进程的独立启动步骤

## 延迟优化 Todo

当前日志基线：

- [x] 已加入 `./check_audio_health.sh`，可统计 STT/EOU、LLM TTFT、TTS TTFB、播放延迟和 slow TTS flush。
- [x] 当前 TTS 卡顿已明显改善：`slow-TTS flush lines: 0`。
- [x] 当前播放链路不是瓶颈：`playback_latency` 接近 `0s`。
- [ ] 当前端到端反馈仍偏慢：`e2e_latency avg ~= 2.75s, max ~= 3.55s`。

优先级 P0：先优化最大瓶颈 LLM 首 token。

- [ ] 调研 LiveKit Inference 中更低延迟的 LLM model，目标让 `llm_node_ttft avg < 1.0s`。
- [ ] 如果模型切换收益不够，考虑口语练习的模板化短回复策略：简单寒暄、鼓励、常见纠错可由规则生成，复杂情况再走 LLM。
- [ ] 保持 `LLM_MAX_TOKENS` 小于等于 `60`，必要时继续降低到 `40`，观察回答质量和 `llm_node_ttft`。
- [ ] 在 README 记录 LLM 选择 tradeoff：低延迟优先于复杂推理能力，因为这是实时口语 tutor demo。

优先级 P1：继续压 STT / endpointing。

- [ ] 当前 `end_of_turn_delay avg ~= 0.86s, max ~= 1.23s`，可尝试把 `STT_EOT_TIMEOUT_MS` 从 `700` 降到 `500`。
- [ ] 如果用户短句测试稳定，再尝试 `STT_EOT_TIMEOUT_MS=400`。
- [ ] 验证风险：timeout 太低可能导致用户还没说完 agent 就抢答。
- [ ] 验证指标：`end_of_turn_delay avg < 0.6s`，同时不要出现明显抢答。

优先级 P2：保留 TTS 当前配置，除非再次出现卡顿。

- [ ] 当前 `tts_node_ttfb avg ~= 0.43s`，无需优先优化。
- [ ] 保持 `TTS_MODEL=cartesia/sonic-turbo`、`TTS_SPEED=normal`、`TTS_MAX_BUFFER_DELAY_MS=300`。
- [ ] 如果再次出现 `slow-TTS flush lines > 0`，优先继续缩短 tutor 回复长度或换更低延迟 voice。

优先级 P3：优化首次进入房间冷启动。

- [ ] 当前首次进入房间包含 agent job/process/audio pipeline/AEC warmup 准备成本，约数秒级。
- [ ] 调研是否能 warm worker / 预热 agent process，减少 `no warmed process available`。
- [ ] 评估是否能降低或跳过部分 recording/reporting 开销，但不能影响挑战要求和 LiveKit agent 稳定性。

每次调参后的验证步骤：

- [ ] 重启 `./start_all.sh`，确保 agent 加载新 env。
- [ ] 真机跑一轮：`Connect -> Start Session -> 说 3-5 个短句`。
- [ ] 执行 `./check_audio_health.sh`。
- [ ] 记录这几项：`e2e_latency`、`llm_node_ttft`、`end_of_turn_delay`、`tts_node_ttfb`、`slow-TTS flush lines`。
