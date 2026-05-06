# Backend Dev Scripts

Use these scripts to run the backend demo locally.

中文：使用这些脚本在本地启动后端 demo。

## Prerequisite

Edit the Finder-visible root `env` file before starting services.
The scripts automatically copy `env` to `.env` before setup/start.

```bash
open ../env
```

Fill:
- `LIVEKIT_URL`
- `LIVEKIT_API_KEY`
- `LIVEKIT_API_SECRET`

中文：启动前编辑 Finder 可见的根目录 `env` 文件。脚本会在 setup/start 前自动复制 `env` 到 `.env`。
Finder-visible templates are also available at root as `env` and `env.example`.

中文：根目录也提供 Finder 可见模板 `env` 和 `env.example`。

## Commands

```bash
cd backend
./scripts/setup.sh
./scripts/start_all.sh
```

The combined startup writes logs to:
- `../logs/api.log`
- `../logs/agent.log`

It also waits for:
- API `/health`
- agent `registered worker`

Then it prints `All backend services ready`.

From project root, run:

```bash
./check_backend.sh
```

Individual scripts:

```bash
./scripts/start_api.sh
./scripts/start_agent.sh
```

Diagnostics:

```bash
source .venv/bin/activate
python tests/diagnose_backend.py --verbose
```

中文：
- `setup.sh` 创建 `.venv`、安装依赖、下载 agent 模型文件。
- `start_api.sh` 启动 FastAPI。
- `start_agent.sh` 启动 LiveKit agent dev 模式。
- `start_all.sh` 同时启动 API 和 agent，将日志写入根目录 `logs/`，等待 API 和 agent ready，并在 Ctrl+C 时停止两个进程。
