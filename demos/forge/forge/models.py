from __future__ import annotations

from dataclasses import dataclass

import yaml

from forge.paths import config_dir


from forge.usage import format_profile_pricing, pricing_for_model


@dataclass(frozen=True)
class Profile:
    key: str
    label: str
    goose_provider: str
    model: str
    api_key_env: str
    context_window: str = "—"


@dataclass(frozen=True)
class SetupProfileRow:
    key: str
    label: str
    context_window: str
    pricing_label: str | None
    pricing_title: str | None


def load_setup_profile_rows() -> list[SetupProfileRow]:
    rows: list[SetupProfileRow] = []
    for p in load_profiles():
        pricing = pricing_for_model(p.model)
        if pricing is None:
            pricing_label = None
            pricing_title = None
        else:
            pricing_label = format_profile_pricing(
                pricing.input_per_million_usd,
                pricing.output_per_million_usd,
            )
            pricing_title = "Input / output USD per 1M tokens"
        rows.append(
            SetupProfileRow(
                key=p.key,
                label=p.label,
                context_window=p.context_window,
                pricing_label=pricing_label,
                pricing_title=pricing_title,
            )
        )
    return rows


def load_profiles() -> list[Profile]:
    path = config_dir() / "models.yaml"
    raw = yaml.safe_load(path.read_text(encoding="utf-8"))
    profiles: list[Profile] = []
    for row in raw.get("profiles") or []:
        profiles.append(
            Profile(
                key=str(row["key"]),
                label=str(row["label"]),
                goose_provider=str(row.get("goose_provider", "modular")),
                model=str(row["model"]),
                api_key_env=str(row.get("api_key_env", "MODULAR_API_KEY")),
                context_window=str(row.get("context_window") or "—"),
            )
        )
    return profiles


def profile_by_key(key: str) -> Profile | None:
    for p in load_profiles():
        if p.key == key:
            return p
    return None


def profiles_by_keys(keys: list[str]) -> list[Profile]:
    out: list[Profile] = []
    seen: set[str] = set()
    for key in keys:
        k = key.strip()
        if not k or k in seen:
            continue
        p = profile_by_key(k)
        if p is None:
            raise ValueError(f"Unknown profile: {k}")
        seen.add(k)
        out.append(p)
    return out
