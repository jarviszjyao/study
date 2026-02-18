# Skill Interface Specification

## Purpose

Skills are executable capability modules invoked by the orchestrator.

Examples:

- ECS diagnostics
- RDS health check
- Cloud violation lookup

---

## Interface Contract

Each skill must implement:

# Skill Interface Specification

## Purpose

Skills are executable capability modules invoked by the orchestrator.

Examples:

- ECS diagnostics
- RDS health check
- Cloud violation lookup

---

## Interface Contract

Each skill must implement:


---

## Input

```json
{
  "parameters": {},
  "sessionId": "string",
  "requestId": "string"
}
Output
{
  "success": true,
  "data": {},
  "visualization": {},
  "message": "optional human-readable summary"
}

Requirements

Must be stateless

Must be idempotent when possible

Timeout < 15 seconds

Registration

Skills are registered via:

/skills/registry.json

Example:

ecs_service_health
rds_instance_status
cloud_violation_lookup

Execution Flow

LLM → QuerySpec → Orchestrator → Skill → Result → LLM Summary