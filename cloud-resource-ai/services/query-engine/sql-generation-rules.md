# SQL Generation Rules

SQL is generated deterministically.

---

## Allowed

SELECT
WHERE
GROUP BY
COUNT
SUM

---

## Forbidden

DELETE
UPDATE
INSERT
DDL statements
subqueries beyond approved templates

---

## Template Example

SELECT
  {dimension},
  COUNT(*) as total
FROM {dataset}
WHERE {filters}
GROUP BY {dimension};