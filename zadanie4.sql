-- Active: 1791738834113@@127.0.0.1@5432@retail_sales
CREATE VIEW high_value_customers AS
SELECT
    c.customer_id,
    c.customer_name,
    SUM(o.sales) AS total_sales
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING SUM(o.sales) > 2000;

SELECT * FROM high_value_customers;

CREATE VIEW regional_monthly_sales AS
SELECT
    c.region,
    DATE_TRUNC('month', o.order_date) AS month,
    SUM(o.sales) AS monthly_sales
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.region, DATE_TRUNC('month', o.order_date);

SELECT *
FROM regional_monthly_sales
WHERE region = 'West';

CREATE VIEW analyst_orders AS
SELECT
    order_id,
    customer_id,
    product_id,
    sales,
    quantity,
    discount
FROM orders;

SELECT * FROM analyst_orders;

CREATE INDEX idx_orders_customer_id
ON orders(customer_id);

SELECT *
FROM orders
WHERE customer_id = 'C001';

CREATE INDEX idx_orders_order_date
ON orders(order_date);

SELECT
    DATE_TRUNC('month', order_date) AS month,
    SUM(sales) AS monthly_sales
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month ASC;

CREATE INDEX idx_orders_region_category
ON orders(customer_id, order_date);

SELECT
    c.customer_name,
    c.region,
    o.order_date,
    o.profit
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE c.region = 'West'
  AND o.order_date >= '2024-01-01';

EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE customer_id = 'C001';

CREATE DATABASE retail_sales;


CREATE TABLE orders (
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20),
    product_id VARCHAR(20),
    order_date DATE,
    region VARCHAR(20),
    category VARCHAR(50),
    ship_mode VARCHAR(30),
    sales NUMERIC(10,2),
    profit NUMERIC(10,2)
);

ALTER DATABASE retail_sales
SET datestyle TO 'ISO, MDY';

SELECT *
FROM orders;

CREATE OR REPLACE PROCEDURE get_customer_sales(
    p_customer_id VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_sales NUMERIC(18,2);
BEGIN
    SELECT COALESCE(SUM(sales), 0)
    INTO v_total_sales
    FROM orders
    WHERE customer_id = p_customer_id;

    RAISE NOTICE 'Customer ID: %, Total Sales: %',
        p_customer_id, v_total_sales;
END;
$$;


CALL get_customer_sales('C001');


CREATE OR REPLACE PROCEDURE apply_regional_discount(
    region_name VARCHAR(20),
    discount_rate NUMERIC(5,2)
)
LANGUAGE plpgsql
AS $procedure$
BEGIN
    UPDATE orders
    SET sales = sales * (1 - discount_rate)
    WHERE region = region_name;

    RAISE NOTICE 'Discount % applied to region %',
        discount_rate, region_name;
END;
$procedure$;

CALL apply_regional_discount('West', 0.10);

CREATE PROCEDURE get_sales_between(
    start_date DATE,
    end_date DATE
)
LANGUAGE plpgsql
AS $procedure$
DECLARE
    v_total_sales NUMERIC(12,2);
BEGIN
    SELECT SUM(sales)
    INTO v_total_sales
    FROM orders
    WHERE order_date BETWEEN start_date AND end_date;

    RAISE NOTICE 'Start date: %, End date: %, Total sales: %',
        start_date, end_date, v_total_sales;
END;
$procedure$;

CALL get_sales_between('2024-01-01', '2024-03-31');