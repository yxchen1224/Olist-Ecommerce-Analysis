-- Olist 项目：数据库与数据导入
-- 说明：
-- 1. 本文件用于首次搭建数据库和导入 CSV。
-- 2. 如果数据库和五张表已经存在且数据已导入，不需要重复执行。
-- 3. 导入路径按当前项目目录设置；如项目位置不同，请修改路径。
-- 4. 重复导入前请先确认表内是否已有数据，避免重复写入。

CREATE DATABASE IF NOT EXISTS olist
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE olist;

-- 订单表
CREATE TABLE IF NOT EXISTS orders (
    order_id VARCHAR(32) PRIMARY KEY,
    customer_id VARCHAR(32),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

-- 客户表
CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR(32) PRIMARY KEY,
    customer_unique_id VARCHAR(32),
    customer_zip_code_prefix VARCHAR(5),
    customer_city VARCHAR(100),
    customer_state VARCHAR(2)
);

-- 订单商品明细表
CREATE TABLE IF NOT EXISTS order_items (
    order_id VARCHAR(32),
    order_item_id INT,
    product_id VARCHAR(32),
    seller_id VARCHAR(32),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);

-- 商品表
CREATE TABLE IF NOT EXISTS products (
    product_id VARCHAR(32) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

-- 评论表
CREATE TABLE IF NOT EXISTS reviews (
    review_id VARCHAR(32) PRIMARY KEY,
    order_id VARCHAR(32),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);

-- 开启本地文件导入权限（需要相应数据库权限）
SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';

-- 以下导入语句按项目 data 文件夹路径设置
-- 如果 MySQL 客户端仍提示 local data is disabled，
-- 还需要在客户端连接配置中允许 LOCAL INFILE。

LOAD DATA LOCAL INFILE 'D:/Olist-Ecommerce-Analysis/data/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:/Olist-Ecommerce-Analysis/data/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:/Olist-Ecommerce-Analysis/data/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, order_item_id, product_id, seller_id,
 shipping_limit_date, price, freight_value);

LOAD DATA LOCAL INFILE 'D:/Olist-Ecommerce-Analysis/data/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_category_name,
 product_name_lenght, product_description_lenght,
 product_photos_qty, product_weight_g,
 product_length_cm, product_height_cm, product_width_cm);

LOAD DATA LOCAL INFILE 'D:/Olist-Ecommerce-Analysis/data/olist_order_reviews_dataset.csv'
INTO TABLE reviews
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(review_id, order_id, review_score, review_comment_title,
 review_comment_message, review_creation_date, review_answer_timestamp);

-- 导入后检查行数
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM orders
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews;
