/*
==================================================================================
        BIKE STORES - SQL ANALYTICS QUERIES (POSTGRESQL)
==================================================================================
This script contains all SQL queries used for the BikeStores analytics project.

The queries are grouped into several categories:
1.  Store and Sales Performance
2.  Product and Inventory Analysis
3.  Customer Behavior Analysis
4.  Staff (HR) Analysis
5.  Advanced Analytics and Trends
*/


-- ==================================================================
-- 1. Total Orders by Store
-- ==================================================================
-- Find total number of orders per store
SELECT s.store_name, COUNT(o.order_id) AS total_orders
FROM "Stores" s
LEFT JOIN "Orders" o ON s.store_id = o.store_id
GROUP BY s.store_name;


-- ==================================================================
-- 2. Active Staff Count by Store
-- ==================================================================
-- Find number of active staff per store
SELECT s.store_name, COUNT(st.staff_id) AS active_staffs
FROM "Staffs" st
JOIN "Stores" s ON st.store_id = s.store_id
WHERE st.active = 1
GROUP BY s.store_name;


-- ==================================================================
-- 3. Total Products per Brand
-- ==================================================================
-- Find total number of products for each brand
SELECT b.brand_name, COUNT(p.product_id) AS total_products
FROM "Brands" b
LEFT JOIN "Products" p ON b.brand_id = p.brand_id
GROUP BY b.brand_name;


-- ==================================================================
-- 4. Total Stock Quantity by Store
-- ==================================================================
-- Calculate total available stock quantity for each store
SELECT s.store_name, SUM(st.quantity) AS total_stock
FROM "Stores" s
JOIN "Stocks" st ON s.store_id = st.store_id
GROUP BY s.store_name;


-- ==================================================================
-- 5. Average Product Price by Brand
-- ==================================================================
-- Calculate average product price by brand
SELECT b.brand_name, ROUND(AVG(p.list_price),2) AS avg_price
FROM "Brands" b
JOIN "Products" p ON b.brand_id = p.brand_id
GROUP BY b.brand_name
ORDER BY avg_price DESC;


-- ==================================================================
-- 6. Category with the Highest Number of Products
-- ==================================================================
-- Find category that contains the most products
SELECT ca.category_name, COUNT(p.product_id) AS product_count
FROM "Categories" ca
JOIN "Products" p ON ca.category_id = p.category_id
GROUP BY ca.category_name
ORDER BY product_count DESC
LIMIT 1;


-- ==================================================================
-- 7. Products Never Ordered
-- ==================================================================
-- List products that have never been ordered
SELECT p.product_name
FROM "Products" p
WHERE NOT EXISTS (
    SELECT 1
    FROM "Order_Items" oi
    WHERE oi.product_id = p.product_id
);


-- ==================================================================
-- 8. Customers with Only One Order
-- ==================================================================
-- Find customers who placed only one order
SELECT c.first_name, c.last_name, COUNT(o.order_id) AS order_count, MAX(o.order_date) AS single_order_date
FROM "Customers" c
JOIN "Orders" o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(o.order_id) = 1;


-- ==================================================================
-- 9. Sequential Order Number per Customer
-- ==================================================================
-- Assign sequential order numbers for each customer's orders
SELECT customer_id, order_id, order_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_number
FROM "Orders";


-- ==================================================================
-- 10. Total Sales by Staff
-- ==================================================================
-- Calculate total sales amount per staff
SELECT st.first_name, st.last_name, 
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_sales
FROM "Staffs" st
JOIN "Orders" o ON st.staff_id = o.staff_id
JOIN "Order_Items" oi ON o.order_id = oi.order_id
GROUP BY st.first_name, st.last_name
ORDER BY total_sales DESC;


-- ==================================================================
-- 11. Total Sales by City
-- ==================================================================
-- Find total sales amount by city
SELECT c.city,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_sales
FROM "Customers" c
JOIN "Orders" o ON c.customer_id = o.customer_id
JOIN "Order_Items" oi ON o.order_id = oi.order_id
GROUP BY c.city
ORDER BY total_sales DESC;


-- ==================================================================
-- 12. Customers Reordering the Same Product
-- ==================================================================
-- Identify customers who ordered the same product more than once
SELECT c.first_name, c.last_name, p.product_name, COUNT(*) AS times_ordered
FROM "Customers" c
JOIN "Orders" o ON c.customer_id = o.customer_id
JOIN "Order_Items" oi ON o.order_id = oi.order_id
JOIN "Products" p ON oi.product_id = p.product_id
GROUP BY c.first_name, c.last_name, p.product_name
HAVING COUNT(*) > 1;


-- ==================================================================
-- 13. Top 10 Best-Selling Products
-- ==================================================================
-- Display top 10 products by total quantity sold
SELECT p.product_name, b.brand_name, ca.category_name, SUM(oi.quantity) AS total_sold
FROM "Products" p
JOIN "Brands" b ON p.brand_id = b.brand_id
JOIN "Categories" ca ON p.category_id = ca.category_id
JOIN "Order_Items" oi ON p.product_id = oi.product_id
GROUP BY p.product_name, b.brand_name, ca.category_name
ORDER BY total_sold DESC
LIMIT 10;


-- ==================================================================
-- 14. Employees with Their Managers
-- ==================================================================
-- Show each employee and their manager (if any)
SELECT e.first_name || ' ' || e.last_name AS employee_name,
    COALESCE(m.first_name || ' ' || m.last_name, 'N/A') AS manager_name
FROM "Staffs" e
LEFT JOIN "Staffs" m ON e.manager_id = m.staff_id;


-- ==================================================================
-- 15. Monthly Orders and Sales
-- ==================================================================
-- Calculate monthly total orders and sales
SELECT
    DATE_TRUNC('month', o.order_date)::DATE AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_sales
FROM "Orders" o
JOIN "Order_Items" oi ON o.order_id = oi.order_id
GROUP BY order_month
ORDER BY order_month;


-- ==================================================================
-- 16. Customer Order Summary
-- ==================================================================
-- Show total, first, and last order date per customer
SELECT c.first_name,c.last_name,
    COUNT(o.order_id) AS total_orders,
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS last_order_date
FROM "Customers" c
JOIN "Orders" o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_orders DESC;


-- ==================================================================
-- 17. Customers Ordering in at Least 3 Different Months (2018)
-- ==================================================================
-- Find customers who ordered in 3 or more months during 2018
SELECT c.first_name,c.last_name,
COUNT(DISTINCT DATE_TRUNC('month', o.order_date)) AS distinct_months_ordered
FROM "Customers" c
JOIN "Orders" o ON c.customer_id = o.customer_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2018
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(DISTINCT DATE_TRUNC('month', o.order_date)) >= 3
ORDER BY distinct_months_ordered DESC;


-- ==================================================================
-- 18. Days Between First and Second Orders per Customer
-- ==================================================================
-- Calculate days between the first and second order of each customer
WITH OrderedOrders AS (
    SELECT customer_id, order_date,
    ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) AS order_num
    FROM "Orders"
),
FirstTwoOrders AS (
    SELECT customer_id,order_date,order_num,
    LAG(order_date, 1) OVER(PARTITION BY customer_id ORDER BY order_date) AS prev_order_date
    FROM OrderedOrders
    WHERE order_num <= 2
)
SELECT c.first_name,c.last_name,
(f.order_date - f.prev_order_date) AS days_between_first_and_second
FROM FirstTwoOrders f
JOIN "Customers" c ON f.customer_id = c.customer_id
WHERE f.order_num = 2 AND f.prev_order_date IS NOT NULL
ORDER BY days_between_first_and_second;


-- ==================================================================
-- 19. Products Priced Above Category Average
-- ==================================================================
-- List products that are more expensive than their category’s average
SELECT ca.category_name,p.product_name, p.list_price
FROM "Products" p
JOIN "Categories" ca ON p.category_id = ca.category_id
WHERE p.list_price > (
    SELECT AVG(p2.list_price)
    FROM "Products" p2
    WHERE p2.category_id = p.category_id
);


-- ==================================================================
-- 20. Most Expensive Product per Brand (Window Function)
-- ==================================================================
-- Show the most expensive product for each brand
SELECT brand_name,product_name,list_price
FROM (
    SELECT b.brand_name,p.product_name,p.list_price,
    RANK() OVER (PARTITION BY b.brand_id ORDER BY p.list_price DESC) AS rnk
    FROM "Brands" b
    JOIN "Products" p ON b.brand_id = p.brand_id
) AS RankedProducts
WHERE rnk = 1
ORDER BY brand_name;


-- ==================================================================
-- 21. Total Orders by Day of the Week
-- ==================================================================
-- Count how many orders were made each weekday
SELECT
    EXTRACT(ISODOW FROM order_date) AS day_num,  
    TO_CHAR(order_date, 'FMDay') AS day_of_week,
    COUNT(order_id) AS total_orders
FROM "Orders"
GROUP BY day_num, TO_CHAR(order_date, 'FMDay')
ORDER BY day_num;


-- ==================================================================
-- 22. Products Available in All Stores
-- ==================================================================
-- Find products available (quantity > 0) in every store
SELECT p.product_name
FROM "Stocks" s
JOIN "Products" p ON s.product_id = p.product_id
WHERE s.quantity > 0
GROUP BY p.product_id, p.product_name
HAVING COUNT(DISTINCT s.store_id) = (SELECT COUNT(*) FROM "Stores");


-- ==================================================================
-- 23. Staff Ranking by Number of Orders Processed
-- ==================================================================
-- Rank staff by how many orders they have processed
SELECT s.first_name,s.last_name,
    COUNT(o.order_id) AS total_orders_processed,
    DENSE_RANK() OVER(ORDER BY COUNT(o.order_id) DESC) AS staff_rank
FROM "Staffs" s
JOIN "Orders" o ON s.staff_id = o.staff_id
GROUP BY s.staff_id, s.first_name, s.last_name
ORDER BY staff_rank;


-- ==================================================================
-- 24. Top-Selling Product per Category (by Revenue)
-- ==================================================================
-- Identify top-selling product per category by total revenue
WITH ProductSales AS (
    SELECT p.product_id,p.product_name,p.category_id,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue
    FROM "Products" p
    JOIN "Order_Items" oi ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.product_name, p.category_id
)
SELECT c.category_name,ps.product_name,ps.total_revenue,
    RANK() OVER(PARTITION BY c.category_name ORDER BY ps.total_revenue DESC) AS sales_rank_in_category
FROM ProductSales ps
JOIN "Categories" c ON ps.category_id = c.category_id
ORDER BY c.category_name, sales_rank_in_category;


-- ==================================================================
-- 25. Order Summary: Unique Products and Total Value per Order
-- ==================================================================
-- For each order, count unique products and total revenue
SELECT order_id,
COUNT(DISTINCT product_id) AS unique_product_count,
ROUND(SUM(quantity * list_price * (1 - discount))) AS total_order_amount
FROM "Order_Items"
GROUP BY order_id
ORDER BY unique_product_count DESC;


-- ==================================================================
-- 26. Yearly Sales and YOY Growth
-- ==================================================================
-- Calculate total yearly sales and year-over-year growth percentage
WITH YearlySales AS (
    SELECT EXTRACT(YEAR FROM o.order_date) AS order_year,
           SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_sales
    FROM "Orders" o
    JOIN "Order_Items" oi ON o.order_id = oi.order_id
    GROUP BY order_year
)
SELECT order_year,
       total_sales,
       ROUND((total_sales - LAG(total_sales) OVER (ORDER BY order_year)) / 
             LAG(total_sales) OVER (ORDER BY order_year) * 100, 2) AS yoy_growth
FROM YearlySales
ORDER BY order_year;


-- ==================================================================
-- 27. Customer Repeat Rate
-- ==================================================================
-- Calculate repeat purchase rate (percentage of returning customers)
WITH CustomerOrders AS (
    SELECT customer_id, COUNT(order_id) AS total_orders
    FROM "Orders"
    GROUP BY customer_id
)
SELECT 
    ROUND(100.0 * COUNT(CASE WHEN total_orders > 1 THEN 1 END) / COUNT(*), 2) AS repeat_rate_percent
FROM CustomerOrders;


-- ==================================================================
-- 28. Average Discount by Staff
-- ==================================================================
-- Calculate average discount percentage given by each staff
SELECT st.first_name || ' ' || st.last_name AS staff_name,
       ROUND(AVG(oi.discount)*100,2) AS avg_discount_percent
FROM "Staffs" st
JOIN "Orders" o ON st.staff_id = o.staff_id
JOIN "Order_Items" oi ON o.order_id = oi.order_id
GROUP BY staff_name
ORDER BY avg_discount_percent DESC;


-- ==================================================================
-- 29. Top Performing Store by Monthly Revenue
-- ==================================================================
-- Identify the store with the highest revenue for each month.
WITH MonthlyTop AS (
    SELECT 
        TO_CHAR(O.Order_date, 'YYYY-MM') AS MONTH,
        S.Store_name,
        ROUND(SUM(Oi.Quantity * Oi.List_price * (1 - Oi.Discount)), 2) AS Total_Revenue,
        COUNT(DISTINCT O.Order_id) AS Total_Orders,
        ROUND(AVG(Oi.Quantity * Oi.List_price * (1 - Oi.Discount)), 2) AS Avg_Revenue,
        ROW_NUMBER() OVER (
            PARTITION BY TO_CHAR(O.Order_date, 'YYYY-MM')
            ORDER BY SUM(Oi.Quantity * Oi.List_price * (1 - Oi.Discount)) DESC
        ) AS rn
    FROM "Orders" O
    JOIN "Stores" S ON O.Store_id = S.Store_id
    JOIN "Order_Items" Oi ON O.Order_id = Oi.Order_id
    GROUP BY MONTH, S.Store_name
)
SELECT MONTH, Store_name, Total_Orders, Total_Revenue, Avg_Revenue
FROM MonthlyTop
WHERE rn = 1
ORDER BY MONTH;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- 30. Most Frequently Bought Product Pairs (Times Ordered > 15)
WITH OrderProducts AS (
    SELECT oi.order_id, p.product_id, p.product_name
    FROM "Order_Items" oi
    JOIN "Products" p ON oi.product_id = p.product_id
),
ProductPairs AS (
    SELECT op1.product_name AS product_1, op2.product_name AS product_2,
           COUNT(*) AS times_ordered_together
    FROM OrderProducts op1
    JOIN OrderProducts op2 ON op1.order_id = op2.order_id AND op1.product_id < op2.product_id
    GROUP BY op1.product_name, op2.product_name
)
SELECT *
FROM ProductPairs
WHERE times_ordered_together > 15
ORDER BY times_ordered_together DESC;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------