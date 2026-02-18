# AI Reasoning Flow

The reasoning process is iterative.

## Step 1 — Intent Understanding
Determine user's goal.

## Step 2 — Slot Extraction
Extract known parameters.

Example:
"Show AWS accounts for retail"

slots:
cloud=AWS
department=retail

---

## Step 3 — Gap Detection

Identify missing information required to execute query.

---

## Step 4 — Clarification Planning

If ambiguity exists, generate clarification question.

---

## Step 5 — Query Planning

Produce Query Spec describing data retrieval.