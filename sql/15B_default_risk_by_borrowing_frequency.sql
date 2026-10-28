-- Banking capstone | synthetic data | PostgreSQL
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
