# LLM Observability

Track quality and cost.

---

## Metrics

- intent accuracy
- clarification rate
- query success rate
- hallucination rejection count
- token usage
- latency

---

## Logging Layers

1. User request
2. Generated Query Spec
3. SQL executed
4. Result size
5. LLM response

---

## CloudWatch Log Structure

{
  session_id,
  intent,
  confidence,
  query_type,
  execution_time_ms,
  tokens_used
}

---

## X-Ray Tracing

Trace segments:

API → Orchestrator → LLM → DB → Formatter