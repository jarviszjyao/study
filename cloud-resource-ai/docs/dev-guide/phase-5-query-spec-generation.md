# Phase 5 — Query Spec Generation

Goal:
LLM produces structured Query Spec.

Input:
- intent
- schema
- user constraints

Output:

{
  "entity": "accounts",
  "filters": [
    {"field":"department","operator":"=","value":"Payments"}
  ]
}

Validation REQUIRED before execution.

Definition of Done:

✓ Invalid specs rejected
✓ Valid spec stored in session