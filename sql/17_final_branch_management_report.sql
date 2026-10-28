-- Banking capstone | synthetic data | PostgreSQL
-- TASK 17 | Final branch risk report, one row per branch
-- This joins through customers and uses original principal, not outstanding balance.
SELECT b.branch_name,
       COUNT(l.loan_id) AS total_loans,
       SUM(l.loan_amount) AS total_loan_value,
       SUM(CASE WHEN l.loan_status = 'Defaulted' THEN 1 ELSE 0 END) AS defaulted_loans,
       ROUND(100.0 * SUM(CASE WHEN l.loan_status = 'Defaulted' THEN 1 ELSE 0 END)
             / NULLIF(COUNT(l.loan_id), 0), 2) AS default_count_percentage,
       SUM(CASE WHEN l.loan_status = 'Defaulted' THEN l.loan_amount ELSE 0 END)
           AS defaulted_loan_value,
       ROUND(100.0 * SUM(CASE WHEN l.loan_status = 'Defaulted' THEN l.loan_amount ELSE 0 END)
             / NULLIF(SUM(l.loan_amount), 0), 2) AS defaulted_principal_percentage
FROM banking_capstone.bank_loans AS l
INNER JOIN banking_capstone.bank_customers AS c ON c.customer_id = l.customer_id
INNER JOIN banking_capstone.bank_branches AS b ON b.branch_id = c.branch_id
GROUP BY b.branch_id, b.branch_name
ORDER BY defaulted_loan_value DESC;
