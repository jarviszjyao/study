cloud-resource-ai/
│
├── README.md   （已提供）
├── ARCHITECTURE.md  （已提供）
├── DEVELOPMENT_ROADMAP.md （提供了/doc/dev-guide）
│
├── docs/
│
│   ├── product/ (未提供)
│   │   ├── product-vision.md
│   │   ├── user-personas.md
│   │   └── supported-usecases.md
│   │
│   ├── architecture/
│   │   ├── system-overview.md
│   │   ├── aws-deployment-architecture.md (未提供)
│   │   ├── agent-orchestrator.md (已提供)
│   │   ├── session-management.md  (已提供)
│   │   ├── conversation-state-machine.md （已提供）
│   │   ├── chat-flow.md (未提供)
│   │   └── security-guardrails.md (未提供)
│   │
│   ├── ai/
│   │   ├── llm-interaction-model.md (已提供)
│   │   ├── reasoning-flow.md (已提供)
│   │   ├── prompt-design.md (已提供)
│   │   ├── query-spec.md (已提供)
│   │   └── tool-skill-definition.md (未提供)
│   │
│   ├── data/ (未提供)
│   │   ├── metadata-ingestion.md
│   │   ├── schema-registry.md 
│   │   ├── entity-resolution.md
│   │   └── graph-model-design.md
│   │
│   ├── api/ (未提供)
│   │   ├── chat-api-contract.md
│   │   ├── query-api-contract.md
│   │   └── visualization-response.md
│   │
│   └── diagrams/
│       ├── system-architecture.mmd (未提供)
│       ├── aws-infra-architecture.mmd (未提供)
│       ├── orchestrator-internal-flow.mmd (已提供)
│       ├── session-lifecycle.mmd (已提供)
│       ├── conversation-state-machine.mmd (已提供)
│       ├── llm-interaction-flow.mmd (未提供)
│       └── query-execution-flow.mmd (未提供)
│
│
├── infrastructure/ (不需要提供，另一个过程通过IaC处理)
│   │
│   ├── terraform/
│   │   ├── api-gateway/
│   │   ├── lambda/
│   │   ├── dynamodb/
│   │   ├── aurora/
│   │   ├── opensearch/
│   │   ├── bedrock/
│   │   └── iam/
│   │
│   └── environments/
│       ├── dev.tfvars
│       ├── staging.tfvars
│       └── prod.tfvars
│
│
├── services/
│
│   ├── chat-orchestrator/ (完整)
│   │   ├── README.md
│   │   │
│   │   ├── domain/
│   │   │   ├── session-model.md
│   │   │   ├── intent-model.md
│   │   │   └── slot-definition.md
│   │   │
│   │   ├── orchestration/
│   │   │   ├── flow-description.md
│   │   │   └── state-transitions.md
│   │   │
│   │   ├── llm/
│   │   │   ├── context-builder.md
│   │   │   ├── prompt-contract.md
│   │   │   └── response-schema.md
│   │   │
│   │   ├── session/
│   │   │   ├── repository-design.md
│   │   │   └── lifecycle-policy.md
│   │   │
│   │   └── tools/
│   │       └── tool-catalog.md
│   │
│   ├── query-engine/ (完整)
│   │   ├── query-planner.md
│   │   ├── sql-generation-rules.md
│   │   └── execution-policy.md
│   │
│   ├── entity-service/ (完整)
│   │   ├── entity-index-design.md
│   │   └── resolution-flow.md
│   │
│   └── visualization-service/ (完整)
│       ├── chart-spec.md
│       └── dashboard-contract.md
│
│
├── session/ (完整)
│   ├── session-schema.json
│   ├── session-state-definition.md
│   ├── ttl-policy.md
│   └── audit-and-replay.md
│
│
├── schema-registry/(完整)
│   │
│   ├── registry-definition.md
│   │
│   ├── tables/
│   │   ├── aws_resources.yaml
│   │   ├── gcp_resources.yaml
│   │   ├── azure_resources.yaml
│   │   └── alibaba_resources.yaml
│   │
│   └── examples/
│       └── llm-context-example.json
│
│
├── prompts/ (完整)
│   ├── intent-detection.prompt
│   ├── clarification.prompt
│   ├── query-planning.prompt
│   ├── sql-generation.prompt
│   └── response-formatting.prompt
│
│
├── data-models/ (完整)
│   │
│   ├── relational/
│   │   ├── cloud_accounts.sql
│   │   ├── resources.sql
│   │   ├── departments.sql
│   │   ├── projects.sql
│   │   └── ownership.sql
│   │
│   ├── semantic/
│   │   ├── embedding-strategy.md
│   │   └── vector-index-design.md
│   │
│   └── graph/
│       └── resource-relationship-model.md
│
│
├── frontend/ （(完整)
│   ├── web-demo/
│   │   ├── ui-spec.md
│   │   ├── chat-flow.md
│   │   └── visualization-layout.md
│   │
│   └── api-integration.md
│
│
├── tests/ (完整)
│   ├── conversation-scenarios/
│   │   ├── fuzzy-department.md
│   │   ├── multi-turn-query.md
│   │   └── invalid-request.md
│   │
│   └── evaluation/ 
│       ├── llm-evaluation-spec.md
│       └── benchmark-cases.md
│
│
└── governance/ (完整)
    ├── access-control-model.md
    ├── audit-logging.md
    ├── cost-control.md
    └── data-classification.md