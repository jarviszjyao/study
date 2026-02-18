# Cloud AI Assistant

Enterprise conversational interface for querying multi-cloud
resource metadata stored in a centralized database.

The system runs entirely on AWS and uses an AI Orchestrator
to convert natural language into structured queries.

IMPORTANT RULES:

1. LLM never generates SQL.
2. Query execution only via Query Spec abstraction.
3. Session memory stored in DynamoDB.
4. Orchestrator controls reasoning workflow.
5. Database is the single source of truth.

Refer to /docs for system specification.