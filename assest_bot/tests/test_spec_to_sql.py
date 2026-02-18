"""Tests for Spec -> SQL translation."""
import pytest

from src.executor.spec_to_sql import spec_to_sql
from src.shared.models import FilterSpec, QuerySpec


def test_spec_to_sql_simple():
    spec = QuerySpec(resource="aws_account", select=["account_id", "owner"], limit=10)
    sql, params = spec_to_sql(spec)
    assert "SELECT" in sql
    assert "aws_accounts" in sql
    assert "account_id" in sql
    assert "LIMIT 10" in sql
    assert params == []


def test_spec_to_sql_with_filter():
    spec = QuerySpec(
        resource="aws_account",
        filters=[FilterSpec(field="department", op="=", value="Finance")],
        select=["account_id"],
        limit=50,
    )
    sql, params = spec_to_sql(spec)
    assert "WHERE" in sql
    assert "department" in sql
    assert params == ["Finance"]


def test_spec_to_sql_invalid_resource():
    spec = QuerySpec(resource="unknown")
    with pytest.raises(ValueError, match="Unknown resource"):
        spec_to_sql(spec)
