# Backend and Agent Feature

## 1. Purpose
Provide the minimal backend, LiveKit voice agent, and optional post-session summary endpoint needed for the realtime English speaking tutor.

中文：提供实时英语口语家教所需的最小后端、LiveKit 语音 agent 和可选课后摘要接口。

## 2. Entry Points
- Backend API: `main.py`
- Learning profile normalization/store: `learning_profile.py`
- Token generation: `token_service.py`
- Voice agent: `agent.py`
- Diagnostics: `tests/diagnose_backend.py`
- Dev scripts: `scripts/setup.sh`, `scripts/start_api.sh`, `scripts/start_agent.sh`, `scripts/start_all.sh`

## 3. Main Flow / Logic
1. iOS calls backend `POST /session`.
2. Request may include `learning_mode`, `tutor_style`, `difficulty`, `custom_goal`, and optional `resume_context` from a previous local session.
3. Backend normalizes the learning profile and resume context, creates a LiveKit participant token and room name, and stores both keyed by room name.
4. iOS joins the returned LiveKit room. For a fresh empty chat, the agent gives one short warm-up opener; for History Continue or reconnect fallback with resume context, the agent waits for learner input.
5. LiveKit Agents runtime dispatches `agent.py` into the room.
6. Agent loads the room's learning profile plus short resume context and injects both into the English tutor prompt.
7. Agent uses LiveKit Inference STT, LLM, and TTS to run the English speaking tutor loop.
8. Agent chooses a startup-only voice profile from `VOICE_PIPELINE_PROFILE`.
9. `smooth` is the default demo profile and buffers each short TTS sentence before playback; `balanced` uses LiveKit's default streaming TTS path with very short replies; `realtime` uses LiveKit's default streaming TTS node with interruption enabled.
10. During a session, iOS can call `POST /summary/incremental` with the previous running summary, new transcript turns, and learning profile.
11. When iOS ends a session, it can call `POST /summary` with transcript text, the latest running summary, and learning profile.
12. Backend uses LiveKit Inference LLM to generate concise JSON summaries when available.
13. If AI summary generation fails, backend returns deterministic fallback summaries so local demo flow remains reliable.
14. Local demo startup is handled by scripts that prepare `.venv`, download model files, and run API + agent processes.

中文：
1. iOS 调用后端 `POST /session`。
2. 请求可以包含 `learning_mode`、`tutor_style`、`difficulty`、`custom_goal`，以及来自上一次本地会话的可选 `resume_context`。
3. 后端标准化学习配置和继续学习上下文，生成 LiveKit participant token 和 room name，并按 room name 保存 profile 与上下文。
4. iOS 加入返回的 LiveKit 房间；全新空聊天由 agent 给一句简短 warm-up，History Continue 或带 resume context 的重连会保持安静等待学习者输入。
5. LiveKit Agents runtime 将 `agent.py` 分配到房间。
6. Agent 读取该 room 的学习配置和短上下文，并注入英语 tutor prompt。
7. Agent 使用 LiveKit Inference 的 STT、LLM、TTS 运行英语口语家教闭环。
8. Agent 会在启动时根据 `VOICE_PIPELINE_PROFILE` 选择语音 profile。
9. `smooth` 是默认演示 profile，会在播放前缓冲完整短句 TTS；`balanced` 使用 LiveKit 默认流式 TTS 路径和极短回复；`realtime` 使用 LiveKit 默认流式 TTS 节点并允许打断。
10. 会话中，iOS 可以向 `POST /summary/incremental` 发送 previous running summary、新增 transcript turns 和学习配置。
11. iOS 结束会话时，可以向 `POST /summary` 发送 transcript 文本、最新 running summary 和学习配置。
12. 后端优先使用 LiveKit Inference LLM 生成简短 JSON 摘要。
13. 如果 AI 摘要生成失败，后端返回确定性的 fallback 摘要，保证本地 demo 流程可靠。
14. 本地 demo 启动由脚本处理：准备 `.venv`、下载模型文件、运行 API 和 agent 进程。

## 4. State Model
- Backend idle: API server is running.
- Session issued: `/session` returned room/token payload.
- Agent waiting: agent process is running in dev mode.
- Agent active: LiveKit dispatches the agent into a room.
- Failure: missing env config, token failure, SDK import/runtime failure, or room dispatch failure.

## 5. Error Handling
- Missing LiveKit config -> backend returns a clear 500 error.
- Agent import/runtime failure -> inspect installed LiveKit Agents SDK version and official docs.
- Agent not responding -> verify agent process is running and joins the same LiveKit project/room.
- Incremental or final summary failure -> backend returns fallback summary; inspect API logs for the provider error type.
- Repeated slow voice output -> inspect `[profile]`, `[latency]`, STT timeout, and adaptive interruption lines; default `smooth` is the most stable demo path, `balanced` is the later tuning compromise, and `realtime` is the lowest-latency option.
- Diagnostics failure -> run `python tests/diagnose_backend.py --verbose` and inspect the failing section.
- Summary diagnostics failure -> verify backend API is running, `SUMMARY_LLM_*` config is set as expected, and fallback summary responses still return the required JSON shape.
- Learning profile missing -> backend falls back to `Daily Conversation / Gentle Coach / Intermediate`, so demo flow still works.
- Resume context missing or malformed -> backend ignores it and starts a normal new session.
- Startup failure -> run `./scripts/setup.sh`, confirm root `.env`, then rerun `./scripts/start_all.sh`.

## 6. Dependencies
- `fastapi`
- `uvicorn`
- `python-dotenv`
- `livekit-api`
- `livekit-agents[silero,turn-detector]`

## 7. Change Log
- 2026-05-11: Added Words Practice prompt protocol when `custom_goal` starts with `Words Practice:` so tutor outputs structured score/correction/better-sentence/next-challenge feedback and includes expansion words.
- 2026-05-11: Added fresh-chat proactive warm-up opener while keeping History Continue and resume-context reconnects quiet.
- 2026-05-11: Added optional `/session` resume context so History Continue can give the agent a short previous-session summary/transcript background without raw audio.
- 2026-05-09: Added learning profile normalization, room-keyed profile storage, `/session` profile response, and profile-aware agent/summary prompts.
- 2026-05-08: Added `POST /summary` with LiveKit Inference LLM generation and deterministic fallback summary.
- 2026-05-08: Removed the unsuccessful `legacy` experiment and retuned `balanced` back to the SDK default streaming TTS path with shorter replies and `cartesia/sonic-3`.
- 2026-05-08: Set `VOICE_PIPELINE_PROFILE=smooth` as the default demo profile; balanced remains available for later latency tuning and realtime remains the lowest-latency option.
- 2026-05-08: Added `POST /summary/incremental` for running summary draft updates.
- 2026-05-08: Extended backend diagnostics to smoke-check `/summary` and `/summary/incremental` response shape when the API server is running.
- 2026-05-06: Added real LiveKit Agents scaffold using LiveKit Inference STT/LLM/TTS.
- 2026-05-06: Added backend diagnostics script with structured logs.
- 2026-05-06: Added backend setup/start scripts for local demo startup.
