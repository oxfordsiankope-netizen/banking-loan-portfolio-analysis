-- Banking capstone | synthetic data | PostgreSQL
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
