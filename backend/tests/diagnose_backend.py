#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parents[2]
BACKEND_DIR = Path(__file__).resolve().parents[1]
ENV_PATH = ROOT_DIR / ".env"


def log(level: str, message: str) -> None:
    timestamp = time.strftime("%H:%M:%S")
    print(f"[{timestamp}] [{level}] {message}")


def mask(value: str | None) -> str:
    if not value:
        return "<missing>"
    if len(value) <= 8:
        return "<set>"
    return f"{value[:4]}...{value[-4:]}"


def load_env_file(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.exists():
        return values

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def check_env() -> bool:
    log("INFO", f"Checking env file: {ENV_PATH}")
    values = load_env_file(ENV_PATH)
    required = ["LIVEKIT_URL", "LIVEKIT_API_KEY", "LIVEKIT_API_SECRET"]
    ok = True

    if not ENV_PATH.exists():
        log("WARN", "Root .env file is missing. Copy .env.example to .env and fill LiveKit values.")

    for key in required:
        value = os.getenv(key) or values.get(key)
        if value:
            log("OK", f"{key} is set: {mask(value)}")
        else:
            log("FAIL", f"{key} is missing")
            ok = False

    tutor_subject = os.getenv("TUTOR_SUBJECT") or values.get("TUTOR_SUBJECT", "english-speaking")
    log("INFO", f"TUTOR_SUBJECT={tutor_subject}")
    return ok


def check_imports() -> bool:
    log("INFO", "Checking Python imports")
    checks = [
        ("fastapi", "FastAPI backend"),
        ("dotenv", "python-dotenv"),
        ("livekit", "LiveKit base package"),
        ("livekit.agents", "LiveKit Agents runtime"),
        ("livekit.plugins.silero", "Silero VAD plugin"),
        ("livekit.plugins.turn_detector.multilingual", "Turn detector plugin"),
    ]

    ok = True
    for module_name, label in checks:
        try:
            __import__(module_name)
            log("OK", f"{label} import succeeded ({module_name})")
        except Exception as exc:
            log("FAIL", f"{label} import failed ({module_name}): {exc}")
            ok = False
    return ok


def check_agent_cli(verbose: bool) -> bool:
    log("INFO", "Checking agent CLI")
    command = [sys.executable, str(BACKEND_DIR / "agent.py"), "--help"]
    try:
        result = subprocess.run(command, cwd=BACKEND_DIR, text=True, capture_output=True, timeout=20)
    except Exception as exc:
        log("FAIL", f"agent.py --help failed to run: {exc}")
        return False

    output = f"{result.stdout}\n{result.stderr}"
    if result.returncode != 0:
        log("FAIL", f"agent.py --help exited with {result.returncode}")
        if verbose:
            print(output)
        return False

    required_commands = ["download-files", "dev", "start", "connect", "console"]
    missing = [command_name for command_name in required_commands if command_name not in output]
    if missing:
        log("FAIL", f"agent CLI missing expected commands: {', '.join(missing)}")
        if verbose:
            print(output)
        return False

    log("OK", "agent CLI loaded with expected commands")
    return True


def request_json(url: str, method: str = "GET", body: dict | None = None, timeout: float = 5.0) -> tuple[int, dict]:
    data = None
    headers = {}
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"

    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    with urllib.request.urlopen(request, timeout=timeout) as response:
        payload = response.read().decode("utf-8")
        return response.status, json.loads(payload)


def check_backend_api(base_url: str, verbose: bool) -> bool:
    log("INFO", f"Checking backend API at {base_url}")
    ok = True

    try:
        status, payload = request_json(f"{base_url}/health")
        if status == 200 and payload.get("status") == "ok":
            log("OK", "/health returned ok")
        else:
            log("FAIL", f"/health unexpected response: {status} {payload}")
            ok = False
    except urllib.error.URLError as exc:
        log("FAIL", f"/health request failed. Is the API server running? {exc}")
        return False
    except Exception as exc:
        log("FAIL", f"/health request failed: {exc}")
        return False

    try:
        status, payload = request_json(
            f"{base_url}/session",
            method="POST",
            body={"display_name": "Diagnostics Learner"},
        )
        required = ["livekit_url", "tutor_subject", "token", "room_name", "participant_identity", "issued_at", "session_id"]
        missing = [key for key in required if key not in payload]

        if status == 200 and not missing:
            log("OK", "/session returned required payload shape")
            log("INFO", f"room_name={payload['room_name']}")
            log("INFO", f"participant_identity={payload['participant_identity']}")
            log("INFO", f"token={mask(payload['token'])}")
        else:
            log("FAIL", f"/session missing keys: {missing}")
            ok = False

        if verbose:
            safe_payload = dict(payload)
            if "token" in safe_payload:
                safe_payload["token"] = mask(safe_payload["token"])
            log("DEBUG", json.dumps(safe_payload, indent=2, sort_keys=True))
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        log("FAIL", f"/session returned HTTP {exc.code}: {body}")
        ok = False
    except Exception as exc:
        log("FAIL", f"/session request failed: {exc}")
        ok = False

    return ok


def main() -> int:
    parser = argparse.ArgumentParser(description="Diagnose AITutor backend and LiveKit agent setup.")
    parser.add_argument("--base-url", default="http://127.0.0.1:8000", help="Backend API base URL")
    parser.add_argument("--skip-api", action="store_true", help="Skip /health and /session checks")
    parser.add_argument("--verbose", action="store_true", help="Print extra diagnostic detail")
    args = parser.parse_args()

    checks = [
        ("env", check_env()),
        ("imports", check_imports()),
        ("agent_cli", check_agent_cli(args.verbose)),
    ]

    if not args.skip_api:
        checks.append(("backend_api", check_backend_api(args.base_url.rstrip("/"), args.verbose)))
    else:
        log("INFO", "Skipping backend API checks")

    failed = [name for name, passed in checks if not passed]
    if failed:
        log("FAIL", f"Diagnostics failed: {', '.join(failed)}")
        return 1

    log("OK", "All diagnostics passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
