# Access Control Model

Security is enforced OUTSIDE the LLM.

LLM never decides permissions.

---

## Identity Flow

User Login → Cognito → JWT Token

JWT contains:
- user_id
- role
- department_scope

---

## Authorization Layer

Orchestrator applies filters:

Example:

WHERE department IN user.allowed_departments

---

## Principle

LLM generates INTENT.
System enforces ACCESS.

---

## Sensitive Protection

Never expose:
- account credentials
- secrets
- IAM policies
- raw audit logs

Only summarized metadata allowed.