-- BANKING CAPSTONE TASKS 12-17 | ALL FINISHED QUERIES
-- NOTE: These are SELECT-only scripts for your existing PostgreSQL banking_capstone schema.
-- Use individual SQL files to view result tables one at a time.
-- Dataset is randomized on initial setup: do not rerun setup unless rebuilding intentionally.



-- ============================================================
-- 12A_income_group_loan_counts.sql
-- ============================================================
-- TASK 12A | Number of loans per customer-income segment
-- One customer can have multiple loans, so this counts LOANS, not customers.
WITH income_group AS (
    SELECT customer_id,
           CASE
             WHEN monthly_income < 10000 THEN 'low_income'
             WHEN monthly_income < 20000 THEN 'lower-middle_income'
             WHEN monthly_income < 40000 THEN 'upper-middle_income'
             ELSE 'high_income'
           END AS income_category
    FROM banking_capstone.bank_customers
    WHERE monthly_income IS NOT NULL
)
SELECT g.income_category,
       COUNT(l.loan_id) AS total_loans
FROM income_group AS g
INNER JOIN banking_capstone.bank_loans AS l ON l.customer_id = g.customer_id
GROUP BY g.income_category
ORDER BY total_loans DESC;



-- ============================================================
-- 12B_income_group_default_risk.sql
-- ============================================================
-- TASK 12B | Defaults and original principal by monthly-income group
WITH income_group AS (
    SELECT customer_id,
           CASE
             WHEN monthly_income < 10000 THEN 'low_income'
             WHEN monthly_income < 20000 THEN 'lower-middle_income'
             WHEN monthly_income < 40000 THEN 'upper-middle_income'
             ELSE 'high_income'
           END AS income_category
    FROM banking_capstone.bank_customers
    WHERE monthly_income IS NOT NULL
)
SELECT g.income_category,
       COUNT(l.loan_id) AS total_loans,
       SUM(CASE WHEN l.loan_status = 'Defaulted' THEN 1 ELSE 0 END) AS defaulted_loans,
       ROUND(100.0 * SUM(CASE WHEN l.loan_status = 'Defaulted' THEN 1 ELSE 0 END)
             / NULLIF(COUNT(l.loan_id), 0), 2) AS default_percentage,
       SUM(l.loan_amount) AS total_loan_value,
       SUM(CASE WHEN l.loan_status = 'Defaulted' THEN l.loan_amount ELSE 0 END)
           AS defaulted_loan_value,
       ROUND(100.0 * SUM(CASE WHEN l.loan_status = 'Defaulted' THEN l.loan_amount ELSE 0 END)
             / NULLIF(SUM(l.loan_amount), 0), 2) AS default_value_percentage
FROM income_group AS g
INNER JOIN banking_capstone.bank_loans AS l ON l.customer_id = g.customer_id
GROUP BY g.income_category
ORDER BY default_percentage DESC, g.income_category;



-- ============================================================
-- 13_loan_size_default_risk.sql
-- ============================================================
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



-- ============================================================
-- 14A_interest_rate_default_risk.sql
-- ============================================================
-- TASK 14A | Interest-rate bands and observed defaulted loan shares
-- No causal interpretation: this is synthetic, cross-sectional data.
WITH rate_groups AS (
    SELECT loan_id, loan_status, interest_rate, loan_amount,
           CASE
             WHEN interest_rate < 15 THEN 'under_15'
             WHEN interest_rate < 22 THEN '15_to_under_22'
             WHEN interest_rate < 29 THEN '22_to_under_29'
             ELSE '29_and_above'
           END AS interest_rate_band
    FROM banking_capstone.bank_loans
)
SELECT interest_rate_band,
       COUNT(*) AS total_loans,
       ROUND(AVG(interest_rate), 2) AS average_interest_rate,
       SUM(CASE WHEN loan_status = 'Defaulted' THEN 1 ELSE 0 END) AS defaulted_loans,
       ROUND(100.0 * SUM(CASE WHEN loan_status = 'Defaulted' THEN 1 ELSE 0 END)
             / NULLIF(COUNT(*), 0), 2) AS default_percentage
FROM rate_groups
GROUP BY interest_rate_band
ORDER BY default_percentage DESC, interest_rate_band;



-- ============================================================
-- 14B_product_default_risk.sql
-- ============================================================
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



-- ============================================================
-- 14C_product_status_breakdown.sql
-- ============================================================
-- TASK 14 STRETCH | Five loan types x three possible statuses
SELECT loan_type, loan_status,
       COUNT(*) AS loan_count,
       SUM(loan_amount) AS total_loan_value
FROM banking_capstone.bank_loans
GROUP BY loan_type, loan_status
ORDER BY loan_type, loan_status;



-- ============================================================
-- 15A_customer_borrowing_frequency.sql
-- ============================================================
-- TASK 15A | Counts both borrowers and customers with NO loans.
WITH customer_loan_counts AS (
    SELECT c.customer_id, COUNT(l.loan_id) AS loan_count
    FROM banking_capstone.bank_customers AS c
    LEFT JOIN banking_capstone.bank_loans AS l ON l.customer_id = c.customer_id
    GROUP BY c.customer_id
), frequency_groups AS (
    SELECT loan_count,
           CASE
             WHEN loan_count = 0 THEN '0_loans'
             WHEN loan_count = 1 THEN '1_loan'
             WHEN loan_count = 2 THEN '2_loans'
             ELSE '3_or_more'
           END AS borrowing_group,
           LEAST(loan_count, 3) AS sort_order
    FROM customer_loan_counts
)
SELECT borrowing_group,
       COUNT(*) AS customer_count,
       SUM(loan_count) AS total_loans
FROM frequency_groups
GROUP BY borrowing_group, sort_order
ORDER BY sort_order;



-- ============================================================
-- 15B_default_risk_by_borrowing_frequency.sql
-- ============================================================
-- TASK 15B | Loan-level defaults by customer borrowing frequency
-- Zero-loan group has NULL default_percentage, not 0%.
WITH customer_loan_counts AS (
    SELECT c.customer_id,
           COUNT(l.loan_id) AS loan_count,
           SUM(CASE WHEN l.loan_status = 'Defaulted' THEN 1 ELSE 0 END) AS defaulted_loan_count,
           MAX(CASE WHEN l.loan_status = 'Defaulted' THEN 1 ELSE 0 END) AS has_defaulted_loan
    FROM banking_capstone.bank_customers AS c
    LEFT JOIN banking_capstone.bank_loans AS l ON l.customer_id = c.customer_id
    GROUP BY c.customer_id
), frequency_groups AS (
    SELECT loan_count, defaulted_loan_count, has_defaulted_loan,
           CASE
             WHEN loan_count = 0 THEN '0_loans'
             WHEN loan_count = 1 THEN '1_loan'
             WHEN loan_count = 2 THEN '2_loans'
             ELSE '3_or_more'
           END AS borrowing_group,
           LEAST(loan_count, 3) AS sort_order
    FROM customer_loan_counts
)
SELECT borrowing_group,
       COUNT(*) AS customer_count,
       SUM(loan_count) AS total_loans,
       SUM(defaulted_loan_count) AS defaulted_loans,
       ROUND(100.0 * SUM(defaulted_loan_count)
             / NULLIF(SUM(loan_count), 0), 2) AS default_percentage,
       SUM(has_defaulted_loan) AS customers_with_any_default,
       ROUND(100.0 * SUM(has_defaulted_loan)
             / NULLIF(COUNT(*), 0), 2) AS customer_with_default_percentage
FROM frequency_groups
GROUP BY borrowing_group, sort_order
ORDER BY sort_order;



-- ============================================================
-- 16A_duplicate_loan_ids.sql
-- ============================================================
-- TASK 16A | Must return no rows if loan_id PK is enforced
SELECT loan_id, COUNT(*) AS occurrences
FROM banking_capstone.bank_loans
GROUP BY loan_id
HAVING COUNT(*) > 1;



-- ============================================================
-- 16B_orphan_loans.sql
-- ============================================================
-- TASK 16B | Must return no rows if FK is enforced
SELECT l.loan_id, l.customer_id
FROM banking_capstone.bank_loans AS l
LEFT JOIN banking_capstone.bank_customers AS c ON c.customer_id = l.customer_id
WHERE c.customer_id IS NULL;



-- ============================================================
-- 16C_missingness_invalid_values.sql
-- ============================================================
-- TASK 16C | Missing values, loan amounts, statuses, interest rates
SELECT COUNT(*) AS total_loans,
       COUNT(*) FILTER (WHERE loan_amount IS NULL) AS null_loan_amounts,
       COUNT(*) FILTER (WHERE loan_status IS NULL) AS null_statuses,
       COUNT(*) FILTER (WHERE loan_amount <= 0) AS invalid_loan_amounts,
       COUNT(*) FILTER (WHERE loan_status NOT IN ('Active','Defaulted','Paid')) AS invalid_statuses,
       COUNT(*) FILTER (WHERE interest_rate < 0 OR interest_rate > 100) AS invalid_interest_rates,
       COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_ids
FROM banking_capstone.bank_loans;



-- ============================================================
-- 16D_reconcile_portfolio.sql
-- ============================================================
-- TASK 16D | Automatically reconciles detail with status subtotals, without manual addition.
WITH grand_totals AS (
    SELECT COUNT(*)::bigint AS all_loans,
           SUM(loan_amount)::numeric AS all_principal,
           COUNT(*) FILTER (WHERE loan_status = 'Defaulted') AS all_defaulted_loans,
           COALESCE(SUM(loan_amount) FILTER (WHERE loan_status = 'Defaulted'), 0)::numeric
               AS all_defaulted_principal
    FROM banking_capstone.bank_loans
), by_status AS (
    SELECT loan_status, COUNT(*)::bigint AS loan_count,
           SUM(loan_amount)::numeric AS principal
    FROM banking_capstone.bank_loans
    GROUP BY loan_status
), reconciled AS (
    SELECT SUM(loan_count)::bigint AS status_count_total,
           SUM(principal)::numeric AS status_principal_total,
           COALESCE(SUM(loan_count) FILTER (WHERE loan_status = 'Defaulted'), 0)::bigint
               AS status_default_count,
           COALESCE(SUM(principal) FILTER (WHERE loan_status = 'Defaulted'), 0)::numeric
               AS status_default_principal
    FROM by_status
)
SELECT g.all_loans, r.status_count_total,
       g.all_principal, r.status_principal_total,
       g.all_defaulted_loans, r.status_default_count,
       g.all_defaulted_principal, r.status_default_principal,
       (g.all_loans = r.status_count_total
        AND g.all_principal = r.status_principal_total
        AND g.all_defaulted_loans = r.status_default_count
        AND g.all_defaulted_principal = r.status_default_principal) AS totals_reconcile
FROM grand_totals g CROSS JOIN reconciled r;



-- ============================================================
-- 16E_full_quality_assertions.sql
-- ============================================================
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



-- ============================================================
-- 17_all_segments_combined.sql
-- ============================================================
-- TASK 17 | For final report, returns four top-default-rate segment leaders.
-- Use the detailed Task 12-14 files to inspect all categories and sample sizes.
WITH income_segments AS (
    SELECT CASE WHEN c.monthly_income < 10000 THEN 'low_income'
                WHEN c.monthly_income < 20000 THEN 'lower-middle_income'
                WHEN c.monthly_income < 40000 THEN 'upper-middle_income'
                ELSE 'high_income' END AS segment,
           l.loan_status
    FROM banking_capstone.bank_loans l
    INNER JOIN banking_capstone.bank_customers c ON c.customer_id = l.customer_id
    WHERE c.monthly_income IS NOT NULL
), size_segments AS (
    SELECT CASE WHEN loan_amount < 50000 THEN 'small'
                WHEN loan_amount < 100000 THEN 'medium'
                WHEN loan_amount < 200000 THEN 'large'
                ELSE 'very_large' END AS segment,
           loan_status
    FROM banking_capstone.bank_loans
), rate_segments AS (
    SELECT CASE WHEN interest_rate < 15 THEN 'under_15'
                WHEN interest_rate < 22 THEN '15_to_under_22'
                WHEN interest_rate < 29 THEN '22_to_under_29'
                ELSE '29_and_above' END AS segment,
           loan_status
    FROM banking_capstone.bank_loans
), unioned AS (
    SELECT 'income' AS dimension, segment, loan_status FROM income_segments
    UNION ALL SELECT 'loan_size', segment, loan_status FROM size_segments
    UNION ALL SELECT 'interest_rate', segment, loan_status FROM rate_segments
    UNION ALL SELECT 'loan_product', loan_type AS segment, loan_status
              FROM banking_capstone.bank_loans
), summary AS (
    SELECT dimension, segment, COUNT(*) AS total_loans,
           COUNT(*) FILTER (WHERE loan_status = 'Defaulted') AS defaulted_loans,
           ROUND(100.0 * COUNT(*) FILTER (WHERE loan_status = 'Defaulted')
                 / NULLIF(COUNT(*), 0), 2) AS default_percentage
    FROM unioned
    GROUP BY dimension, segment
)
SELECT s.dimension, s.segment AS highest_default_share_segment,
       s.total_loans, s.defaulted_loans, s.default_percentage
FROM summary AS s
WHERE s.segment = (
    SELECT s2.segment
    FROM summary AS s2
    WHERE s2.dimension = s.dimension
    ORDER BY s2.default_percentage DESC, s2.total_loans DESC, s2.segment
    LIMIT 1
)
ORDER BY s.dimension;



-- ============================================================
-- 17_final_branch_management_report.sql
-- ============================================================
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



-- ============================================================
-- 17_portfolio_headlines.sql
-- ============================================================
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

