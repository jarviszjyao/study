# Context Assembly Strategy

## Purpose

The orchestrator is responsible for constructing a structured prompt context
before invoking the LLM.

The goal is to provide:

- Conversation continuity
- Relevant operational data
- Minimal token usage
- Deterministic behavior

---

## Context Layers

Context is assembled in the following order:

### 1. System Instructions (Static)

Defines assistant role and constraints.

Example:

- You are a Cloud Troubleshooting AI
- Prefer structured output
- Never hallucinate AWS resource states

---

### 2. Session Memory (Short-term)

Last N conversation turns.

Default:
- Last 6 messages
- Summarized when exceeding token limit

---

### 3. Retrieved Knowledge (Optional)

From:
- Vector DB
- Runbook knowledge
- Documentation

Only included if relevance score > threshold.

---

### 4. Live Operational Context

Examples:

- ECS service status
- Deployment state
- Cloud violations

Provided as structured JSON.

---

### 5. Current User Message

Always appended last.

---

## Assembly Example

[System Prompt]
[Session Summary]
[Operational Context JSON]
[Relevant Knowledge]
User: Why is my service unhealthy?


---

## Token Optimization

If token limit reached:

1. Summarize history
2. Drop low-relevance knowledge
3. Keep operational data intact
