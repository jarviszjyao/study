# AWS Deployment Architecture

All runtime components are deployed in AWS.

Core Services:

- API Gateway
- Lambda (Orchestrator + Skills)
- Step Functions (conversation workflow)
- DynamoDB (session store)
- Aurora PostgreSQL (resource inventory)
- OpenSearch (semantic search)
- Bedrock (LLM)

Flow:

User → API Gateway → Orchestrator
→ Step Functions
→ Skills
→ Data Layer