from __future__ import annotations

import shutil
from pathlib import Path

from forge.paths import repo_root

SANDBOX_VENDOR_DIR = "vendor"


def vendor_template_dir() -> Path:
    return repo_root() / SANDBOX_VENDOR_DIR


def install_sandbox_vendor(sandbox: Path) -> bool:
    """Copy vendored Three.js into the lane sandbox. Returns False if template missing."""
    src = vendor_template_dir()
    if not src.is_dir():
        return False
    dest = sandbox / SANDBOX_VENDOR_DIR
    dest.mkdir(parents=True, exist_ok=True)
    for name in ("three.module.min.js", "OrbitControls.js", "README.md"):
        item = src / name
        if item.is_file():
            shutil.copy2(item, dest / name)
    return (dest / "three.module.min.js").is_file()
