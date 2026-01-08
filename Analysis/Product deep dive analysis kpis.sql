###############  Product Deep Dive — [Cte de Blaye]   ######################
######## Total + counts:
SELECT
  p.ProductID,
  p.ProductName,
  SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS total_revenue,
  SUM(od.Quantity) AS total_units,
  COUNT(DISTINCT od.OrderID) AS orders_with_product,
  COUNT(DISTINCT o.CustomerID) AS customers_bought
FROM `Order Details` od
JOIN Orders o ON od.OrderID = o.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE p.productname = 'Cte de Blaye'
GROUP BY p.ProductID, p.ProductName;
########### AOV, rev/customer, qty/customer:  ###################
SELECT
  SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) * 1.0 / NULLIF(COUNT(DISTINCT od.OrderID),0) AS product_aov,   ## avg product revenue per order (product aov)
  SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) * 1.0 / NULLIF(COUNT(DISTINCT o.CustomerID),0) AS revenue_per_customer,       #product revenue per customer
  SUM(od.Quantity) * 1.0 / NULLIF(COUNT(DISTINCT o.CustomerID),0) AS qty_per_customer                                           # units per customer (consumption intensity)
FROM `Order Details` od 
JOIN Orders o ON od.OrderID = o.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE p.ProductName = 'Cte de Blaye';
############ Revenue by country: ###################
SELECT
  COALESCE(o.ShipCountry, 'Unknown') AS country,
  SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS revenue,
  SUM(od.Quantity) AS units_sold,
  COUNT(DISTINCT o.CustomerID) AS customers,
  SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) * 1.0 / NULLIF(COUNT(DISTINCT o.CustomerID),0) AS revenue_per_customer
FROM `Order Details` od
JOIN Orders o ON od.OrderID = o.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE p.ProductName = 'Cte de Blaye'
GROUP BY COALESCE(o.ShipCountry,'Unknown')
ORDER BY revenue DESC;
_______________
STARTING AGAIN
###########      Côte de Blaye sales with revenue:  ###################
WITH cte_de_blaye_sales AS (
    SELECT 
        o.OrderID,
        o.CustomerID,
        c.Country,
        od.Quantity,
        od.UnitPrice,
        od.Discount,
        (od.Quantity * od.UnitPrice * (1 - od.Discount)) AS Revenue
    FROM `Order Details` od
    JOIN Orders o ON od.OrderID = o.OrderID
    JOIN Customers c ON o.CustomerID = c.CustomerID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE p.ProductName = 'Cte de Blaye'
)
#### Revenue Per Customer
#SELECT 
 #   AVG(TotalRevenue) AS RevenuePerCustomer
#FROM (
 #   SELECT CustomerID, SUM(Revenue) AS TotalRevenue
  #  FROM cte_de_blaye_sales
   # GROUP BY CustomerID
#) t;
#Revenue Per Order (AOV)
#SELECT 
 #   AVG(RevenuePerOrder) AS AvgOrderValue
#FROM (
 #   SELECT OrderID, SUM(Revenue) AS RevenuePerOrder
 #   FROM cte_de_blaye_sales
  #  GROUP BY OrderID
#) t;
#Quantity per customer
#SELECT 
 #   AVG(TotalQuantity) AS QuantityPerCustomer
#FROM (
 #   SELECT CustomerID, SUM(Quantity) AS TotalQuantity
  #  FROM cte_de_blaye_sales
   # GROUP BY CustomerID
#) t;
###### COUNTRY LRVRL COMPARISON ##########
SELECT 
    Country,
    AVG(CustomerRevenue) AS RevenuePerCustomer
FROM (
    SELECT CustomerID, Country, SUM(Revenue) AS CustomerRevenue
    FROM cte_de_blaye_sales
    GROUP BY CustomerID, Country
) t
GROUP BY Country
ORDER BY RevenuePerCustomer DESC;

-----------------------------------
WITH cte_de_blaye_sales AS (
    SELECT 
        o.CustomerID,
        c.Country,
        SUM(od.Quantity * od.UnitPrice * (1 - od.Discount)) AS Revenue
    FROM `Order Details` od
    JOIN Orders o ON od.OrderID = o.OrderID
    JOIN Customers c ON o.CustomerID = c.CustomerID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE p.ProductName = 'Cte de Blaye'
    GROUP BY o.CustomerID, c.Country
),
country_avg AS (
    SELECT 
        Country,
        AVG(Revenue) AS AvgRevenuePerCustomerInCountry
    FROM cte_de_blaye_sales
    GROUP BY Country
),
global_avg AS (
    SELECT AVG(Revenue) AS GlobalAvgRevenuePerCustomer
    FROM cte_de_blaye_sales
)
SELECT 
    ca.Country,
    ca.AvgRevenuePerCustomerInCountry,
    ga.GlobalAvgRevenuePerCustomer,
    CASE 
        WHEN ca.AvgRevenuePerCustomerInCountry >= ga.GlobalAvgRevenuePerCustomer 
        THEN 'Above Average'
        ELSE 'Below Average'
    END AS Comparison
FROM country_avg ca
CROSS JOIN global_avg ga
ORDER BY ca.AvgRevenuePerCustomerInCountry DESC;

########## Revenue per order
WITH cte_de_blaye_orders AS (
    SELECT 
        o.OrderID,
        c.Country,
        SUM(od.Quantity * od.UnitPrice * (1 - od.Discount)) AS OrderRevenue
    FROM `Order Details` od
    JOIN Orders o ON od.OrderID = o.OrderID
    JOIN Customers c ON o.CustomerID = c.CustomerID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE p.ProductName = 'Cte de Blaye'
    GROUP BY o.OrderID, c.Country
),
country_avg AS (
    SELECT 
        Country,
        AVG(OrderRevenue) AS AvgRevenuePerOrderInCountry
    FROM cte_de_blaye_orders
    GROUP BY Country
),
global_avg AS (
    SELECT AVG(OrderRevenue) AS GlobalAvgRevenuePerOrder
    FROM cte_de_blaye_orders
)
SELECT 
    ca.Country,
    ca.AvgRevenuePerOrderInCountry,
    ga.GlobalAvgRevenuePerOrder,
    CASE 
        WHEN ca.AvgRevenuePerOrderInCountry >= ga.GlobalAvgRevenuePerOrder 
        THEN 'Above Average'
        ELSE 'Below Average'
    END AS Comparison
FROM country_avg ca
CROSS JOIN global_avg ga
ORDER BY ca.AvgRevenuePerOrderInCountry DESC;

############# quantity per customer
WITH cte_de_blaye_customers AS (
    SELECT 
        o.CustomerID,
        c.Country,
        SUM(od.Quantity) AS TotalQuantity
    FROM `Order Details` od
    JOIN Orders o ON od.OrderID = o.OrderID
    JOIN Customers c ON o.CustomerID = c.CustomerID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE p.ProductName = 'Cte de Blaye'
    GROUP BY o.CustomerID, c.Country
),
country_avg AS (
    SELECT 
        Country,
        AVG(TotalQuantity) AS AvgQuantityPerCustomerInCountry
    FROM cte_de_blaye_customers
    GROUP BY Country
),
global_avg AS (
    SELECT AVG(TotalQuantity) AS GlobalAvgQuantityPerCustomer
    FROM cte_de_blaye_customers
)
SELECT 
    ca.Country,
    ca.AvgQuantityPerCustomerInCountry,
    ga.GlobalAvgQuantityPerCustomer,
    CASE 
        WHEN ca.AvgQuantityPerCustomerInCountry >= ga.GlobalAvgQuantityPerCustomer 
        THEN 'Above Average'
        ELSE 'Below Average'
    END AS Comparison
FROM country_avg ca
CROSS JOIN global_avg ga
ORDER BY ca.AvgQuantityPerCustomerInCountry DESC;
############# Quantity per Order 
WITH cte_de_blaye_orders AS (
    SELECT 
        o.OrderID,
        c.Country,
        SUM(od.Quantity) AS OrderQuantity
    FROM `Order Details` od
    JOIN Orders o ON od.OrderID = o.OrderID
    JOIN Customers c ON o.CustomerID = c.CustomerID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE p.ProductName = 'Cte de Blaye'
    GROUP BY o.OrderID, c.Country
),
country_avg AS (
    SELECT 
        Country,
        AVG(OrderQuantity) AS AvgQuantityPerOrderInCountry
    FROM cte_de_blaye_orders
    GROUP BY Country
),
global_avg AS (
    SELECT AVG(OrderQuantity) AS GlobalAvgQuantityPerOrder
    FROM cte_de_blaye_orders
)
SELECT 
    ca.Country,
    ca.AvgQuantityPerOrderInCountry,
    ga.GlobalAvgQuantityPerOrder,
    CASE 
        WHEN ca.AvgQuantityPerOrderInCountry >= ga.GlobalAvgQuantityPerOrder 
        THEN 'Above Average'
        ELSE 'Below Average'
    END AS Comparison
FROM country_avg ca
CROSS JOIN global_avg ga
ORDER BY ca.AvgQuantityPerOrderInCountry DESC;



