-- Active: 1790767540130@@127.0.0.1@5432@datacraftinglab_db
CREATE DATABASE datacraftinglab_db

CREATE TABLE flourmills_sales (
    sales_id INT PRIMARY KEY,
    sales_date DATE,
    region VARCHAR(100),
    state VARCHAR(100),
    product_category VARCHAR(100),
    product_name VARCHAR(150),
    customer_type VARCHAR(100),
    customer_id INT,
    quantity_sold INT,
    unit_price NUMERIC(16,2),
    discount_rate INT,
    payment_method VARCHAR(100),
    sales_rep VARCHAR(150),
    warehouse VARCHAR(100),
    delivery_status VARCHAR(100),
    order_channel VARCHAR(100),
    batch_number INT,
    production_date DATE,
    total_amount NUMERIC(16,2)
);

SELECT * FROM flourmills_sales;

SELECT product_name, total_amount
FROM flourmills_sales
WHERE total_amount > (
    SELECT AVG(total_amount)
    FROM flourmills_sales);

SELECT sales_id, sale_date, region, product_category
FROM flourmills_sales
WHERE product_category = (
    SELECT product_category
    FROM flourmills_sales
    GROUP BY product_category
    ORDER BY SUM(total_amount) DESC
    LIMIT 1);

SELECT product_name, total_amount, (
    SELECT AVG(total_amount)
    FROM flourmills_sales
) AS avg_amount
FROM flourmills_sales;

SELECT product_name, total_amount, total_amount / (
    SELECT SUM(total_amount)
    FROM flourmills_sales
) AS amount_share
FROM flourmills_sales;

SELECT month, monthly_sales
FROM (
    SELECT EXTRACT(MONTH FROM sale_date) AS month, SUM(total_amount) AS monthly_sales
    FROM flourmills_sales
    GROUP BY EXTRACT(MONTH FROM sale_date)
)
ORDER BY monthly_sales DESC;

SELECT product_category, total_sales
FROM (
    SELECT product_category, SUM(total_amount) AS total_sales
    FROM flourmills_sales
    GROUP BY product_category
)
WHERE total_sales > 50000000
ORDER BY total_sales DESC;

SELECT product_name, product_category, total_amount
FROM flourmills_sales AS t1
WHERE total_amount > (
    SELECT AVG(t2.total_amount)
    FROM flourmills_sales AS t2
    WHERE t2.product_category = t1.product_category
);

SELECT
    product_name,
    region,
    total_amount,
    (
        SELECT MIN(t2.total_amount)
        FROM flourmills_sales AS t2
        WHERE t2.region = t.region
    ) AS region_min_amount
FROM flourmills_sales AS t;

SELECT
    t.product_name,
    t.product_category,
    t.sale_date,
    t.total_amount
FROM flourmills_sales AS t
WHERE EXISTS (
    SELECT 1
    FROM flourmills_sales AS t2
    WHERE t2.product_name = t.product_name
    GROUP BY t2.product_name
    HAVING COUNT(DISTINCT (
        EXTRACT(YEAR FROM t2.sale_date),
        EXTRACT(MONTH FROM t2.sale_date)
    )) >= 2
);

SELECT
    product_category,
    product_name,
    total_amount
FROM flourmills_sales AS t
WHERE EXISTS (
    SELECT 1
    FROM flourmills_sales AS t2
    WHERE t2.product_category = t.product_category
      AND t2.total_amount > 200000
);

SELECT DISTINCT
    t.product_category
FROM flourmills_sales AS t
WHERE EXISTS (
    SELECT 1
    FROM flourmills_sales AS t2
    WHERE t2.product_category = t.product_category
    GROUP BY t2.product_category
    HAVING COUNT(DISTINCT t2.region) > 3
);

SELECT
    product_name,
    product_category,
    region,
    sale_date,
    total_amount
FROM flourmills_sales AS t
WHERE EXISTS (
    SELECT 1
    FROM flourmills_sales AS t2
    WHERE t2.region = t.region
      AND EXTRACT(YEAR FROM t2.sale_date) = 2024
);

SELECT DISTINCT
    t.product_category
FROM flourmills_sales AS t
WHERE NOT EXISTS (
    SELECT 1
    FROM flourmills_sales AS t2
    WHERE t2.product_category = t.product_category
      AND t2.total_amount > 500000
);

SELECT DISTINCT
    t.region
FROM flourmills_sales AS t
WHERE NOT EXISTS (
    SELECT 1
    FROM flourmills_sales AS t2
    WHERE t2.region = t.region
      AND t2.product_category = 'Flour'
);
