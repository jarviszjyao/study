# Planner-Based Reasoning Model

This system replaces intent detection with LLM planning.

---

## Traditional Intent System (NOT USED)

Intent classification requires predefined categories.

Problems:

- brittle
- incomplete
- hard to scale

---

## Planner Model

LLM performs reasoning instead of classification.

Input:
- user message
- context
- schema metadata

Output:
decision object:

{
  "action": "execute_query | clarification_required | unsupported",
  "reasoning": "...",
  "query_spec": {}
}

---

## Planner Responsibilities

- infer user goal
- detect missing parameters
- request clarification
- construct QuerySpec

---

## Planner Constraints

Planner MUST NOT:

- generate SQL
- access database
- assume unknown entities

---

## Advantages

- handles fuzzy language
- adaptive queries
- fewer hardcoded paths
