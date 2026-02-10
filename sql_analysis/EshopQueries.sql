/* ==========================================================================
   PROJECT: VirtualEshopDB - Business Intelligence & Data Analysis
   AUTHOR: [40panos]
   PURPOSE: Simulation of real-world business queries for an E-commerce store.
   DATABASE: Oracle SQL
   ========================================================================== */

-- 1. Category Profitability & Margin Analysis
-- Analysis: Identifies top-performing categories by net profit and margin %.
-- Use Case: Helps prioritize ad spend for high-margin categories vs. cost-cutting for low-margin ones.
SELECT 
    c.category_name, 
    ROUND(SUM(oi.quantity * oi.unit_price)) AS total_revenue,
    ROUND(SUM(oi.quantity * (oi.unit_price - p.cost_price))) AS total_profit,
    ROUND((SUM(oi.quantity * (oi.unit_price - p.cost_price)) / 
           SUM(oi.quantity * oi.unit_price)) * 100, 2) AS margin_percentage
FROM Category c
JOIN Product p ON c.category_id = p.category_id
JOIN Order_item oi ON p.product_id = oi.product_id
JOIN "Order" o ON oi.order_id = o.order_id 
WHERE o.status = 'Completed'
GROUP BY c.category_name
ORDER BY total_profit DESC;
--------------------------------------------------------------------------------

-- 2. Customer Lifetime Value (CLV) - Top 10 High-Value Clients
-- Objective: Rank customers by total historical spend and generated profit.
-- Use Case: Segmenting "VIP" users for loyalty rewards and personalized marketing.

SELECT 
    cu.first_name , cu.last_name ,
    ROUND(SUM (oi.quantity*(oi.unit_price-pr.cost_price))) as  customer_accumulated_profit,
    ROUND(SUM (oi.quantity*oi.unit_price)) as  total_customer_spendings 
FROM CUSTOMER cu
JOIN "Order" o      ON cu.customer_id = o.customer_id  
JOIN ORDER_ITEM oi  ON o.order_id = oi.order_id        
JOIN PRODUCT pr     ON oi.product_id = pr.product_id  
WHERE o.status = 'Completed'
group by cu.customer_id ,cu.first_name, cu.last_name
ORDER BY customer_accumulated_profit DESC
FETCH FIRST 10 ROWS ONLY;
--------------------------------------------------------------------------------

-- 3. Average Order Value (AOV)
-- KPI: Measures the average revenue generated per unique transaction.
-- Strategy: If AOV is low, consider bundling or free shipping thresholds.

SELECT
    ROUND(SUM(oi.quantity * oi.unit_price) / COUNT(DISTINCT o.order_id), 1) AS AOV
FROM "Order" o
JOIN order_item oi ON oi.order_id = o.order_id
WHERE o.status = 'Completed';
--------------------------------------------------------------------------------

-- 4. Slow-Moving Stock (Bottom 10 Performers)
-- Objective: Identify products with the lowest sales volume.
-- Action: Potential products to be dropped in order to free up warehouse space.


SELECT 
    pr.product_name, 
    NVL(SUM(CASE WHEN o.status = 'Completed' THEN oi.quantity ELSE 0 END), 0) AS units_sold  
FROM PRODUCT pr
LEFT JOIN order_item oi ON pr.product_id = oi.product_id
LEFT JOIN "Order" o ON oi.order_id = o.order_id
GROUP BY pr.product_id, pr.product_name 
ORDER BY units_sold ASC    
FETCH FIRST 10 ROWS ONLY;
--------------------------------------------------------------------------------

-- 5. Monthly Sales & Seasonality Trends (2025)
-- Objective: Track order volume and profit fluctuations across months.
-- Use Case: Forecasting inventory needs and peak-season staffing.

SELECT 
    EXTRACT(MONTH FROM o.order_date) AS "month",
    COUNT(DISTINCT o.order_id) AS orders_volume,
    SUM(oi.quantity) AS products_sold,
    ROUND(SUM(oi.quantity * (oi.unit_price - p.cost_price))) AS total_profit
FROM "Order" o 
JOIN ORDER_ITEM oi ON oi.order_id = o.order_id   
JOIN PRODUCT p     ON p.product_id = oi.product_id
WHERE o.status = 'Completed' 
  AND EXTRACT(YEAR FROM o.order_date) = 2025
GROUP BY EXTRACT(MONTH FROM o.order_date)
ORDER BY "month" ASC;
--------------------------------------------------------------------------------

-- 6. Operational Inventory Audit
-- Analysis: Breakdown of stock movements (Sales, Returns, Restocks).
-- Note: High return frequency may indicate quality control issues.

SELECT 
    reason AS "Reason for Change",
    COUNT(*) AS "Frequency",
    SUM(ABS(change_amount)) AS "Total Units Impacted"
FROM 
    Inventory_log 
GROUP BY 
    reason
ORDER BY 
    "Frequency" DESC;
--------------------------------------------------------------------------------    

-- 7. Product Return Rate Analysis
-- Objective: Identify specific products with the highest return volumes.
-- Goal: Reduce return overhead by addressing defective or misdescribed items.

SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    SUM(ABS(il.change_amount)) AS "Total_returned_Units"
FROM     Product p
JOIN     Inventory_log il ON p.product_id = il.product_id
WHERE     il.reason = 'Return'  
GROUP BY     p.product_id, p.product_name, p.sku
HAVING     SUM(ABS(il.change_amount)) > 0
ORDER BY     "Total_returned_Units" DESC
FETCH FIRST 10 ROWS ONLY;
--------------------------------------------------------------------------------

-- 8. Market Basket Analysis (Co-occurrence)
-- Objective: Find pairs of products frequently bought together in one order.
-- Use Case: Upselling strategies and creating product bundles.

SELECT 
    p1.product_name AS product_a, 
    p2.product_name AS product_b, 
    COUNT(*) AS times_bought_together
FROM Order_item oi1
JOIN Order_item oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
JOIN "Order" o ON oi1.order_id = o.order_id
JOIN Product p1 ON oi1.product_id = p1.product_id
JOIN Product p2 ON oi2.product_id = p2.product_id
WHERE o.status = 'Completed'
GROUP BY p1.product_name, p2.product_name
ORDER BY times_bought_together DESC
FETCH FIRST 10 ROWS ONLY;
--------------------------------------------------------------------------------

/* PowerBI EXPORT QUERIES */
-- Flat tables optimized for PowerBI data modeling and visualization.

-- Transactional Fact Table

SELECT 
    o.order_id,
    o.order_date,
    o.status,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) AS total_revenue,
    (oi.quantity * p.cost_price) AS total_cost,
    ((oi.quantity * oi.unit_price) - (oi.quantity * p.cost_price)) AS profit,
    p.product_name,
    c.category_name,
    cust.city,
    cust.first_name || ' ' || cust.last_name AS customer_full_name
FROM "Order" o
JOIN Order_item oi ON o.order_id = oi.order_id
JOIN Product p ON oi.product_id = p.product_id
JOIN Category c ON p.category_id = c.category_id
JOIN Customer cust ON o.customer_id = cust.customer_id
WHERE o.status = 'Completed';

-- Inventory Movement History

SELECT 
    log_date,
    reason,
    change_amount,
    product_id
FROM Inventory_log
WHERE reason IN ('Sale', 'Return');

-- END OF SCRIPT

