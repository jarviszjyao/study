# Clarification Engine

Purpose:
Guide users when input is ambiguous or incomplete.

---

## When Clarification is Triggered

1. Entity not found
2. Multiple matches exist
3. Required parameter missing
4. Confidence score low

---

## Example

User:
"show infra issues for payment"

Database:
Payments Platform
Payment Gateway
Payment Risk

Assistant response:

"I found multiple departments:
1. Payments Platform
2. Payment Gateway
3. Payment Risk

Which one do you mean?"

---

## Clarification State (Session)

{
  "pending_field": "department",
  "options": ["Payments Platform", "Payment Gateway"]
}

Next user message resolves the state.

---

## LLM Role

LLM suggests clarification question.

Orchestrator validates before sending to user.