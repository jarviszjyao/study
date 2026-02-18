# API Gateway Settings

API Gateway is created and configured separately by Terraform. This document outlines the settings required to integrate with the Chat Orchestrator Lambda.

## Endpoint

| Method | Path | Integration |
|--------|------|-------------|
| POST | `/query` | Lambda (Chat Orchestrator) |

## Request / Response

### Request

- **Content-Type**: `application/json`
- **Body**:
  ```json
  { "question": "List AWS accounts under Finance department" }
  ```

### Response

- **Content-Type**: `application/json`
- **Body** (examples):
  - Executable:
    ```json
    {
      "decision": "executable",
      "result": {
        "format": "table",
        "title": "AWS Accounts",
        "columns": ["account_id", "account_name", "owner"],
        "rows": [["123456789012", "finance-prod", "Finance"], ...]
      }
    }
    ```
  - Clarify:
    ```json
    {
      "decision": "clarify",
      "clarification": {
        "message": "Which cloud platform do you mean?",
        "suggestions": ["AWS", "Azure", "GCP"]
      }
    }
    ```
  - Unsupported:
    ```json
    {
      "decision": "unsupported",
      "message": "This query type is not supported."
    }
    ```

## CORS

Enable CORS if the Web app is served from a different origin:

- **Access-Control-Allow-Origin**: per policy (e.g. `*` for demo, specific domain for prod)
- **Access-Control-Allow-Methods**: `POST, OPTIONS`
- **Access-Control-Allow-Headers**: `Content-Type`

## Auth

- Auth (IAM / Cognito / API Key) is configured by Terraform and is outside this project’s scope.
- Lambda execution role must have Bedrock invoke permissions and VPC access (if DB is in VPC).
