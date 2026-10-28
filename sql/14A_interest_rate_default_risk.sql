-- Banking capstone | synthetic data | PostgreSQL
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
