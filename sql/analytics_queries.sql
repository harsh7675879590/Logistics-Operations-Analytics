-- ============================================================================
-- LOGISTICS OPERATIONS — ANALYTICAL QUERIES
-- 15 Production-Grade Business Intelligence Queries
-- Author: Senior Data Analyst
-- Compatible: SQLite / MySQL / PostgreSQL
-- ============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 1: Top 10 Cities by Total Revenue
-- Purpose:  Identify highest revenue-generating markets
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    city,
    COUNT(*)                            AS total_orders,
    SUM(total_revenue)                  AS total_revenue,
    ROUND(AVG(total_revenue), 2)        AS avg_revenue_per_order,
    ROUND(SUM(total_revenue) * 100.0 / (SELECT SUM(total_revenue) FROM orders), 2)
                                        AS revenue_share_pct
FROM orders
WHERE order_status != 'Cancelled'
GROUP BY city
ORDER BY total_revenue DESC
LIMIT 10;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 2: Average Delivery Time by City
-- Purpose:  SLA monitoring and city-wise delivery efficiency
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    city,
    COUNT(*)                                    AS deliveries,
    ROUND(AVG(actual_delivery_min), 1)          AS avg_delivery_time_min,
    ROUND(AVG(estimated_delivery_min), 1)       AS avg_estimated_time_min,
    ROUND(AVG(actual_delivery_min - estimated_delivery_min), 1)
                                                AS avg_delay_min,
    ROUND(
        SUM(CASE WHEN actual_delivery_min <= estimated_delivery_min THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 1
    )                                           AS on_time_pct
FROM orders
WHERE order_status = 'Delivered'
  AND actual_delivery_min IS NOT NULL
GROUP BY city
ORDER BY avg_delivery_time_min ASC;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 3: Orders Per Driver (Driver Utilization)
-- Purpose:  Workforce optimization and load balancing
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    driver_id,
    driver_name,
    COUNT(*)                                    AS total_orders,
    SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END)
                                                AS delivered,
    SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END)
                                                AS cancelled,
    ROUND(AVG(rating), 2)                       AS avg_rating,
    ROUND(SUM(COALESCE(distance_km, 0)), 1)     AS total_distance_km,
    ROUND(SUM(total_revenue), 2)                AS total_revenue
FROM orders
GROUP BY driver_id, driver_name
ORDER BY total_orders DESC
LIMIT 20;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 4: Cancellation Rate — Overall & By Reason
-- Purpose:  Identify root causes of order cancellations
-- ─────────────────────────────────────────────────────────────────────────────

-- 4a: Overall cancellation rate
SELECT
    COUNT(*)                                    AS total_orders,
    SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END)
                                                AS cancelled_orders,
    ROUND(
        SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    )                                           AS cancellation_rate_pct
FROM orders;

-- 4b: Cancellation by reason (breakdown)
SELECT
    cancellation_reason,
    COUNT(*)                                    AS cancel_count,
    ROUND(COUNT(*) * 100.0 / (
        SELECT COUNT(*) FROM orders WHERE order_status = 'Cancelled'
    ), 2)                                       AS reason_share_pct
FROM orders
WHERE order_status = 'Cancelled'
GROUP BY cancellation_reason
ORDER BY cancel_count DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 5: Top 20 Customers by Lifetime Value
-- Purpose:  VIP customer identification and retention targeting
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    customer_id,
    customer_name,
    COUNT(*)                                    AS total_orders,
    ROUND(SUM(total_revenue), 2)                AS lifetime_value,
    ROUND(AVG(total_revenue), 2)                AS avg_order_value,
    MIN(order_date)                             AS first_order,
    MAX(order_date)                             AS last_order,
    ROUND(AVG(rating), 2)                       AS avg_rating
FROM orders
WHERE order_status != 'Cancelled'
GROUP BY customer_id, customer_name
ORDER BY lifetime_value DESC
LIMIT 20;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 6: Monthly Revenue Trend with MoM Growth
-- Purpose:  Financial tracking and trend analysis
-- ─────────────────────────────────────────────────────────────────────────────
WITH monthly AS (
    SELECT
        -- Use substr for SQLite compatibility; use DATE_FORMAT for MySQL
        substr(order_date, 1, 7)                AS month,
        COUNT(*)                                AS total_orders,
        ROUND(SUM(total_revenue), 2)            AS revenue,
        COUNT(DISTINCT customer_id)             AS unique_customers
    FROM orders
    WHERE order_status != 'Cancelled'
    GROUP BY substr(order_date, 1, 7)
),
monthly_with_lag AS (
    SELECT
        month,
        total_orders,
        revenue,
        unique_customers,
        LAG(revenue) OVER (ORDER BY month)      AS prev_month_revenue
    FROM monthly
)
SELECT
    month,
    total_orders,
    revenue,
    unique_customers,
    prev_month_revenue,
    CASE
        WHEN prev_month_revenue IS NOT NULL AND prev_month_revenue > 0
        THEN ROUND((revenue - prev_month_revenue) * 100.0 / prev_month_revenue, 2)
        ELSE NULL
    END                                         AS mom_growth_pct
FROM monthly_with_lag
ORDER BY month;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 7: Peak Order Hours (Hourly Distribution)
-- Purpose:  Capacity planning and driver allocation
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    CAST(substr(order_time, 1, 2) AS INTEGER)   AS order_hour,
    COUNT(*)                                    AS order_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2)
                                                AS pct_of_total,
    ROUND(SUM(total_revenue), 2)                AS hourly_revenue,
    ROUND(AVG(total_revenue), 2)                AS avg_order_value
FROM orders
GROUP BY CAST(substr(order_time, 1, 2) AS INTEGER)
ORDER BY order_hour;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 8: Best Performing City (Composite Score)
-- Purpose:  Strategic expansion decisions using multi-metric ranking
-- ─────────────────────────────────────────────────────────────────────────────
WITH city_metrics AS (
    SELECT
        city,
        COUNT(*)                                        AS total_orders,
        ROUND(SUM(total_revenue), 2)                    AS revenue,
        ROUND(AVG(CASE WHEN order_status = 'Delivered' AND actual_delivery_min IS NOT NULL
                       THEN actual_delivery_min END), 1) AS avg_delivery_min,
        ROUND(
            SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
        )                                               AS cancel_rate,
        ROUND(AVG(CASE WHEN rating IS NOT NULL THEN rating END), 2)
                                                        AS avg_rating,
        ROUND(
            SUM(CASE WHEN actual_delivery_min <= estimated_delivery_min THEN 1 ELSE 0 END) * 100.0
            / NULLIF(SUM(CASE WHEN actual_delivery_min IS NOT NULL THEN 1 ELSE 0 END), 0), 1
        )                                               AS on_time_pct
    FROM orders
    GROUP BY city
)
SELECT
    city,
    total_orders,
    revenue,
    avg_delivery_min,
    cancel_rate,
    avg_rating,
    on_time_pct,
    -- Composite score: higher is better
    ROUND(
        (revenue / (SELECT MAX(revenue) FROM city_metrics)) * 30
        + (COALESCE(avg_rating, 3) / 5.0) * 25
        + (COALESCE(on_time_pct, 50) / 100.0) * 25
        + ((100 - cancel_rate) / 100.0) * 20,
    2)                                                  AS composite_score
FROM city_metrics
ORDER BY composite_score DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 9: Daily Order Volume
-- Purpose:  Demand forecasting and operational planning
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    order_date,
    COUNT(*)                                    AS daily_orders,
    ROUND(SUM(total_revenue), 2)                AS daily_revenue,
    COUNT(DISTINCT driver_id)                   AS active_drivers,
    COUNT(DISTINCT customer_id)                 AS unique_customers
FROM orders
GROUP BY order_date
ORDER BY order_date;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 10: Revenue by Vehicle Type
-- Purpose:  Fleet optimization and pricing strategy
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    vehicle_type,
    COUNT(*)                                    AS total_orders,
    ROUND(SUM(total_revenue), 2)                AS total_revenue,
    ROUND(AVG(order_value), 2)                  AS avg_order_value,
    ROUND(AVG(delivery_fee), 2)                 AS avg_delivery_fee,
    ROUND(AVG(distance_km), 1)                  AS avg_distance_km,
    ROUND(AVG(CASE WHEN order_status = 'Delivered' AND actual_delivery_min IS NOT NULL
                   THEN actual_delivery_min END), 1)
                                                AS avg_delivery_time_min,
    ROUND(
        SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
    )                                           AS cancel_rate_pct
FROM orders
GROUP BY vehicle_type
ORDER BY total_revenue DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 11: Average Order Value by City
-- Purpose:  Pricing strategy and market segmentation
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    city,
    COUNT(*)                                    AS orders,
    ROUND(AVG(order_value), 2)                  AS avg_order_value,
    ROUND(MIN(order_value), 2)                  AS min_order_value,
    ROUND(MAX(order_value), 2)                  AS max_order_value,
    ROUND(AVG(delivery_fee), 2)                 AS avg_delivery_fee,
    ROUND(AVG(total_revenue), 2)                AS avg_total_revenue
FROM orders
WHERE order_status != 'Cancelled'
GROUP BY city
ORDER BY avg_order_value DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 12: Driver Performance Ranking
-- Purpose:  HR decisions, incentive allocation, and training needs
-- ─────────────────────────────────────────────────────────────────────────────
WITH driver_stats AS (
    SELECT
        driver_id,
        driver_name,
        COUNT(*)                                AS total_trips,
        SUM(CASE WHEN order_status = 'Delivered' THEN 1 ELSE 0 END)
                                                AS successful_deliveries,
        ROUND(AVG(rating), 2)                   AS avg_rating,
        ROUND(SUM(total_revenue), 2)            AS revenue_generated,
        ROUND(AVG(CASE WHEN actual_delivery_min IS NOT NULL
                       THEN actual_delivery_min END), 1)
                                                AS avg_delivery_min,
        ROUND(
            SUM(CASE WHEN actual_delivery_min <= estimated_delivery_min THEN 1 ELSE 0 END) * 100.0
            / NULLIF(SUM(CASE WHEN actual_delivery_min IS NOT NULL THEN 1 ELSE 0 END), 0), 1
        )                                       AS on_time_pct
    FROM orders
    GROUP BY driver_id, driver_name
)
SELECT
    driver_id,
    driver_name,
    total_trips,
    successful_deliveries,
    avg_rating,
    revenue_generated,
    avg_delivery_min,
    on_time_pct,
    RANK() OVER (ORDER BY avg_rating DESC, on_time_pct DESC)
                                                AS performance_rank
FROM driver_stats
ORDER BY performance_rank
LIMIT 25;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 13: Customer Retention / Repeat Rate
-- Purpose:  Measure customer loyalty and growth quality
-- ─────────────────────────────────────────────────────────────────────────────
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(*)                                AS order_count,
        MIN(order_date)                         AS first_order,
        MAX(order_date)                         AS last_order,
        SUM(total_revenue)                      AS lifetime_revenue
    FROM orders
    WHERE order_status != 'Cancelled'
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN order_count = 1 THEN '1 order (One-time)'
        WHEN order_count BETWEEN 2 AND 3 THEN '2-3 orders (Returning)'
        WHEN order_count BETWEEN 4 AND 6 THEN '4-6 orders (Regular)'
        WHEN order_count BETWEEN 7 AND 10 THEN '7-10 orders (Loyal)'
        ELSE '10+ orders (VIP)'
    END                                         AS customer_segment,
    COUNT(*)                                    AS customer_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_orders), 2)
                                                AS segment_pct,
    ROUND(AVG(lifetime_revenue), 2)             AS avg_lifetime_value,
    ROUND(SUM(lifetime_revenue), 2)             AS total_segment_revenue
FROM customer_orders
GROUP BY
    CASE
        WHEN order_count = 1 THEN '1 order (One-time)'
        WHEN order_count BETWEEN 2 AND 3 THEN '2-3 orders (Returning)'
        WHEN order_count BETWEEN 4 AND 6 THEN '4-6 orders (Regular)'
        WHEN order_count BETWEEN 7 AND 10 THEN '7-10 orders (Loyal)'
        ELSE '10+ orders (VIP)'
    END
ORDER BY MIN(order_count);


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 14: Delayed Delivery Analysis
-- Purpose:  Operations improvement — identify delay patterns
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    city,
    vehicle_type,
    COUNT(*)                                    AS total_deliveries,
    SUM(CASE WHEN actual_delivery_min > estimated_delivery_min THEN 1 ELSE 0 END)
                                                AS delayed_deliveries,
    ROUND(
        SUM(CASE WHEN actual_delivery_min > estimated_delivery_min THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2
    )                                           AS delay_pct,
    ROUND(AVG(CASE WHEN actual_delivery_min > estimated_delivery_min
                   THEN actual_delivery_min - estimated_delivery_min END), 1)
                                                AS avg_delay_minutes
FROM orders
WHERE order_status = 'Delivered'
  AND actual_delivery_min IS NOT NULL
GROUP BY city, vehicle_type
HAVING COUNT(*) >= 20
ORDER BY delay_pct DESC
LIMIT 25;


-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 15: Payment Mode Distribution & Insights
-- Purpose:  Fintech partnership decisions and payment optimization
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    payment_mode,
    COUNT(*)                                    AS total_orders,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2)
                                                AS usage_pct,
    ROUND(SUM(total_revenue), 2)                AS total_revenue,
    ROUND(AVG(order_value), 2)                  AS avg_order_value,
    ROUND(
        SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
    )                                           AS cancel_rate_pct,
    ROUND(AVG(rating), 2)                       AS avg_rating
FROM orders
GROUP BY payment_mode
ORDER BY total_orders DESC;

-- ============================================================================
-- END OF ANALYTICAL QUERIES
-- ============================================================================
