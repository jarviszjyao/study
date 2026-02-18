# Prompt Governance

Prompts are VERSIONED assets.

Never hardcode prompts inside Lambda.

---

## Directory

/prompts/
  intent.prompt.md
  query_generation.prompt.md
  clarification.prompt.md

---

## Versioning

prompt_version: v1.2

Stored in session logs for debugging.

---

## Prompt Principles

1. Structured output required
2. No free-form SQL allowed
3. Must follow Query Spec schema
4. Must ask clarification when unsure

---

## Safety Rule

If confidence < threshold:
→ ASK USER
Never guess.