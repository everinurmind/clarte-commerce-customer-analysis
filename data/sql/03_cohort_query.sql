-- ============================================================
-- Clarté Commerce — Cohort Retention Query
-- Author: Nurbol Sultanov
-- Date: 2026-03-08
-- Description: Monthly cohort retention analysis
-- ============================================================

WITH customer_cohort AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(transaction_date)) AS cohort_month
    FROM transactions
    WHERE customer_id NOT LIKE 'CLR-TEST%'
    GROUP BY customer_id
),

monthly_activity AS (
    SELECT DISTINCT
        t.customer_id,
        DATE_TRUNC('month', t.transaction_date) AS activity_month
    FROM transactions t
    WHERE t.customer_id NOT LIKE 'CLR-TEST%'
),

cohort_data AS (
    SELECT 
        c.cohort_month,
        a.activity_month,
        EXTRACT(YEAR FROM age(a.activity_month, c.cohort_month)) * 12 
            + EXTRACT(MONTH FROM age(a.activity_month, c.cohort_month)) AS month_offset,
        COUNT(DISTINCT a.customer_id) AS active_customers
    FROM customer_cohort c
    JOIN monthly_activity a ON c.customer_id = a.customer_id
    GROUP BY c.cohort_month, a.activity_month
),

cohort_sizes AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM customer_cohort
    GROUP BY cohort_month
)

SELECT 
    cd.cohort_month,
    cs.cohort_size,
    cd.month_offset,
    cd.active_customers,
    ROUND(cd.active_customers::DECIMAL / cs.cohort_size * 100, 1) AS retention_pct
FROM cohort_data cd
JOIN cohort_sizes cs ON cd.cohort_month = cs.cohort_month
WHERE cd.month_offset <= 24
ORDER BY cd.cohort_month, cd.month_offset;