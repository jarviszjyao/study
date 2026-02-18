# Cloud Resource AI Query

AI-powered chatbot for querying multi-cloud resource configuration via natural language.

## Architecture

```
User (Web/API) → API Gateway → Chat Orchestrator (Lambda) → LLM (API)
                                    ↓
                            Query Spec (JSON)
                                    ↓
                         Query Executor (in Lambda) → Aurora PostgreSQL
                                    ↓
                         Response Formatter → User
```

## Assumptions

| Component | Assumption |
|-----------|------------|
| **User (Web/API)** | Built by another team. This project provides a **demo page** for testing only. A process API may not be required if the Web app calls the Chat Orchestrator via API Gateway directly. |
| **API Gateway** | Created and configured separately by Terraform. No IaC in this project. Required settings are documented in [docs/API_GATEWAY_SETTINGS.md](./docs/API_GATEWAY_SETTINGS.md). |
| **Chat Orchestrator (Lambda)** | Lambda is created by Terraform with two layers: (1) **lib layer** — includes pgclient for Aurora PostgreSQL; (2) **app layer** — this project. We only prepare Python code and deploy the app layer via the existing deployment pipeline. |
| **LLM (API)** | Provided by another team (GPT-4.1 or similar via AWS Bedrock). Transparent to this project. We call the APIs; configuration selects one of two possible API endpoints. |
| **Query Spec (JSON)** | Implemented in this project. Must support various query types and be easily extensible. |
| **Response Formatter** | Implemented in this project. Must output formats sufficient for the Web chat lib to render chats, lists, tables, and **pivot tables**. |
| **User** | Cloud engineers, leads, ITSOs, stakeholders. Queries in **English or Chinese**. May not match the query spec on first attempt; multi-round clarification is expected. |

## Project Structure

```
assest_bot/
├── src/
│   ├── orchestrator/     # Chat Orchestrator Lambda (app layer)
│   ├── executor/         # Query Executor (invoked by orchestrator)
│   ├── formatter/        # Response formatting (table, chart, pivot)
│   └── shared/           # Config, models, utilities
├── api/                  # Optional local dev API (for demo only)
├── schema/               # Query Spec schema, extensible resource mappings
├── docs/                 # API Gateway settings, deployment notes
├── tests/
└── demo.html             # Demo page for testing
```

## Quick Start

### Local Development

```bash
python -m venv .venv
.venv\Scripts\activate   # Windows
# source .venv/bin/activate  # Linux/macOS

pip install -r requirements.txt
copy .env.example .env

# Run local API (optional, for demo)
uvicorn api.main:app --reload
```

### Deployment

- **Lambda**: Terraform creates the function and layers. This repo’s Python code is deployed to the **app layer** via the existing pipeline.
- **API Gateway**: See [docs/API_GATEWAY_SETTINGS.md](./docs/API_GATEWAY_SETTINGS.md).

## Docs

- [requirement.md](./requirement.md) — Product requirements
- [flow.md](./flow.md) — Architecture flow
- [docs/API_GATEWAY_SETTINGS.md](./docs/API_GATEWAY_SETTINGS.md) — Required API Gateway configuration
- [docs/flow.puml](./docs/flow.puml) — PlantUML sequence diagram (end-to-end flow)
- [docs/flow_activity.puml](./docs/flow_activity.puml) — PlantUML activity diagram (Orchestrator decision flow)
- [docs/flow_component.puml](./docs/flow_component.puml) — PlantUML component diagram
- [docs/flow.md](./docs/flow.md) — Flow diagram overview and Mermaid preview
- [docs/LAMBDA_ENV_VARS.md](./docs/LAMBDA_ENV_VARS.md) — Lambda architecture (single Lambda) and environment variables
