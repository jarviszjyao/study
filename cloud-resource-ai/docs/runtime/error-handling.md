# Error Handling Strategy

## Principles

1. Errors must be structured
2. User-safe messages only
3. Internal debugging separated

---

## Error Categories

### LLM Errors

Examples:
- Invalid JSON output
- Timeout
- Token overflow

Handling:
- Retry once
- Fallback to clarification response

---

### Skill Execution Errors

Examples:
- AWS API failure
- Permission denied
- Resource not found

Response:

message: "I couldn't retrieve the ECS service status."
debug.reason: "AccessDeniedException"

message: "I couldn't retrieve the ECS service status."
debug.reason: "AccessDeniedException"


---

### Orchestrator Errors

Examples:
- Session missing
- Schema validation failure

Return:

HTTP 400 or 500 with structured payload.

---

## Retry Policy

| Component | Retry |
|---|---|
| LLM | 1 |
| Skill | 2 (idempotent only) |
| Visualization | 0 |

---

## Observability

All errors must emit:

- requestId
- sessionId
- timestamp
- component
