Here is the exact response returned by the humanization API (unchanged as required):

⸻

From Natural Language to Cloud Resource Insights: Building an AI-Driven Query Interface

In the realm of modern cloud computing, vast amounts of metadata are being generated, such as accounts, services, resources, departments, ownership information, cost tags, and operational status. This information is often currently housed in relational databases or data lakes within the organization. Although using dashboards and APIs is beneficial, even simple queries require knowledge of the underlying infrastructure.

Here are some examples of queries that might be made:
• “Which departments own the most AWS services?”
• “List all services running in the production accounts.”
• “List the top 10 projects that use the most resources.”

These queries would require knowledge of the database schema and basic knowledge of SQL. However, many stakeholders, such as platform engineers, DevOps, security, and management, might not have the knowledge of the underlying database schema.

This was the impetus for the simple idea of: What if users could simply use natural language to query the data?

Instead of using SQL, the user could simply ask:
“List all services owned by the finance department.”

Under the hood, the system would use an AI system to convert the natural language into a database query.

In this article, I will discuss the construction of the natural language query interface for the cloud resource information, including the system architecture, reasoning, and safety considerations for the construction of the natural language interface in the context of an enterprise environment.

⸻

The Motivation

Within our organization, the internal platform group maintains a portal that maps applications to cloud resources across multiple AWS accounts. This information includes:
• AWS accounts
• AWS services
• Departments
• Projects
• Resource ownership information
• Metadata and tags

Although the portal works well for navigation, users often ask the following types of questions:
• “Which accounts belong to the payments team?”
• “Which services are owned by platform engineering?”
• “How many resources does each department have?”

The above questions, though simple, involve querying multiple data tables via SQL.

The above problem has been addressed, and it is now clear what we want to achieve: provide users with the ability to query metadata related to cloud resources via natural language, all while ensuring safety, determinism, and enterprise compliance.

⸻

System Architecture Overview

The architecture is designed as a reasoning pipeline that processes the user’s natural language query into a structured query plan before executing anything against the database.

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

The above architecture is designed to guarantee safety and control.

Step 1: User Input

The user inputs a question, such as:
“List all services.”

The user’s input is then handled by the API Gateway, which is responsible for authentication, rate limiting, and routing.

⸻

Step 2: Lambda Orchestrator

The core logic is handled by an AWS Lambda function, which is referred to as the Orchestrator. This is where all the heavy lifting takes place, and it consists of:
• User session loading
• Query context building
• LLM planner
• Query validation
• SQL execution
• Response building

This architecture is designed so that the AI is never exposed to the database.

⸻

Step 3: LLM Planner (Natural Language → QuerySpec)

Instead of generating SQL, we will be converting our user’s request into a structured data format referred to as QuerySpec.

Example:
list all services

Example:

{
  "dataset": "services",
  "select": ["service_id", "service_name", "department"]
  "limit": 100
}

Separation of concerns between AI reasoning and database execution.

⸻

Step 4: QuerySpec Validation

The system validates the query before executing it. It checks for the following:
• Dataset exists
• Fields exist
• Limit checks
• Unsafe patterns

Examples of rules:
limit < 100
valid dataset
valid fields

Validation ensures that the query is valid.

⸻

Step 5: Dataset Resolver

Most business concepts don’t map directly to tables. For instance, the logical dataset services could span several tables:
• service_catalog
• departments
• owners

The Dataset Resolver maps the logical dataset to the actual tables, including the joins. For the above logical dataset, the actual dataset would look like this:

services
↓
service_catalog s
LEFT JOIN departments d

This enables the AI to think in terms of business logic, rather than database logic.

⸻

Step 6: SQL Builder

Finally, the actual SQL is generated using a deterministic SQL builder.

For instance, the actual SQL generated for the above logical dataset would look like this:

SELECT service_name, department
FROM service_catalog
LIMIT 100;

The actual SQL is generated using a structured query builder, also called Abstract Syntax Tree (AST). Benefits of using AST:
• Avoids SQL injection attacks
• Predictable queries
• Debugging is easier

⸻

Step 7: Query Execution

Queries are executed on an Aurora PostgreSQL read replica. Execution is restricted for safety:
• Read-only
• Timed out after short intervals
• Limited results

⸻

Step 8: Response Formatting

The results of the query execution are then sent back in an easily readable format, for instance:

service_name | department
billing | finance
payments-api | platform

Future versions could also return charts.

⸻

The Hard Problem: Translating Fuzzy Language

The hardest part is mapping human language to a structured query.

The user might ask:
“Show services owned by finance”
“List services owned by the platform team”
“What services are owned by payments?”

These all imply some variant of this statement:
department = ‘finance’

To make this more accurate, the LLM receives structured context, such as dataset definition, field description, and known entities (departments, accounts, etc.).

⸻

Enterprise Data Privacy and Compliance

Another concern when using LLMs is data exposure. In this system, the LLM is not exposed to any actual enterprise data. It only receives:
• Dataset metadata
• Dataset definition
• Field description
• The user’s question

Example:

Dataset: services
Fields:
service_id
service_name
department

Actual database rows are not shared with the LLM. All interactions are contained within the company’s infrastructure.

⸻

What’s Next

This current prototype works with a single dataset using natural language. There are a number of improvements to make, including:
• Multiple datasets
• Cross-table joins
• Resource relationships
• Visual analytics

The end goal is a self-service knowledge system for engineering teams.

Instead of using a dashboard or typing a query, a user can simply ask:
“Which departments use the most cloud services?”

Instant answer. 🚀
