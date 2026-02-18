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

✅ STEP 6 — Copilot Agent 第一条真正开发指令（黄金 Prompt）

在 VS Code Copilot Agent 中输入👇（完整复制）：

🧠 GOLDEN PROMPT — 生成 Orchestrator Skeleton
We are starting implementation.

You must generate ONLY the architectural skeleton for the Chat Orchestrator service.

Follow repository documents and constraints strictly.

GOAL:
Create a clean orchestrator-centered architecture that supports
multi-turn AI conversations.

IMPORTANT RULES:

1. DO NOT implement business logic.
2. DO NOT call real AWS services.
3. DO NOT implement SQL or LLM calls.
4. Create interfaces (ports) and empty implementations only.
5. Follow separation:

   - domain → pure models
   - application → orchestration flow
   - ports → external capabilities
   - adapters → mock implementations

REQUIRED COMPONENTS:

1. Orchestrator
   - receives chat request
   - loads session
   - decides next step
   - calls pipeline

2. Conversation Pipeline
   stages:
   - intent detection
   - clarification check
   - query spec generation
   - skill execution
   - response formatting

3. Step Executor
   executes pipeline stages sequentially.

4. Ports (interfaces only):
   - LLMPort
   - SessionRepository
   - SkillExecutor

5. Domain models:
   - SessionState
   - IntentResult
   - QuerySpec

Each file must include comments explaining responsibility.

Generate minimal but production-grade structure.
Do NOT generate frontend or API controller code.

✅ 为什么这条 Prompt 是“黄金级”

它强制 Agent：

1️⃣ 进入 Hexagonal Architecture（六边形架构）

否则 Copilot 会生成：

controller → service → db


这种传统结构会毁掉你的 AI Orchestrator。

2️⃣ 强制先建立 Pipeline 思维

你的系统本质是：

Conversation = State Machine Pipeline


不是 API 调用。

3️⃣ 防止 Agent 偷偷实现逻辑

AI 很喜欢：

自动写 SQL

自动连 SDK

自动做假设计

这一步完全禁止。

✅ STEP 7 — 生成后你必须检查的 5 件事

让 Copilot 生成完后，检查：

✅ 1. orchestrator 不直接调用 LLM

应该是：

orchestrator
   ↓
LLMPort interface


不是：

import OpenAI / Bedrock

✅ 2. session 是 domain model（不是 DynamoDB）

必须是：

class SessionState {}


而不是 AWS SDK。

✅ 3. pipeline 是可扩展阶段

应该类似：

pipeline.execute([
  IntentStep,
  ClarificationStep,
  QueryPlanningStep
])

✅ 4. Skill 是接口
execute(querySpec): Promise<Result>


而不是 SQL。

✅ 5. 没有 Controller

如果生成了：

app.ts
express router


❌ 让它删除。

✅ STEP 8 — 立即强化 Agent 行为（非常关键）

生成完成后，立刻告诉 Agent：

This orchestrator is the central brain of the system.

All future features must integrate through pipeline stages
instead of adding logic directly into orchestrator.

Confirm understanding.


这一步会极大降低后续架构污染。

✅ 下一步你将进入（真正开始变强的阶段）

下一阶段我们会做：

Phase-2（真正 AI 系统开始）

你将让 Copilot 构建：

Session Memory Engine
+
Context Assembly Engine


这是：

🔥 LLM 能做多轮推理的真正原因

而 90% AI 项目失败就是没这层。