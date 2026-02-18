# Phase 2 — Orchestrator Skeleton

Goal:
Single Lambda handles chat request.

Flow:

API Gateway
 → Orchestrator Lambda
 → return mock response

NO LLM yet.

Response example:

{
  "message": "Orchestrator received input"
}

Definition of Done:

✓ Session loads successfully
✓ User message stored
✓ Response returned