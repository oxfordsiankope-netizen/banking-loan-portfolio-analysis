-- Banking capstone | synthetic data | PostgreSQL
-- TASK 16C | Missing values, loan amounts, statuses, interest rates
SELECT COUNT(*) AS total_loans,
       COUNT(*) FILTER (WHERE loan_amount IS NULL) AS null_loan_amounts,
       COUNT(*) FILTER (WHERE loan_status IS NULL) AS null_statuses,
       COUNT(*) FILTER (WHERE loan_amount <= 0) AS invalid_loan_amounts,
       COUNT(*) FILTER (WHERE loan_status NOT IN ('Active','Defaulted','Paid')) AS invalid_statuses,
       COUNT(*) FILTER (WHERE interest_rate < 0 OR interest_rate > 100) AS invalid_interest_rates,
       COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_ids
FROM banking_capstone.bank_loans;
