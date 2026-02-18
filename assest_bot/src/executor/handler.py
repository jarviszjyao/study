"""Query Executor - entry point."""
from typing import Optional

from src.shared.models import ExecutorResult, QuerySpec

from .db_client import execute_query_raw
from .spec_to_sql import spec_to_sql


def execute_query(spec: QuerySpec, config=None) -> ExecutorResult:
    """
    Validate QuerySpec, translate to SQL, execute, return ExecutorResult.
    """
    try:
        sql, params = spec_to_sql(spec)
    except ValueError as e:
        return ExecutorResult(columns=[], rows=[], error=str(e))

    return execute_query_raw(sql, params, config)
