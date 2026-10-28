-- Loan portfolio descriptive statistics.
SELECT
    COUNT(*) AS total_loans,
    SUM(loan_amount) AS total_loan_value,
    ROUND(AVG(loan_amount), 2) AS average_loan,
    MAX(loan_amount) AS largest_loan,
    MIN(loan_amount) AS smallest_loan
FROM banking_capstone.bank_loans;
