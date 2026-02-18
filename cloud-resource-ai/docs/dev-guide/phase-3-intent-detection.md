# Phase 3 — Intent Detection

Goal:
User input classified into intent categories.

Example intents:

- list_accounts
- resource_summary
- violation_analysis
- unknown

Implementation:

Call LLM using intent.prompt.md

Output:

{
  "intent": "list_accounts",
  "confidence": 0.87
}

Definition of Done:

✓ Intent stored in session
✓ Unknown intent triggers clarification