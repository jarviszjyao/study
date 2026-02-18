"""Query Spec -> SQL translation."""
from typing import List

from src.shared.models import FilterSpec, QuerySpec

# Resource -> table name mapping (assumed schema)
RESOURCE_TABLE_MAP = {
    "aws_account": "aws_accounts",
    "rds_instance": "rds_instances",
    "ec2_instance": "ec2_instances",
    "ecs_cluster": "ecs_clusters",
    "gcp_project": "gcp_projects",
    "azure_subscription": "azure_subscriptions",
}


def filter_to_sql(f: FilterSpec, idx: int) -> tuple[str, list]:
    """Convert a FilterSpec to SQL WHERE clause fragment and params."""
    col = _safe_col(f.field)
    op = f.op.lower()
    val = f.value

    if op == "=":
        return f"{col} = %s", [val]
    if op == "!=":
        return f"{col} != %s", [val]
    if op == "like":
        return f"{col} LIKE %s", [val]
    if op in (">", "<", ">=", "<="):
        return f"{col} {op} %s", [val]
    if op == "in":
        if isinstance(val, list):
            placeholders = ", ".join(["%s"] * len(val))
            return f"{col} IN ({placeholders})", val
        return f"{col} = %s", [val]
    if op == "not in":
        if isinstance(val, list):
            placeholders = ", ".join(["%s"] * len(val))
            return f"{col} NOT IN ({placeholders})", val
        return f"{col} != %s", [val]
    return f"{col} = %s", [val]


def _safe_col(name: str) -> str:
    """Simple column name validation (no SQL injection)."""
    allowed = set("abcdefghijklmnopqrstuvwxyz0123456789_")
    if all(c in allowed or c == "_" for c in name.lower()):
        return f'"{name}"'
    raise ValueError(f"Invalid column name: {name}")


def spec_to_sql(spec: QuerySpec) -> tuple[str, list]:
    """
    Translate QuerySpec to SQL.
    Returns (sql, params).
    """
    table = RESOURCE_TABLE_MAP.get(spec.resource)
    if not table:
        raise ValueError(f"Unknown resource: {spec.resource}")

    select_cols = spec.select
    if not select_cols:
        select_cols = ["*"]
    else:
        select_cols = [_safe_col(c) for c in select_cols]
    select_str = ", ".join(select_cols)

    where_parts: List[str] = []
    params: List[object] = []

    for i, f in enumerate(spec.filters):
        frag, p = filter_to_sql(f, i)
        where_parts.append(frag)
        params.extend(p)

    sql = f"SELECT {select_str} FROM {table}"
    if where_parts:
        sql += " WHERE " + " AND ".join(where_parts)
    if spec.group_by:
        group_cols = [_safe_col(c) for c in spec.group_by]
        sql += " GROUP BY " + ", ".join(group_cols)
    if spec.order_by:
        order_cols = [_safe_col(c.split()[0]) for c in spec.order_by]
        directions = ["DESC" if "desc" in c.lower() else "ASC" for c in spec.order_by]
        parts = [f"{col} {dir}" for col, dir in zip(order_cols, directions)]
        sql += " ORDER BY " + ", ".join(parts)
    sql += f" LIMIT {max(1, min(spec.limit, 1000))}"

    return sql, params
