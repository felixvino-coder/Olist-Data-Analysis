-- ============================================================
-- PROJECT: Olist E-Commerce Data Analysis
-- DESCRIPTION: Strategic Business Analytics, Operational Efficiency, & Customer Insights
-- ============================================================

USE olist_portofolio;
-- LIST OF CORE BUSINESS QUESTIONS:
-- 1. [Module 1 - Fulfillment Funnel]
--     At which order lifecycle stage do cancellations occur most frequently?
-- 2. [Module 2 - Financial Trend]
--     What is the Month-over-Month (MoM) growth trend for Total Revenue (GMV)?
-- 3. [Module 3 - Product Dominance]
--     Which product category generates the highest revenue in each peak month?
-- 4. [Module 4 - Logistics & Satisfaction]
--     How severe is the impact of late deliveries on customer review scores?
-- 5. [Module 5 - Regional Strategy]
--     What is the top-selling product category in each Brazilian state?
-- ============================================================


-- 1. [Module 1 - Fulfillment Funnel]
--     At which order lifecycle stage do cancellations occur most frequently?
CREATE OR REPLACE VIEW view_cancellation_funnel AS
SELECT 
    CASE 
        WHEN order_approved_at IS NULL 
            THEN '1. Canceled Before Payment Approval'
        WHEN order_delivered_carrier_date IS NULL 
            THEN '2. Canceled During Seller Processing (Before Carrier)'
        WHEN order_delivered_customer_date IS NULL 
            THEN '3. Canceled In-Transit (Logistics/Carrier Drop-off)'
        ELSE '4. Canceled Post-Delivery (Returned/Refunded)'
    END AS cancellation_stage,
    
    COUNT(*) AS total_canceled_orders,
    
    ROUND(
        (COUNT(*) / (SELECT COUNT(*) FROM orders WHERE order_status = 'canceled')) * 100, 
        2
    ) AS total_cancellations_percentage

FROM orders
WHERE order_status = 'canceled'
GROUP BY cancellation_stage
ORDER BY cancellation_stage;


-- 2. [Module 2 - Financial Trend]
--     What is the Month-over-Month (MoM) growth trend for Total Revenue (GMV)?
CREATE OR REPLACE VIEW view_mom_revenue AS 
WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS year_moth,
        SUM(payment_value) AS total_revenue
    FROM orders o
    JOIN order_payments p ON o.order_id = p.order_id
    WHERE order_status = 'delivered'
    GROUP BY 1
)
SELECT 
    year_moth,
    total_revenue,
    LAG(total_revenue) OVER (ORDER BY year_moth) AS previous_month_revenue
FROM monthly_revenue;


-- 3. [Module 3 - Product Dominance]
--     Which product category generates the highest revenue in each peak month?
CREATE OR REPLACE VIEW view_category_highest_revenue_month AS
WITH category_sales AS(
select DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS year_moth,
		SUM(payment_value) AS total_revenue,
		product_category_name,
		row_number() OVER(PARTITiON BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m') ORDER BY SUM(payment_value)DESC) AS category_rank 
from orders o
JOIN order_payments op
	ON o.order_id=op.order_id
JOIN order_items oi
	ON oi.order_id=o.order_id
JOIN products p
	ON oi.product_id= p.product_id
WHERE order_status='delivered' AND product_category_name IS NOT NULL
GROUP BY 1, 3
ORDER BY 1
)

SELECT 
    year_moth,
    product_category_name AS top_product_category,
    total_revenue,
    category_rank
FROM category_sales
WHERE category_rank = 1  
ORDER BY year_moth ASC;

-- 4. [Module 4 - Logistics & Satisfaction]
--     How severe is the impact of late deliveries on customer review scores?
CREATE OR REPLACE VIEW view_delivery_impact_on_reviews AS
WITH delivery_analysis AS (
	SELECT 
		DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) AS selisih,
		CASE
			WHEN DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date) < 0 THEN 'Late'
			ELSE 'Ontime'
		END AS status_pengiriman,
		review_score
	FROM orders o
	JOIN order_reviews ore ON ore.order_id = o.order_id
	WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
)
SELECT 
    status_pengiriman,
    COUNT(*) AS total_orders,
	ROUND(AVG(review_score), 2) AS avg_review_score,
    ROUND(AVG(selisih), 2) AS avg_days_difference
FROM delivery_analysis
GROUP BY status_pengiriman;

select *
from view_delivery_impact_on_reviews;

-- 5. [Module 5 - Regional Strategy]
--     What is the top-selling product category in each Brazilian state?

CREATE OR REPLACE VIEW view_regional_top_category AS
WITH top_category_each_state AS(
SELECT 
	product_category_name,
	sum(payment_value) AS total_revenue, 
    customer_state,
    row_number() OVER(PARTITION BY customer_state ORDER BY sum(payment_value) DESC) AS ranking
FROM orders o
JOIN order_items oi
	ON oi.order_id=o.order_id
JOIN products p
	ON p.product_id=oi.product_id
JOIN customers c
	ON c.customer_id=o.customer_id
JOIN order_payments op
	ON op.order_id=o.order_id
WHERE order_status='delivered' AND p.product_category_name IS NOT NULL
GROUP BY 1,3)

SELECT 
	customer_state,
	product_category_name,
	total_revenue
FROM top_category_each_state
WHERE ranking=1