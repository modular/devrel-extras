from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import yaml

from forge.paths import config_dir

_CONSTRAINTS: str | None = None
_THREEJS_3D: str | None = None
_PLAYBOOK: str | None = None

THREEJS_PROMPT_IDS = frozenset({"solar-system", "sunset-circuit", "eiffel-tower"})

CONSTRAINTS_MARKER = "Constraints: static files only"


@dataclass(frozen=True)
class ExamplePrompt:
    id: str
    title: str
    description: str
    prompt: str


@dataclass(frozen=True)
class ResolvedPrompt:
    """Pieces sent to Goose as one `--text` argument."""

    brief: str
    threejs_block: str | None
    constraints: str
    playbook: str
    preassembled: bool = False

    @property
    def agent_prompt(self) -> str:
        if self.preassembled:
            return self.brief
        parts = [self.brief]
        if self.threejs_block:
            parts.append(self.threejs_block)
        if self.constraints:
            parts.append(self.constraints)
        if self.playbook:
            parts.append(self.playbook)
        return "\n".join(parts)


def _read_config_text(name: str) -> str:
    return (config_dir() / name).read_text(encoding="utf-8").strip()


def load_constraints() -> str:
    global _CONSTRAINTS
    if _CONSTRAINTS is None:
        _CONSTRAINTS = _read_config_text("constraints.txt")
    return _CONSTRAINTS


def load_threejs_block() -> str:
    global _THREEJS_3D
    if _THREEJS_3D is None:
        _THREEJS_3D = _read_config_text("threejs_3d.txt")
    return _THREEJS_3D


def load_agent_playbook() -> str:
    global _PLAYBOOK
    if _PLAYBOOK is None:
        _PLAYBOOK = _read_config_text("agent_playbook.txt")
    return _PLAYBOOK


def load_example_prompts() -> list[ExamplePrompt]:
    path = config_dir() / "prompts.yaml"
    raw = yaml.safe_load(path.read_text(encoding="utf-8"))
    out: list[ExamplePrompt] = []
    for row in raw.get("prompts") or []:
        out.append(
            ExamplePrompt(
                id=str(row["id"]),
                title=str(row["title"]),
                description=str(row.get("description", "")),
                prompt=str(row["prompt"]).strip(),
            )
        )
    return out


def example_by_id(prompt_id: str) -> ExamplePrompt | None:
    for p in load_example_prompts():
        if p.id == prompt_id:
            return p
    return None


def resolve_agent_prompt(*, brief: str, prompt_id: str | None = None) -> str:
    return resolve_agent_prompt_parts(brief=brief, prompt_id=prompt_id).agent_prompt


def resolve_agent_prompt_parts(*, brief: str, prompt_id: str | None = None) -> ResolvedPrompt:
    """User brief + optional THREEJS block, constraints, agent playbook."""
    text = brief.strip()
    if not text:
        raise ValueError("Prompt is empty")
    if CONSTRAINTS_MARKER in text:
        return ResolvedPrompt(
            brief=text,
            threejs_block=None,
            constraints="",
            playbook="",
            preassembled=True,
        )

    pid = (prompt_id or "").strip()
    threejs = load_threejs_block() if pid in THREEJS_PROMPT_IDS else None
    return ResolvedPrompt(
        brief=text,
        threejs_block=threejs,
        constraints=load_constraints(),
        playbook=load_agent_playbook(),
    )


def resolve_prompt_from_form(*, prompt_id: str | None, prompt_text: str | None) -> ResolvedPrompt:
    brief = (prompt_text or "").strip()
    pid = (prompt_id or "").strip()
    if pid:
        example = example_by_id(pid)
        if example and not brief:
            brief = example.prompt
        elif example is None and not brief:
            raise ValueError(f"Unknown example prompt: {pid}")
    if not brief:
        raise ValueError("Choose an example or enter a prompt")
    return resolve_agent_prompt_parts(brief=brief, prompt_id=pid or None)
