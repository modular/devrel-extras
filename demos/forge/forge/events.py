from __future__ import annotations

import json
import threading
from collections import defaultdict
from dataclasses import dataclass, field
from typing import Any, Iterator


@dataclass
class RunState:
    run_id: str
    status: str = "pending"
    events: list[dict[str, Any]] = field(default_factory=list)
    _lock: threading.Lock = field(default_factory=threading.Lock, repr=False)
    _seq: int = 0

    def append(self, event_type: str, payload: dict[str, Any] | None = None) -> dict[str, Any]:
        with self._lock:
            self._seq += 1
            event = {
                "type": event_type,
                "seq": self._seq,
                "payload": payload or {},
            }
            self.events.append(event)
            return event

    def snapshot_from(self, after_seq: int) -> list[dict[str, Any]]:
        with self._lock:
            return [e for e in self.events if e["seq"] > after_seq]


_runs: dict[str, RunState] = {}
_runs_lock = threading.Lock()


def get_run(run_id: str) -> RunState:
    with _runs_lock:
        state = _runs.get(run_id)
        if state is None:
            state = RunState(run_id=run_id)
            _runs[run_id] = state
        return state


def publish(run_id: str, event_type: str, payload: dict[str, Any] | None = None) -> None:
    get_run(run_id).append(event_type, payload)


def sse_stream(run_id: str) -> Iterator[str]:
    """Yield SSE lines until run reaches a terminal event."""
    state = get_run(run_id)
    last_seq = 0
    terminal = {"done", "cancelled"}
    idle_ticks = 0
    while idle_ticks < 1200:
        batch = state.snapshot_from(last_seq)
        if batch:
            idle_ticks = 0
        else:
            idle_ticks += 1
        for event in batch:
            last_seq = event["seq"]
            data = json.dumps(event, ensure_ascii=False)
            yield f"data: {data}\n\n"
            if event["type"] in terminal:
                return
        if state.status in ("complete", "failed", "cancelled") and not batch:
            return
        threading.Event().wait(0.25)
