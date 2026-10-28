-- BANKING DATA ANALYTICS CAPSTONE (SYNTHETIC DATA)
-- PostgreSQL 14+ / pgAdmin
-- Snapshot date for this fictional portfolio: 2026-10-25
-- Creates data inside a NEW schema and does not modify your old public.bank_customers
-- Run this entire script in Query Tool against your practice database.
-- Safe to rerun after a successful completion: existing populated tables are not duplicated.

BEGIN;

CREATE SCHEMA IF NOT EXISTS banking_capstone;

CREATE TABLE IF NOT EXISTS banking_capstone.bank_branches (
    branch_id       INTEGER PRIMARY KEY,
    branch_name     TEXT NOT NULL,
    city            TEXT NOT NULL,
    province        TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS banking_capstone.bank_customers (
    customer_id     INTEGER PRIMARY KEY,
    customer_name   TEXT NOT NULL,
    age             INTEGER NOT NULL CHECK (age BETWEEN 18 AND 90),
    monthly_income  NUMERIC(12,2) NOT NULL CHECK (monthly_income >= 0),
    branch_id       INTEGER NOT NULL REFERENCES banking_capstone.bank_branches(branch_id),
    customer_since  DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS banking_capstone.bank_loans (
    loan_id         INTEGER PRIMARY KEY,
    customer_id     INTEGER NOT NULL REFERENCES banking_capstone.bank_customers(customer_id),
    loan_type       TEXT NOT NULL CHECK (loan_type IN ('Personal', 'Business', 'Agriculture', 'Vehicle', 'Education')),
    loan_amount     NUMERIC(14,2) NOT NULL CHECK (loan_amount > 0),
    interest_rate   NUMERIC(5,2) NOT NULL CHECK (interest_rate BETWEEN 0 AND 100),
    loan_term_months INTEGER NOT NULL CHECK (loan_term_months BETWEEN 6 AND 84),
    disbursement_date DATE NOT NULL,
    loan_status     TEXT NOT NULL CHECK (loan_status IN ('Active', 'Defaulted', 'Paid'))
);

INSERT INTO banking_capstone.bank_branches (branch_id, branch_name, city, province)
SELECT b.branch_id, b.branch_name, b.city, b.province
FROM (VALUES
  (1, 'Lusaka Central', 'Lusaka', 'Lusaka'),
  (2, 'Cairo Road', 'Lusaka', 'Lusaka'),
  (3, 'Kafue Branch', 'Kafue', 'Lusaka'),
  (4, 'Kitwe Branch', 'Kitwe', 'Copperbelt'),
  (5, 'Ndola Branch', 'Ndola', 'Copperbelt'),
  (6, 'Chingola Branch', 'Chingola', 'Copperbelt'),
  (7, 'Livingstone Branch', 'Livingstone', 'Southern'),
  (8, 'Kabwe Branch', 'Kabwe', 'Central')
) AS b(branch_id, branch_name, city, province)
WHERE NOT EXISTS (SELECT 1 FROM banking_capstone.bank_branches);

-- Populate 20,000 fictional customers. Duplicate NAMES are plausible; IDs are unique.
-- MATERIALIZED freezes the per-row random samples inside the CTE.
WITH customer_seed AS MATERIALIZED (
    SELECT
        n AS customer_id,
        (1 + FLOOR(RANDOM() * 20))::INT AS first_idx,
        (1 + FLOOR(RANDOM() * 20))::INT AS last_idx,
        (18 + FLOOR(RANDOM() * 53))::INT AS age,
        ROUND((2500 + POWER(RANDOM(), 1.8) * 72500)::numeric, 2) AS monthly_income,
        (1 + FLOOR(RANDOM() * 8))::INT AS branch_id,
        (DATE '2018-01-01' + FLOOR(RANDOM() * 3130)::INT) AS customer_since
    FROM GENERATE_SERIES(1, 20000) AS n
)
INSERT INTO banking_capstone.bank_customers
    (customer_id, customer_name, age, monthly_income, branch_id, customer_since)
SELECT
    customer_id,
    (ARRAY['Brian','Mary','Peter','Esther','John','Grace','Joseph','Ruth','James','Chipo',
           'Mwamba','Mutale','Thandiwe','Kelvin','Agnes','Moses','Loveness','Patrick','Natasha','Simon'])[first_idx]
    || ' ' ||
    (ARRAY['Banda','Phiri','Mwansa','Zulu','Tembo','Mumba','Chanda','Mulenga','Sakala','Moyo',
           'Nkonde','Mbewe','Musonda','Lungu','Daka','Nyirenda','Chilufya','Kabwe','Mwanza','Kaluba'])[last_idx],
    age,
    monthly_income,
    branch_id,
    customer_since
FROM customer_seed
WHERE NOT EXISTS (SELECT 1 FROM banking_capstone.bank_customers);

-- Populate 40,000 fictional loans, each linked to a real customer in THIS schema.
-- Amounts are ORIGINAL LOAN PRINCIPAL, not current outstanding balances.
-- Loan disbursement dates are not earlier than the corresponding customer onboarding date.
-- Statuses are illustrative and designed to support interesting credit-risk analysis.
WITH loan_seed AS MATERIALIZED (
    SELECT
        n AS loan_id,
        (1 + FLOOR(RANDOM() * 20000))::INT AS customer_id,
        RANDOM() AS loan_type_draw,
        ROUND((2500 + POWER(RANDOM(), 1.5) * 347500)::numeric, 2) AS loan_amount,
        ROUND((8 + RANDOM() * 27)::numeric, 2) AS interest_rate,
        (ARRAY[6, 12, 18, 24, 36, 48, 60, 72])[(1 + FLOOR(RANDOM() * 8))::INT] AS loan_term_months,
        (DATE '2022-01-01' + FLOOR(RANDOM() * 1715)::INT) AS proposed_disbursement_date,
        RANDOM() AS status_draw
    FROM GENERATE_SERIES(1, 40000) AS n
),
loan_enriched AS (
    SELECT
        l.loan_id,
        l.customer_id,
        l.loan_amount,
        l.interest_rate,
        l.loan_term_months,
        l.status_draw,
        GREATEST(l.proposed_disbursement_date, c.customer_since) AS disbursement_date,
        c.monthly_income,
        CASE
            WHEN l.loan_type_draw < 0.32 THEN 'Personal'
            WHEN l.loan_type_draw < 0.57 THEN 'Business'
            WHEN l.loan_type_draw < 0.74 THEN 'Agriculture'
            WHEN l.loan_type_draw < 0.88 THEN 'Vehicle'
            ELSE 'Education'
        END AS loan_type
    FROM loan_seed AS l
    INNER JOIN banking_capstone.bank_customers AS c
        ON c.customer_id = l.customer_id
)
INSERT INTO banking_capstone.bank_loans
    (loan_id, customer_id, loan_type, loan_amount, interest_rate, loan_term_months, disbursement_date, loan_status)
SELECT
    loan_id,
    customer_id,
    loan_type,
    loan_amount,
    interest_rate,
    loan_term_months,
    disbursement_date,
    CASE
        -- Slightly higher default propensity for loans large relative to reported monthly income.
        WHEN status_draw < CASE
            WHEN loan_amount > monthly_income * 8 THEN 0.21
            WHEN loan_amount > monthly_income * 4 THEN 0.14
            ELSE 0.07
        END THEN 'Defaulted'
        WHEN (disbursement_date + (loan_term_months || ' months')::interval)::date <= DATE '2026-10-25'
             AND status_draw > 0.76 THEN 'Paid'
        ELSE 'Active'
    END
FROM loan_enriched
WHERE NOT EXISTS (SELECT 1 FROM banking_capstone.bank_loans);

-- Useful indexes for common joins; we'll learn their significance as we analyse.
CREATE INDEX IF NOT EXISTS idx_capstone_customers_branch
    ON banking_capstone.bank_customers (branch_id);
CREATE INDEX IF NOT EXISTS idx_capstone_loans_customer
    ON banking_capstone.bank_loans (customer_id);
CREATE INDEX IF NOT EXISTS idx_capstone_loans_status
    ON banking_capstone.bank_loans (loan_status);
CREATE INDEX IF NOT EXISTS idx_capstone_loans_date
    ON banking_capstone.bank_loans (disbursement_date);

-- Update planner statistics after loading.
ANALYZE banking_capstone.bank_branches;
ANALYZE banking_capstone.bank_customers;
ANALYZE banking_capstone.bank_loans;

COMMIT;

-- VERIFICATION: should show 8 branches, 20,000 customers, 40,000 loans.
SELECT
    (SELECT COUNT(*) FROM banking_capstone.bank_branches) AS branches,
    (SELECT COUNT(*) FROM banking_capstone.bank_customers) AS customers,
    (SELECT COUNT(*) FROM banking_capstone.bank_loans) AS loans;

-- A first look at actual generated loan statuses (not a hard-coded result).
SELECT loan_status, COUNT(*) AS loan_count
FROM banking_capstone.bank_loans
GROUP BY loan_status
ORDER BY loan_count DESC;
