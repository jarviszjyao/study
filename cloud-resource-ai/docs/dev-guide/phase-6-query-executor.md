# Phase 6 — Query Executor

Goal:
Translate Query Spec → SQL/API.

Executor responsibilities:

- build SQL safely
- enforce access control
- execute query
- return JSON

LLM NEVER touches DB.

Definition of Done:

✓ Query results returned from real data
✓ Permission filters applied