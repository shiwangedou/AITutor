# AITutor Runbook

中文：AITutor 故障排查手册

## Purpose

This runbook is the first place to check when the demo does not start, the iPhone cannot connect, the agent does not speak, audio is choppy, transcripts are missing, or summaries do not update.

中文：当 demo 无法启动、iPhone 连不上、agent 不说话、语音卡顿、转写缺失或摘要不更新时，优先查看这份排障手册。

## Golden Path

1. Copy root `env.example` to `env` and fill LiveKit values.
2. Run `./start_all.sh` from the repository root.
3. Wait for `Backend API ready`, `Agent registered worker`, and `All backend services ready`.
4. Run `./scripts/check_backend.sh` in another terminal.
5. Run the iOS app on a physical iPhone from Xcode.
6. In the app: `Connect -> Start Session -> speak -> wait for tutor voice -> End Session`.
7. If audio quality is being checked, run `./scripts/check_audio_health.sh` after a 3-5 turn session.

中文：
1. 将根目录 `env.example` 复制为 `env` 并填写 LiveKit 配置。
2. 在仓库根目录运行 `./start_all.sh`。
3. 等待看到 `Backend API ready`、`Agent registered worker`、`All backend services ready`。
4. 另开终端运行 `./scripts/check_backend.sh`。
5. 用 Xcode 在真机运行 iOS App。
6. App 内执行：`Connect -> Start Session -> 说话 -> 等待 tutor 语音回应 -> End Session`。
7. 如果要检查语音质量，完成 3-5 轮对话后运行 `./scripts/check_audio_health.sh`。

## Logs And Diagnostics

- Backend API log: `logs/api.log`
- LiveKit agent log: `logs/agent.log`
- Clear runtime logs: `./scripts/clear_logs.sh`
- Backend diagnostics: `./scripts/check_backend.sh`
- Audio diagnostics: `./scripts/check_audio_health.sh`
- Xcode debug filter: `[test]`

Do not paste real tokens, API keys, API secrets, raw audio, or full private transcripts into issues or review notes.

中文：
- 后端 API 日志：`logs/api.log`
- LiveKit agent 日志：`logs/agent.log`
- 清空运行日志：`./scripts/clear_logs.sh`
- 后端诊断：`./scripts/check_backend.sh`
- 音频诊断：`./scripts/check_audio_health.sh`
- Xcode 调试过滤：`[test]`

不要把真实 token、API key、API secret、原始音频或完整私人转写粘贴到 issue 或 review 说明里。

## Backend Does Not Start

Symptoms:
- `address already in use`
- `/health request failed`
- `Connection refused`

Checks:
1. Confirm no old backend is still bound to port `8000`.
2. Run `lsof -i :8000` and stop the stale process if needed.
3. Re-run `./start_all.sh`.
4. If Python dependencies fail, run `cd backend && ./scripts/setup.sh`.

中文：
症状：
- `address already in use`
- `/health request failed`
- `Connection refused`

检查：
1. 确认没有旧后端进程占用 `8000`。
2. 运行 `lsof -i :8000`，必要时停止旧进程。
3. 重新运行 `./start_all.sh`。
4. 如果 Python 依赖失败，运行 `cd backend && ./scripts/setup.sh`。

## Agent Does Not Register

Symptoms:
- No `Agent registered worker`
- Agent log exits immediately
- LiveKit room has user but no tutor

Checks:
1. Confirm `LIVEKIT_URL`, `LIVEKIT_API_KEY`, and `LIVEKIT_API_SECRET` are set in root `env`.
2. Confirm `LIVEKIT_URL` starts with `wss://`.
3. Confirm the API key and secret belong to the same LiveKit project as the iOS app.
4. Check `logs/agent.log` for import errors, authentication errors, or model download errors.
5. Re-run `./scripts/check_backend.sh` after the agent is started.

中文：
症状：
- 没有 `Agent registered worker`
- agent 日志很快退出
- LiveKit 房间里有用户但没有 tutor

检查：
1. 确认根目录 `env` 设置了 `LIVEKIT_URL`、`LIVEKIT_API_KEY`、`LIVEKIT_API_SECRET`。
2. 确认 `LIVEKIT_URL` 以 `wss://` 开头。
3. 确认 API key 和 secret 属于 iOS App 使用的同一个 LiveKit project。
4. 查看 `logs/agent.log` 是否有 import、认证或模型下载错误。
5. agent 启动后重新运行 `./scripts/check_backend.sh`。

## Duplicate Tutor Voices

Symptoms:
- Two tutor voices speak at once
- Agent replies twice
- Startup warns about an existing agent process

Checks:
1. Stop old terminals running `agent.py dev`.
2. If needed, use `ps aux | rg "agent.py dev"` to find stale agents.
3. Stop stale agent processes before starting again.
4. Run only one `./start_all.sh` session per LiveKit project during demo.

中文：
症状：
- 两个 tutor 声音同时说话
- agent 回复两次
- 启动时提示已有 agent 进程

检查：
1. 关闭旧终端里的 `agent.py dev`。
2. 必要时用 `ps aux | rg "agent.py dev"` 找旧 agent。
3. 先停止旧 agent，再重新启动。
4. demo 时同一个 LiveKit project 只保留一个 `./start_all.sh` 会话。

## iPhone Cannot Reach Backend

Symptoms:
- App state becomes `Backend Failed`
- Xcode `[test] POST /session` fails
- iPhone works on simulator but not physical device

Checks:
1. Confirm iPhone and Mac are on the same Wi-Fi.
2. Confirm `BACKEND_BASE_URL` is `http://<Mac LAN IP>:8000`, not `127.0.0.1`.
3. Run `IOS_BACKEND_BASE_URL=http://<Mac LAN IP>:8000 ios/scripts/configure_backend_url.sh` if needed.
4. Confirm macOS firewall allows incoming Python/Uvicorn connections.
5. From the Mac, run `curl http://<Mac LAN IP>:8000/health`.

中文：
症状：
- App 状态变成 `Backend Failed`
- Xcode `[test] POST /session` 失败
- 模拟器可以但真机不行

检查：
1. 确认 iPhone 和 Mac 在同一 Wi-Fi。
2. 确认 `BACKEND_BASE_URL` 是 `http://<Mac 局域网 IP>:8000`，不是 `127.0.0.1`。
3. 必要时运行 `IOS_BACKEND_BASE_URL=http://<Mac LAN IP>:8000 ios/scripts/configure_backend_url.sh`。
4. 确认 macOS 防火墙允许 Python/Uvicorn 入站连接。
5. 在 Mac 上运行 `curl http://<Mac LAN IP>:8000/health`。

## Microphone Or Audio Engine Fails

Symptoms:
- App state becomes `Mic Permission Failed`
- App state becomes `Audio Session Failed`
- App state becomes `Mic Publish Failed`
- Xcode logs mention audio route or microphone publish errors

Checks:
1. Confirm iOS Settings allows microphone access for AITutor.
2. Use a physical iPhone for voice validation; simulator microphone behavior is less reliable.
3. Watch Xcode `[test]` logs for permission, route, category, mode, sample rate, and publish result.
4. Disconnect Bluetooth headsets if route behavior looks strange.
5. Tap `Reconnect`, then `Start Session` again.

中文：
症状：
- App 状态变成 `Mic Permission Failed`
- App 状态变成 `Audio Session Failed`
- App 状态变成 `Mic Publish Failed`
- Xcode 日志出现音频路由或麦克风发布错误

检查：
1. 确认 iOS 设置允许 AITutor 使用麦克风。
2. 语音验证优先使用真机；模拟器麦克风行为不稳定。
3. 查看 Xcode `[test]` 日志里的权限、路由、category、mode、sample rate、publish 结果。
4. 如果音频路由异常，先断开蓝牙耳机。
5. 点击 `Reconnect`，再点击 `Start Session`。

## Tutor Speaks Too Early

Expected behavior:
- `Connect` should only join LiveKit.
- `Start Session` should request microphone permission, publish the microphone, and trigger the tutor warm-up.

Checks:
1. If the tutor speaks immediately after `Connect`, check for old agent processes or duplicate rooms.
2. Confirm iOS sends the start signal only from `LiveKitAgentClient.startConversation()`.
3. Confirm the agent prompt does not auto-greet on room join.

中文：
预期行为：
- `Connect` 只加入 LiveKit。
- `Start Session` 才请求麦克风权限、发布麦克风并触发 tutor warm-up。

检查：
1. 如果 `Connect` 后 tutor 立刻说话，先检查是否有旧 agent 进程或重复房间。
2. 确认 iOS 只在 `LiveKitAgentClient.startConversation()` 中发送开始信号。
3. 确认 agent prompt 没有设置入房自动问候。

## Tutor Does Not Respond

Symptoms:
- App connects and microphone publishes, but tutor stays silent
- Transcript has learner text but no tutor response

Checks:
1. Confirm `Agent registered worker` exists in `logs/agent.log`.
2. Confirm iOS `[test]` log room name matches `/session` and agent project.
3. Confirm `Start Session` was tapped after `Connect`.
4. Try text input once; if text works but voice does not, focus on microphone publish or STT.
5. Check `logs/agent.log` for STT, LLM, TTS, or model errors.

中文：
症状：
- App 已连接且麦克风已发布，但 tutor 不说话
- transcript 有 learner 内容但没有 tutor 回复

检查：
1. 确认 `logs/agent.log` 有 `Agent registered worker`。
2. 确认 iOS `[test]` 日志里的 room name 和 `/session`、agent project 一致。
3. 确认 `Connect` 后点击过 `Start Session`。
4. 尝试发送一次文字；如果文字有效但语音无效，重点排查麦克风 publish 或 STT。
5. 查看 `logs/agent.log` 是否有 STT、LLM、TTS 或模型错误。

## Choppy Tutor Voice

Default demo policy:
- `VOICE_PIPELINE_PROFILE=smooth`
- The tutor may start later, but each sentence should be clearer and more continuous.

Checks:
1. Confirm root `env` uses `VOICE_PIPELINE_PROFILE=smooth`.
2. Restart with `./start_all.sh`.
3. Run a 3-5 turn real-device session.
4. Run `./scripts/check_audio_health.sh`.
5. If smooth still sounds choppy, keep the full audio-check output and inspect iPhone network, route, and LiveKit provider latency.

Profile guidance:
- `smooth`: best for demo clarity and full-sentence playback.
- `balanced`: experimental middle ground.
- `realtime`: lower latency, but can expose streaming TTS flush/chunking.

中文：
默认 demo 策略：
- `VOICE_PIPELINE_PROFILE=smooth`
- tutor 可以晚一点开口，但每句话内部应该更清晰、更连续。

检查：
1. 确认根目录 `env` 使用 `VOICE_PIPELINE_PROFILE=smooth`。
2. 重新运行 `./start_all.sh`。
3. 真机完成 3-5 轮对话。
4. 运行 `./scripts/check_audio_health.sh`。
5. 如果 smooth 仍卡顿，保留完整 audio-check 输出，并检查 iPhone 网络、音频路由和 LiveKit provider 延迟。

模式建议：
- `smooth`：最适合 demo，优先清晰和整句播放。
- `balanced`：实验性的中间方案。
- `realtime`：延迟更低，但可能暴露流式 TTS flush/分块风险。

## Transcript Missing

Symptoms:
- Voice works, but transcript panel is empty or one-sided

Checks:
1. Confirm the agent is publishing transcription events.
2. Check Xcode `[test]` logs for `Transcript You` or `Transcript Tutor`.
3. Use text input as a fallback to verify UI transcript rendering.
4. If LiveKit transcription delegate is inconsistent, add an `lk.transcription` text-stream fallback before submission hardening.

中文：
症状：
- 语音可用，但 transcript 面板为空或只有一方内容

检查：
1. 确认 agent 正在发布 transcription events。
2. 在 Xcode `[test]` 日志中搜索 `Transcript You` 或 `Transcript Tutor`。
3. 用文字输入作为 fallback，确认 UI transcript 渲染没问题。
4. 如果 LiveKit transcription delegate 不稳定，提交前补 `lk.transcription` text-stream fallback。

## Summary Does Not Generate

Expected behavior:
- Local summary is saved immediately at `End Session`.
- AI final summary is best-effort and depends on transcript text and backend summary endpoint.
- Incremental draft appears only after enough final transcript turns.

Checks:
1. Confirm transcript has final learner/tutor turns before ending.
2. Confirm `/summary` and `/summary/incremental` pass in `./scripts/check_backend.sh`.
3. Check Xcode `[test]` storage/network logs.
4. If AI summary fails, local metadata/summary should still be saved.

中文：
预期行为：
- `End Session` 时立即保存本地 summary。
- AI final summary 是 best-effort，依赖 transcript text 和后端 summary endpoint。
- incremental draft 只有在 final transcript turn 足够时才会出现。

检查：
1. 结束前确认 transcript 有 final learner/tutor turns。
2. 确认 `./scripts/check_backend.sh` 中 `/summary` 和 `/summary/incremental` 通过。
3. 查看 Xcode `[test]` storage/network 日志。
4. 如果 AI summary 失败，本地 metadata/summary 仍应保存。

## Background Mode Issues

Expected behavior:
- The app declares audio background mode.
- Active voice sessions should either continue or clearly recover with `Reconnect` after foreground return.

Checks:
1. Validate on a physical iPhone, not simulator.
2. Start a session, then lock the screen or switch apps.
3. Return to foreground and inspect `[test]` foreground audio/LiveKit snapshots.
4. If audio stopped, tap `Reconnect`, then `Start Session` if needed.

中文：
预期行为：
- App 已声明 audio background mode。
- 活跃语音会话应尽量继续；如果系统中断，应在回前台后通过 `Reconnect` 清晰恢复。

检查：
1. 使用真机验证，不用模拟器判断。
2. 开始会话后锁屏或切 App。
3. 回前台查看 `[test]` foreground audio/LiveKit snapshot。
4. 如果音频停止，点击 `Reconnect`，必要时再点击 `Start Session`。

## Before Submission

1. Run `./scripts/check_backend.sh`.
2. Run a real-device session and then `./scripts/check_audio_health.sh`.
3. Run iOS build/tests from Xcode or command line.
4. Confirm `README.md`, `.env.example`, `plan.md`, `workflow.md`, and this `RUNBOOK.md` are accurate.
5. Confirm no real secrets, raw audio, generated logs, `.venv`, `__pycache__`, or personal local files are committed.

中文：
提交前：
1. 运行 `./scripts/check_backend.sh`。
2. 真机跑一次会话，然后运行 `./scripts/check_audio_health.sh`。
3. 从 Xcode 或命令行运行 iOS build/tests。
4. 确认 `README.md`、`.env.example`、`plan.md`、`workflow.md` 和本 `RUNBOOK.md` 准确。
5. 确认没有真实密钥、原始音频、生成日志、`.venv`、`__pycache__` 或个人本地文件进入提交。
