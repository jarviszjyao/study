# AI Semantic Query Engine – Copilot Development Instructions

This repository implements an **AI Semantic Query Engine** that allows users to query enterprise metadata using natural language.

The system converts natural language questions into **structured query plans (QuerySpec)** which are then executed deterministically against a database.

The architecture is intentionally designed for:

- enterprise safety
- deterministic execution
- schema stability
- controlled AI usage

Copilot must follow the design principles and rules defined in this document when generating or modifying code.

---

# 1 Core Design Principle

This system is NOT a direct NL-to-SQL generator.

The architecture strictly separates:

LLM reasoning  
and  
deterministic execution

Pipeline:

Natural Language  
→ QuerySpec (LLM output)  
→ SQL Builder (code)  
→ Database execution

LLMs are only used for **intent understanding and query planning**.

All database interaction must be implemented using deterministic code.

---

# 2 System Architecture Overview

The runtime system runs primarily as an **AWS Lambda Query Engine**.

High-level request flow:

User  
→ API Gateway  
→ Lambda Query Runtime  
→ LLM Planner  
→ QuerySpec  
→ QuerySpec Validator  
→ Dataset Resolver  
→ SQL Builder  
→ Database  
→ Response Formatter

The LLM must never directly generate SQL.

---

# 3 Runtime Query Pipeline

The runtime query engine must follow this pipeline order:

1 Parse API request

Extract:

- domain
- user question
- session id (optional)

2 Load domain configuration

Each domain defines:

- database connection
- dataset catalog location
- vector index configuration
- query limits

3 Load dataset catalog

Dataset catalog contains semantic dataset definitions.

Datasets represent logical data sources.

Datasets are NOT database tables.

4 Retrieve relevant datasets

If many datasets exist, use semantic retrieval to select a small subset.

Dataset retrieval may use embeddings and vector search.

5 Build planner prompt context

Planner context includes:

- user question
- candidate datasets
- dataset descriptions
- dataset fields
- example queries

6 Call LLM planner

The LLM converts the question into a structured QuerySpec.

7 Validate QuerySpec

The validator checks:

- dataset exists
- selected fields exist
- filter fields exist
- limit constraints
- allowed operators

8 Resolve dataset

Map logical dataset → physical tables and joins.

9 Generate SQL

SQL must be generated using a deterministic SQL builder.

10 Execute query

Queries must use read-only database connections.

11 Format response

Results are returned as structured JSON or tables.

---

# 4 QuerySpec Specification

The LLM must produce QuerySpec JSON.

Example:

{
  "dataset": "services",
  "select": ["service_name", "department"],
  "filters": [
    {
      "field": "department",
      "operator": "=",
      "value": "finance"
    }
  ],
  "limit": 100
}

QuerySpec rules:

- dataset must exist
- fields must exist
- limit must not exceed system limits
- operators must be allowed

Allowed operators include:

=  
!=  
IN  
LIKE  
>  
<

SQL fragments are not allowed.

---

# 5 Dataset Concept

Datasets represent semantic data sources.

A dataset maps to one or more database tables.

Example dataset definition:

dataset: services

table: service_catalog

description: internal platform services deployed in cloud environments

fields:

service_name  
department  
owner

Datasets may also include:

- description
- keywords
- field descriptions
- example queries

Datasets are stored in a **dataset catalog**.

---

# 6 Dataset Routing

The system may contain many datasets.

The planner must select the correct dataset for a user query.

Dataset routing uses:

- semantic embeddings
- dataset descriptions
- keywords
- example queries

Only a small subset of datasets should be provided to the LLM planner.

This improves:

- accuracy
- prompt size
- performance

The runtime may use vector search to retrieve the top relevant datasets.

---

# 7 Dataset Catalog

Dataset definitions are stored in a dataset catalog.

Example structure:

catalog/

cloud_resources/
services.yaml
resources.yaml
accounts.yaml

api_inventory/
apis.yaml
api_owners.yaml

The runtime loads dataset definitions from this catalog.

Dataset catalog files contain metadata only.

They do not contain real business data.

---

# 8 Metadata Discovery and Dataset Auto-Discovery

Dataset catalogs may be generated automatically using a **metadata discovery pipeline**.

Metadata discovery scans database schemas and generates dataset definitions.

Discovery steps may include:

- scanning database tables
- extracting column metadata
- generating dataset descriptions
- generating keywords
- generating example queries
- generating dataset embeddings

Important rule:

Metadata discovery is an **offline process**.

It must never run during query execution.

Runtime query engines must only read the generated dataset catalog.

Discovery may run using a separate service such as:

services/metadata-discovery

Possible triggers include:

- scheduled Lambda jobs
- CI/CD pipelines
- manual admin triggers

Discovery outputs dataset files into the catalog directory.

Example:

catalog/cloud_resources/services.yaml

The runtime query engine loads these files during query execution.

---

# 9 Deterministic SQL Generation

SQL must be generated by a dedicated SQL builder module.

The LLM must never generate SQL.

SQL builder responsibilities:

- map dataset fields to table columns
- construct SELECT statements
- apply filters
- apply limits
- bind parameters safely

Example SQL:

SELECT service_name, department
FROM service_catalog
WHERE department = :department
LIMIT 100

The SQL builder must prevent:

- SQL injection
- schema mismatch
- uncontrolled joins

---

# 10 Query Guardrails

The runtime must enforce query safety.

Guardrails include:

Row limits

Queries must enforce a maximum row count.

Query timeout

Database queries must have execution time limits.

Operator restrictions

Only approved filter operators are allowed.

Dataset restrictions

Only datasets defined in the catalog may be queried.

---

# 11 Security and Compliance

The system is designed to protect enterprise data.

LLMs must never receive:

- raw database rows
- sensitive business data
- customer information

LLM context may only include:

- dataset metadata
- dataset descriptions
- field definitions
- example queries

Database access must be:

- read-only
- restricted by IAM
- protected with query limits

---

# 12 Multi-Domain Architecture

The system supports multiple data domains.

Examples:

cloud_resources  
api_inventory  
change_logs  
security_findings

Each domain may have:

- separate database
- separate dataset catalog
- separate vector index

Example API request:

{
  "domain": "cloud_resources",
  "question": "list all services"
}

The runtime must load domain configuration dynamically.

---

# 13 Observability

The runtime should log:

request id  
user question  
selected dataset  
generated QuerySpec  
generated SQL  
query execution time

Logs must never contain sensitive data.

Observability helps with:

- debugging
- performance tuning
- query auditing

---

# 14 Repository Structure

Typical repository layout:

core/

shared query engine modules

services/query-runtime/

Lambda runtime

services/metadata-discovery/

metadata discovery pipeline

domains/

domain-specific dataset definitions

catalog/

generated dataset metadata

infra/

infrastructure definitions

tests/

query and planner test cases

---

# 15 Coding Guidelines

When generating code, Copilot must follow these principles:

Keep modules small and focused.

Separate components clearly:

planner  
validator  
dataset resolver  
sql builder  
query executor

Avoid tightly coupled modules.

Use clear interfaces between components.

Prefer dependency injection where possible.

---

# 16 Error Handling

The system must gracefully handle invalid queries.

Common errors include:

unknown dataset  
unknown field  
invalid filter  
invalid QuerySpec

Errors should return structured responses.

Example:

{
  "error": "unknown_dataset",
  "message": "Dataset 'applications' does not exist"
}

---

# 17 Prompt Context Construction

Planner prompts must remain compact.

The runtime should avoid passing all datasets to the LLM.

Instead:

1 perform dataset retrieval  
2 select the most relevant datasets  
3 build prompt context using those datasets

This prevents prompt size explosion and improves LLM accuracy.

---

# 18 Future Extensions

The architecture is designed to support future capabilities:

semantic dataset discovery  
vector-based dataset routing  
cross-dataset queries  
visualization generation  
conversational query sessions

Copilot should avoid generating code that prevents these extensions.

---

# 19 Copilot Behavioral Rules

When generating or modifying code, Copilot must follow these rules:

Never generate SQL directly from natural language.

Always use the QuerySpec pipeline.

Never bypass the QuerySpec validator.

Never scan database schemas during runtime queries.

Never expose database credentials.

Never send real data to LLMs.

Respect the separation between:

LLM reasoning  
and  
deterministic execution.

---

# 20 Final Design Principle

This system follows a strict design philosophy:

LLM for reasoning  
Code for execution

LLMs generate query plans.

The application executes those plans deterministically.

This separation must always be preserved.
