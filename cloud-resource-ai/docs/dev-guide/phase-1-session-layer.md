# Phase 1 — Session Layer

Goal:
Conversation persistence works BEFORE LLM integration.

Tasks:

1. Create DynamoDB table:
   chat_sessions

2. Implement:
   - create_session
   - load_session
   - update_session
   - expire_session

3. API endpoint:
   POST /session/start

Test:

curl start session
refresh page
session still exists

Definition of Done:

✓ Session survives multiple requests
✓ TTL works
✓ Conversation history appendable