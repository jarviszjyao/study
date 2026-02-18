"""Tests for Query Spec parsing."""
import pytest

from src.orchestrator.query_spec import parse_llm_json, validate_and_build_spec
from src.shared.models import FilterSpec, QuerySpec


def test_parse_llm_json_bare():
    j = '{"resource": "aws_account", "limit": 50}'
    out = parse_llm_json(j)
    assert out is not None
    assert out["resource"] == "aws_account"
    assert out["limit"] == 50


def test_parse_llm_json_markdown():
    j = '```json\n{"resource": "rds_instance", "select": ["engine"]}\n```'
    out = parse_llm_json(j)
    assert out is not None
    assert out["resource"] == "rds_instance"


def test_validate_and_build_spec_ok():
    data = {
        "resource": "aws_account",
        "filters": [{"field": "department", "op": "=", "value": "Finance"}],
        "select": ["account_id", "account_name"],
        "limit": 100,
    }
    spec, err = validate_and_build_spec(data)
    assert err is None
    assert spec.resource == "aws_account"
    assert len(spec.filters) == 1
    assert spec.filters[0].field == "department"
    assert spec.filters[0].op == "="
    assert spec.filters[0].value == "Finance"
    assert spec.select == ["account_id", "account_name"]


def test_validate_and_build_spec_invalid_resource():
    data = {"resource": "unknown_resource"}
    spec, err = validate_and_build_spec(data)
    assert spec is None
    assert "Invalid resource" in err
