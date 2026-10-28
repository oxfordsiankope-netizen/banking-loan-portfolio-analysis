-- Banking capstone | synthetic data | PostgreSQL
-- TASK 16B | Must return no rows if FK is enforced
SELECT l.loan_id, l.customer_id
FROM banking_capstone.bank_loans AS l
LEFT JOIN banking_capstone.bank_customers AS c ON c.customer_id = l.customer_id
WHERE c.customer_id IS NULL;
