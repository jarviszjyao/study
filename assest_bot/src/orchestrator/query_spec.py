"""Query Spec model and validation.

Extensible: add new resources in ALLOWED_RESOURCES and resource_tables.json.
"""
import json
from typing import Any, List, Optional

from src.shared.models import FilterSpec, QuerySpec

# Extensible: add new resource types here and in schema/resource_tables.json
ALLOWED_RESOURCES = frozenset(
    ["aws_account", "rds_instance", "ec2_instance", "ecs_cluster", "gcp_project", "azure_subscription"]
)
ALLOWED_OPS = frozenset(["=", "!=", "in", "not in", "like", ">", "<", ">=", "<="])
DEFAULT_SELECT_LIMIT = 100


def parse_llm_json(raw: str) -> Optional[dict]:
    """Extract JSON from LLM output (may have markdown code blocks)."""
    raw = raw.strip()
    if raw.startswith("```"):
        lines = raw.split("\n")
        start = 1 if lines[0].startswith("```json") else 0
        end = next((i for i, L in enumerate(lines[1:], 1) if L.strip() == "```"), len(lines))
        raw = "\n".join(lines[start:end])
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return None


def validate_and_build_spec(data: dict) -> tuple[Optional[QuerySpec], Optional[str]]:
    """
    Validate LLM output and build QuerySpec.
    Returns (QuerySpec, error_message). If error_message is set, QuerySpec is None.
    """
    if not isinstance(data, dict):
        return None, "Expected JSON object"

    resource = data.get("resource")
    if not resource or resource not in ALLOWED_RESOURCES:
        return None, f"Invalid resource. Allowed: {sorted(ALLOWED_RESOURCES)}"

    filters = []
    for f in data.get("filters", []) or []:
        if not isinstance(f, dict) or "field" not in f or "op" not in f or "value" not in f:
            continue
        op = str(f["op"]).lower()
        if op not in ALLOWED_OPS:
            continue
        filters.append(FilterSpec(field=str(f["field"]), op=op, value=f["value"]))

    select = data.get("select") or []
    if isinstance(select, list):
        select = [str(s) for s in select]
    else:
        select = []

    limit = data.get("limit", DEFAULT_SELECT_LIMIT)
    try:
        limit = int(limit)
        limit = max(1, min(limit, 1000))
    except (TypeError, ValueError):
        limit = DEFAULT_SELECT_LIMIT

    output_format = (data.get("output_format") or "table").lower()
    if output_format not in ("table", "pie", "bar", "pivot"):
        output_format = "table"

    spec = QuerySpec(
        resource=resource,
        filters=filters,
        select=select,
        group_by=data.get("group_by") or None,
        order_by=data.get("order_by") or None,
        limit=limit,
        output_format=output_format,
    )
    return spec, None
