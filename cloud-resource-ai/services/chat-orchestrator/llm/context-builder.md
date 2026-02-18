# Context Builder

Transforms session + metadata into LLM prompt context.

---

## Inputs

- session state
- conversation summary
- schema registry
- entity candidates
- user message

---

## Output

Structured prompt payload.

---

## Context Layout

SYSTEM ROLE

Known datasets:
- aws_accounts
- resources
- departments

Resolved entities:
department candidates:
1. Retail Banking
2. Retail Platform

Conversation summary:
User searching for department resources.