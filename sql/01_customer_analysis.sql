-- Olist 项目：客户数量、复购与购买间隔分析
USE olist;

-- 1. 客户表规模与真实客户数
SELECT
    COUNT(*) AS customer_id_count,
    COUNT(DISTINCT customer_unique_id) AS real_customer_count
FROM customers;

-- 2. 订单关联真实客户，计算每位客户的订单数
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
)
SELECT *
FROM customer_orders
ORDER BY order_count DESC;

-- 3. 客户订单次数分布
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    order_count,
    COUNT(*) AS customer_count
FROM customer_orders
GROUP BY order_count
ORDER BY order_count;

-- 4. 一次购买客户与复购客户数量
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    CASE
        WHEN order_count = 1 THEN '一次购买客户'
        ELSE '复购客户'
    END AS customer_type,
    COUNT(*) AS customer_count
FROM customer_orders
GROUP BY
    CASE
        WHEN order_count = 1 THEN '一次购买客户'
        ELSE '复购客户'
    END;

-- 5. 复购客户数与整体观察期复购率
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS total_customers,
    SUM(order_count >= 2) AS repeat_customers,
    ROUND(100 * SUM(order_count >= 2) / COUNT(*), 2) AS repeat_customer_rate_pct
FROM customer_orders;

-- 6. 使用 LAG 计算每位真实客户相邻两笔订单的时间间隔
WITH purchase_intervals AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        LAG(o.order_purchase_timestamp) OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp, o.order_id
        ) AS previous_purchase_time
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
)
SELECT
    customer_unique_id,
    order_id,
    order_purchase_timestamp,
    previous_purchase_time,
    TIMESTAMPDIFF(
        SECOND,
        previous_purchase_time,
        order_purchase_timestamp
    ) / 86400.0 AS interval_days
FROM purchase_intervals
WHERE previous_purchase_time IS NOT NULL
ORDER BY customer_unique_id, order_purchase_timestamp;

-- 7. 复购间隔记录数、零间隔数、小于一天间隔数及受影响客户数
WITH purchase_intervals AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        LAG(o.order_purchase_timestamp) OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp, o.order_id
        ) AS previous_purchase_time
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
)
SELECT
    COUNT(*) AS total_interval_records,
    SUM(o.order_purchase_timestamp = o.previous_purchase_time) AS zero_interval_records,
    SUM(
        o.order_purchase_timestamp > o.previous_purchase_time
        AND o.order_purchase_timestamp < DATE_ADD(o.previous_purchase_time, INTERVAL 1 DAY)
    ) AS intervals_under_1_day,
    COUNT(DISTINCT CASE
        WHEN o.order_purchase_timestamp > o.previous_purchase_time
         AND o.order_purchase_timestamp < DATE_ADD(o.previous_purchase_time, INTERVAL 1 DAY)
        THEN o.customer_unique_id
    END) AS affected_customers
FROM purchase_intervals o
WHERE o.previous_purchase_time IS NOT NULL;

-- 8. 每位客户小于一天的间隔次数分布
WITH purchase_intervals AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp,
        LAG(o.order_purchase_timestamp) OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp, o.order_id
        ) AS previous_purchase_time
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
),
short_intervals AS (
    SELECT customer_unique_id
    FROM purchase_intervals
    WHERE previous_purchase_time IS NOT NULL
      AND order_purchase_timestamp > previous_purchase_time
      AND order_purchase_timestamp < DATE_ADD(previous_purchase_time, INTERVAL 1 DAY)
),
customer_short_counts AS (
    SELECT
        customer_unique_id,
        COUNT(*) AS short_interval_count
    FROM short_intervals
    GROUP BY customer_unique_id
)
SELECT
    short_interval_count,
    COUNT(*) AS customer_count
FROM customer_short_counts
GROUP BY short_interval_count
ORDER BY short_interval_count;
