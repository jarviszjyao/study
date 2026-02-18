# Session State Definition

Each session tracks reasoning progress.

## Stored Fields

- intent
- slots
- missing_slots
- resolved_entities
- last_question
- summary

---

## Why Needed

LLMs are stateless.
Sessions provide continuity.