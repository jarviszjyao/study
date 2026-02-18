"""LLM client - supports dual API selection by config (Bedrock / Bedrock-alt / Mock)."""
import json
import os
from typing import Any, Optional

from src.orchestrator.prompts import SYSTEM_PROMPT, user_prompt
from src.shared.config import LlmConfig, LlmProvider
from src.shared.models import ClarificationRequest, QueryDecision, QuerySpec

from .query_spec import parse_llm_json, validate_and_build_spec


def _mock_llm(question: str) -> str:
    """Return a simple QuerySpec for demo when Bedrock is unavailable."""
    q = question.lower()
    if "aws" in q and "account" in q:
        return json.dumps({
            "resource": "aws_account",
            "filters": [{"field": "department", "op": "=", "value": "Finance"}],
            "select": ["account_id", "account_name", "owner"],
            "limit": 100,
        })
    if "rds" in q or "postgres" in q:
        return json.dumps({
            "resource": "rds_instance",
            "select": ["engine", "version", "count"],
            "group_by": ["engine", "version"],
            "limit": 100,
        })
    if "ec2" in q and "region" in q:
        return json.dumps({
            "resource": "ec2_instance",
            "select": ["region", "count"],
            "group_by": ["region"],
            "output_format": "bar",
            "limit": 50,
        })
    return json.dumps({"decision": "unsupported", "message": "Demo: try AWS accounts, RDS, or EC2 by region."})


def _invoke_bedrock_one(region: str, model_id: str, prompt: str) -> str:
    """Call a single Bedrock endpoint."""
    import boto3
    client = boto3.client("bedrock-runtime", region_name=region)
    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1024,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.2,
    }
    response = client.invoke_model(
        modelId=model_id,
        contentType="application/json",
        accept="application/json",
        body=json.dumps(body),
    )
    out = json.loads(response["body"].read())
    return out.get("content", [{}])[0].get("text", "")


def invoke_llm(question: str, config: Optional[LlmConfig] = None) -> str:
    """
    Invoke LLM and return raw response. Selects one of two API calls by LLM_PROVIDER:
    - bedrock: primary Bedrock (BEDROCK_MODEL_ID)
    - bedrock_alt: alternative Bedrock (BEDROCK_ALT_MODEL_ID)
    - mock: no real API (for demo)
    """
    cfg = config or LlmConfig.from_env()
    if cfg.provider == LlmProvider.MOCK or os.getenv("USE_MOCK_LLM", "0") == "1":
        return _mock_llm(question)

    prompt = f"{SYSTEM_PROMPT}\n\n{user_prompt(question)}"
    try:
        if cfg.provider == LlmProvider.BEDROCK_ALT and cfg.alt_model_id:
            return _invoke_bedrock_one(cfg.alt_region or cfg.region, cfg.alt_model_id, prompt)
        return _invoke_bedrock_one(cfg.region, cfg.model_id, prompt)
    except Exception:
        return _mock_llm(question)


def llm_to_spec(question: str, config: Optional[LlmConfig] = None) -> tuple[QueryDecision, Optional[QuerySpec], Optional[ClarificationRequest], Optional[str]]:
    """
    Call LLM and parse output into QuerySpec or clarification.
    Returns (decision, query_spec, clarification, raw_llm_output).
    """
    try:
        raw = invoke_llm(question, config)
    except Exception as e:
        return QueryDecision.UNSUPPORTED, None, None, str(e)

    data = parse_llm_json(raw)
    if data is None:
        return QueryDecision.UNSUPPORTED, None, None, raw

    decision_str = (data.get("decision") or "").lower()
    if decision_str == "clarify":
        return (
            QueryDecision.CLARIFY,
            None,
            ClarificationRequest(
                message=data.get("message", "Please clarify your question."),
                suggestions=data.get("suggestions", []),
            ),
            raw,
        )
    if decision_str == "unsupported":
        return (
            QueryDecision.UNSUPPORTED,
            None,
            ClarificationRequest(message=data.get("message", "This query is not supported.")),
            raw,
        )

    spec, err = validate_and_build_spec(data)
    if err:
        return QueryDecision.UNSUPPORTED, None, ClarificationRequest(message=err), raw
    return QueryDecision.EXECUTABLE, spec, None, raw
