-- Banking capstone | synthetic data | PostgreSQL
-- TASK 16A | Must return no rows if loan_id PK is enforced
SELECT loan_id, COUNT(*) AS occurrences
FROM banking_capstone.bank_loans
GROUP BY loan_id
HAVING COUNT(*) > 1;
