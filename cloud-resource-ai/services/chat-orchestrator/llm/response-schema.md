# LLM Response Schema

LLM must return JSON:

{
  "intent": "",
  "slots_detected": {},
  "missing_slots": [],
  "clarification_needed": false,
  "clarification_question": "",
  "query_spec": null
}

Example Clarification

{
  "intent": "list_accounts",
  "slots_detected": {},
  "missing_slots": ["department"],
  "clarification_needed": true,
  "clarification_question":
    "Which department do you mean?"
}

Example Ready Query

{
  "intent": "count_resources",
  "missing_slots": [],
  "clarification_needed": false,
  "query_spec": {...}
}

