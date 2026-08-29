-- ============================================================
-- PROJECT: Olist E-Commerce Data Analysis
-- DESCRIPTION: Database Setup, Data Ingestion, Cleaning & Foreign Keys
--
-- [IMPORTANT] CONFIGURATION PREREQUISITES BEFORE EXECUTING:
-- To prevent Error 3948 & Error 2068 during 'LOAD DATA LOCAL INFILE':
-- 1. SERVER SIDE: Execute 'SET GLOBAL local_infile = 1;' (Line 16).
-- 2. CLIENT SIDE (MySQL Workbench):
--    - Edit Connection -> Advanced Tab -> In 'Others:' field add: OPT_LOCAL_INFILE=1
--    - Save and Reconnect your database connection.
-- ============================================================

-- ------------------------------------------------------------
-- 0. PREPARATION & PERMISSION SETTINGS
-- ------------------------------------------------------------
SET GLOBAL local_infile = 1;

SET SESSION sql_mode = '';
SET SQL_SAFE_UPDATES = 0;

DROP DATABASE IF EXISTS olist_portofolio;
CREATE DATABASE olist_portofolio;
USE olist_portofolio;

-- ------------------------------------------------------------
-- 1. PARENT TABLES
-- ------------------------------------------------------------

CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code_prefix VARCHAR(10) NOT NULL,
    customer_city VARCHAR(50) NOT NULL,
    customer_state VARCHAR(5) NOT NULL
);

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(10) NOT NULL,
    seller_city VARCHAR(50) NOT NULL,
    seller_state VARCHAR(5) NOT NULL
);

CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100) NOT NULL
);

-- ------------------------------------------------------------
-- 2. CHILD TABLES
-- ------------------------------------------------------------

CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    order_purchase_timestamp DATETIME NOT NULL,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

CREATE TABLE order_items (
    order_id VARCHAR(50) NOT NULL,
    order_item_id INT NOT NULL,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    CONSTRAINT order_items_order_id_order_item_id_PK PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
    order_id VARCHAR(50) NOT NULL,
    payment_sequential INT NOT NULL,
    payment_type VARCHAR(20) NOT NULL,
    payment_installments INT NOT NULL,
    payment_value DECIMAL(10, 2) NOT NULL,
    CONSTRAINT order_payments_order_id_payment_sequential_PK PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE order_reviews (
    review_id VARCHAR(50) NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    review_score INT NOT NULL,
    review_comment_title VARCHAR(100),
    review_comment_message TEXT,
    review_creation_date DATETIME NULL,
    review_answer_timestamp DATETIME NULL,
    CONSTRAINT order_reviews_review_id_order_id_PK PRIMARY KEY (review_id, order_id)
);

-- ------------------------------------------------------------
-- 3. DATA INGESTION (Import Raw Data from CSV)
-- NOTE: Update the file path 'C:/Users/User/Downloads/...' to match your local directory structure
-- ------------------------------------------------------------

LOAD DATA LOCAL INFILE 'C:/Users/User/Downloads/Olist Brazilian E-commerce/olist_customers_dataset.csv'
INTO TABLE customers 
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/User/Downloads/Olist Brazilian E-commerce/olist_products_dataset.csv'
INTO TABLE products 
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/User/Downloads/Olist Brazilian E-commerce/olist_sellers_dataset.csv'
INTO TABLE sellers 
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/User/Downloads/Olist Brazilian E-commerce/product_category_name_translation.csv'
INTO TABLE product_category_name_translation 
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/User/Downloads/Olist Brazilian E-commerce/olist_orders_dataset.csv'
INTO TABLE orders 
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/User/Downloads/Olist Brazilian E-commerce/olist_order_items_dataset.csv'
INTO TABLE order_items 
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/User/Downloads/Olist Brazilian E-commerce/olist_order_payments_dataset.csv'
INTO TABLE order_payments 
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/User/Downloads/Olist Brazilian E-commerce/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews 
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- ------------------------------------------------------------
-- 4. DATA CLEANING
-- ------------------------------------------------------------

UPDATE order_reviews 
SET review_creation_date = NULL 
WHERE CAST(review_creation_date AS CHAR) = '0000-00-00 00:00:00';

UPDATE order_reviews 
SET review_answer_timestamp = NULL 
WHERE CAST(review_answer_timestamp AS CHAR) = '0000-00-00 00:00:00';

UPDATE orders 
SET order_approved_at = NULL 
WHERE CAST(order_approved_at AS CHAR) = '0000-00-00 00:00:00';

UPDATE orders 
SET order_delivered_carrier_date = NULL 
WHERE CAST(order_delivered_carrier_date AS CHAR) = '0000-00-00 00:00:00';

UPDATE orders 
SET order_delivered_customer_date = NULL 
WHERE CAST(order_delivered_customer_date AS CHAR) = '0000-00-00 00:00:00';

-- Kembalikan Mode Aman MySQL setelah seluruh data bersih
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SET SQL_SAFE_UPDATES = 1;

-- ------------------------------------------------------------
-- 5. RELATIONAL CONSTRAINTS (Foreign Key Constraints)
-- ------------------------------------------------------------

ALTER TABLE orders
ADD CONSTRAINT orders_customer_id_FK 
FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

ALTER TABLE order_items
ADD CONSTRAINT order_items_order_id_FK FOREIGN KEY (order_id) REFERENCES orders(order_id),
ADD CONSTRAINT order_items_product_id_FK FOREIGN KEY (product_id) REFERENCES products(product_id),
ADD CONSTRAINT order_items_seller_id_FK FOREIGN KEY (seller_id) REFERENCES sellers(seller_id);

ALTER TABLE order_payments
ADD CONSTRAINT order_payments_order_id_FK 
FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE order_reviews
ADD CONSTRAINT order_reviews_order_id_FK 
FOREIGN KEY (order_id) REFERENCES orders(order_id);