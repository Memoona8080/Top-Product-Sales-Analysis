
###Employee sales performance
SELECT employeeid, sum(quantity*unitprice) AS TotalSales
FROM orders o
LEFT JOIN `order details` od
USING (orderid)
LEFT JOIN Employees e
USING (employeeid)
GROUP BY employeeid
----------------
##using ORDER TABLE for order volume over time
SELECT YEAR(orderdate) AS OrderYear, MONTH(orderdate) AS OrderMonth, count(orderID) AS ordercount
FROM orders o
GROUP by YEAR(orderdate), MONTH(orderdate)
ORDER BY OrderYear, OrderMonth;

SELECT YEAR(orderdate) AS OrderYear, count(orderID) AS ordercount
FROM orders o
GROUP by YEAR(orderdate);
_______________________________
#merging  all column in one table
Select 
 o.OrderID,
  o.OrderDate,
  o.CustomerID,
  c.CompanyName AS CustomerName,
  c.Country AS CustomerCountry,
  o.EmployeeID,
  concat(e.FirstName,' ', e.LastName) AS EmployeeName,
  od.ProductID,
  p.ProductName,
  p.CategoryID,
  od.UnitPrice,
  od.Quantity,
  od.Discount,
	od.Unitprice*od.Quantity*(1-od.Discount) As Revenue,
  o.ShipCountry
FROM `order details` od                         #joining all the order details with orders that are placed
JOIN orders o on od.OrderID = o.OrderID
	JOIN products p on od.productID = p.productID        #joining all the product details with orderdetails table
		LEFT JOIN Customers c ON o.CustomerID = c.CustomerID         #joining all the customers with orders table
			LEFT JOIN Employees e ON o.EmployeeID = e.EmployeeID    #joining all the employee info with order table
limit 4000;


________________
Select *
FROM `order details` od                        
JOIN orders o on od.OrderID = o.OrderID
	JOIN products p on od.productID = p.productID 
Where productname = 'Cte de Blaye';

-----------------------------
###################         merging territories with employees with orders     ########################
SELECT *  
FROM `order details` od                                
JOIN orders o ON o.OrderID = od.OrderID                  #link each order with the product it has 
JOIN Products p ON od.ProductID = p.ProductID            #adds product info
LEFT JOIN employeeterritories et ON o.employeeid = et.employeeid    #Which areas the employee is responsible for when taking orders
LEft JOIN territories t ON et.TerritoryID = t.TerritoryID             #Adds territory descriptions for the assigned employee.
LEFT JOIN region r ON r.RegionID = t.RegionID                          #Adds region descriptions for the assigned employee.
#WHERE p.productname = 'Cte de Blaye'
Limit 4000;
---------------

##           Check which territory and region CTE DE Balye is selling or where it's not        ##################
WITH SalesByTerritory AS (
    SELECT
        t.TerritoryID,
        SUM(od.Quantity * od.UnitPrice * (1 - od.Discount)) AS TotalSales
    FROM `Order Details` od
    JOIN Orders o ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    LEFT JOIN EmployeeTerritories et ON o.EmployeeID = et.EmployeeID
    LEFT JOIN Territories t ON et.TerritoryID = t.TerritoryID
    WHERE p.ProductName = 'Cte de Blaye'
    GROUP BY t.TerritoryID
)
SELECT 
    t.TerritoryDescription,
    r.RegionDescription,
    COALESCE(s.TotalSales, 0) AS TotalSales
FROM Territories t
LEFT JOIN Region r ON r.RegionID = t.RegionID
LEFT JOIN SalesByTerritory s ON t.TerritoryID = s.TerritoryID
ORDER BY TotalSales;
------------------------
####       which employees are actually handling its orders and how many? #######################

SELECT 
    e.EmployeeID,
    CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
    COUNT(DISTINCT o.OrderID) AS OrdersHandled,
    SUM(od.Quantity * od.UnitPrice * (1 - od.Discount)) AS TotalSales
FROM `Order Details` od
JOIN Orders o ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
JOIN Employees e ON o.EmployeeID = e.EmployeeID
WHERE p.ProductName = 'Cte de Blaye'
GROUP BY e.EmployeeID, e.FirstName, e.LastName
ORDER BY TotalSales DESC;
----------------------------
############# which region these employee are assigned to for the top product?      ######################
SELECT 
    Distinct base.EmployeeID,
    base.EmployeeName,
    base.OrdersHandled,
    base.TotalSales,
    r.RegionDescription
FROM (
    SELECT 
        e.EmployeeID,
        CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
        COUNT(DISTINCT o.OrderID) AS OrdersHandled,
        SUM(od.Quantity * od.UnitPrice * (1 - od.Discount)) AS TotalSales
    FROM `Order Details` od
    JOIN Orders o ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    JOIN Employees e ON o.EmployeeID = e.EmployeeID
    WHERE p.ProductName = 'Cte de Blaye'
    GROUP BY e.EmployeeID, e.FirstName, e.LastName
) AS base
LEFT JOIN EmployeeTerritories et ON base.EmployeeID = et.EmployeeID
LEFT JOIN Territories t ON et.TerritoryID = t.TerritoryID
LEFT JOIN Region r ON t.RegionID = r.RegionID
ORDER BY base.TotalSales DESC;

#______________________________________
################# How many employees are assigned to eaach region for the top product? #########################
SELECT
    r.RegionDescription,
    COUNT(DISTINCT e.EmployeeID) AS EmployeesHandling
FROM `Order Details` od
JOIN Orders o           ON o.OrderID = od.OrderID
JOIN Products p         ON od.ProductID = p.ProductID
JOIN Employees e        ON o.EmployeeID = e.EmployeeID
LEFT JOIN EmployeeTerritories et ON e.EmployeeID = et.EmployeeID
LEFT JOIN Territories t          ON et.TerritoryID = t.TerritoryID
LEFT JOIN Region r               ON t.RegionID = r.RegionID
WHERE p.ProductName = 'Cte de Blaye'
GROUP BY r.RegionDescription
ORDER BY EmployeesHandling DESC;

-------------

SELECT
    COALESCE(CONCAT(e.FirstName, ' ', e.LastName), 'Unassigned') AS EmployeeName,
    r.RegionDescription,
    COUNT(DISTINCT t.TerritoryID) AS TerritoriesForProduct
FROM `Order Details` od
JOIN Orders o            ON o.OrderID = od.OrderID
JOIN Products p          ON od.ProductID = p.ProductID
LEFT JOIN Employees e    ON o.EmployeeID = e.EmployeeID
LEFT JOIN EmployeeTerritories et ON e.EmployeeID = et.EmployeeID
LEFT JOIN Territories t  ON et.TerritoryID = t.TerritoryID
LEFT JOIN Region r       ON t.RegionID = r.RegionID
WHERE p.ProductName = 'Cte de Blaye'
GROUP BY e.EmployeeID, e.FirstName, e.LastName, r.RegionDescription
ORDER BY r.RegionDescription, TerritoriesForProduct DESC;



.................-------------------------------------
####### ROUGH WORK territories info  #######################
SELECT *  
FROM orders o
LEFT JOIN employeeterritories et ON o.employeeid = et.employeeid
LEft JOIN territories t ON et.TerritoryID = t.TerritoryID
LEFT JOIN region r ON r.RegionID = t.RegionID
----------------------------
SELECT *  
FROM  employeeterritories et ON o.employeeid = et.employeeid
LEft JOIN territories t ON et.TerritoryID = t.TerritoryID
LEFT JOIN region r ON r.RegionID = t.RegionID
------------------------
SELECT * FROM territories LEFT JOIN region USING (regionid)
				left join employeeterritories using (TerritoryID)
_________________________________________
#################  FIND CTE DE BALYE supplier ###############
SELECT 
    p.ProductName,
    s.SupplierID,
    s.CompanyName AS SupplierName,
    s.ContactName,
    s.City,
    s.Country
    SELECT *
FROM Products p
JOIN Suppliers s 
    ON p.SupplierID = s.SupplierID
WHERE p.ProductName = 'Cte de Blaye';

---------------
###SHIPPER how many orders and the value of this product were shipped by each shipper
SELECT 
    sh.ShipperID,
    sh.CompanyName AS ShipperName,
    COUNT(DISTINCT o.OrderID) AS OrdersShipped,
    SUM(od.Quantity * od.UnitPrice * (1 - od.Discount)) AS TotalValue
FROM `Order Details` od
JOIN Orders o 
    ON od.OrderID = o.OrderID
JOIN Shippers sh 
    ON o.ShipVia = sh.ShipperID
JOIN Products p 
    ON od.ProductID = p.ProductID
WHERE p.ProductName = 'Cte de Blaye'
GROUP BY sh.ShipperID, sh.CompanyName
ORDER BY TotalValue DESC;

---------------------
###########               which customers purchase Côte de Blaye most and how many orders.     ##########
SELECT
    c.CompanyName,
    c.Country,
    SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Revenue
FROM `Order Details` od
JOIN Orders o   ON od.OrderID = o.OrderID
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN Products p ON od.ProductID = p.ProductID
WHERE p.ProductName = 'cte de Blaye'
GROUP BY c.CompanyName, c.Country
ORDER BY Revenue DESC;

### quantity sold per country
SELECT
    c.Country,
    SUM(od.Quantity) AS TotalQuantitySold,
    SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotalRevenue
FROM `Order Details` od
JOIN Orders o ON od.OrderID = o.OrderID
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN Products p ON od.ProductID = p.ProductID
WHERE p.ProductName = 'CTE De Blaye'
GROUP BY c.Country
ORDER BY TotalRevenue DESC;
________________________________________________________
#### Population #####
SELECT
    c.Country,
    SUM(od.Quantity) AS TotalQuantitySold,
    SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotalRevenue,
    -- population in thousands
    CASE c.Country
        WHEN 'USA' THEN 340100
        WHEN 'Germany' THEN 84550
        WHEN 'Brazil' THEN 212900
        WHEN 'Austria' THEN 9110
        WHEN 'Denmark' THEN 5940
        WHEN 'Canada' THEN 39740
        WHEN 'Mexico' THEN 130860
        WHEN 'Sweden' THEN 10500
        WHEN 'France' THEN 65800
        WHEN 'Norway' THEN 5600
        WHEN 'Argentina' THEN 46200
        ELSE NULL
    END AS PopulationIn000s,
    -- Sales per capita
    SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) /
    CASE c.Country
        WHEN 'USA' THEN 340100
        WHEN 'Germany' THEN 84550
        WHEN 'Brazil' THEN 212900
        WHEN 'Austria' THEN 9110
        WHEN 'Denmark' THEN 5940
        WHEN 'Canada' THEN 39740
        WHEN 'Mexico' THEN 130860
        WHEN 'Sweden' THEN 10500
        WHEN 'France' THEN 65800
        WHEN 'Norway' THEN 5600
        WHEN 'Argentina' THEN 46200
        ELSE NULL
    END AS RevenuePerCapita
FROM `Order Details` od
JOIN Orders o ON od.OrderID = o.OrderID
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN Products p ON od.ProductID = p.ProductID
WHERE p.ProductName = 'CTE De Blaye'
GROUP BY c.Country
ORDER BY RevenuePerCapita DESC;


##################################  EACH YEAR   ##################################
SELECT
    c.CustomerID,
    c.CompanyName,
    YEAR(o.OrderDate) AS OrderYear,
    SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Revenue,
    COUNT(DISTINCT o.OrderID) AS OrdersCount
FROM `Order Details` od
JOIN Orders o    ON od.OrderID = o.OrderID
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN Products p  ON od.ProductID = p.ProductID
WHERE p.ProductName = 'Cte de Blaye'
GROUP BY c.CustomerID, c.CompanyName, YEAR(o.OrderDate)
ORDER BY c.CompanyName, OrderYear;

#######################     RFM  ##################################
WITH product_sales AS (
    SELECT
        c.CustomerID,
        c.CompanyName,
        MAX(o.OrderDate) AS LastPurchase,
        COUNT(DISTINCT o.OrderID) AS Frequency,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Monetary
    FROM `Order Details` od
    JOIN Orders o    ON od.OrderID = o.OrderID
    JOIN Customers c ON o.CustomerID = c.CustomerID
    JOIN Products p  ON od.ProductID = p.ProductID
    WHERE p.ProductName = 'Cte de Blaye'   
    GROUP BY c.CustomerID, c.CompanyName
),
base AS (
    SELECT
        CustomerID,
        CompanyName,
        DATEDIFF(CURDATE(), LastPurchase) AS RecencyDays,
        Frequency,
        Monetary
    FROM product_sales
),
scored AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY RecencyDays ASC)  AS R_score,  -- recent = high = 1
        NTILE(5) OVER (ORDER BY Frequency DESC)   AS F_score, -- Highest frequency =1 
        NTILE(5) OVER (ORDER BY Monetary DESC)    AS M_score -- highest spend = 1
    FROM base
)
SELECT
    CustomerID,
    CompanyName,
    RecencyDays,
    Frequency,
    Monetary,
    R_score,
    F_score,
    M_score,
    #CONCAT(R_score, F_score, M_score) AS RFM_Code,
    #R_score + F_score + M_score AS RFM_Total,
	CASE
        WHEN R_score <=2 AND F_score <=2 AND M_score <=2 THEN 'Loyal'
        WHEN R_score <=3 AND F_score <=3 THEN 'New Customer'
        WHEN R_score >=4 AND (F_score <=3 OR M_score <=3) THEN 'At Risk'
        ELSE 'At Risk'
    END AS Segment
    
FROM scored;
#ORDER BY RFM_Total DESC;

#################################          CHURN ANAYSIS               #####################
#Which of our Côte de Blaye customers used to buy, but haven’t recently — and how do we re-engage them?
WITH product_sales AS (
    SELECT
        c.CustomerID,
        c.CompanyName,
        MAX(o.OrderDate) AS LastPurchase,
        COUNT(DISTINCT o.OrderID) AS Frequency,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Monetary
    FROM `Order Details` od
    JOIN Orders o    ON od.OrderID = o.OrderID
    JOIN Customers c ON o.CustomerID = c.CustomerID
    JOIN Products p  ON od.ProductID = p.ProductID
    WHERE p.ProductName = 'Cte de Blaye'
    GROUP BY c.CustomerID, c.CompanyName
)
SELECT
    CustomerID,
    CompanyName,
    LastPurchase,
    Frequency,
    Monetary,
    DATEDIFF(CURDATE(), LastPurchase) AS DaysSinceLastPurchase,
    CASE
        WHEN DATEDIFF('1998-05-06', LastPurchase) > 365 THEN 'Churned'
        WHEN DATEDIFF('1998-05-06', LastPurchase) BETWEEN 180 AND 365 THEN 'At Risk'
        ELSE 'Active'
    END AS ChurnStatus
FROM product_sales
ORDER BY DaysSinceLastPurchase DESC;
#countries that buy this product, revenue of cte de blaye
SELECT 
    c.Country,
    COUNT(DISTINCT o.CustomerID) AS NumberOfCustomers,
    SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotalRevenue
FROM 
    `Order Details` od
JOIN 
    Orders o ON od.OrderID = o.OrderID
JOIN 
    Customers c ON o.CustomerID = c.CustomerID
JOIN 
    Products p ON od.ProductID = p.ProductID
WHERE 
    p.ProductName = 'CTE De Blaye'
GROUP BY 
    c.Country
ORDER BY 
    TotalRevenue DESC;

    #### sales trend per country
SELECT 
    c.Country,
    YEAR(o.OrderDate) AS OrderYear,
    SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotalRevenue
FROM 
    `Order Details` od
JOIN 
    Orders o ON od.OrderID = o.OrderID
JOIN 
    Customers c ON o.CustomerID = c.CustomerID
JOIN 
    Products p ON od.ProductID = p.ProductID
WHERE 
    p.ProductName = 'CTE De Blaye'
GROUP BY 
    c.Country,
    YEAR(o.OrderDate)
ORDER BY 
    c.Country,
    OrderYear;


#################       CROSS SELLING PRODUCTS ###################################
##########  What other products tend to be purchased in the same orders as this wine (cte de blaye)? ##############
WITH WineOrders AS (
    SELECT DISTINCT od.OrderID
    FROM `Order Details` od
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE p.ProductName = 'Cte de Blaye'
)
SELECT 
    p.ProductName AS OtherProduct,
    COUNT(*) AS TimesBoughtTogether,
    SUM(od.Quantity * od.UnitPrice) AS RevenueTogether
FROM `Order Details` od
JOIN Products p ON od.ProductID = p.ProductID
JOIN WineOrders wo ON od.OrderID = wo.OrderID
WHERE p.ProductName <> 'Côte de Blaye'
GROUP BY p.ProductName
ORDER BY TimesBoughtTogether DESC;
#Shows every other product that appears in the same order.
WITH target AS (
    SELECT ProductID
    FROM Products
    WHERE ProductName = 'Cte de Blaye'
),
orders_with_target AS (
    SELECT DISTINCT OrderID
    FROM `Order Details`
    WHERE ProductID = (SELECT ProductID FROM target)
)
SELECT
    od.OrderID,
    p.ProductName AS OtherProduct
FROM `Order Details`  od
JOIN Products p      ON od.ProductID = p.ProductID
JOIN orders_with_target owt ON od.OrderID = owt.OrderID
WHERE od.ProductID <> (SELECT ProductID FROM target)
ORDER BY od.OrderID, p.ProductName;

#b) Frequency table (how often each item is bought with it)
WITH target AS (
    SELECT ProductID
    FROM Products
    WHERE ProductName = 'Cte de Blaye'
),
orders_with_target AS (
    SELECT DISTINCT OrderID
    FROM `Order Details` 
    WHERE ProductID = (SELECT ProductID FROM target)
)
SELECT
    p.ProductName      AS OtherProduct,
    COUNT(DISTINCT od.OrderID) AS OrdersTogether,
    SUM(od.Quantity)   AS QuantityTogether
FROM `Order Details`  od
JOIN Products p      ON od.ProductID = p.ProductID
JOIN orders_with_target owt ON od.OrderID = owt.OrderID
WHERE od.ProductID <> (SELECT ProductID FROM target)
GROUP BY p.ProductName
ORDER BY OrdersTogether DESC;

#Find the ProductID for the item we care about
WITH target AS (
    SELECT ProductID
    FROM Products
    WHERE ProductName = 'Cte de Blaye'
),

#Orders that include the target product
orders_with_target AS (
    SELECT DISTINCT OrderID
    FROM `Order Details`
    WHERE ProductID = (SELECT ProductID FROM target)
)

-- 3️⃣ Pull all other products from those orders, plus their category
SELECT
    p.ProductName AS OtherProduct,
    c.CategoryName AS Category,
    COUNT(DISTINCT od.OrderID) AS OrdersTogether,
    SUM(od.Quantity)    AS QuantityTogether
FROM `Order Details` od
JOIN Products   p ON od.ProductID = p.ProductID
JOIN Categories c ON p.CategoryID = c.CategoryID
JOIN orders_with_target owt ON od.OrderID = owt.OrderID
WHERE od.ProductID <> (SELECT ProductID FROM target)        -- exclude the wine itself
GROUP BY p.ProductName, c.CategoryName
ORDER BY OrdersTogether DESC, QuantityTogether DESC;


