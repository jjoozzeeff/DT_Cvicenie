-- Active: 1791372306937@@127.0.0.1@5432@postgres
CREATE VIEW high_value_customers AS
SELECT c.customer_id,
       c.customer_name,
       SUM(o.sales) AS total_sales
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id
HAVING SUM(o.sales) > 2000;

SELECT *
FROM high_value_customers;

CREATE VIEW regional_monthly_sales AS
SELECT