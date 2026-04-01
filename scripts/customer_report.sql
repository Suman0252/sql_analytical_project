/*
==========================================================================================
Customer Report
==========================================================================================
Purpose:
    -This report consolidates key customer matrics and behaviors

Highlights:
    1. Gather essential fields such as names, ages, and transaction details.
    2. Segments customer into category (VIP,Regular,New) and age groups.
    3. Aggregates customer_level metrics:
        - total orders
        - total sales
        - total quantity purchhased
        - total products
        - lifespan (in months)
    4. Calculates valueable KPIs:
         - recency (months since last order)
         - average order value
         - average monthly spend

    ======================================================================================
    */
    CREATE VIEW gold.report_customers AS
    WITH base_query AS (
        SELECT 
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name,' ',c.last_name) AS customer_name,
        DATEDIFF(year,c.birthdate,GETDATE()) AS age
        FROM gold.fact_sales AS f
        LEFT JOIN gold.dim_customers AS c 
        ON f.customer_key = c.customer_key
        WHERE order_date IS NOT NULL
    )

    ,customer_aggregation AS
    (
        SELECT 
        customer_key,
        customer_number,
        customer_name,
        age,
        MAX(order_date) AS lastorder_date,
        COUNT(DISTINCT order_number) AS total_order,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,
        DATEDIFF(month,MIN(order_date),MAX(order_date)) AS total_months
        FROM base_query
        GROUP BY  customer_key,customer_number,customer_name,age

    )

    SELECT
    customer_key,
    customer_number,
    customer_name,
    CASE WHEN age <20 THEN 'Under 20'
         WHEN age BETWEEN 20 AND 29 THEN '20-29'
         WHEN age BETWEEN 30 AND 39 THEN '20-29'
         WHEN age BETWEEN 40 AND 49 THEN '20-29'
         ELSE '50 and above'
    END AS age_group,
    lastorder_date,
    DATEDIFF(month,lastorder_date,GETDATE ()) AS recency,
    total_order,
    total_sales,
    total_quantity,
    total_products,
    total_months,
    CASE WHEN total_order = 0 THEN 0
         ELSE total_order/total_order
    END  AS AVG_order_value,
    CASE WHEN  total_sales > 5000 AND total_months >= 12  THEN 'VIP'
		    WHEN  total_sales <= 5000 AND total_months >= 12 THEN 'Regular'
		    ELSE 'New'
	END AS customer_category,
    CASE WHEN total_months = 0 THEN total_sales
         ELSE total_sales/total_months
    END AS avg_monthly_spend
    FROM customer_aggregation






 
