# Tool Registry

LLM operates through tools.

Tools are defined capabilities exposed by orchestrator.

---

## Tool Types

READ TOOLS
- search_departments
- list_accounts
- get_resource_summary

ANALYTICS TOOLS
- aggregate_by_department
- risk_distribution

UTILITY TOOLS
- fuzzy_match
- entity_resolver

---

## Tool Contract

Input:
JSON schema

Output:
Structured JSON only

---

## Example

tool: search_departments

input:
{
  "query": "payment"
}

output:
[
  "Payments Platform",
  "Payment Gateway"
]