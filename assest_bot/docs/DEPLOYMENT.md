# Deployment Notes

## Lambda App Layer

The Chat Orchestrator Lambda is created by Terraform with two layers:

1. **Lib layer**: Includes `psycopg2` (or pgclient) for Aurora PostgreSQL. Do not bundle DB client in the app layer.
2. **App layer**: This project’s Python code. Deploy via the existing deployment pipeline.

## Dependencies for App Layer

The app layer should include only:

- `boto3` (for Bedrock) — typically provided by Lambda runtime
- Project code under `src/`

Do **not** bundle `psycopg2` — it comes from the lib layer.

## Environment Variables

Configure via Lambda environment (or SSM/Secrets Manager):

| Variable | Description |
|----------|-------------|
| `LLM_PROVIDER` | `bedrock` \| `bedrock_alt` \| `mock` |
| `AWS_REGION` | Default region |
| `BEDROCK_MODEL_ID` | Primary Bedrock model |
| `BEDROCK_ALT_MODEL_ID` | Alternative model (when `LLM_PROVIDER=bedrock_alt`) |
| `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` | Aurora PostgreSQL connection |

## Query Spec Extensibility

To add new query types:

1. Add resource type to `src/orchestrator/query_spec.py` → `ALLOWED_RESOURCES`
2. Add table mapping in `src/executor/spec_to_sql.py` → `RESOURCE_TABLE_MAP`
3. Add schema in `schema/resource_tables.json`
