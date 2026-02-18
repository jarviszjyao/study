# Query Planner

Converts Query Spec into executable query instructions.

The planner validates:

- dataset exists
- filters valid
- allowed aggregations

---

## Planner Responsibilities

1. Validate Query Spec
2. Apply policy constraints
3. Forward to SQL generator