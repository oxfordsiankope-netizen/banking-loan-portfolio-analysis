-- Banking capstone | synthetic data | PostgreSQL
-- TASK 14B | Loan product comparison
SELECT loan_type,
       COUNT(*) AS total_loans,
       SUM(loan_amount) AS total_loan_value,
       SUM(CASE WHEN loan_status = 'Defaulted' THEN 1 ELSE 0 END) AS defaulted_loans,
       ROUND(100.0 * SUM(CASE WHEN loan_status = 'Defaulted' THEN 1 ELSE 0 END)
             / NULLIF(COUNT(*), 0), 2) AS default_percentage
FROM banking_capstone.bank_loans
GROUP BY loan_type
ORDER BY default_percentage DESC, loan_type;
