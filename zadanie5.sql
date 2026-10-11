-- Active: 1791738834113@@127.0.0.1@5432@datacraftinglab_db
-- Active: 1791738834113@@127.0.0.1@5432@datacraftinglab_db
SELECT * from flourmills_sales;


WITH daily_sales AS (
    SELECT
        sales_date AS sale_date,
        SUM(total_amount) AS total_daily_sales
    FROM flourmills_sales
    GROUP BY sales_date
)
SELECT
    sale_date,
    total_daily_sales
FROM daily_sales
WHERE total_daily_sales > 3000000
ORDER BY total_daily_sales DESC;

WITH category_sales AS (
    SELECT
        product_category,
        SUM(total_amount) AS total_sales
    FROM flourmills_sales
    GROUP BY product_category
)
SELECT
    product_category,
    total_sales
FROM category_sales
ORDER BY total_sales DESC;


WITH product_sales AS (
    SELECT
        product_category,
        product_name,
        SUM(total_amount) AS total_product_sales
    FROM flourmills_sales
    GROUP BY product_category, product_name
),
ranked_products AS (
    SELECT
        product_category,
        product_name,
        total_product_sales,
        RANK() OVER (
            PARTITION BY product_category
            ORDER BY total_product_sales DESC
        ) AS category_rank
    FROM product_sales
)
SELECT
    product_category,
    product_name,
    total_product_sales,
    category_rank
FROM ranked_products
WHERE category_rank <= 3
ORDER BY product_category, category_rank;

WITH customer_sales AS (
    SELECT
        customer_type,
        SUM(total_amount) AS revenue
    FROM flourmills_sales
    GROUP BY customer_type
),
revenue_share AS (
    SELECT
        customer_type,
        revenue,
        SUM(revenue) OVER () AS total_revenue,
        ROUND(revenue * 100.0 / SUM(revenue) OVER (), 2) AS revenue_percentage
    FROM customer_sales
)
SELECT
    customer_type,
    revenue,
    total_revenue,
    revenue_percentage
FROM revenue_share
ORDER BY revenue DESC;

WITH customer_transactions AS (
    SELECT
        customer_id,
        product_name,
        sales_date AS sale_date,
        total_amount,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY sales_date DESC
        ) AS row_num
    FROM flourmills_sales
)
SELECT
    customer_id,
    product_name,
    sale_date,
    total_amount
FROM customer_transactions
WHERE row_num = 1
ORDER BY customer_id ASC;

WITH RECURSIVE date_range AS (
    SELECT
        MIN(sales_date) AS min_date,
        MAX(sales_date) AS max_date
    FROM flourmills_sales
),
calendar AS (
    SELECT min_date AS sales_date, max_date
    FROM date_range

    UNION ALL

    SELECT sales_date + 1, max_date
    FROM calendar
    WHERE sales_date < max_date
)
SELECT sales_date
FROM calendar
ORDER BY sales_date ASC;


WITH RECURSIVE monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', sales_date)::date AS month,
        SUM(total_amount) AS revenue
    FROM flourmills_sales
    GROUP BY DATE_TRUNC('month', sales_date)
),
ordered_months AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY month) AS rn,
        month,
        revenue
    FROM monthly_revenue
),
cumulative_target AS (
    SELECT
        rn,
        month,
        revenue,
        revenue AS cumulative_revenue
    FROM ordered_months
    WHERE rn = 1

    UNION ALL

    SELECT
        next.rn,
        next.month,
        next.revenue,
        current.cumulative_revenue + next.revenue AS cumulative_revenue
    FROM cumulative_target AS current
    JOIN ordered_months AS next
        ON next.rn = current.rn + 1
    WHERE current.cumulative_revenue < 500000000
)
SELECT
    rn,
    month,
    revenue,
    cumulative_revenue
FROM cumulative_target
WHERE cumulative_revenue >= 500000000
ORDER BY rn
LIMIT 1;