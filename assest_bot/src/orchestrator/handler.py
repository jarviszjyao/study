"""Chat Orchestrator Lambda handler."""
import json
from typing import Any, Dict

from src.executor.handler import execute_query
from src.formatter.formatter import format_response
from src.shared.models import QueryDecision

from .llm_client import llm_to_spec


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    API Gateway / Lambda entry.
    Expects: { "body": "{\"question\": \"...\"}" } or { "question": "..." }
    """
    try:
        body = event.get("body")
        if isinstance(body, str):
            body = json.loads(body) if body else {}
        question = (body or event).get("question", "").strip()
    except (json.JSONDecodeError, TypeError):
        return _resp(400, {"error": "Invalid request body"})

    if not question:
        return _resp(400, {"error": "question is required"})

    decision, spec, clarification, _ = llm_to_spec(question)

    if decision == QueryDecision.CLARIFY:
        return _resp(200, {"decision": "clarify", "clarification": _clar_to_dict(clarification)})
    if decision == QueryDecision.UNSUPPORTED:
        return _resp(200, {"decision": "unsupported", "message": clarification.message if clarification else "Unsupported"})

    if not spec:
        return _resp(500, {"error": "Failed to produce Query Spec"})

    result = execute_query(spec)
    if result.error:
        return _resp(500, {"error": result.error, "query_spec": _spec_to_dict(spec)})

    formatted = format_response(spec, result)
    return _resp(200, {"decision": "executable", "result": formatted})


def _resp(status: int, body: dict) -> dict:
    return {"statusCode": status, "headers": {"Content-Type": "application/json"}, "body": json.dumps(body)}


def _spec_to_dict(spec) -> dict:
    return {
        "resource": spec.resource,
        "filters": [{"field": f.field, "op": f.op, "value": f.value} for f in spec.filters],
        "select": spec.select,
        "group_by": spec.group_by,
        "order_by": spec.order_by,
        "limit": spec.limit,
        "output_format": spec.output_format,
    }


def _clar_to_dict(c):
    return {"message": c.message, "suggestions": getattr(c, "suggestions", [])}
