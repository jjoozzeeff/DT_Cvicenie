SELECT o.order_id, c.customer_name, o.sales
FROM orders o
JOIN customer c ON o.customer_id = c.customer_id
WHERE o.sales > 500
ORDER BY o.sales DESC;

SELECT o.order_id, c.customer_name, p.category, o.sales
FROM orders o
JOIN customer c ON o.customer_id = c.customer_id
JOIN products p ON o.product_id = p.product_id;

SELECT c.region, SUM(o.sales) AS celkova_hodnota_predaja
FROM customer c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.region;

SELECT p.product_name, COALESCE(SUM(o.sales), 0) AS celkova_hodnota_predaja
FROM products p
LEFT JOIN orders o ON p.product_id = o.product_id
GROUP BY p.product_id, p.product_name;

SELECT c.customer_name, o.order_id, o.sales
FROM customer c
FULL OUTER JOIN orders o ON c.customer_id = o.customer_id;

SELECT c.region, SUM(o.sales) AS celkova_hodnota_predaja
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.region;

SELECT c.customer_name, COUNT(o.order_id) AS pocet_objednavok
FROM customer c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name;

SELECT p.category, AVG(o.discount) AS priemerna_zlava
FROM products p
JOIN orders o ON p.product_id = o.product_id
GROUP BY p.category;

SELECT c.customer_name, SUM(o.sales) AS celkova_hodnota_nakupov
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING SUM(o.sales) > 2000;

SELECT c.region, 
        SUM(o.sales) AS celkova_hodnota_predaja, 
        AVG(o.discount) AS priemerna_zlava, 
        COUNT(o.order_id) AS pocet_objednavok
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.region;

SELECT c.region,
       SUM(CASE WHEN o.sales > 1000 THEN 1 ELSE 0 END) AS high_value,
       SUM(CASE WHEN o.sales <= 1000 THEN 1 ELSE 0 END) AS low_value
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.region;

SELECT c.customer_name,
       SUM(o.sales) AS celkovy_predaj,
       AVG(o.discount) AS priemerna_zlava,
       COUNT(o.order_id) AS pocet_objednavok,
       CASE
           WHEN SUM(o.sales) > 2500 THEN 'VIP'
           ELSE 'REGULAR'
       END AS typ_zakaznika
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY celkovy_predaj DESC;
