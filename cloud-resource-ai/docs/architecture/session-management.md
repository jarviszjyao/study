# Session Management

A session represents a continuous conversational context
between a user and the system.

---

## Session Definition

A session is identified by:

session_id (UUID)

Stored in DynamoDB.

---

## Session Responsibilities

Session stores:

- recent messages
- resolved entities
- clarification state
- last QuerySpec
- timestamps

---

## Lifecycle

Create → Active → Idle → Expired (TTL)

TTL recommended: 30–60 minutes.

---

## Why Session Exists

Lambda is stateless.

Session provides:

- conversational continuity
- incremental query refinement
- ambiguity resolution

---

## Session Update Rules

Lambda MUST update session:

- after planner decision
- after query execution
- after clarification response
