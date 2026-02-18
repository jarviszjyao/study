# Chat Orchestrator

The orchestrator is the control plane of the AI system.

It coordinates:

- Session loading
- LLM interaction
- Entity resolution
- Query planning
- Response formatting

---

## Responsibilities

1. Load session
2. Build LLM context
3. Call LLM
4. Interpret structured output
5. Update session state
6. Trigger tools

---

## Key Principle

LLM = reasoning engine
Orchestrator = decision authority
