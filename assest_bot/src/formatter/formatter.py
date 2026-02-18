"""Format ExecutorResult for API response (table, pie, bar, pivot).

Output formats are sufficient for Web chat lib to render chats, lists, tables,
and pivot tables.
"""
from typing import Any, Dict, List

from src.shared.models import ExecutorResult, QuerySpec


def format_response(spec: QuerySpec, result: ExecutorResult) -> Dict[str, Any]:
    """
    Format ExecutorResult into API response. Supports table, pie, bar, pivot.
    """
    if result.error:
        return {"format": "error", "message": result.error}

    fmt = (spec.output_format or "table").lower()
    if fmt not in ("table", "pie", "bar", "pivot"):
        fmt = "table"

    columns = result.columns
    rows = result.rows

    if fmt in ("table", "pivot"):
        return {
            "format": fmt,
            "title": _title_for_resource(spec.resource),
            "columns": columns,
            "rows": rows,
            "pivot": fmt == "pivot",  # Hint for Web chat lib to render as pivot
        }

    # For pie/bar: first col = labels, second col = values (or first numeric)
    if not rows:
        return {"format": fmt, "title": _title_for_resource(spec.resource), "labels": [], "values": []}

    label_idx = 0
    value_idx = 1
    if len(columns) > 1:
        for i, c in enumerate(columns):
            if _is_numeric_col(c):
                value_idx = i
                label_idx = 0 if i != 0 else 1
                break

    labels = [str(r[label_idx]) for r in rows]
    values = [_to_num(r[value_idx]) for r in rows]

    return {
        "format": fmt,
        "title": _title_for_resource(spec.resource),
        "labels": labels,
        "values": values,
    }


def _title_for_resource(resource: str) -> str:
    m = {
        "aws_account": "AWS Accounts",
        "rds_instance": "RDS Instances",
        "ec2_instance": "EC2 Instances",
        "ecs_cluster": "ECS Clusters",
        "gcp_project": "GCP Projects",
        "azure_subscription": "Azure Subscriptions",
    }
    return m.get(resource, resource.replace("_", " ").title())


def _is_numeric_col(name: str) -> bool:
    n = name.lower()
    return "count" in n or "num" in n or "sum" in n or "total" in n or n.endswith("_id") is False


def _to_num(v: Any) -> float:
    try:
        return float(v)
    except (TypeError, ValueError):
        return 0
