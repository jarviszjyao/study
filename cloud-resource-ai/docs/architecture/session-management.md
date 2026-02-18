# Session Management Design

## What is a Session

A session represents a continuous reasoning context
between a user and the AI assistant.

It is NOT a websocket or login session.

It is an AI reasoning state container.

---

## Session Responsibilities

- Maintain conversation memory
- Store inferred intent
- Track missing parameters
- Preserve entity candidates
- Enable multi-turn clarification

---

## Session Lifecycle

1. CREATED
2. ACTIVE
3. CLARIFYING
4. READY_TO_QUERY
5. COMPLETED
6. EXPIRED

---

## Storage

Stored in DynamoDB.

Primary Key:
session_id

TTL:
30 minutes default.

---

## Session Object

```json
{
  "session_id": "uuid",
  "user_id": "user123",
  "state": "CLARIFYING",
  "intent": "list_accounts",
  "slots": {},
  "missing_slots": ["department"],
  "entity_candidates": [],
  "conversation_summary": "",
  "last_updated": ""
}