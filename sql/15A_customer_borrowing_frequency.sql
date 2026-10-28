-- Banking capstone | synthetic data | PostgreSQL
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
