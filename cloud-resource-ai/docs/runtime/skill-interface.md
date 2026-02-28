# Skill Interface

Skills represent executable capabilities available to the orchestrator.

Examples:

- query_database
- resolve_entity
- generate_visualization

---

## Skill Contract

Each skill exposes:

input_schema
output_schema
execution_function

---

## Principles

Skills are deterministic.

LLM selects WHAT to do.
Skills perform HOW to do it.

---

## Example

Planner Output:

action = execute_query

Orchestrator invokes:

query_database(QuerySpec)
