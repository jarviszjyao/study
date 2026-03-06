From Natural Language to Cloud Resource Insights: Building an AI-Driven Query Interface

Modern cloud environments generate enormous amounts of metadata: accounts, services, resources, departments, ownership mappings, cost tags, and operational signals. In many organizations, these datasets are scattered across different systems and stored in relational databases or data lakes. While dashboards and APIs help, answering even simple questions can still require technical knowledge.

For example:
	•	“Which departments own the most AWS services?”
	•	“List all services running in production accounts.”
	•	“Show the top 10 projects consuming the most resources.”

Traditionally, answering these questions requires someone who understands the database schema and SQL. But many stakeholders—platform engineers, DevOps teams, security teams, or managers—may not know how the underlying data is structured.

This led me to explore a simple idea:

What if users could query our cloud resource data using natural language?

Instead of writing SQL, users could ask questions like:

“List all services owned by the finance department.”

Behind the scenes, an AI system translates the request into a precise database query.

This article shares my exploration of building a natural language query interface for cloud resource data, including the system architecture, the reasoning pipeline, and the design decisions needed to make it secure and reliable in an enterprise environment.

⸻

The Motivation

Our internal platform team maintains a portal that maps applications to their cloud resources across multiple AWS accounts. The data includes:
	•	AWS accounts
	•	Services
	•	Departments
	•	Projects
	•	Resource ownership
	•	Metadata and tags

The portal works well when users navigate manually. However, many users still ask questions like:
	•	“Which accounts belong to the payments team?”
	•	“Which services are owned by platform engineering?”
	•	“How many resources does each department have?”

These questions are simple conceptually but require writing SQL queries against multiple tables.

So the goal became clear:

Enable users to query cloud resource metadata using natural language.

The challenge was not just generating SQL, but doing so in a safe, deterministic, and enterprise-compliant way.

⸻

System Architecture Overview

The system architecture is designed as a reasoning pipeline that converts natural language into a structured query plan before executing it against the database.

The high-level flow looks like this:

User Question
     ↓
API Gateway
     ↓
Lambda Orchestrator
     ↓
LLM Planner
     ↓
QuerySpec Validator
     ↓
Dataset Resolver
     ↓
SQL Builder
     ↓
Aurora PostgreSQL
     ↓
Response Formatter

Each stage plays a specific role in ensuring that the system is both flexible and safe.

Step 1: User Input

A user enters a question such as:

“List all services.”

The request is sent through API Gateway, which handles authentication, rate limiting, and routing.

⸻

Step 2: Lambda Orchestrator

The core logic runs inside an AWS Lambda function called the Orchestrator.

Its responsibilities include:
	•	Loading the user session
	•	Assembling query context
	•	Calling the LLM planner
	•	Validating the query
	•	Executing the SQL
	•	Formatting the response

The orchestrator ensures that the system behaves as a controlled pipeline rather than allowing the AI to directly access databases.

⸻

Step 3: LLM Planner (Natural Language → QuerySpec)

Instead of asking the LLM to generate SQL directly, the system first converts the user question into a structured intermediate format called QuerySpec.

Example input:
list all services

Example output:
{
  "dataset": "services",
  "select": ["service_id", "service_name", "department"],
  "limit": 100
}

This design is critical because it separates AI reasoning from database execution.

The LLM only performs semantic interpretation, not SQL generation.

⸻

Step 4: QuerySpec Validation

Before anything touches the database, the system validates the query specification.

Checks include:
	•	Dataset exists
	•	Fields exist
	•	Query limits are enforced
	•	Dangerous patterns are blocked

For example:

limit must be <= 100
dataset must exist
fields must be valid

This step protects the system from malformed or unsafe queries.

Step 5: Dataset Resolver

In most enterprise systems, business concepts do not map directly to database tables.

Dataset: services

For example:

Dataset: services

May actually come from multiple tables:

service_catalog
departments
owners

The Dataset Resolver maps logical datasets to their physical table joins.

Example:
services
↓
service_catalog s
LEFT JOIN departments d

This allows the AI to reason using business concepts rather than raw database schemas.

Step 6: SQL Builder

Once the dataset and fields are resolved, a deterministic SQL builder generates the final query.

Example SQL:
SELECT service_name, department
FROM service_catalog
LIMIT 100;

Importantly, SQL is generated using a structured query builder (AST), not free-form text generation. This ensures:
	•	No SQL injection
	•	Predictable queries
	•	Easy debugging

Step 7: Query Execution

The query runs against an Aurora PostgreSQL read replica with strict safeguards:
	•	Read-only access
	•	Short execution timeouts
	•	Limited result size

This protects the operational database from heavy or unsafe workloads.

Step 8: Response Formatting

The final step converts query results into a user-friendly format such as:

service_name | department
billing      | finance
payments-api | platform

Future versions may also support visualizations such as charts or dashboards.

The Hard Problem: Turning Fuzzy Language into Precise Queries

The most challenging part of this system is bridging the gap between human language and structured data.

Users may say things like:
	•	“Show services owned by finance”
	•	“List the platform team’s services”
	•	“What services belong to payments?”

All of these mean roughly the same thing, but the database requires precise values such as:

department = 'finance'

To solve this, the system provides the LLM with structured metadata context, including:
	•	dataset definitions
	•	field descriptions
	•	known entities (departments, accounts, etc.)

This allows the AI to map fuzzy language to structured fields more accurately.

Enterprise Data Privacy and Compliance

A common concern when using external LLM services is:

Are we exposing sensitive company data?

In this design, the answer is no.

The LLM never receives raw enterprise data. Instead, it only sees:
	•	dataset metadata
	•	schema definitions
	•	field descriptions
	•	the user’s question

For example, the LLM might receive context like:

Dataset: services
Fields:
- service_id
- service_name
- department

But it never receives actual data rows from the database.

All real data queries are executed internally within the company’s infrastructure.

This architecture ensures that:
	•	No production data is sent to the LLM provider
	•	Only metadata is shared
	•	All query execution remains inside the enterprise environment

This approach allows organizations to benefit from AI reasoning while maintaining strict data governance and compliance.

What’s Next

The current prototype already supports natural language queries against a single dataset. The next step is expanding it to support:
	•	Multiple datasets
	•	Cross-table joins
	•	Resource relationships
	•	Visual analytics

Ultimately, the goal is to turn cloud metadata into a self-service knowledge interface for engineering teams.

Instead of searching dashboards or writing SQL, users can simply ask:

“Which departments run the most cloud services?”

And get the answer instantly.

⸻

Natural language interfaces won’t replace traditional analytics tools, but they can dramatically lower the barrier to accessing operational data.

For cloud platform teams, this opens an exciting possibility:

turning infrastructure metadata into an intelligent, queryable knowledge system.


