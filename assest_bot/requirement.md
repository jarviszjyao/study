# Cloud Resource AI Query — Product Requirements

## 1. Business Context

The company runs workloads across **four cloud providers**:

- **AWS** (ECS, EC2, RDS, etc.)
- **GCP** (e.g. GKE)
- **Azure** (e.g. SQL DB)
- **Alibaba Cloud**

Resources are owned by different teams and scoped by:

- AWS accounts  
- GCP projects  
- Azure subscriptions  
- Alibaba Cloud resource sets  

A **cloud resource administrator** already runs **scheduled scans** and stores resource metadata and configuration in a **relational database**. The goal is to expose this data through an **AI-powered chatbot** so that anyone can query it via natural language.

---

## 2. Problem Statement

Teams need quick, self-service answers about cloud estate (e.g. “How many RDS Postgres 14 instances do we have?” or “Show me resource distribution by platform”). Today this requires either ad hoc SQL, dashboards, or asking the cloud admin. An **AI chatbot** should let users ask in plain language and get structured answers (tables, charts) without writing queries or knowing the schema.

---

## 3. Goals

- **Natural-language queries** over multi-cloud resource and configuration data.
- **Structured outputs**: tables, aggregations, and visualizations (e.g. pie/bar charts) where appropriate.
- **Self-service**: any authorized user can query without writing SQL or understanding the data model.
- **Reuse existing assets**: built on top of the current scanned data and an available LLM, not a full data-ingestion project.

---

## 4. Example Use Cases

| # | Example query | Expected behavior |
|---|----------------|-------------------|
| 1 | “Summarize RDS PostgreSQL versions and group by instance count.” | Table: version, count (and optionally owner). |
| 2 | “Show RDS PostgreSQL version counts by project owner.” | Table or chart by owner. |
| 3 | “Show distribution of resources (or accounts) by cloud platform as a pie chart.” | Pie chart: AWS / GCP / Azure / Alibaba. |
| 4 | “List all AWS accounts under the Finance department.” | Table: account id, name, owner, etc. |
| 5 | “How many EC2 instances per region?” | Table or bar chart by region. |
| 6 | “Top N GCP projects by resource count.” | Table or bar chart. |

The system should support both **tabular** and **chart** answers (e.g. “show me the chart for the distribution on cloud platform by number of accounts”).

---

## 5. Assumptions

- **Data**: Cloud resource and configuration data is already collected and stored in a **relational database** (e.g. RDS/Aurora) with a known schema.
- **LLM**: An **LLM** (e.g. Amazon Bedrock, OpenAI, or similar) is available and can be called from the application.
- **Security & access**: Authentication and authorization (e.g. IAM, SSO, or internal portal) are handled separately; this document focuses on the query and response flow.

---

## 6. Out of Scope (for this requirement)

- Designing or implementing the resource-scanning pipeline.
- Defining the exact database schema (assumed to exist).
- Choosing or training the LLM model.
- Integration with specific chat channels (e.g. Slack, Teams) — can be added later.

---

## 7. Request for Proposal

Given:

1. Existing cloud resource and configuration data in a relational database, and  
2. Access to an LLM API,  

**What is a concrete, implementable architecture and flow** (e.g. API Gateway → orchestration service → LLM → query spec → SQL executor → formatter) so that users can ask questions in natural language and receive tables or charts as above? Please recommend a step-by-step, deployable approach (including safety considerations such as no raw SQL generation by the LLM, validation of query specs, and read-only access).
