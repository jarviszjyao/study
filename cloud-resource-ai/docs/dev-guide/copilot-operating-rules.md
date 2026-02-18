# Copilot Agent Operating Rules

Copilot MUST follow these constraints:

1. Never invent new architecture.
2. Follow docs/architecture exactly.
3. Use Query Spec schema strictly.
4. Do not directly connect LLM to database.
5. All state must go through session manager.
6. Prompts must be loaded from /prompts folder.

If unsure:
→ ask clarification instead of guessing.