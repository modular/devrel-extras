from __future__ import annotations

import os
from pathlib import Path

from forge.paths import repo_root

_loaded = False


def load_env() -> None:
    global _loaded
    if _loaded:
        return
    try:
        from dotenv import load_dotenv
    except ImportError:
        _loaded = True
        return
    root = repo_root()
    load_dotenv(root / ".env")
    load_dotenv(root / ".env.local")
    _loaded = True


def modular_api_key(preferred_env: str = "MODULAR_API_KEY") -> str | None:
    load_env()
    for name in (preferred_env, "MODULAR_API_KEY", "MODULAR_CLOUD_API_KEY"):
        value = os.environ.get(name, "").strip()
        if value:
            return value
    return None


# Per-lane Goose `--max-turns` cap. Not exposed in the UI or via env; edit here if you need longer runs.
MAX_AGENT_TURNS_PER_LANE = 80


def require_modular_api_key(preferred_env: str = "MODULAR_API_KEY") -> str:
    key = modular_api_key(preferred_env)
    if not key:
        raise RuntimeError(
            "Set MODULAR_API_KEY (or MODULAR_CLOUD_API_KEY) in demos/forge/.env — see .env.example"
        )
    return key
