-- Banking capstone | synthetic data | PostgreSQL
-- TASK 13A + 13B | Loan-size risk and principal concentration
WITH loan_sizes AS (
    SELECT loan_id, loan_status, loan_amount,
           CASE
             WHEN loan_amount < 50000 THEN 'small'
             WHEN loan_amount < 100000 THEN 'medium'
             WHEN loan_amount < 200000 THEN 'large'
             ELSE 'very_large'
           END AS loan_size_group
    FROM banking_capstone.bank_loans
)
SELECT loan_size_group,
       COUNT(*) AS total_loans,
       SUM(loan_amount) AS total_loan_value,
       SUM(CASE WHEN loan_status = 'Defaulted' THEN 1 ELSE 0 END) AS defaulted_loans,
       ROUND(100.0 * SUM(CASE WHEN loan_status = 'Defaulted' THEN 1 ELSE 0 END)
             / NULLIF(COUNT(*), 0), 2) AS default_percentage,
       SUM(CASE WHEN loan_status = 'Defaulted' THEN loan_amount ELSE 0 END)
           AS defaulted_loan_value,
       ROUND(100.0 * SUM(CASE WHEN loan_status = 'Defaulted' THEN loan_amount ELSE 0 END)
             / NULLIF(SUM(loan_amount), 0), 2) AS default_value_percentage
FROM loan_sizes
GROUP BY loan_size_group
ORDER BY default_percentage DESC, loan_size_group;
