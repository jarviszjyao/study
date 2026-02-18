# Lambda Architecture & Environment Variables

## One Lambda, Not Multiple

**Important**: There is **only one Lambda function** in this project — the **Chat Orchestrator**.

```
src/
├── orchestrator/   ← Lambda handler (entry point)
├── executor/       ← In-process module (called by orchestrator)
├── formatter/      ← In-process module (called by orchestrator)
└── shared/         ← Shared config, models, utilities
```

- **orchestrator**: The Lambda handler. Invoked by API Gateway.
- **executor**: Runs inside the same Lambda process. Called via `execute_query(spec)`.
- **formatter**: Runs inside the same Lambda process. Called via `format_response(...)`.
- **shared**: Config loader, models, etc. Used by all modules.

There is **no inter-Lambda invocation**. All logic runs in one process. No Lambda-to-Lambda environment variables are needed.

---

## Required Environment Variables

These variables must be set on the **Chat Orchestrator Lambda** (Terraform or Console).

### LLM API

| Variable | Description | Example |
|----------|-------------|---------|
| `LLM_PROVIDER` | Which LLM to use: `bedrock` \| `bedrock_alt` \| `mock` | `bedrock` |
| `AWS_REGION` | AWS region (for Bedrock) | `us-east-1` |
| `BEDROCK_MODEL_ID` | Primary Bedrock model ID | `anthropic.claude-v2` |
| `BEDROCK_ALT_MODEL_ID` | Alternative model (when `LLM_PROVIDER=bedrock_alt`) | (optional) |
| `BEDROCK_ALT_REGION` | Alternative region for alt model | (optional) |
| `USE_MOCK_LLM` | `1` = use mock (no real API). For demo only | `0` |

### Aurora PostgreSQL (RDS)

| Variable | Description | Example |
|----------|-------------|---------|
| `DB_HOST` | Aurora/RDS endpoint | `my-aurora.cluster-xxx.us-east-1.rds.amazonaws.com` |
| `DB_PORT` | Port | `5432` |
| `DB_NAME` | Database name | `cloud_resources` |
| `DB_USER` | DB user | `app_user` |
| `DB_PASSWORD` | DB password | (sensitive) |

### Lambda & Network

| Variable | Description |
|----------|-------------|
| `AWS_REGION` | Usually set by Lambda runtime; can override |
| VPC config | If DB is in VPC, Lambda must be in same VPC and have subnet/SG allowing DB access |

---

## Using Secrets Manager for DB Credentials

Instead of plain env vars for `DB_USER` and `DB_PASSWORD`, store them in AWS Secrets Manager and reference the secret in Lambda:

1. Create a secret (e.g. `cloud-resources-db-credentials`) with JSON:
   ```json
   {
     "username": "app_user",
     "password": "xxx"
   }
   ```

2. Grant the Lambda execution role permission to read the secret:
   ```hcl
   # Terraform
   resource "aws_iam_role_policy" "lambda_secrets" {
     ...
     policy = jsonencode({
       Statement = [{
         Effect   = "Allow"
         Action   = ["secretsmanager:GetSecretValue"]
         Resource = "arn:aws:secretsmanager:REGION:ACCOUNT:secret:cloud-resources-db-*"
       }]
     })
   }
   ```

3. Add env var:
   - `DB_SECRET_ARN` = ARN of the secret

4. Update `src/shared/config.py` or `src/executor/db_client.py` to fetch user/password from Secrets Manager when `DB_SECRET_ARN` is set, and fall back to `DB_USER`/`DB_PASSWORD` otherwise.

---

## IAM Permissions for Lambda

| Permission | Purpose |
|------------|---------|
| `bedrock:InvokeModel` | Call LLM (Bedrock) |
| `ec2:CreateNetworkInterface`, `ec2:DescribeNetworkInterfaces`, `ec2:DeleteNetworkInterface` | VPC access (if Lambda in VPC) |
| `secretsmanager:GetSecretValue` | (Optional) Read DB credentials |

---

## Summary

| Question | Answer |
|----------|--------|
| Multiple Lambdas? | No. One Lambda (Chat Orchestrator). |
| Lambda-to-Lambda env vars? | Not needed. |
| LLM connection | Via `LLM_PROVIDER`, `BEDROCK_MODEL_ID`, etc. |
| DB connection | Via `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` (or Secrets Manager). |
