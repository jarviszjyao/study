# Development Strategy

This project MUST be developed incrementally.

DO NOT attempt full system generation at once.

Reason:
LLM orchestration systems fail when built top-down.

Instead we build:

Infrastructure Skeleton
→ Session Layer
→ Orchestrator Core
→ Intent Detection
→ Query Spec Generation
→ Execution Layer
→ UI Integration
→ Observability

Each phase must be runnable before moving forward.