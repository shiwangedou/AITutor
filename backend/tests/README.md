# Backend Test Scripts

This folder contains manual diagnostic scripts for backend and agent verification.

中文：本目录存放后端和 agent 的手动诊断脚本。

## `diagnose_backend.py`

Checks local configuration, Python imports, agent CLI availability, and backend API responses.

中文：检查本地配置、Python import、agent CLI 是否可用，以及后端 API 响应。

Run:

```bash
cd backend
source .venv/bin/activate
python tests/diagnose_backend.py
```

Optional:

```bash
python tests/diagnose_backend.py --base-url http://127.0.0.1:8000 --verbose
```

Notes:
- Start the API server separately before API checks:
  `python -m uvicorn main:app --host 0.0.0.0 --port 8000`
- This script does not start or stop the backend server.
- This script does not print secrets or raw token values.

中文：
- 运行 API 检查前需要单独启动 API server。
- 脚本不会启动或停止后端服务。
- 脚本不会打印密钥或完整 token。
