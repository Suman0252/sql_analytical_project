--Analysis 1: Changes OverTime
--============================
SELECT * FROM gold.fact_sales
SELECT 
YEAR(order_date) AS order_year,
MONTH(order_date) AS order_month,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quantity,
COUNT(customer_key) AS total_customer
FROM gold.fact_sales 
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date),MONTH(order_date)
ORDER BY YEAR(order_date),MONTH(order_date)

--Using DATETRUNC
SELECT
DATETRUNC(month,order_date) AS order_date,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quantity,
COUNT(DISTINCT customer_key) AS total_customer
FROM gold.fact_sales 
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month,order_date)
ORDER BY DATETRUNC(month,order_date)

--Using FORMAT
SELECT
FORMAT(order_date,'yyyy-MM') AS order_month, --use 'MMM' for sept,aug,jan but using MMM wil turn order month into a string 
SUM(sales_amount) AS total_sales,             --so order will not be maintained among months
SUM(quantity) AS total_quantity,
COUNT(DISTINCT customer_key) AS total_customer
FROM gold.fact_sales 
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date,'yyyy-MM')
ORDER BY FORMAT(order_date,'yyyy-MM')

--Analysis 2: Cumulative Analysis
--===============================
--Aggregate the data progressively with time
--Helps to understand a buissness is growing or declining over time


--Calculate the total sales of a month or year and the running total of sales over time

SELECT *,
SUM(total_sales) OVER(  ORDER BY order_date) AS running_total,
AVG(average_price) OVER(ORDER BY order_date) AS moving_avg
FROM
(
	SELECT 
	DATETRUNC(year,order_date) AS order_date,
	SUM(sales_amount) AS total_sales,
	AVG(price) average_price
	FROM gold.fact_sales
	WHERE order_date  IS NOT NULL
	GROUP BY DATETRUNC(year,order_date) 
	--ORDER BY DATETRUNC(month,order_date) AS ORDER BY is not allowed inside a subquery
)t

--Performance Analysis
--====================
--Comapring the current value to a target value
--> Helps measure success and compare performance
/*
 Current[Measure] - Target[Measure]
 Current Sales - Average Sales
 Current year Sales - Previous year Sales
 Current Sales - Lowest Sales
*/

/* Analyze the yearly performance of products by comparing their sales 
to both the average sales performance of the product and previous year's sales */

--> year to year analysis used for seeing the long term pattern or behaviour of the buissness
--> while month to month analysis is used for analysing current or recent trends
WITH yearly_product_sales AS (
	SELECT YEAR(order_date) AS order_year,
	product_name,
	SUM(sales_amount) AS current_sales
	FROM gold.fact_sales AS f
	LEFT JOIN gold.dim_products AS p
	ON f.product_key = p.product_key
	WHERE order_date IS NOT NULL
	GROUP BY YEAR(order_date),product_name
)
	--ORDER BY YEAR(order_date),product_name -- can not use order by in CTE )

SELECT 
order_year,
product_name,
current_sales,
AVG(current_sales) OVER(PARTITION BY product_name) AS Avg_sales,
current_sales - AVG(current_sales) OVER(PARTITION BY product_name) AS diff_avg_sales,
CASE WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name ) > 0 THEN 'Above avg'
     WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name ) < 0 THEN 'Below avg'
	 ELSE 'no change'
END AS average_analysis,
LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS previous_year_sales,
current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS diff_py,
CASE WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increasing'
     WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'decreasing'
	 ELSE 'no change'
END AS py_change 
FROM yearly_product_sales



--Part to Whole(Proportional Analysis
--===================================
--Analyse how an individual part is performing compared to the overall, 
--allowing us to understand which category has the greatest impact on business

--([Measure] / Total[Measure]) * 100 By [Dimension]
 --  (Sales/Total Sales) * 100 BY category
 -- (Quantity/Total Quantity)* 100 By country


 --Which category contribute the most to overall sales
 -- as category not present in fact_sales view join is required
 
WITH sales_by_category AS ( 
	 SELECT category,
	 SUM(sales_amount) AS total_sales_by_cat
	 FROM gold.fact_sales AS f
	 LEFT JOIN gold.dim_products AS p
	 ON p.product_key = f.product_key
	 GROUP BY category
 )
 SELECT *,
 SUM(total_sales_by_cat) OVER() AS total_sales,
 ROUND(CAST(total_sales_by_cat AS FLOAT )* 100 /SUM(total_sales_by_cat) OVER(),2) AS perce_contri
 FROM sales_by_category



 --DATA SEGMENTATION
 --[Measure]  BY [Measure]
 --Total Products By Sales Range
 --Total Customers By Age

 WITH product_segment AS
 (    SELECT 
	 product_key,
	 product_name,
	 cost,
	 CASE WHEN cost < 100 THEN 'Below 100'
		  WHEN cost BETWEEN 100 AND 500 THEN '100-500'
		  WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
		  ELSE 'Above 1000'
	END cost_range
	FROM gold.dim_products
)

SELECT
cost_range,
COUNT(product_key) AS total_products
FROM product_segment
GROUP BY cost_range
ORDER BY total_products DESC

/* Group customers into three segments based on their spending behaviour:
   - VIP: Customers with at least 12 months of history and spending more than rs 5,000.
   - Regular: Customers with at least 12 months of history but spending rs 5000 or less.
   - New: Customer with a lifespan less than 12 months.
AND find the total number of customers by each group
*/
WITH customer_spending AS
(
	SELECT
	c.customer_key,
	SUM(sales_amount) total_spending,
	MAX(order_date) AS lastorder_date,
	MIN(order_date) AS firstorder_date,
	DATEDIFF(month,MIN(order_date),MAX(order_date)) AS total_months
	FROM gold.dim_customers AS c
	LEFT JOIN gold.fact_sales AS f
	ON c.customer_key = f.customer_key
	GROUP BY c.customer_key
)
SELECT 
customer_category,
COUNT(customer_key)
FROM (
	SELECT 
	customer_key,
	total_spending,
	total_months,
	CASE WHEN total_spending > 5000 AND total_months >= 12  THEN 'VIP'
		 WHEN total_spending <= 5000 AND total_months >= 12 THEN 'Regular'
		 ELSE 'New'
	END AS customer_category
	FROM customer_spending
) t
GROUP BY customer_category
