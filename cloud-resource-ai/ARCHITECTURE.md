# Cloud Resource AI Assistant – Architecture Overview

## Goal

Provide a conversational AI interface allowing users to query
multi-cloud resource metadata using natural language.

Supported clouds:

- AWS
- GCP
- Azure
- Alibaba Cloud

The system converts natural language into structured queries
against centralized cloud metadata.

---

## Core Principles

1. LLM never directly accesses database
2. All reasoning is stateful (session driven)
3. Queries are generated via Query Spec abstraction
4. Orchestrator controls AI behavior
5. Deterministic execution layer

---

## High-Level Flow

User → Web UI → API Gateway → Chat Orchestrator
→ LLM Reasoning → Query Planner → Database
→ Visualization Response