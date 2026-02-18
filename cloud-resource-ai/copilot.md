You are joining an existing project.

Before writing any code, you MUST understand the architecture and rules of this repository.

Please do the following:

1. Read and learn project intent from:
   - README.md
   - docs/context-assembly.md
   - docs/error-handling.md
   - docs/skill-interface.md
   - .github/copilot-instructions.md

2. Understand that this is NOT a normal API backend.
   This project implements an AI Orchestrator architecture with:
   - session-aware orchestration
   - LLM structured outputs
   - skill plugin execution
   - visualization contracts

3. Summarize back to me:
   - system architecture
   - orchestrator responsibilities
   - session lifecycle
   - how LLM interacts with skills

DO NOT generate code yet.
Only confirm understanding.


STEP 2 — 让 Agent 建立 Workspace Memory

当 Agent 输出总结后，你继续输入：

Now scan the schemas directory and explain how contracts enforce deterministic AI behavior.
Focus on:
- queryspec.schema.json
- chat.request.schema.json
- chat.response.schema.json
- visualization.schema.json

STEP 3 — 建立“开发规则锁”（90% 人不会做）

接下来输入：

From now on, follow these development constraints:

1. LLM output must always validate against schemas.
2. Business logic lives ONLY in orchestrator.
3. Skills are stateless plugins.
4. Session manager owns conversation memory.
5. Controllers must remain thin.

Confirm you will follow these rules when generating code.

STEP 4 — 验证 Agent 是否真的理解（关键检查）

问一个测试问题：

If I ask "Why is my ECS service unhealthy?",
describe step-by-step what components are involved BEFORE any code is written

STEP 5 — 建立长期 Agent 记忆（隐藏技巧 ⭐）

创建文件：

/docs/agent-context.md


内容：

# Agent Context

This repository implements an AI troubleshooting system using
an orchestrator-centered architecture.

The LLM never directly performs actions.
All actions are executed through skills.

Sessions represent reasoning continuity, not authentication.

All responses must conform to schemas.


然后对 Copilot 说：

Treat agent-context.md as persistent project memory.


以后 Agent 每次都会参考它。