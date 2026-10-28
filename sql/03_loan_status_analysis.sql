-- Number and original value of loans by current recorded status.
SELECT
    loan_status,
    COUNT(*) AS loan_count,
    SUM(loan_amount) AS total_loan_value,
    ROUND(AVG(loan_amount), 2) AS average_loan
FROM banking_capstone.bank_loans
GROUP BY loan_status
ORDER BY total_loan_value DESC;
