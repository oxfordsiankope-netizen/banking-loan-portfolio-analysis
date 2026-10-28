-- Banking capstone | synthetic data | PostgreSQL
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
