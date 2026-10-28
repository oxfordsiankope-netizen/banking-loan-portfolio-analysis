-- Banking capstone | synthetic data | PostgreSQL
-- TASK 12B | Defaults and original principal by monthly-income group
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
       COUNT(l.loan_id) AS total_loans,
       SUM(CASE WHEN l.loan_status = 'Defaulted' THEN 1 ELSE 0 END) AS defaulted_loans,
       ROUND(100.0 * SUM(CASE WHEN l.loan_status = 'Defaulted' THEN 1 ELSE 0 END)
             / NULLIF(COUNT(l.loan_id), 0), 2) AS default_percentage,
       SUM(l.loan_amount) AS total_loan_value,
       SUM(CASE WHEN l.loan_status = 'Defaulted' THEN l.loan_amount ELSE 0 END)
           AS defaulted_loan_value,
       ROUND(100.0 * SUM(CASE WHEN l.loan_status = 'Defaulted' THEN l.loan_amount ELSE 0 END)
             / NULLIF(SUM(l.loan_amount), 0), 2) AS default_value_percentage
FROM income_group AS g
INNER JOIN banking_capstone.bank_loans AS l ON l.customer_id = g.customer_id
GROUP BY g.income_category
ORDER BY default_percentage DESC, g.income_category;
