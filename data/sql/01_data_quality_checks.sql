-- ============================================================
-- Clarté Commerce — Data Quality Checks
-- Author: Nurbol Sultanov
-- Date: 2026-02-17
-- Description: Initial data validation queries before analysis
-- ============================================================

-- 1. Row counts
SELECT 'transactions' AS table_name, COUNT(*) AS row_count FROM transactions
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products;

-- 2. Date range validation
SELECT 
    MIN(transaction_date) AS earliest_txn,
    MAX(transaction_date) AS latest_txn,
    COUNT(DISTINCT DATE_TRUNC('month', transaction_date)) AS months_covered
FROM transactions;

-- 3. Null checks — transactions
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END) AS null_txn_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_cust_id,
    SUM(CASE WHEN transaction_date IS NULL THEN 1 ELSE 0 END) AS null_date,
    SUM(CASE WHEN total_amount IS NULL THEN 1 ELSE 0 END) AS null_amount,
    SUM(CASE WHEN total_amount <= 0 THEN 1 ELSE 0 END) AS negative_or_zero_amount
FROM transactions;

-- 4. Null checks — customers
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_cust_id,
    SUM(CASE WHEN registration_date IS NULL THEN 1 ELSE 0 END) AS null_reg_date,
    SUM(CASE WHEN age_group IS NULL THEN 1 ELSE 0 END) AS null_age,
    SUM(CASE WHEN region IS NULL THEN 1 ELSE 0 END) AS null_region
FROM customers;

-- 5. Orphan check: transactions without matching customer
SELECT COUNT(*) AS orphan_transactions
FROM transactions t
LEFT JOIN customers c ON t.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 6. Duplicate transaction IDs
SELECT transaction_id, COUNT(*) AS cnt
FROM transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- 7. Customers with suspicious patterns
SELECT 
    customer_id,
    COUNT(*) AS txn_count,
    SUM(total_amount) AS total_spent
FROM transactions
WHERE customer_id LIKE 'CLR-TEST%'
GROUP BY customer_id;

-- 8. Channel distribution over time
SELECT 
    DATE_TRUNC('quarter', transaction_date) AS quarter,
    channel,
    COUNT(*) AS txn_count,
    ROUND(AVG(total_amount), 2) AS avg_order_value
FROM transactions
GROUP BY 1, 2
ORDER BY 1, 2;

-- 9. Basic stats per year
SELECT 
    EXTRACT(YEAR FROM transaction_date) AS year,
    COUNT(*) AS transactions,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(AVG(total_amount), 2) AS avg_order_value,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM transactions
GROUP BY 1
ORDER BY 1;