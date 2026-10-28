-- Banking capstone | synthetic data | PostgreSQL
-- TASK 17 | Overall portfolio executive KPIs in one row
SELECT COUNT(*) AS total_loans,
       SUM(loan_amount) AS total_original_principal,
       ROUND(AVG(loan_amount), 2) AS average_loan_amount,
       COUNT(*) FILTER (WHERE loan_status = 'Active') AS active_loans,
       COUNT(*) FILTER (WHERE loan_status = 'Paid') AS paid_loans,
       COUNT(*) FILTER (WHERE loan_status = 'Defaulted') AS defaulted_loans,
       ROUND(100.0 * COUNT(*) FILTER (WHERE loan_status = 'Defaulted')
             / NULLIF(COUNT(*), 0), 2) AS default_count_percentage,
       COALESCE(SUM(loan_amount) FILTER (WHERE loan_status = 'Defaulted'), 0)
           AS defaulted_original_principal,
       ROUND(100.0 * COALESCE(SUM(loan_amount) FILTER (WHERE loan_status = 'Defaulted'), 0)
             / NULLIF(SUM(loan_amount), 0), 2) AS defaulted_principal_percentage
FROM banking_capstone.bank_loans;
