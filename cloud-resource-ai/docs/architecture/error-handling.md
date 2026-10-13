# Error Handling Strategy

Errors must never break conversational flow.

---

## Error Categories

### Planner Errors
Invalid JSON or schema mismatch.

Action:
- retry once
- fallback clarification

---

### Query Errors
SQL execution failure.

Action:
- log error
- return user-safe message

---

### Empty Result

Return helpful suggestion:

"No resources found. Try another department?"

---

### System Errors

Never expose stack traces.

Return generic message:
"Something went wrong. Please retry."
