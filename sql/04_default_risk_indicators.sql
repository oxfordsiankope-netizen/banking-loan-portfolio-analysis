-- Snapshot count share and original-principal share of loans marked Defaulted.
-- These metrics are NOT financial loss rates or outstanding NPL ratios.
SELECT
    COUNT(*) AS total_loans,
    SUM(CASE WHEN loan_status = 'Defaulted' THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND(
        100.0 * SUM(CASE WHEN loan_status = 'Defaulted' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS default_count_pct,
    ROUND(
        100.0 * SUM(CASE WHEN loan_status = 'Defaulted' THEN loan_amount ELSE 0 END)
        / NULLIF(SUM(loan_amount), 0), 2
    ) AS default_value_pct
FROM banking_capstone.bank_loans;
