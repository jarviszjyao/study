Below is the exact response returned by the humanization API (word-for-word, unchanged as required):

⸻

From Natural Language to Cloud Resource Insights: Building an AI-Driven Query Interface

We live in a world where modern cloud infrastructures produce vast amounts of metadata, including accounts, services, resources, departments, ownership information, cost tags, and operating signals. In a typical organization, this information is spread across various systems, residing in a relational database or a data lake. Although using a dashboard or API can provide some relief, answering even simple questions about this information still poses a technical challenge. Some examples of such questions are:
	•	“Which departments own the maximum number of AWS services?”
	•	“List all services running in production accounts.”
	•	“List the top 10 projects consuming the maximum amount of resources.”

Typically, answering these questions would require someone who is familiar with the database schema and SQL. Unfortunately, this might not be the case with platform engineers, DevOps, security, or managers who need this information. This led me to think about a simple idea:

What if users could query our cloud resource data using a natural language query?

This means, instead of using SQL, users could ask questions like:

“List all services owned by the finance department.”

This would, behind the scenes, get translated into a specific database query using an AI system.

This article is about my exploration of how we could create a natural language query interface for our cloud resource data, including the system architecture, the reasoning pipeline, and the design considerations necessary to make this work securely and reliably in an enterprise setting.

⸻

The Motivation

We, being a platform team, maintain a portal that maps applications to their respective cloud resources across various AWS accounts. This information includes:
	•	AWS accounts
	•	Services
• Departments
• Projects
• Resource ownership
• Metadata and tags

Although the portal works well for users who want to manually perform the queries, many users still want to ask questions like:
• “What accounts does the payments team own?”
• “What services does platform engineering own?”
• “How many resources does each department own?”

These are simple queries conceptually, but they require us to write SQL queries against multiple tables. So the goal became clear:
“Allow users to query the cloud resource metadata using natural language queries.”

But the challenge was not simply to generate the SQL queries. The challenge was to generate the queries in a way that was safe, deterministic, and enterprise compliant.

⸻

System Architecture Overview

The system architecture is designed as a reasoning pipeline that uses natural language queries to generate a structured query plan before executing the query against the database.

Here is the overall flow of the architecture:

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

Each of the components in the architecture has a specific responsibility in the overall process of making the system flexible and safe.

Step 1: User Input

A user wants to ask the following question:
“List all services.”

⸻

Step 2: Lambda Orchestrator

The logic for the system is inside an AWS Lambda function named the Orchestrator.

The tasks of the Orchestrator are:
• Loading the user session
• Assembling the context for the query
• Running the LLM planner
• Validating the query
• Running the SQL
• Running the formatter

The orchestrator guarantees that the system is controlled and acts like a controlled pipeline, as opposed to allowing direct access by the AI.

⸻

Step 3: LLM Planner (Natural Language → QuerySpec)

Instead of asking the LLM to generate SQL code, the system uses an LLM to generate an intermediate data structure, which is called QuerySpec.

Example input:
list all services

Example output:

{
“dataset”: “services”,
“select”: [“service_id”, “service_name”, “department”],
“limit”: 100
}

This is an important step because it disconnects AI reasoning from database execution.

The LLM is simply doing semantic interpretation, and it doesn’t have to generate SQL code.

⸻

Step 4: QuerySpec Validation

The system validates the query specification before anything is sent to the database.

The validation checks include:
• Does the dataset exist?
• Do the fields exist?
• Does the query have limits?
• Is it safe?

Example:

limit must be <= 100
dataset must exist
fields must be valid

This is an important step to safeguard against invalid and potentially harmful queries.

Step 5: Dataset Resolver

In an enterprise system, data concepts do not necessarily exist as database tables.

Dataset: services

Example:
Dataset: services

This dataset might actually be derived from two database tables:
service_catalog
departments
owners

The Dataset Resolver maps concepts to their physical joins.

Example:

services
↓
service_catalog s
LEFT JOIN departments d

This allows the AI to think at the business level, not at the database level.

Step 6: SQL Builder

Now that we have our dataset and our fields, we can generate our SQL code.

Example:

SELECT service_name, department
FROM service_catalog
LIMIT 100;

Important to note is that SQL is generated using a structured query builder, rather than a text generator. This ensures that:
• There is no SQL injection
• The SQL is predictable
• There is ease of debugging

Step 7: Query Execution

This query is executed on an Aurora PostgreSQL read replica database with tight access controls in place, including:
• Read-only access
• Short execution time
• Limited result size

This ensures that the database used in production is not overloaded or misused.

Step 8: Response Formatting

The final step involves transforming the query results into a user-friendly format, such as:

• service_name | department
	•	billing | finance
	•	payments-api | platform

Future versions could also display graphs or dashboard views, depending on the query results.

The Hard Problem: Fuzzy Language to Structured Queries

The hardest part of this system is the gap between how a user thinks about data, represented by language, and how a database represents data, represented by a query.

A user might ask the system to perform a query such as:
• “Show services owned by finance”
• “List the services owned by the platform team”
• “What services belong to payments?”

These are all the same thing, but the database wants a specific value, such as:

• department = ‘finance’

To perform this mapping, the LLM is provided with some context about the data, including:
• dataset definition
• field definition
• known entities (departments, accounts, etc.)

This makes it easier to map language to a database query.

Enterprise Data Privacy and Compliance

A key concern when using LLM services is whether we’re exposing our company data to a third party. In this system, the answer is a firm ‘no.’

Why? Because the LLM is not provided with any actual data, but rather with:
• dataset metadata
• schema definitions
• field descriptions
• the user’s question

The context provided to the LLM might look like this:

Dataset: services
Fields:
service_id
service_name
department

But no actual data is sent to the LLM from the database.

All data queries are performed internally and are contained within the company’s environment.

This design enables us to take full advantage of AI reasoning, ensuring data governance and data compliance for the organization.

What’s Next

The current prototype is already capable of handling natural language queries for a single dataset. The next step is to extend this to accommodate:
• Multiple datasets
• Cross-table joins
• Resource relationships
• Visual analytics

The end result is to create a self-service interface for the organization’s engineering teams using the cloud metadata.

The idea is to ask a natural language query, such as:

“Which departments have the highest number of cloud services?”

And get the answer instantly.

⸻

Natural language query tools will not replace traditional analytics tools, but they will greatly reduce the barrier for accessing data for many organizations.

For the cloud platform teams, this presents an exciting opportunity to:
Turn our infrastructure metadata into an intelligent, queryable knowledge system. 🚀
