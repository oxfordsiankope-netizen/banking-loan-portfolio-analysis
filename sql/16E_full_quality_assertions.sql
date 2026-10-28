-- Banking capstone | synthetic data | PostgreSQL
-- TASK 16 EXTRA | One compact pass/fail dashboard for the user's ORIGINAL snapshot.
-- Do NOT use the fixed numeric targets after regenerating random source data.
WITH base AS (
    SELECT (SELECT COUNT(*) FROM banking_capstone.bank_branches) AS branches,
           (SELECT COUNT(*) FROM banking_capstone.bank_customers) AS customers,
           (SELECT COUNT(*) FROM banking_capstone.bank_loans) AS loans,
           (SELECT COUNT(*) FROM banking_capstone.bank_loans WHERE loan_status = 'Defaulted') AS defaults,
           (SELECT SUM(loan_amount) FROM banking_capstone.bank_loans) AS principal,
           (SELECT SUM(loan_amount) FROM banking_capstone.bank_loans WHERE loan_status = 'Defaulted') AS defaulted_principal
), joined AS (
    SELECT COUNT(l.loan_id) AS joined_loan_count
    FROM banking_capstone.bank_loans l
    INNER JOIN banking_capstone.bank_customers c ON c.customer_id = l.customer_id
    INNER JOIN banking_capstone.bank_branches b ON b.branch_id = c.branch_id
), checks AS (
    SELECT 'branches = 8' AS check_name, (branches = 8) AS passes FROM base
    UNION ALL SELECT 'customers = 20000', (customers = 20000) FROM base
    UNION ALL SELECT 'loans = 40000', (loans = 40000) FROM base
    UNION ALL SELECT 'defaulted loans = 5313', (defaults = 5313) FROM base
    UNION ALL SELECT 'original principal matches prior verified value',
                     (principal = 5672889156.80) FROM base
    UNION ALL SELECT 'defaulted principal matches prior verified value',
                     (defaulted_principal = 917841641.54) FROM base
    UNION ALL SELECT 'all loan rows survive customer-and-branch joins',
                     (joined_loan_count = loans) FROM base CROSS JOIN joined
)
SELECT check_name, CASE WHEN passes THEN 'PASS' ELSE 'FAIL' END AS result
FROM checks ORDER BY check_name;
