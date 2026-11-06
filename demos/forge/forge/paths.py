from __future__ import annotations

from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parent.parent


def repo_root() -> Path:
    return _REPO_ROOT


def data_dir() -> Path:
    return _REPO_ROOT / "data"


def sandbox_dir(run_id: str) -> Path:
    return data_dir() / "sandbox" / run_id


def goose_home(run_id: str) -> Path:
    return data_dir() / "goose" / run_id


def config_dir() -> Path:
    return _REPO_ROOT / "config"


def templates_dir() -> Path:
    return _REPO_ROOT / "templates"


def static_dir() -> Path:
    return _REPO_ROOT / "static"


def vendor_template_dir() -> Path:
    return _REPO_ROOT / "vendor"
