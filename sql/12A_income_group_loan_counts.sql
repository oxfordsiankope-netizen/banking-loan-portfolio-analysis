-- Banking capstone | synthetic data | PostgreSQL
-- TASK 12A | Number of loans per customer-income segment
-- One customer can have multiple loans, so this counts LOANS, not customers.
WITH income_group AS (
    SELECT customer_id,
           CASE
             WHEN monthly_income < 10000 THEN 'low_income'
             WHEN monthly_income < 20000 THEN 'lower-middle_income'
             WHEN monthly_income < 40000 THEN 'upper-middle_income'
             ELSE 'high_income'
           END AS income_category
    FROM banking_capstone.bank_customers
    WHERE monthly_income IS NOT NULL
)
SELECT g.income_category,
       COUNT(l.loan_id) AS total_loans
FROM income_group AS g
INNER JOIN banking_capstone.bank_loans AS l ON l.customer_id = g.customer_id
GROUP BY g.income_category
ORDER BY total_loans DESC;
