# Chat Orchestrator Runtime Design

The Orchestrator Lambda is the brain of the system.

It performs controlled reasoning instead of letting LLM act freely.

---

## Responsibilities

1. Load session state
2. Classify intent
3. Detect ambiguity
4. Fetch grounding data
5. Call LLM with structured prompt
6. Validate Query Spec
7. Execute query
8. Format response
9. Update session

---

## Execution Flow

API Gateway
   ↓
Chat Orchestrator Lambda
   ↓
Session Load (DynamoDB)
   ↓
Intent Detection
   ↓
Need Clarification?
   ├─ YES → ask user question
   └─ NO
        ↓
Query Spec Generation
        ↓
Query Execution
        ↓
Response Formatting
        ↓
Session Update

---

## Lambda Duration

Lambda execution is SHORT-LIVED.

Each user message = one Lambda invocation.

There is NO long-running conversation process.

Conversation continuity is achieved via:
→ DynamoDB session persistence.

---

## Internal Modules

orchestrator/
  intent_engine
  clarification_engine
  llm_client
  query_builder
  validator
  executor
  formatter

---

## Golden Rule

LLM never directly queries infrastructure.

All actions go through orchestrator-controlled tools.