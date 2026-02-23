-- ============================================================
-- Clarté Commerce — RFM Base Query
-- Author: Nurbol Sultanov
-- Date: 2026-02-23
-- Description: Calculate Recency, Frequency, Monetary values
--              per customer for RFM segmentation
-- ============================================================

-- Reference date: end of data period
-- Using 2024-12-31 as the snapshot date

WITH customer_rfm AS (
    SELECT 
        t.customer_id,
        DATEDIFF('day', MAX(t.transaction_date), DATE '2024-12-31') AS recency_days,
        COUNT(DISTINCT t.transaction_id) AS frequency,
        ROUND(SUM(t.total_amount), 2) AS monetary,
        MIN(t.transaction_date) AS first_purchase,
        MAX(t.transaction_date) AS last_purchase,
        COUNT(DISTINCT DATE_TRUNC('month', t.transaction_date)) AS active_months
    FROM transactions t
    WHERE t.customer_id NOT LIKE 'CLR-TEST%'
    GROUP BY t.customer_id
),

-- Assign quintile scores (1-5) for each dimension
rfm_scores AS (
    SELECT 
        customer_id,
        recency_days,
        frequency,
        monetary,
        first_purchase,
        last_purchase,
        active_months,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM customer_rfm
)

SELECT 
    r.*,
    (r_score + f_score + m_score) AS rfm_total,
    CONCAT(r_score, f_score, m_score) AS rfm_segment,
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score >= 3 AND f_score >= 1 AND m_score >= 2 THEN 'Potential Loyalists'
        WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'Cant Lose Them'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Other'
    END AS rfm_label
FROM rfm_scores r
ORDER BY rfm_total DESC;