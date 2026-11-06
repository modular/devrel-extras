#!/usr/bin/env python3
"""HTTP smoke for Forge; optional live Goose compare when .env + goose are ready.

Set FORGE_E2E_LIVE=0 to skip the live compare even when credentials exist.
"""

from __future__ import annotations

import os
import shutil
import sys
import time

from fastapi.testclient import TestClient

from forge.app import app
from forge.compare import get_current_compare
from forge.env import load_env, modular_api_key
from forge.events import get_run
from forge.paths import repo_root
from forge.vendor import vendor_template_dir


def smoke_http(client: TestClient) -> int:
    home = client.get("/")
    if home.status_code != 200:
        print(f"FAIL GET / → {home.status_code}")
        return 1
    if "<h1>Forge</h1>" not in home.text:
        print("FAIL GET / missing title")
        return 1
    if "frontier-level" not in home.text:
        print("FAIL GET / missing setup lede")
        return 1
    print("OK GET /")

    in_flight = client.get("/api/compare/in-flight")
    if in_flight.status_code != 200:
        print(f"FAIL GET /api/compare/in-flight → {in_flight.status_code}")
        return 1
    if in_flight.json().get("in_flight") is not False:
        print("FAIL expected in_flight=false on fresh process")
        return 1
    print("OK GET /api/compare/in-flight")

    vendor = vendor_template_dir()
    if not (vendor / "three.module.min.js").is_file():
        print(f"FAIL missing {vendor / 'three.module.min.js'}")
        return 1
    if not (vendor / "OrbitControls.js").is_file():
        print(f"FAIL missing {vendor / 'OrbitControls.js'}")
        return 1
    print("OK vendor/ Three.js template")

    compare_no_session = client.get("/compare")
    if compare_no_session.status_code != 404:
        print(f"FAIL GET /compare without session → {compare_no_session.status_code}")
        return 1
    print("OK GET /compare without session → 404")

    return 0


def smoke_live_compare(client: TestClient) -> int:
    resp = client.post(
        "/compare",
        data={
            "prompt_id": "pelican-bicycle",
            "prompt_text": "",
            "profile_keys": ["m3-shared", "m3.1-flash-shared"],
        },
        follow_redirects=False,
    )
    if resp.status_code != 303:
        print(f"FAIL POST /compare → {resp.status_code} {resp.text[:200]}")
        return 1
    location = resp.headers.get("location", "")
    if location.rstrip("/") != "/compare":
        print(f"FAIL POST /compare redirect → {location!r}")
        return 1
    print("OK POST /compare → /compare")

    if client.get("/api/compare/in-flight").json().get("in_flight") is not True:
        print("FAIL expected in_flight=true while lanes running")
        return 1
    print("OK in_flight while compare running")

    page = client.get("/compare")
    if page.status_code != 200:
        print(f"FAIL GET compare page → {page.status_code}")
        return 1
    if "lane-grid" not in page.text:
        print("FAIL compare page missing lane-grid")
        return 1
    if "compare-prompt-dialog" not in page.text:
        print("FAIL compare page missing agent prompt dialog")
        return 1
    if 'building-wait.html' not in page.text:
        print("FAIL compare page missing building placeholder")
        return 1
    print("OK GET /compare")

    session = get_current_compare()
    if session is None or len(session.lanes) != 2:
        print("FAIL compare session registry")
        return 1

    deadline = time.time() + 600
    pending = {lane.run_id for lane in session.lanes}
    failed: list[str] = []
    while pending and time.time() < deadline:
        for run_id in list(pending):
            state = get_run(run_id)
            done_event = next((e for e in state.events if e.get("type") == "done"), None)
            if done_event is None:
                continue
            pending.discard(run_id)
            payload = done_event.get("payload") or {}
            code = payload.get("exit_code")
            has_preview = payload.get("has_preview")
            ok = has_preview is True
            if not ok:
                err = next(
                    (e for e in state.events if e.get("type") == "error"),
                    None,
                )
                msg = (err or {}).get("payload", {}).get("message", "")
                failed.append(f"{run_id[:8]} exit={code} {msg[:80]}")
            else:
                print(f"OK lane {run_id[:8]}… done exit={code} preview=True")
        if pending:
            time.sleep(2)

    if failed and len(failed) >= len(session.lanes):
        for line in failed:
            print(f"FAIL lane {line}")
        return 1
    if failed:
        print("WARN some lanes failed (compare UI still OK):", "; ".join(failed))

    if pending:
        print(f"FAIL timeout waiting for lanes: {pending}")
        return 1

    print("OK e2e live compare finished")
    return 0


def main() -> int:
    load_env()
    os.chdir(repo_root())
    client = TestClient(app)

    code = smoke_http(client)
    if code != 0:
        return code

    if os.environ.get("FORGE_E2E_LIVE", "1").strip().lower() in ("0", "false", "no"):
        print("SKIP live compare — FORGE_E2E_LIVE=0")
        return 0

    if modular_api_key() is None:
        print("SKIP live compare — no MODULAR_API_KEY / MODULAR_CLOUD_API_KEY in .env")
        return 0

    if shutil.which("goose") is None:
        print("SKIP live compare — goose not on PATH")
        return 0

    return smoke_live_compare(client)


if __name__ == "__main__":
    sys.exit(main())
