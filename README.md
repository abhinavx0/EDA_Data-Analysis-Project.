# 📊 SQL Business Insights Project

This project explores and analyzes business data using SQL queries. Each query targets a specific real-world business question — from sales performance to customer behavior and logistics optimization.

---

##  Query List

<details>
<summary> Get all orders and customer info</summary>

```sql
SELECT 
    o.orderID,
    c.customerID,
    c.companyName,
    c.city
FROM orders o
JOIN customers c ON o.customerID = c.customerID;
````

</details>

---

<details>
<summary> Total quantity sold per product</summary>

```sql
SELECT 
    p.productID,
    p.productName,
    SUM(od.quantity) AS product_quantity
FROM products p
JOIN order_details od ON p.productID = od.productID
GROUP BY p.productID, p.productName
ORDER BY product_quantity DESC;
```

</details>

---

<details>
<summary> Revenue % contribution by product</summary>

```sql
SELECT 
    p.productID,
    p.productName,
    ROUND((
        SUM(od.quantity * od.unitPrice * (1 - od.discount)) /
        (SELECT SUM(od2.quantity * od2.unitPrice * (1 - od2.discount)) FROM order_details od2)
    ) * 100, 2) AS perc_revn
FROM products p
JOIN order_details od ON p.productID = od.productID
GROUP BY p.productID, p.productName
ORDER BY perc_revn DESC;
```

</details>

---

<details>
<summary> Top 5 customers by total spend</summary>

```sql
SELECT 
    o.customerID,
    SUM(od.quantity * od.unitPrice * (1 - od.discount)) AS customer_spend
FROM orders o
JOIN order_details od ON o.orderID = od.orderID
GROUP BY o.customerID
ORDER BY customer_spend DESC
LIMIT 5;
```

</details>

---

<details>
<summary>Remove discounts from discontinued products</summary>

```sql
UPDATE order_details
SET discount = 0
WHERE productID IN (
    SELECT productID
    FROM products
    WHERE discontinued = 1
);
```

</details>

---

<details>
<summary> Shippers with above-average freight cost</summary>

```sql
SELECT 
    o.shipperID,
    AVG(o.freight) AS avg_freight
FROM orders o
GROUP BY o.shipperID
HAVING avg_freight > (
    SELECT AVG(freight) FROM orders
);
```

</details>

---

<details>
<summary> Monthly sales revenue by employee</summary>

```sql
SELECT 
    YEAR(o.orderDate) AS year_,
    MONTH(o.orderDate) AS month_,
    o.employeeID,
    SUM(od.quantity * od.unitPrice * (1 - od.discount)) AS monthly_sales
FROM orders o
JOIN order_details od ON o.orderID = od.orderID
GROUP BY year_, month_, o.employeeID
ORDER BY year_, month_, o.employeeID;
```

</details>

---

<details>
<summary> Shipper with most high-value orders (>$500)</summary>

```sql
WITH above_500_orders AS (
    SELECT 
        od.orderID,
        SUM(od.quantity * od.unitPrice * (1 - od.discount)) AS total_order_value
    FROM order_details od
    GROUP BY od.orderID
    HAVING total_order_value > 500
)
SELECT 
    o.shipperID,
    COUNT(*) AS high_value_orders
FROM above_500_orders a5o
JOIN orders o ON a5o.orderID = o.orderID
GROUP BY o.shipperID
ORDER BY high_value_orders DESC;
```

</details>

---

<details>
<summary> Top-selling employee per product category</summary>

```sql
WITH cat_emp_sales AS (
    SELECT 
        cat.categoryID,
        e.employeeID,
        SUM(od.quantity * od.unitPrice * (1 - od.discount)) AS emp_cat_sales
    FROM categories cat
    JOIN products p ON cat.categoryID = p.categoryID
    JOIN order_details od ON od.productID = p.productID
    JOIN orders o ON o.orderID = od.orderID
    JOIN employees e ON e.employeeID = o.employeeID
    GROUP BY cat.categoryID, e.employeeID
),
cat_max_sales AS (
    SELECT 
        categoryID,
        MAX(emp_cat_sales) AS max_sales
    FROM cat_emp_sales
    GROUP BY categoryID
)
SELECT 
    ces.categoryID,
    ces.employeeID,
    e.employeeName
FROM cat_emp_sales ces
JOIN cat_max_sales cms 
    ON ces.categoryID = cms.categoryID AND ces.emp_cat_sales = cms.max_sales
JOIN employees e ON e.employeeID = ces.employeeID;
```

</details>
