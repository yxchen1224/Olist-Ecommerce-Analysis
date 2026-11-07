-- Olist 项目：商品类别、销售额、价格与运费分析
USE olist;

-- 1. 检查订单商品与商品类别关联结果
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    p.product_category_name,
    oi.price,
    oi.freight_value
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LIMIT 10;

-- 2. 各商品类别订单数与销售额 TOP 10
SELECT
    p.product_category_name,
    COUNT(*) AS item_rows,
    COUNT(DISTINCT oi.order_id) AS order_count,
    SUM(oi.price) AS total_sales
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_sales DESC
LIMIT 10;

-- 3. 各商品类别平均商品价格 TOP 10
SELECT
    p.product_category_name,
    COUNT(*) AS item_rows,
    SUM(oi.price) AS total_sales,
    AVG(oi.price) AS avg_item_price
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY avg_item_price DESC
LIMIT 10;

-- 4. 各商品类别平均运费 TOP 10
SELECT
    p.product_category_name,
    COUNT(*) AS item_rows,
    SUM(oi.freight_value) AS total_freight,
    AVG(oi.freight_value) AS avg_freight,
    AVG(oi.price) AS avg_item_price
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY avg_freight DESC
LIMIT 10;

-- 5. 各商品类别运费占销售额比例 TOP 10
-- 仅保留至少 100 条商品明细的类别，降低极小样本带来的波动
SELECT
    p.product_category_name,
    COUNT(*) AS item_rows,
    SUM(oi.price) AS total_sales,
    SUM(oi.freight_value) AS total_freight,
    ROUND(
        SUM(oi.freight_value) / NULLIF(SUM(oi.price), 0) * 100,
        2
    ) AS freight_ratio_pct
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
HAVING COUNT(*) >= 100
ORDER BY freight_ratio_pct DESC
LIMIT 10;

-- 6. 不同商品重量区间的运费与商品价格
WITH item_weight AS (
    SELECT
        oi.order_id,
        oi.product_id,
        oi.price,
        oi.freight_value,
        p.product_weight_g,
        CASE
            WHEN p.product_weight_g <= 500 THEN '0-500g'
            WHEN p.product_weight_g <= 1500 THEN '501-1500g'
            WHEN p.product_weight_g <= 5000 THEN '1501-5000g'
            ELSE '5000g以上'
        END AS weight_group
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE p.product_weight_g IS NOT NULL
      AND p.product_weight_g > 0
)
SELECT
    weight_group,
    COUNT(*) AS item_rows,
    COUNT(DISTINCT product_id) AS product_count,
    ROUND(AVG(product_weight_g), 2) AS avg_weight_g,
    ROUND(AVG(freight_value), 2) AS avg_freight,
    ROUND(AVG(price), 2) AS avg_price
FROM item_weight
GROUP BY weight_group
ORDER BY MIN(product_weight_g);

-- 7. 不同商品重量区间的运费占比
WITH item_weight AS (
    SELECT
        oi.price,
        oi.freight_value,
        p.product_weight_g,
        CASE
            WHEN p.product_weight_g <= 500 THEN '0-500g'
            WHEN p.product_weight_g <= 1500 THEN '501-1500g'
            WHEN p.product_weight_g <= 5000 THEN '1501-5000g'
            ELSE '5000g以上'
        END AS weight_group
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE p.product_weight_g IS NOT NULL
      AND p.product_weight_g > 0
)
SELECT
    weight_group,
    COUNT(*) AS item_rows,
    ROUND(
        SUM(freight_value) / NULLIF(SUM(price), 0) * 100,
        2
    ) AS freight_ratio_pct
FROM item_weight
GROUP BY weight_group
ORDER BY MIN(product_weight_g);

-- 8. 不同商品体积区间的平均运费
WITH item_volume AS (
    SELECT
        oi.freight_value,
        oi.price,
        p.product_length_cm * p.product_width_cm * p.product_height_cm AS volume_cm3
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE p.product_length_cm > 0
      AND p.product_width_cm > 0
      AND p.product_height_cm > 0
)
SELECT
    CASE
        WHEN volume_cm3 <= 1000 THEN '0-1000cm3'
        WHEN volume_cm3 <= 5000 THEN '1001-5000cm3'
        WHEN volume_cm3 <= 20000 THEN '5001-20000cm3'
        ELSE '20000cm3以上'
    END AS volume_group,
    COUNT(*) AS item_rows,
    ROUND(AVG(volume_cm3), 2) AS avg_volume_cm3,
    ROUND(AVG(freight_value), 2) AS avg_freight
FROM item_volume
GROUP BY volume_group
ORDER BY MIN(volume_cm3);
