-- Active: 1791738834113@@127.0.0.1@5432@retail
CREATE DATABASE retail;

CREATE TABLE retail_sales (
    invoice_no VARCHAR(20),
    stock_code VARCHAR(50),
    description TEXT,
    quantity INTEGER,
    invoice_date TIMESTAMP,
    unit_price NUMERIC(10, 2),
    customer_id INTEGER,
    country VARCHAR(100)
);

SELECT *
FROM retail_sales;


WITH predaj AS (
    SELECT
        customer_id,
        invoice_no,
        invoice_date,
        quantity,
        unit_price,
        quantity * unit_price AS revenue
    FROM retail_sales
    WHERE customer_id IS NOT NULL
)
SELECT
    customer_id,
    invoice_no,
    invoice_date,
    quantity,
    unit_price,
    revenue,
    SUM(revenue) OVER (
        PARTITION BY customer_id
        ORDER BY invoice_date
        RANGE BETWEEN INTERVAL '14 days' PRECEDING
        AND CURRENT ROW
    ) AS revenue_last_14_days
FROM predaj
ORDER BY customer_id, invoice_date;

SELECT
    stock_code,
    country,
    invoice_date,
    quantity,
    ROUND(
        AVG(quantity) OVER (
            PARTITION BY stock_code, country
            ORDER BY invoice_date
            RANGE BETWEEN INTERVAL '7 days' PRECEDING AND CURRENT ROW
        ),
        2
    ) AS avg_quantity_7_days
FROM retail_sales
WHERE quantity > 1
ORDER BY stock_code, country, invoice_date;

WITH objednavky AS (
    SELECT DISTINCT
        customer_id,
        invoice_no,
        invoice_date::DATE AS invoice_date
    FROM retail_sales
    WHERE customer_id IS NOT NULL
),
nasledujuce_objednavky AS (
    SELECT
        customer_id,
        invoice_no,
        invoice_date,
        LEAD(invoice_date) OVER (
            PARTITION BY customer_id
            ORDER BY invoice_date, invoice_no
        ) AS next_invoice_date
    FROM objednavky
)
SELECT
    customer_id,
    invoice_no,
    invoice_date,
    next_invoice_date,
    next_invoice_date - invoice_date AS days_to_next_invoice
FROM nasledujuce_objednavky
WHERE next_invoice_date IS NOT NULL
ORDER BY days_to_next_invoice DESC;

WITH ceny AS (
    SELECT
        stock_code,
        invoice_no,
        invoice_date,
        LAG(unit_price) OVER (
            PARTITION BY stock_code
            ORDER BY invoice_date
        ) AS previous_price,
        unit_price AS current_price
    FROM retail_sales
)
SELECT
    stock_code,
    invoice_no,
    invoice_date,
    previous_price,
    current_price,
    current_price - previous_price AS price_difference
FROM ceny
WHERE previous_price IS NOT NULL
  AND current_price <> previous_price
ORDER BY invoice_date ASC;

WITH predaj_zakaznikov AS (
    SELECT
        customer_id,
        SUM(quantity * unit_price) AS total_amount
    FROM retail_sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),
kvartily AS (
    SELECT
        customer_id,
        total_amount,
        NTILE(4) OVER (
            ORDER BY total_amount DESC
        ) AS sales_quartile
    FROM predaj_zakaznikov
)
SELECT
    customer_id,
    total_amount,
    sales_quartile
FROM kvartily
ORDER BY total_amount DESC;

WITH mesacny_predaj AS (
    SELECT
        country,
        DATE_TRUNC('month', invoice_date)::DATE AS month,
        SUM(quantity * unit_price) AS total_amount
    FROM retail_sales
    GROUP BY country, DATE_TRUNC('month', invoice_date)
),
kvartily AS (
    SELECT
        country,
        month,
        total_amount,
        NTILE(4) OVER (
            PARTITION BY country
            ORDER BY total_amount DESC
        ) AS sales_quartile
    FROM mesacny_predaj
)
SELECT
    country,
    month,
    total_amount,
    sales_quartile
FROM kvartily
ORDER BY country ASC, month ASC;

WITH prve_nakupy AS (
    SELECT
        customer_id,
        invoice_no,
        invoice_date,
        stock_code,
        description,
        quantity,
        unit_price,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY invoice_date ASC, invoice_no, stock_code
        ) AS poradie
    FROM retail_sales
    WHERE customer_id IS NOT NULL
)
SELECT
    customer_id,
    invoice_no,
    invoice_date,
    stock_code,
    description,
    quantity,
    unit_price
FROM prve_nakupy
WHERE poradie = 1
ORDER BY customer_id ASC;

WITH polozky AS (
    SELECT
        invoice_no,
        stock_code,
        description,
        quantity,
        unit_price,
        quantity * unit_price AS amount,
        ROW_NUMBER() OVER (
            PARTITION BY invoice_no
            ORDER BY quantity * unit_price DESC
        ) AS row_num
    FROM retail_sales
)
SELECT
    invoice_no,
    stock_code,
    description,
    quantity,
    unit_price,
    amount,
    row_num
FROM polozky
WHERE row_num <= 3
ORDER BY invoice_no, row_num;

WITH mesacny_predaj AS (
    SELECT
        country,
        DATE_TRUNC('month', invoice_date)::DATE AS month,
        customer_id,
        SUM(quantity * unit_price) AS total_amount
    FROM retail_sales
    WHERE customer_id IS NOT NULL
    GROUP BY
        country,
        DATE_TRUNC('month', invoice_date)::DATE,
        customer_id
),
poradie_zakaznikov AS (
    SELECT
        country,
        month,
        customer_id,
        total_amount,
        DENSE_RANK() OVER (
            PARTITION BY country, month
            ORDER BY total_amount DESC
        ) AS sales_rank
    FROM mesacny_predaj
)
SELECT
    country,
    month,
    customer_id,
    total_amount,
    sales_rank
FROM poradie_zakaznikov
WHERE sales_rank <= 5
ORDER BY country, month, sales_rank, customer_id;

WITH ceny AS (
    SELECT
        invoice_no,
        stock_code,
        description,
        quantity,
        unit_price,
        DENSE_RANK() OVER (
            PARTITION BY invoice_no
            ORDER BY unit_price DESC
        ) AS price_rank
    FROM retail_sales
)
SELECT
    invoice_no,
    stock_code,
    description,
    quantity,
    unit_price,
    price_rank
FROM ceny
WHERE price_rank <= 5
ORDER BY invoice_no, price_rank, stock_code;