from __future__ import annotations

import uuid
from dataclasses import dataclass, field
from threading import Lock

from forge.events import get_run, publish
from forge.goose_runner import (
    bump_compare_generation,
    get_compare_generation,
    start_lane_thread,
    stop_lanes,
)
from forge.models import Profile
from forge.prompts import ResolvedPrompt


@dataclass
class Lane:
    run_id: str
    profile: Profile
    lane_index: int


@dataclass
class CompareSession:
    resolved: ResolvedPrompt
    prompt_label: str
    max_turns: int
    lanes: list[Lane] = field(default_factory=list)

    @property
    def agent_prompt(self) -> str:
        return self.resolved.agent_prompt


_current: CompareSession | None = None
_lock = Lock()

_CANCEL_MESSAGE = "Cancelled — a new compare started on this server."


def _done_timing_ms() -> dict[str, int]:
    import time

    ended = int(time.time() * 1000)
    return {"ended_at_ms": ended}


def get_current_compare() -> CompareSession | None:
    with _lock:
        return _current


def has_in_flight_lanes() -> bool:
    """True if the current session has any lane still pending or running Goose."""
    with _lock:
        session = _current
    if session is None:
        return False
    for lane in session.lanes:
        if get_run(lane.run_id).status in ("pending", "running"):
            return True
    return False


def cancel_all_in_flight_work() -> None:
    """Stop every lane still running in this process (hard requirement before a new compare)."""
    bump_compare_generation()
    with _lock:
        session = _current
    if session is None:
        return
    run_ids = [
        lane.run_id
        for lane in session.lanes
        if get_run(lane.run_id).status in ("pending", "running")
    ]
    if not run_ids:
        return
    stop_lanes(run_ids)
    for run_id in run_ids:
        state = get_run(run_id)
        if state.status in ("complete", "failed", "cancelled"):
            continue
        publish(run_id, "error", {"message": _CANCEL_MESSAGE})
        publish(
            run_id,
            "done",
            {"exit_code": 130, "has_preview": False, **_done_timing_ms()},
        )
        state.status = "cancelled"


def start_compare(
    *,
    resolved: ResolvedPrompt,
    prompt_label: str,
    profiles: list[Profile],
    max_turns: int,
) -> CompareSession:
    cancel_all_in_flight_work()
    compare_generation = get_compare_generation()
    lanes: list[Lane] = []
    for i, profile in enumerate(profiles):
        run_id = uuid.uuid4().hex
        lanes.append(Lane(run_id=run_id, profile=profile, lane_index=i))
    session = CompareSession(
        resolved=resolved,
        prompt_label=prompt_label,
        max_turns=max_turns,
        lanes=lanes,
    )
    with _lock:
        global _current
        _current = session
    agent_prompt = resolved.agent_prompt
    for lane in lanes:
        start_lane_thread(
            run_id=lane.run_id,
            profile=lane.profile,
            agent_prompt=agent_prompt,
            max_turns=max_turns,
            compare_generation=compare_generation,
        )
    return session
