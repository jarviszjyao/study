User (Web / Portal / API Client)
        ↓
API Gateway
        ↓
Chat Orchestrator (Lambda)
        ↓
LLM (Amazon Bedrock)
        ↓
Query Spec Generator
        ↓
Query Executor (Lambda → DB / API)
        ↓
Response Formatter
        ↓
User



二、你每一层具体用什么 AWS 服务（不纠结）
1️⃣ 前端（先简单）

Web Portal / 内部门户

一个输入框 + 一个结果区

HTTP POST 原始问题

👉 不要先做 IM / Slack 集成

2️⃣ API 层

Amazon API Gateway

Auth：IAM / Cognito / 内网

Logging：CloudWatch

Throttling：默认即可

3️⃣ Chat Orchestrator（核心控制点）

AWS Lambda（Python）

它做 6 件事（非常重要）：

接收用户问题

调用 LLM（Bedrock）

解析 LLM 输出（不是直接执行）

判断：

✅ 可执行

❓ 需要澄清

❌ 不支持

生成 / 校验 Query Spec

调用查询执行器

这是整套系统最关键的 Lambda

4️⃣ LLM（只做一件事）

Amazon Bedrock（Claude / Llama / Titan 都行）

⚠️ 严格约束职责：

输入：用户问题 + 系统 schema

输出：

语义结构（JSON）

或 Clarification Request

❌ 不让它：

写 SQL

决定执行

碰数据库

5️⃣ Query Spec（你的护城河）

你之前让我写的 Query Spec v1
在这里直接用 ✔️

示例：

{
  "resource": "aws_account",
  "filters": [
    { "field": "department", "op": "=", "value": "Finance" }
  ],
  "select": ["account_id", "account_name", "owner"],
  "limit": 100
}

6️⃣ Query Executor（傻一点反而安全）

另一个 Lambda（只干一件事）

校验 Query Spec

翻译成 SQL

查询 RDS / Aurora

返回结果

👉 它完全不理解自然语言

7️⃣ 数据层（你已经有）

Aurora / RDS

定时扫描同步的云资源数据

标准化 schema