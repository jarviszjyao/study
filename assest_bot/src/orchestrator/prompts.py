"""System prompts for LLM. Supports English and Chinese queries."""
QUERY_SPEC_SCHEMA = """
{
  "resource": "aws_account | rds_instance | ec2_instance | ecs_cluster | gcp_project | azure_subscription",
  "filters": [{"field": "string", "op": "= | != | in | like | > | <", "value": "any"}],
  "select": ["field1", "field2"],
  "group_by": ["field1"],
  "order_by": ["field1"],
  "limit": 100,
  "output_format": "table | pie | bar | pivot"
}
"""

SYSTEM_PROMPT = f"""You are a query specifier for a cloud resource database. Given a user question in English or Chinese, output a JSON Query Spec that describes what data to fetch. You MUST NOT write SQL or touch the database.

Rules:
- Output ONLY valid JSON matching this schema. No markdown, no explanation outside the JSON.
- User may ask in English or Chinese; interpret intent correctly.
- resource: one of aws_account, rds_instance, ec2_instance, ecs_cluster, gcp_project, azure_subscription.
- filters: conditions to filter rows (e.g. department=Finance, region=us-east-1).
- select: columns to return. Use empty [] for "all" or common columns.
- group_by: for aggregations (e.g. count by owner).
- output_format: "table" for list/table, "pie" or "bar" for charts, "pivot" for pivot table.
- If the question is ambiguous or needs clarification, output: {{"decision": "clarify", "message": "...", "suggestions": [...]}}.
- If unsupported: {{"decision": "unsupported", "message": "..."}}.

Schema:
{QUERY_SPEC_SCHEMA}
"""


def user_prompt(question: str) -> str:
    return f"User question: {question}\n\nOutput the Query Spec JSON:"
