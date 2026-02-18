# Query Schema Management

LLM must understand available data structures.

Schema is provided as controlled context.

---

## Schema Source

Stored in:

/schemas/

Example:

accounts.schema.json
resources.schema.json
violations.schema.json

---

## Schema Example

{
  "table": "accounts",
  "description": "Cloud accounts metadata",
  "fields": [
    {"name": "account_id", "type": "string"},
    {"name": "department", "type": "string"},
    {"name": "owner", "type": "string"},
    {"name": "risk_score", "type": "number"}
  ]
}

---

## Schema Injection Strategy

DO NOT send full database schema every time.

Instead:

1. Intent detected
2. Relevant schemas selected
3. Inject only related schema into prompt

Example:

Intent = account discovery
→ load accounts.schema.json only

---

## Schema Loader

Orchestrator loads schema dynamically.

Benefits:
- smaller token usage
- faster LLM reasoning
- safer generation