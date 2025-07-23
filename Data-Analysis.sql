--  Get all orders and the customer details who placed them
SELECT 
    o.orderID,                  -- Order ID
    c.customerID,              -- Customer who placed the order
    c.companyName,             -- Name of the customer
    c.city                     -- Customer's city
FROM orders o
JOIN customers c ON o.customerID = c.customerID;



--  Find out how many units of each product have been sold in total
SELECT 
    p.productID,               
    p.productName,             
    SUM(od.quantity) AS product_quantity   -- Total units sold per product
FROM products p
JOIN order_details od ON p.productID = od.productID
GROUP BY p.productID, p.productName
ORDER BY product_quantity DESC;           -- Sort by quantity sold



--  Calculate how much each product contributes to total revenue (as a percentage)
SELECT 
    p.productID,
    p.productName,
    ROUND((
        SUM(od.quantity * od.unitPrice * (1 - od.discount)) /      -- Revenue per product
        (SELECT SUM(od2.quantity * od2.unitPrice * (1 - od2.discount)) FROM order_details od2) -- Total revenue
    ) * 100, 2) AS perc_revn     -- Final % value rounded to 2 decimals
FROM products p
JOIN order_details od ON p.productID = od.productID
GROUP BY p.productID, p.productName
ORDER BY perc_revn DESC;         -- Most profitable products first



--  Find the top 5 customers who have spent the most money
SELECT 
    o.customerID,
    SUM(od.quantity * od.unitPrice * (1 - od.discount)) AS customer_spend
FROM orders o
JOIN order_details od ON o.orderID = od.orderID
GROUP BY o.customerID
ORDER BY customer_spend DESC
LIMIT 5;                         -- Top 5 only



--  Remove discounts from any orders that include discontinued products
UPDATE order_details
SET discount = 0
WHERE productID IN (
    SELECT productID
    FROM products
    WHERE discontinued = 1       -- Discontinued = true
);



--  Find the average shipping (freight) cost for each shipper,
-- but only show those shippers who charge more than the global average
SELECT 
    o.shipperID,
    AVG(o.freight) AS avg_freight
FROM orders o
GROUP BY o.shipperID
HAVING avg_freight > (
    SELECT AVG(freight) FROM orders   -- Global average freight
);



-- Calculate how much revenue each employee generated every month
SELECT 
    YEAR(o.orderDate) AS year_,
    MONTH(o.orderDate) AS month_,
    o.employeeID,
    SUM(od.quantity * od.unitPrice * (1 - od.discount)) AS monthly_sales
FROM orders o
JOIN order_details od ON o.orderID = od.orderID
GROUP BY year_, month_, o.employeeID
ORDER BY year_, month_, o.employeeID;



--  Which shipping company handled the most high-value orders? (>$500)
WITH above_500_orders AS (
    SELECT 
        od.orderID,
        SUM(od.quantity * od.unitPrice * (1 - od.discount)) AS total_order_value
    FROM order_details od
    GROUP BY od.orderID
    HAVING total_order_value > 500   -- Only orders worth over $500
)
SELECT 
    o.shipperID,
    COUNT(*) AS high_value_orders    -- Number of expensive orders shipped
FROM above_500_orders a5o
JOIN orders o ON a5o.orderID = o.orderID
GROUP BY o.shipperID
ORDER BY high_value_orders DESC;     -- Most active shipper on top



--  For each product category, find the employee who made the highest sales
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
        MAX(emp_cat_sales) AS max_sales    -- Highest revenue in each category
    FROM cat_emp_sales
    GROUP BY categoryID
)
SELECT 
    ces.categoryID,
    ces.employeeID,
    e.employeeName                         -- Get the name of the top seller
FROM cat_emp_sales ces
JOIN cat_max_sales cms 
    ON ces.categoryID = cms.categoryID AND ces.emp_cat_sales = cms.max_sales
JOIN employees e ON e.employeeID = ces.employeeID;
