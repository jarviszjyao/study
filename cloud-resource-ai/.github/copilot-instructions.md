
---

# ✅ 8️⃣ `.github/copilot-instructions.md`

这是 **非常关键** 的文件 —— 让 VS Code Copilot Agent 按你的架构写代码。

```md
# Copilot Instructions for AI Troubleshooter Project

## Architecture Overview

This project follows an Orchestrator-based AI architecture.

Main components:

- Web UI
- API Gateway
- Orchestrator (core brain)
- LLM Adapter
- Skill Plugins
- Session Manager

---

## Coding Principles

1. Prefer strongly typed interfaces.
2. All LLM outputs must validate against JSON schema.
3. Business logic MUST live in orchestrator layer.
4. Skills must remain independent modules.
5. No direct AWS calls from controllers.

---

## Folder Responsibilities

| Folder | Responsibility |
|---|---|
| orchestrator | workflow logic |
| skills | cloud capability plugins |
| llm | model interaction |
| session | memory management |
| schemas | contracts |

---

## LLM Interaction Rules

- Always request structured JSON output.
- Never trust raw LLM text.
- Validate using schema before processing.

---

## Error Handling

Use centralized error handler.

Never throw raw exceptions to API layer.

---

## Naming Convention

snake_case for skill names:

ecs_service_health
cloud_violation_lookup

ecs_service_health
cloud_violation_lookup