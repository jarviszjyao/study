# Infrastructure Design — Cloud Resource AI Query

- **Overview**
- Purpose: infrastructure for the Chat Orchestrator as described in `README.md`. The design follows the project's assumptions: the API Gateway is created by Terraform, the Chat Orchestrator runs in Lambda with two layers (lib + app), and the Query Executor logic runs inside the Lambda app layer by default.

**High-level components (aligned to README)**
- Edge / Demo: `S3` (demo UI) optionally fronted by `CloudFront`.
- API: `API Gateway` — created and managed by Terraform per README (not provided by this repo).
- Compute: `Chat Orchestrator Lambda` (single Lambda). Lambda uses two layers:
	- `lib layer`: DB client (`pgclient`) and shared native libs
	- `app layer`: this project's Python code deployed via the pipeline
	The Query Executor logic executes within this Lambda (short SQL queries, validation, formatting).
- Data: `Amazon Aurora (PostgreSQL)` in Multi-AZ private subnets; read replicas for reporting.
- Secrets: `AWS Secrets Manager` for DB credentials and external LLM keys.
- Messaging: `SQS` for optional asynchronous jobs and decoupling long-running tasks.
- Observability: `CloudWatch` + `X-Ray` for tracing; structured logs for analysis.

**Network & Availability**
- Database and Lambda run in private subnets across multiple AZs.
- API Gateway lives in public subnets and is created externally (Terraform). Use WAF in front of the Gateway if required.
- Configure VPC Endpoints for S3 and Secrets Manager to keep service traffic inside AWS.

**Security**
- Use IAM roles with least-privilege for Lambda and any executor.
- Store DB credentials and LLM API keys in Secrets Manager with rotation enabled.
- Enable TLS for external LLM API calls and enforce encryption at rest for Aurora.

**Scaling & Cost (practical guidance given README constraints)**
- Lambda handles short-running orchestrations and scales automatically; set concurrency limits to control costs.
- For heavier analytical queries or long-running transformations, prefer one of:
	- Move heavy Query Executor to ECS/Fargate and trigger via SQS (recommended if queries can block or exceed Lambda limits).
	- Use Aurora read replicas or materialized views to reduce load on the primary DB.

**Observability & Operations**
- Emit structured logs (JSON) from Lambda to CloudWatch; create dashboards for latency, error rate, number of DB connections, and cost.
- Use X-Ray to trace the request path: API Gateway → Lambda → (optional) Executor → Aurora.

**CI/CD & Deployment (per README)**
- The repo provides application code only; infrastructure resources like API Gateway and Lambda creation are managed by Terraform outside this repo.
- Use the pipeline described in README to deploy the `app layer` to Lambda. If moving heavy work to containers, push images to ECR and use pipeline to update ECS/Fargate services.

**Operational notes (aligned)**
- Ensure the Lambda `lib layer` includes the correct native DB client for the target runtime and Aurora.
- Implement retry/backoff for external LLM APIs and record metrics for failed calls.
- Consider exporting a lightweight usage/cost report to monitor LLM API costs.

**Files added / updated**
- PlantUML diagram: [study/assest_bot/docs/infra_architecture.puml](study/assest_bot/docs/infra_architecture.puml)
- Mermaid diagram: [study/assest_bot/docs/infra_architecture.mmd](study/assest_bot/docs/infra_architecture.mmd)
- This design doc (updated): [study/assest_bot/docs/infra_design.md](study/assest_bot/docs/infra_design.md)

---
Next steps I can take for you:
- Generate a minimal Terraform skeleton for API Gateway + Lambda role bindings (does not create DB).
- Create a GitHub Actions workflow to deploy the `app layer` to Lambda (upload zip to S3 and call pipeline).
- Produce PNG/SVG exports of the diagrams for inclusion in the README.

---
If you'd like, I can:
- Generate a Terraform skeleton for these resources.
- Convert these diagrams into PNG/SVG files for documentation.
- Produce GitHub Actions workflows for CI/CD.
