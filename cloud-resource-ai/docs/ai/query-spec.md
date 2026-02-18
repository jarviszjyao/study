# Query Spec v1

Query Spec is an intermediate representation between
natural language and SQL.

It ensures deterministic execution.

---

## Structure

{
  "dataset": "",
  "metrics": [],
  "dimensions": [],
  "filters": {},
  "group_by": [],
  "aggregation": "",
  "visualization_hint": ""
}

---

## Example 1

User:
"Count PostgreSQL RDS by version"

Query Spec:

{
  "dataset": "aws_rds_instances",
  "metrics": ["count"],
  "dimensions": ["engine_version"],
  "filters": {
      "engine": "postgres"
  },
  "group_by": ["engine_version"],
  "aggregation": "count",
  "visualization_hint": "bar_chart"
}

---

## Rules

- dataset must exist in schema registry
- filters must reference known columns
- aggregation must be deterministic