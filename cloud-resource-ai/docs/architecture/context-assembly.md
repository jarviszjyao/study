# Context Assembly

Context assembly prepares structured input for the LLM planner.

---

## Inputs

1. User message
2. Session history (last N turns)
3. Known entities
4. Schema registry metadata
5. Available datasets

---

## Context Structure

{
  system_role,
  conversation_summary,
  known_entities,
  available_tables,
  example_queries
}

---

## Goals

Provide enough grounding so planner can:

- guide users toward valid entities
- avoid hallucinations
- generate valid QuerySpec

---

## Rules

- keep context small (<10KB)
- summarize older history
- include schema descriptions, not full data
