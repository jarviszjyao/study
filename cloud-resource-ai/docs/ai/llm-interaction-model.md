# LLM Interaction Model

The LLM is used as a reasoning engine, not a database query engine.

The system follows a controlled interaction pattern:

User Input
 → Orchestrator builds context
 → LLM produces structured reasoning
 → Orchestrator decides next action

---

## Key Rule

LLM NEVER generates SQL directly.

Instead it produces:

- intent
- slots
- missing parameters
- clarification suggestions
- query plan (Query Spec)

---

## Interaction Cycle

1. Load session state
2. Inject schema metadata
3. Inject conversation summary
4. Provide user message
5. Request structured JSON output

---

## Output Requirement

LLM must return valid JSON only.
No natural language explanations.