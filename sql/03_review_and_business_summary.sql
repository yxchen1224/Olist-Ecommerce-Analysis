-- Olist 项目：客户评价、商品体验与月度经营概览
-- 注意：原始 SQL.sql 中有评价分析和月度经营汇总，
-- 但没有形成完整的配送延迟率/延迟天数 SQL 分析。
-- 本文件不把评价相关性解释为因果关系。
USE olist;

-- 1. 评论数据规模
SELECT
    COUNT(*) AS review_rows,
    COUNT(DISTINCT review_id) AS unique_reviews,
    COUNT(DISTINCT order_id) AS reviewed_orders
FROM reviews;

-- 2. 评分分布
SELECT
    review_score,
    COUNT(*) AS review_count
FROM reviews
GROUP BY review_score
ORDER BY review_score;

-- 3. 各商品类别平均评分（仅保留评价订单数不少于 100 的类别）
WITH order_reviews AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score
    FROM reviews
    GROUP BY order_id
),
category_orders AS (
    SELECT DISTINCT
        p.product_category_name,
        oi.order_id
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
)
SELECT
    co.product_category_name,
    COUNT(*) AS reviewed_order_count,
    ROUND(AVG(orv.avg_review_score), 2) AS avg_review_score
FROM category_orders co
JOIN order_reviews orv
    ON co.order_id = orv.order_id
GROUP BY co.product_category_name
HAVING COUNT(*) >= 100
ORDER BY avg_review_score ASC
LIMIT 15;

-- 4. 商品类别综合表现：销售额、运费占比、平均评分
WITH order_reviews AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score
    FROM reviews
    GROUP BY order_id
),
category_orders AS (
    SELECT DISTINCT
        p.product_category_name,
        oi.order_id
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
),
category_reviews AS (
    SELECT
        co.product_category_name,
        COUNT(*) AS reviewed_order_count,
        AVG(orv.avg_review_score) AS avg_review_score
    FROM category_orders co
    JOIN order_reviews orv
        ON co.order_id = orv.order_id
    GROUP BY co.product_category_name
),
category_sales AS (
    SELECT
        p.product_category_name,
        COUNT(*) AS item_count,
        COUNT(DISTINCT oi.order_id) AS order_count,
        SUM(oi.price) AS total_sales,
        SUM(oi.freight_value) AS total_freight
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    GROUP BY p.product_category_name
)
SELECT
    s.product_category_name,
    s.item_count,
    s.order_count,
    ROUND(s.total_sales, 2) AS total_sales,
    ROUND(s.total_freight, 2) AS total_freight,
    ROUND(s.total_freight / NULLIF(s.total_sales, 0) * 100, 2) AS freight_ratio_pct,
    r.reviewed_order_count,
    ROUND(r.avg_review_score, 2) AS avg_review_score
FROM category_sales s
LEFT JOIN category_reviews r
    ON s.product_category_name = r.product_category_name
ORDER BY r.avg_review_score ASC;

-- 5. 办公家具类别：商品级销售与评价表现
WITH order_reviews AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score
    FROM reviews
    GROUP BY order_id
),
sku_orders AS (
    SELECT DISTINCT
        oi.product_id,
        oi.order_id
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE p.product_category_name = 'moveis_escritorio'
),
sku_reviews AS (
    SELECT
        so.product_id,
        COUNT(*) AS reviewed_order_count,
        AVG(orv.avg_review_score) AS avg_review_score
    FROM sku_orders so
    JOIN order_reviews orv
        ON so.order_id = orv.order_id
    GROUP BY so.product_id
),
sku_sales AS (
    SELECT
        oi.product_id,
        COUNT(*) AS item_count,
        COUNT(DISTINCT oi.order_id) AS order_count,
        SUM(oi.price) AS total_sales,
        AVG(oi.price) AS avg_price,
        SUM(oi.freight_value) AS total_freight
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE p.product_category_name = 'moveis_escritorio'
    GROUP BY oi.product_id
)
SELECT
    s.product_id,
    s.item_count,
    s.order_count,
    ROUND(s.total_sales, 2) AS total_sales,
    ROUND(s.avg_price, 2) AS avg_price,
    ROUND(s.total_freight / NULLIF(s.total_sales, 0) * 100, 2) AS freight_ratio_pct,
    COALESCE(r.reviewed_order_count, 0) AS reviewed_order_count,
    ROUND(r.avg_review_score, 2) AS avg_review_score
FROM sku_sales s
LEFT JOIN sku_reviews r
    ON s.product_id = r.product_id
ORDER BY s.total_sales DESC
LIMIT 20;

-- 6. 办公家具类别低评分订单及评论内容抽查
SELECT
    oi.product_id,
    oi.order_id,
    oi.price,
    oi.freight_value,
    r.review_score,
    r.review_comment_title,
    r.review_comment_message
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN reviews r
    ON oi.order_id = r.order_id
WHERE p.product_category_name = 'moveis_escritorio'
  AND r.review_score <= 2
ORDER BY r.review_score ASC
LIMIT 30;

-- 7. 月度经营概览：订单、客户、销售额、运费和平均评分
-- 订单商品先汇总到订单层级，避免订单多商品导致评价重复计算。
WITH order_sales AS (
    SELECT
        order_id,
        SUM(price) AS total_sales,
        SUM(freight_value) AS total_freight
    FROM order_items
    GROUP BY order_id
),
order_reviews AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score
    FROM reviews
    GROUP BY order_id
)
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(DISTINCT o.order_id) AS order_count,
    COUNT(DISTINCT c.customer_unique_id) AS customer_count,
    ROUND(SUM(os.total_sales), 2) AS total_sales,
    ROUND(AVG(os.total_sales), 2) AS avg_order_value,
    ROUND(SUM(os.total_freight), 2) AS total_freight,
    ROUND(
        SUM(os.total_freight) / NULLIF(SUM(os.total_sales), 0) * 100,
        2
    ) AS freight_ratio_pct,
    ROUND(AVG(orr.avg_review_score), 2) AS avg_review_score
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_sales os
    ON o.order_id = os.order_id
LEFT JOIN order_reviews orr
    ON o.order_id = orr.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY order_month;

-- 8. 已完成订单中，各商品类别销售与平均评分
WITH order_product AS (
    SELECT
        p.product_category_name,
        o.order_id,
        COUNT(*) AS item_count,
        SUM(oi.price) AS total_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY p.product_category_name, o.order_id
),
order_reviews AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score
    FROM reviews
    GROUP BY order_id
)
SELECT
    op.product_category_name,
    SUM(op.item_count) AS item_count,
    COUNT(DISTINCT op.order_id) AS order_count,
    ROUND(SUM(op.total_sales), 2) AS total_sales,
    ROUND(AVG(orv.avg_review_score), 2) AS avg_review_score
FROM order_product op
LEFT JOIN order_reviews orv
    ON op.order_id = orv.order_id
GROUP BY op.product_category_name
HAVING SUM(op.total_sales) > 100000
ORDER BY total_sales DESC;
