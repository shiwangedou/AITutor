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
