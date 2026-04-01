--Explore all the countries that our customers belong to
SELECT DISTINCT country FROM gold.dim_customers ;

--DATE EXPLORATION
--=================

--AFTER exploring all the tables and columns now we explore the dates and try to figure out HOW MANY YEARS OF DATA we are
-- dealing with right now
SELECT MAX(order_date) AS first_order_date,
MIN(order_date) AS last_order_date,
DATEDIFF(year,MIN(order_date),MAX(order_date) )AS order_range_year
FROM gold.fact_sales

--Find the youngest and the oldest Customer
--EXTRACTING AGE FROM birthdate
SELECT
MIN(birthdate) AS oldest_birthdate,
MAX(birthdate) AS youngest_birthdate,
DATEDIFF(year,MIN(birthdate),GETDATE()) AS oldest_age,
DATEDIFF(year,MAX(birthdate),GETDATE()) AS youngest_age
FROM gold.dim_customers



--MEASURE EXPLORATION
--=======================


--SELECT * FROM gold.fact_sales
SELECT SUM(sales_amount) AS Total_Sales,
SUM(quantity) AS Total_units_sold,
AVG(sales_amount) AS AVG_sales_price
FROM gold.fact_sales

--TOTAL NUMBER OF ORDERS
SELECT COUNT(DISTINCT order_number) AS Total_orders
FROM gold.fact_sales
/* As with the same order  the customer is ordering multiple products 
--> that's why we have to use DISTINCT  as order_numbers are repeating
*/
--TOTAL NUMBERS OF PRODUCTS
SELECT  COUNT(DISTINCT product_name) AS Total_customer
FROM gold.dim_products;


--TOTAL NUMBER OF CUSTOMER THAT HAS PLACED ORDER

SELECT COUNT(DISTINCT customer_key) AS Total_number_customer_with_order
FROM gold.fact_sales


--MAGNITUDE ANALYSIS
--====================

--Find Total customers by countries
SELECT country,COUNT(customer_key) AS total_customer_by_country
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customer_by_country DESC

--Find total customers by gender
SELECT gender,COUNT(customer_key) AS total_customer_by_gender
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customer_by_gender


--Find total products by category
SELECT category,COUNT(product_key) AS total_products_by_Category
FROM gold.dim_products
GROUP BY category
ORDER BY total_products_by_Category DESC

--What is the average costs in each category
--select * from gold.fact_sales
SELECT category,AVG(cost) AS avg_costs
FROM gold.dim_products 
GROUP BY category
ORDER BY avg_costs DESC

--What is the total revenue generated for each category
SELECT category,SUM(sales_amount) AS Total_amount_by_Category
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
ON f.product_key = p.product_key
GROUP BY category
ORDER BY Total_amount_by_Category DESC



--Find total revenue is  genrated by each customer
SELECT f.customer_key,
CONCAT(CONCAT(c.first_name,' '),c.last_name)AS customer_name,
SUM(sales_amount) AS Total_amount_by_Cust
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY f.customer_key,CONCAT(CONCAT(c.first_name,' '),c.last_name)
ORDER BY Total_amount_by_Cust DESC

--What is the distribution of sold items across each countries
SELECT c.country,
SUM(f.quantity) AS Total_sold_items
FROM gold.dim_customers c
LEFT JOIN gold.fact_sales f
ON c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY SUM(f.quantity) DESC

--RANKING MEASUREMENTS
--=====================
SELECT TOP 5
product_name,SUM(sales_amount) AS Total_amount_by_product
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
ON f.product_key = p.product_key
GROUP BY product_name
ORDER BY Total_amount_by_product DESC
 
--USING WINDOW Functions
-------------------------
SELECT * FROM
(
	SELECT 
	p.product_name,
	SUM(sales_amount) AS total_revenue,
	ROW_NUMBER () OVER(ORDER BY SUM(sales_amount) DESC) AS Ranking
	FROM gold.fact_sales AS f
	LEFT JOIN gold.dim_products AS p
	ON f.product_key = p.product_key
	GROUP BY product_name
)t
WHERE Ranking <= 5

