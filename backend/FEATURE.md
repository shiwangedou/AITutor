# Backend and Agent Feature

## 1. Purpose
Provide the minimal backend and LiveKit voice agent needed for the realtime English speaking tutor.

中文：提供实时英语口语家教所需的最小后端和 LiveKit 语音 agent。

## 2. Entry Points
- Backend API: `main.py`
- Token generation: `token_service.py`
- Voice agent: `agent.py`
- Diagnostics: `tests/diagnose_backend.py`
- Dev scripts: `scripts/setup.sh`, `scripts/start_api.sh`, `scripts/start_agent.sh`, `scripts/start_all.sh`

## 3. Main Flow / Logic
1. iOS calls backend `POST /session`.
2. Backend creates a LiveKit participant token and room name.
3. iOS joins the returned LiveKit room.
4. LiveKit Agents runtime dispatches `agent.py` into the room.
5. Agent uses LiveKit Inference STT, LLM, and TTS to run the English speaking tutor loop.
6. Local demo startup is handled by scripts that prepare `.venv`, download model files, and run API + agent processes.

中文：
1. iOS 调用后端 `POST /session`。
2. 后端生成 LiveKit participant token 和 room name。
3. iOS 加入返回的 LiveKit 房间。
4. LiveKit Agents runtime 将 `agent.py` 分配到房间。
5. Agent 使用 LiveKit Inference 的 STT、LLM、TTS 运行英语口语家教闭环。
6. 本地 demo 启动由脚本处理：准备 `.venv`、下载模型文件、运行 API 和 agent 进程。

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
- Diagnostics failure -> run `python tests/diagnose_backend.py --verbose` and inspect the failing section.
- Startup failure -> run `./scripts/setup.sh`, confirm root `.env`, then rerun `./scripts/start_all.sh`.

## 6. Dependencies
- `fastapi`
- `uvicorn`
- `python-dotenv`
- `livekit-api`
- `livekit-agents[silero,turn-detector]`

## 7. Change Log
- 2026-05-06: Added real LiveKit Agents scaffold using LiveKit Inference STT/LLM/TTS.
- 2026-05-06: Added backend diagnostics script with structured logs.
- 2026-05-06: Added backend setup/start scripts for local demo startup.
- 2026-05-08: Added low-latency model tuning (`STT_MODEL`, `LLM_MODEL`, `LLM_MAX_TOKENS`, `PREEMPTIVE_TTS`, `TTS_*`), switched defaults to `deepgram/flux-general`, `openai/gpt-4.1-nano`, and `cartesia/sonic-turbo`, enabled latency metrics, and tightened tutor replies to reduce slow feedback.
