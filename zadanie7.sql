-- Active: 1791738834113@@127.0.0.1@5432@superstore
WITH zoradene_objednavky AS (
    SELECT
        c.customer_name,
        o.order_id,
        o.order_date,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date DESC
        ) AS poradie
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
)
SELECT
    customer_name,
    order_id,
    order_date
FROM zoradene_objednavky
WHERE poradie <= 2
ORDER BY customer_name, poradie;

WITH zisky_zakaznikov AS (
    SELECT
        c.region,
        c.customer_name,
        SUM(o.profit) AS total_profit
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.region, c.customer_id, c.customer_name
)
SELECT
    region,
    customer_name,
    total_profit,
    RANK() OVER (
        PARTITION BY region
        ORDER BY total_profit DESC
    ) AS poradie_rank,
    DENSE_RANK() OVER (
        PARTITION BY region
        ORDER BY total_profit DESC
    ) AS poradie_dense_rank
FROM zisky_zakaznikov
ORDER BY region, total_profit DESC;

WITH predaj_zakaznikov AS (
    SELECT
        c.customer_name,
        c.customer_id,
        SUM(o.sales) AS total_sales
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_name,
    total_sales,
    NTILE(4) OVER (
        ORDER BY total_sales DESC
    ) AS quartile
FROM predaj_zakaznikov
ORDER BY total_sales DESC;

WITH mesacny_predaj AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        SUM(sales) AS monthly_sales
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT
    month,
    monthly_sales,
    LAG(monthly_sales, 1) OVER (
        ORDER BY month
    ) AS prev_month_sales,
    LEAD(monthly_sales, 1) OVER (
        ORDER BY month
    ) AS next_month_sales
FROM mesacny_predaj
ORDER BY month ASC;

WITH predaj_produktov AS (
    SELECT
        p.category,
        p.product_name,
        SUM(o.sales) AS product_sales
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    GROUP BY p.category, p.product_id, p.product_name
)
SELECT
    category,
    product_name,
    product_sales,
    SUM(product_sales) OVER (
        PARTITION BY category
    ) AS category_total,
    ROUND(
        product_sales * 100.0 /
        SUM(product_sales) OVER (
            PARTITION BY category
        ),
        2
    ) AS pct_of_category
FROM predaj_produktov
ORDER BY category, product_name;

WITH objednavky_zakaznikov AS (
    SELECT
        c.customer_id,
        c.customer_name,
        o.order_date,
        MAX(o.order_date) OVER (
            PARTITION BY o.customer_id
        ) AS last_order_date,
        MAX(o.order_date) OVER () AS latest_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
)
SELECT DISTINCT
    customer_id,
    customer_name,
    last_order_date
FROM objednavky_zakaznikov
WHERE last_order_date < latest_order_date - INTERVAL '90 days'
ORDER BY last_order_date ASC;

WITH mesacny_predaj AS (
    SELECT
        DATE_TRUNC('month', order_date)::DATE AS month,
        SUM(sales) AS monthly_sales
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)::DATE
),
predchadzajuci_mesiac AS (
    SELECT
        month,
        monthly_sales,
        LAG(monthly_sales) OVER (
            ORDER BY month
        ) AS prev_month_sales
    FROM mesacny_predaj
)
SELECT
    month,
    monthly_sales,
    prev_month_sales,
    monthly_sales - prev_month_sales AS sales_change,
    ROUND(
        (monthly_sales - prev_month_sales) * 100.0
        / NULLIF(prev_month_sales, 0),
        2
    ) AS growth_percentage
FROM predchadzajuci_mesiac
ORDER BY month ASC;

WITH prvi_nakup AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(order_date))::DATE AS prvy_mesiac
    FROM orders
    GROUP BY customer_id
)
SELECT COUNT(*) AS pocet_zakaznikov
FROM prvi_nakup p
WHERE p.prvy_mesiac = DATE '2024-06-01'
  AND EXISTS (
      SELECT 1
      FROM orders o
      WHERE o.customer_id = p.customer_id
        AND DATE_TRUNC('month', o.order_date) > p.prvy_mesiac
  );