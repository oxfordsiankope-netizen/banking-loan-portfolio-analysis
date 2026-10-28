-- Check expected row counts and relationship integrity.
SELECT 'branches' AS table_name, COUNT(*) AS record_count
FROM banking_capstone.bank_branches
UNION ALL
SELECT 'customers', COUNT(*) FROM banking_capstone.bank_customers
UNION ALL
SELECT 'loans', COUNT(*) FROM banking_capstone.bank_loans;

-- Every loan should reference an existing customer (expected 0).
SELECT COUNT(*) AS loans_without_customer
FROM banking_capstone.bank_loans AS l
LEFT JOIN banking_capstone.bank_customers AS c
  ON l.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Check missing loan amounts (expected 0 due to table constraints).
SELECT COUNT(*) AS loans_missing_amount
FROM banking_capstone.bank_loans
WHERE loan_amount IS NULL;
