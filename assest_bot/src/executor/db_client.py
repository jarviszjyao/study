"""Database client for RDS/Aurora."""
from typing import Any, List, Optional

from src.shared.config import DbConfig
from src.shared.models import ExecutorResult


def execute_query_raw(sql: str, params: List[Any], config: Optional[DbConfig] = None) -> ExecutorResult:
    """
    Execute SQL and return ExecutorResult.
    Uses psycopg2 if available; otherwise returns mock data for local dev.
    """
    cfg = config or DbConfig.from_env()
    try:
        import psycopg2
        from psycopg2.extras import RealDictCursor
    except ImportError:
        # Fallback: return mock result for local dev without DB
        return _mock_result(sql, params)

    try:
        conn = psycopg2.connect(
            host=cfg.host,
            port=cfg.port,
            dbname=cfg.name,
            user=cfg.user,
            password=cfg.password,
        )
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(sql, params)
        rows_raw = cur.fetchall()
        columns = list(rows_raw[0].keys()) if rows_raw else []
        rows = [[r[c] for c in columns] for r in rows_raw]
        cur.close()
        conn.close()
        return ExecutorResult(columns=columns, rows=rows, error=None)
    except Exception as e:
        return ExecutorResult(columns=[], rows=[], error=str(e))


def _mock_result(sql: str, params: List[Any]) -> ExecutorResult:
    """Return mock result when DB is not configured (for demo)."""
    sql_lower = sql.lower()
    if "aws_accounts" in sql_lower:
        return ExecutorResult(
            columns=["account_id", "account_name", "owner"],
            rows=[
                ["123456789012", "finance-prod", "Finance"],
                ["210987654321", "finance-dev", "Finance"],
            ],
        )
    if "rds_instances" in sql_lower:
        return ExecutorResult(
            columns=["engine", "version", "count"],
            rows=[["PostgreSQL", "14.3", 4], ["PostgreSQL", "15.2", 2]],
        )
    if "ec2_instances" in sql_lower:
        return ExecutorResult(
            columns=["region", "count"],
            rows=[["us-east-1", 28], ["us-west-2", 15]],
        )
    return ExecutorResult(columns=["info"], rows=[["Mock: DB not configured"]])
