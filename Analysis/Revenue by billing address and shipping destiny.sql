###########################################################
# WANT TO SEE IF CUSTOMERS WHO ARE PLACING ORDERS AND THE REVENUE WE ARE GETTING FROM THIS IS AS SAME AS WHERE THE ORDER IS GETTING SHIPPED AND THE REVENUE WE GETTING FROM THERE
#################################################################
##################################################################

SELECT country, count( country) FROM northwind.customers group by country;
SELECT shipcountry, count( shipcountry) FROM northwind.orders group by shipcountry;

############# customers     #############
SELECT 
    c.Country AS CustomerCountry,
    SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotalRevenue
FROM Customers AS c
INNER JOIN Orders AS o
    ON c.CustomerID = o.CustomerID
INNER JOIN `Order Details` AS od
    ON o.OrderID = od.OrderID
GROUP BY 
    c.Country
ORDER BY 
    TotalRevenue DESC;
    
    
################ Shipped countries ###############
SELECT 
    o.ShipCountry,
    SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS TotalRevenue
FROM Orders AS o
INNER JOIN 	`Order Details` AS od
    ON o.OrderID = od.OrderID
GROUP BY 
    o.ShipCountry
ORDER BY 
    TotalRevenue DESC;

