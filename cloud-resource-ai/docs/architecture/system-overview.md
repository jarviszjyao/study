# System Overview

The platform is an AI-driven cloud resource discovery system.

## Components

### 1. Web Client
Chat interface and visualization rendering.

### 2. API Gateway
Entry point for chat requests.

### 3. Chat Orchestrator (Core Brain)
Responsible for:

- session management
- intent reasoning
- clarification dialog
- query planning

### 4. LLM Service
Provides structured reasoning output.

### 5. Metadata Database
Stores scanned cloud resources.

### 6. Entity Resolution Service
Handles fuzzy matching of departments/projects/accounts.

---

## Design Rule

LLM produces decisions.
System produces execution.