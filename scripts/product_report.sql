   /*
==========================================================================================
Product Report
==========================================================================================
Purpose:
    -This report consolidates key products matrics and behaviors

Highlights:
    1. Gather essential fields such as product name, category, and subcategory and cost.
    2. Segments products by revenue to identify High-Performers, Mid_range, or Low_Performers.
    3. Aggregates product_level metrics:
         - total orders
         - total sales
         - total quantity purchhased
         - total products
         - lifespan (in months)
    4. Calculates valueable KPIs:
         - recency (months since last order)
         - average order value (AOR)
         - average monthly revenue

==========================================================================================
    */
    CREATE VIEW gold.report_products AS
    WITH base_query AS 
    (
        SELECT
        p.product_key,
        p.product_name,
        p.category,
        p.sub_category,
        p.cost,
        f.sales_amount,
        f.quantity,
        f.price,
        f.order_number,
        f.order_date
        FROM gold.dim_products AS p
        LEFT JOIN gold.fact_sales AS f
        ON p.product_key = f.product_key
        WHERE order_date IS NOT NULL
    )

    ,aggregate_products AS
    (
        SELECT 
        product_key,
        product_name,
        category,
        sub_category,
        cost,
        COUNT(order_number) AS total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,
        ROUND(AVG(CAST(sales_amount AS FLOAT)/ NULLIF(quantity,0)),1) AS avg_selling_price,
        MAX(order_date) AS lastorder_date,
        DATEDIFF(month,MIN(order_date),MAX(order_date)) AS lifespan
        FROM base_query
        GROUP BY product_key,product_name,category,sub_category,cost
    )

    SELECT 
    product_key,
    product_name,
    sub_category,
    CASE WHEN total_sales > 50000 THEN 'High Performer'
         WHEN total_sales >= 10000 THEN 'Mid_Range'
         ELSE 'Low_Performer'
    END AS product_performance,
    category,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    avg_selling_price,
    lifespan,
    cost,
    DATEDIFF(month,lastorder_date,GETDATE()) AS recency,
    CASE WHEN total_sales = 0 THEN 0
         ELSE total_sales/total_orders
    END AS average_order_value,
    CASE WHEN total_sales = 0 THEN 0
        ELSE total_sales/lifespan
    END AS average_monthly_revenue
    FROM aggregate_products
