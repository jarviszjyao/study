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