from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import threading
import time
from pathlib import Path
from typing import Any

from forge.events import get_run, publish
from forge.models import Profile, load_profiles
from forge.paths import goose_home, sandbox_dir
from forge.usage import (
    aggregate_usage_from_goose_logs,
    merge_usage_from_json_object,
    pricing_for_model,
    RunUsage,
)
from forge.vendor import install_sandbox_vendor

_active = 0
_active_lock = threading.Lock()
_preview_mtime: dict[str, int] = {}
_proc_by_run: dict[str, subprocess.Popen[Any]] = {}
_proc_lock = threading.Lock()
_compare_generation = 0
_generation_lock = threading.Lock()

CANCEL_NEW_COMPARE_MESSAGE = "Cancelled — a new compare started on this server."

FORGE_READY_RE = re.compile(r"__forgeReady\s*=\s*true", re.IGNORECASE)
MIN_INDEX_BYTES = 200

MODULAR_BASE = "https://api.modular.com/v1/chat/completions"
MAX_CONCURRENT_LANES = 4


def _now_ms() -> int:
    return int(time.time() * 1000)


def _done_timing(started_at_ms: int | None) -> dict[str, int]:
    ended_at_ms = _now_ms()
    payload: dict[str, int] = {"ended_at_ms": ended_at_ms}
    if started_at_ms is not None:
        payload["started_at_ms"] = started_at_ms
        payload["elapsed_ms"] = max(0, ended_at_ms - started_at_ms)
    return payload


def _merge_lane_usage(
    goose_root: Path,
    stream_usage: RunUsage,
) -> RunUsage:
    from_logs = aggregate_usage_from_goose_logs(goose_root)
    if from_logs.tokens_available:
        return from_logs
    return stream_usage


def _publish_lane_metrics(
    run_id: str,
    profile: Profile,
    usage: RunUsage,
) -> None:
    pricing = pricing_for_model(profile.model)
    publish(run_id, "metrics", usage.to_payload(pricing=pricing))


def acquire_slot() -> bool:
    global _active
    with _active_lock:
        if _active >= MAX_CONCURRENT_LANES:
            return False
        _active += 1
        return True


def release_slot() -> None:
    global _active
    with _active_lock:
        _active = max(0, _active - 1)


def get_compare_generation() -> int:
    with _generation_lock:
        return _compare_generation


def bump_compare_generation() -> int:
    global _compare_generation
    with _generation_lock:
        _compare_generation += 1
        return _compare_generation


def _register_proc(run_id: str, proc: subprocess.Popen[Any]) -> None:
    with _proc_lock:
        _proc_by_run[run_id] = proc


def _unregister_proc(run_id: str) -> None:
    with _proc_lock:
        _proc_by_run.pop(run_id, None)


def stop_lanes(run_ids: list[str]) -> None:
    with _proc_lock:
        procs = [(rid, _proc_by_run.get(rid)) for rid in run_ids]
    for _run_id, proc in procs:
        if proc is None or proc.poll() is not None:
            continue
        try:
            proc.terminate()
        except OSError:
            pass
    time.sleep(0.4)
    with _proc_lock:
        for _run_id, proc in procs:
            if proc is None or proc.poll() is not None:
                continue
            try:
                proc.kill()
            except OSError:
                pass


def _lane_superseded(compare_generation: int) -> bool:
    return compare_generation != get_compare_generation()


def _publish_superseded(run_id: str, started_at_ms: int | None) -> None:
    publish(run_id, "error", {"message": CANCEL_NEW_COMPARE_MESSAGE})
    publish(
        run_id,
        "done",
        {"exit_code": 130, "has_preview": False, **_done_timing(started_at_ms)},
    )
    get_run(run_id).status = "cancelled"


def _api_key(profile: Profile) -> str:
    from forge.env import require_modular_api_key

    return require_modular_api_key(profile.api_key_env)


def _write_modular_provider(goose_root: Path) -> None:
    providers_dir = goose_root / "config" / "custom_providers"
    providers_dir.mkdir(parents=True, exist_ok=True)
    models = []
    for p in load_profiles():
        models.append(
            {
                "name": p.model,
                "context_limit": 1_048_576,
                "reasoning": True,
            }
        )
    payload = {
        "name": "modular",
        "engine": "openai",
        "display_name": "Modular",
        "description": "Modular Cloud OpenAI-compatible API",
        "api_key_env": "MODULAR_API_KEY",
        "base_url": MODULAR_BASE,
        "catalog_provider_id": "modular",
        "dynamic_models": False,
        "models": models,
        "supports_streaming": True,
    }
    (providers_dir / "modular.json").write_text(
        json.dumps(payload, indent=2) + "\n",
        encoding="utf-8",
    )


def _write_permissions(goose_root: Path) -> None:
    perm = goose_root / "config" / "permission.yaml"
    perm.parent.mkdir(parents=True, exist_ok=True)
    perm.write_text(
        "user:\n"
        "  always_allow: [write, developer__write, todo_write, todo__todo_write]\n"
        "  ask_before: []\n"
        "  never_allow: [shell, developer__shell]\n",
        encoding="utf-8",
    )


def _format_trace_line(parsed: dict[str, Any]) -> str | None:
    typ = str(parsed.get("type") or parsed.get("event") or "").lower()
    if typ in ("error", "fatal"):
        msg = parsed.get("message") or parsed.get("error") or parsed
        return f"ERROR: {msg}"
    message = parsed.get("message")
    if isinstance(message, dict):
        content = message.get("content")
        if isinstance(content, str) and content.strip():
            return content.strip()[:2000]
        if isinstance(content, list):
            parts: list[str] = []
            for block in content:
                if not isinstance(block, dict):
                    continue
                btype = str(block.get("type", "")).lower()
                if btype in ("text", "output_text") and block.get("text"):
                    parts.append(str(block["text"]))
                elif "toolrequest" in btype or btype == "tool_request":
                    name = block.get("name") or block.get("tool_name") or "tool"
                    parts.append(f"▸ {name}")
            if parts:
                return "\n".join(parts)[:2000]
    if looks_like_tool(parsed):
        return "▸ tool call"
    return None


def looks_like_tool(obj: Any) -> bool:
    if not isinstance(obj, dict):
        return False
    typ = str(obj.get("type") or obj.get("event") or obj.get("kind") or "").lower()
    if typ in ("toolrequest", "tool_request"):
        return True
    content = obj.get("content")
    if isinstance(content, list):
        for block in content:
            if isinstance(block, dict):
                bt = str(block.get("type", "")).lower()
                if bt in ("toolrequest", "tool_request"):
                    return True
    return False


def _maybe_preview_ready(run_id: str, sandbox: Path) -> None:
    index = sandbox / "index.html"
    if not index.is_file():
        return
    mtime = int(index.stat().st_mtime)
    if _preview_mtime.get(run_id) == mtime:
        return
    _preview_mtime[run_id] = mtime
    publish(
        run_id,
        "preview_ready",
        {"url": f"/sandbox/{run_id}/index.html", "mtime": mtime},
    )


def _sandbox_has_preview(sandbox: Path, *, started_at: float) -> bool:
    index = sandbox / "index.html"
    if not index.is_file():
        return False
    stat = index.stat()
    if stat.st_size < MIN_INDEX_BYTES:
        return False
    if stat.st_mtime < started_at - 2.0:
        return False
    try:
        text = index.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return False
    return FORGE_READY_RE.search(text) is not None


def _prepare_sandbox(sandbox: Path) -> bool:
    sandbox.mkdir(parents=True, exist_ok=True)
    return install_sandbox_vendor(sandbox)


def run_goose_lane(
    *,
    run_id: str,
    profile: Profile,
    agent_prompt: str,
    max_turns: int,
    compare_generation: int,
) -> None:
    started_at_ms: int | None = None
    slot_held = False

    def finish_slot() -> None:
        nonlocal slot_held
        if slot_held:
            release_slot()
            slot_held = False

    try:
        if _lane_superseded(compare_generation):
            _publish_superseded(run_id, started_at_ms)
            return

        if shutil.which("goose") is None:
            publish(run_id, "error", {"message": "goose CLI not found on PATH"})
            publish(run_id, "done", {"exit_code": 127, **_done_timing(started_at_ms)})
            get_run(run_id).status = "failed"
            return

        if not acquire_slot():
            publish(run_id, "error", {"message": "Too many concurrent Goose runs"})
            publish(run_id, "done", {"exit_code": 429, **_done_timing(started_at_ms)})
            get_run(run_id).status = "failed"
            return

        slot_held = True

        if _lane_superseded(compare_generation):
            _publish_superseded(run_id, started_at_ms)
            return

        try:
            api_key = _api_key(profile)
        except RuntimeError as exc:
            publish(run_id, "error", {"message": str(exc)})
            publish(run_id, "done", {"exit_code": 1, **_done_timing(started_at_ms)})
            get_run(run_id).status = "failed"
            return

        sandbox = sandbox_dir(run_id)
        root = goose_home(run_id)
        started_at = time.time()
        vendor_ok = _prepare_sandbox(sandbox)
        _write_modular_provider(root)
        _write_permissions(root)

        state = get_run(run_id)
        if state.status == "cancelled":
            return
        state.status = "running"
        started_at_ms = _now_ms()
        publish(
            run_id,
            "run_started",
            {
                "profile_key": profile.key,
                "model": profile.model,
                "label": profile.label,
                "preview_url": f"/sandbox/{run_id}/index.html",
                "vendor_installed": vendor_ok,
                "started_at_ms": started_at_ms,
            },
        )

        if not vendor_ok:
            publish(
                run_id,
                "log",
                {"source": "runner", "text": "WARN: vendor/ not installed — add demos/forge/vendor/"},
            )

        env = os.environ.copy()
        env.update(
            {
                "PWD": str(sandbox),
                "GOOSE_PATH_ROOT": str(root),
                "GOOSE_DISABLE_KEYRING": "1",
                "GOOSE_MODE": "auto",
                profile.api_key_env: api_key,
            }
        )

        cmd = [
            "goose",
            "run",
            "--no-session",
            "--quiet",
            "--with-builtin",
            "developer",
            "--provider",
            profile.goose_provider,
            "--model",
            profile.model,
            "--output-format",
            "stream-json",
            "--max-turns",
            str(max_turns),
            "--text",
            agent_prompt,
        ]

        try:
            proc = subprocess.Popen(
                cmd,
                cwd=sandbox,
                env=env,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1,
            )
        except OSError as exc:
            publish(run_id, "error", {"message": str(exc)})
            publish(run_id, "done", {"exit_code": 1, **_done_timing(started_at_ms)})
            state.status = "failed"
            return

        _register_proc(run_id, proc)

        def drain_stderr() -> None:
            assert proc.stderr is not None
            for line in proc.stderr:
                text = line.strip()
                if text:
                    publish(run_id, "log", {"source": "stderr", "text": text[:2000]})

        threading.Thread(target=drain_stderr, daemon=True).start()

        stream_usage = RunUsage()
        last_metrics_at = 0.0

        def maybe_publish_metrics(force: bool = False) -> RunUsage:
            nonlocal last_metrics_at
            usage = _merge_lane_usage(root, stream_usage)
            now = time.time()
            if force or (usage.tokens_available and now - last_metrics_at >= 2.0):
                _publish_lane_metrics(run_id, profile, usage)
                last_metrics_at = now
            return usage

        assert proc.stdout is not None
        for line in proc.stdout:
            if get_run(run_id).status == "cancelled":
                break
            trimmed = line.strip()
            if not trimmed:
                continue
            if trimmed.startswith("{"):
                try:
                    parsed = json.loads(trimmed)
                except json.JSONDecodeError:
                    publish(run_id, "log", {"source": "stdout", "text": trimmed[:2000]})
                    continue
                if isinstance(parsed, dict):
                    merge_usage_from_json_object(stream_usage, parsed)
                    maybe_publish_metrics()
                trace = _format_trace_line(parsed)
                if trace:
                    publish(run_id, "trace", {"text": trace})
                if looks_like_tool(parsed):
                    _maybe_preview_ready(run_id, sandbox)
            else:
                publish(run_id, "log", {"source": "stdout", "text": trimmed[:2000]})
            _maybe_preview_ready(run_id, sandbox)

        code = proc.wait()
        _unregister_proc(run_id)
        if get_run(run_id).status == "cancelled":
            return
        _maybe_preview_ready(run_id, sandbox)
        final_usage = maybe_publish_metrics(force=True)
        usage_payload = final_usage.to_payload(pricing=pricing_for_model(profile.model))
        has_preview = _sandbox_has_preview(sandbox, started_at=started_at)
        if has_preview:
            state.status = "complete"
            publish(
                run_id,
                "done",
                {
                    "exit_code": code,
                    "has_preview": True,
                    **_done_timing(started_at_ms),
                    **usage_payload,
                },
            )
        elif code == 0:
            state.status = "failed"
            publish(
                run_id,
                "error",
                {
                    "message": "Goose exited but preview is not ready — set window.__forgeReady = true after first render",
                },
            )
            publish(
                run_id,
                "done",
                {
                    "exit_code": code,
                    "has_preview": False,
                    **_done_timing(started_at_ms),
                    **usage_payload,
                },
            )
        else:
            state.status = "failed"
            publish(run_id, "error", {"message": f"Goose exited with code {code}"})
            publish(
                run_id,
                "done",
                {
                    "exit_code": code,
                    "has_preview": False,
                    **_done_timing(started_at_ms),
                    **usage_payload,
                },
            )
    finally:
        finish_slot()


def start_lane_thread(**kwargs: Any) -> None:
    threading.Thread(target=run_goose_lane, kwargs=kwargs, daemon=True).start()
