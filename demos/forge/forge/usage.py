from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

import yaml

from forge.paths import config_dir


def format_profile_pricing(input_per_million_usd: float, output_per_million_usd: float) -> str:
    """Compact in/out rates like Forge landing cards: $0.30 / $1.20."""
    inp = max(0.0, float(input_per_million_usd))
    out = max(0.0, float(output_per_million_usd))
    return f"${inp:.2f} / ${out:.2f}"


@dataclass
class ModelPricing:
    input_per_million_usd: float
    output_per_million_usd: float
    cached_input_per_million_usd: float | None = None


@dataclass
class RunUsage:
    input_tokens: int = 0
    output_tokens: int = 0
    cached_input_tokens: int = 0
    cache_write_tokens: int = 0
    reasoning_tokens: int = 0
    tokens_available: bool = False

    def to_payload(self, *, pricing: ModelPricing | None) -> dict[str, Any]:
        cost_usd = estimate_cost_usd(self, pricing) if pricing else None
        return {
            "input_tokens": self.input_tokens,
            "output_tokens": self.output_tokens,
            "cached_input_tokens": self.cached_input_tokens,
            "cache_write_tokens": self.cache_write_tokens,
            "reasoning_tokens": self.reasoning_tokens,
            "tokens_available": self.tokens_available,
            "cost_usd": cost_usd,
            "cost_available": cost_usd is not None,
        }


def load_pricing_by_model() -> dict[str, ModelPricing | None]:
    path = config_dir() / "pricing.yaml"
    if not path.is_file():
        return {}
    raw = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    out: dict[str, ModelPricing | None] = {}
    for model_id, row in (raw.get("models") or {}).items():
        if row is None:
            out[str(model_id)] = None
            continue
        if not isinstance(row, dict):
            continue
        inp = row.get("input")
        out_val = row.get("output")
        if inp is None or out_val is None:
            out[str(model_id)] = None
            continue
        cached = row.get("cached_input")
        out[str(model_id)] = ModelPricing(
            input_per_million_usd=float(inp),
            output_per_million_usd=float(out_val),
            cached_input_per_million_usd=float(cached) if cached is not None else None,
        )
    return out


def pricing_for_model(model: str) -> ModelPricing | None:
    return load_pricing_by_model().get(model)


def _num(value: Any) -> int | None:
    if value is None:
        return None
    try:
        n = int(value)
    except (TypeError, ValueError):
        try:
            n = int(float(value))
        except (TypeError, ValueError):
            return None
    return n if n >= 0 else None


def _merge_usage_line(usage: RunUsage, obj: dict[str, Any]) -> bool:
    raw = obj.get("usage") or obj.get("token_usage") or obj.get("tokens")
    if not isinstance(raw, dict):
        return False
    inp = _num(raw.get("prompt_tokens") or raw.get("input_tokens") or raw.get("inputTokens"))
    out = _num(
        raw.get("completion_tokens") or raw.get("output_tokens") or raw.get("outputTokens")
    )
    if inp is None and out is None:
        return False
    if inp is not None:
        usage.input_tokens += inp
    if out is not None:
        usage.output_tokens += out

    prompt_details = raw.get("prompt_tokens_details")
    if isinstance(prompt_details, dict):
        cached = _num(prompt_details.get("cached_tokens"))
        if cached is not None:
            usage.cached_input_tokens += cached
        cache_write = _num(prompt_details.get("cache_write_tokens"))
        if cache_write is not None:
            usage.cache_write_tokens += cache_write

    completion_details = raw.get("completion_tokens_details")
    if isinstance(completion_details, dict):
        reasoning = _num(completion_details.get("reasoning_tokens"))
        if reasoning is not None:
            usage.reasoning_tokens += reasoning

    usage.tokens_available = True
    return True


def merge_usage_from_json_object(usage: RunUsage, obj: dict[str, Any]) -> bool:
    if _merge_usage_line(usage, obj):
        return True
    message = obj.get("message")
    if isinstance(message, dict) and _merge_usage_line(usage, message):
        return True
    return False


def aggregate_usage_from_goose_logs(goose_root: Path) -> RunUsage:
    usage = RunUsage()
    logs_dir = goose_root / "state" / "logs"
    if not logs_dir.is_dir():
        return usage
    for path in sorted(logs_dir.glob("llm_request*.jsonl")):
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for line in text.splitlines():
            trimmed = line.strip()
            if not trimmed:
                continue
            try:
                obj = json.loads(trimmed)
            except json.JSONDecodeError:
                continue
            if isinstance(obj, dict):
                merge_usage_from_json_object(usage, obj)
    return usage


def estimate_cost_usd(usage: RunUsage, pricing: ModelPricing | None) -> float | None:
    if pricing is None or not usage.tokens_available:
        return None
    cached = min(usage.cached_input_tokens, usage.input_tokens)
    uncached = max(0, usage.input_tokens - cached)
    cost = (uncached / 1_000_000) * pricing.input_per_million_usd
    cost += (usage.output_tokens / 1_000_000) * pricing.output_per_million_usd
    if pricing.cached_input_per_million_usd is not None and cached > 0:
        cost += (cached / 1_000_000) * pricing.cached_input_per_million_usd
    return round(cost, 6)


def usage_as_dict(usage: RunUsage) -> dict[str, Any]:
    return asdict(usage)
