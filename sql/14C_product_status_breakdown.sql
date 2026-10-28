-- Banking capstone | synthetic data | PostgreSQL
-- TASK 14 STRETCH | Five loan types x three possible statuses
SELECT loan_type, loan_status,
       COUNT(*) AS loan_count,
       SUM(loan_amount) AS total_loan_value
FROM banking_capstone.bank_loans
GROUP BY loan_type, loan_status
ORDER BY loan_type, loan_status;
