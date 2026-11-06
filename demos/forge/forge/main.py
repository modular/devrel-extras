from __future__ import annotations

import os


def main() -> None:
    import uvicorn

    from forge.env import load_env

    load_env()
    host = os.environ.get("FORGE_HOST", "127.0.0.1").strip() or "127.0.0.1"
    port = int(os.environ.get("FORGE_PORT", "8765"))
    uvicorn.run(
        "forge.app:app",
        host=host,
        port=port,
    )


if __name__ == "__main__":
    main()
