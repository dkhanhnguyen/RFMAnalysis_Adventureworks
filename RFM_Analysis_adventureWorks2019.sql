-- This is a project of an RFM Analysis to categorize customers into different groups for further analyzing and designing detailed campaigns
-- Analyzed my: Khanh NGUYEN
-- Datasource: Sample database from Microsoft -- https://docs.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver15&tabs=ssms

-- This project utiliez three aspects: recency, frequency and monetary
-- First look at data - using the table Sales Order Header

SELECT *
FROM AdventureWorks2019.Sales.SalesOrderHeader

SELECT * 
FROM AdventureWorks2019.Sales.Customer

-- 1. Get the customer, the amount of time from the most recent purchase. This project will focus on analyzing customers which have order in 2013

SELECT a.CustomerID, DATEDIFF(day,MAX(a.orderdate),'2013-12-31') recency

FROM AdventureWorks2019.Sales.SalesOrderHeader a
INNER JOIN Sales.Customer b
ON a.CustomerID = b.CustomerID
WHERE year(a.OrderDate) = 2013
GROUP BY a.CustomerID
ORDER BY recency

-- Grouping customer into different categories using subquerry(count customers into recency)
SELECT recency, count(*) AS numbercustomer
FROM 
(SELECT a.CustomerID, 
		DATEDIFF(day,MAX(a.orderdate),'2013-12-31') recency

FROM AdventureWorks2019.Sales.SalesOrderHeader a
INNER JOIN Sales.Customer b
ON a.CustomerID = b.CustomerID
WHERE year(a.OrderDate) = 2013
GROUP BY a.CustomerID) rec
GROUP BY recency
ORDER BY recency


-- Divide into fifth percentile - R1 is the highest, R5 is the lowest

SELECT abc.*,
	NTILE(5) OVER(ORDER BY recency) R_S
FROM
(SELECT a.CustomerID, 
		DATEDIFF(day,MAX(a.orderdate),'2013-12-31') recency
FROM AdventureWorks2019.Sales.SalesOrderHeader a
INNER JOIN Sales.Customer b
ON a.CustomerID = b.CustomerID
WHERE year(a.OrderDate) = 2013
GROUP BY a.CustomerID) abc



-- Frequency may be calculated by: Frequency = Time/number of order. The time is the number of day between the first purchased and the last day of year 2013=> The more orders the higher the frequency
-- Calculate first purchase date
SELECT a.CustomerID, MIN(a.OrderDate) AS first_purchase, COUNT(*) AS purchased_quantity

FROM AdventureWorks2019.Sales.SalesOrderHeader a
INNER JOIN Sales.Customer b
ON a.CustomerID = b.CustomerID
WHERE year(a.OrderDate) = 2013
GROUP BY a.CustomerID

-- -- Calculate Frequency

SELECT DATEDIFF(day,cde.first_purchase,'2013-12-31')/cde.purchased_quantity frequency, count(*)
FROM 
(SELECT a.CustomerID, MIN(a.OrderDate) AS first_purchase, COUNT(*) AS purchased_quantity
FROM AdventureWorks2019.Sales.SalesOrderHeader a
INNER JOIN Sales.Customer b
ON a.CustomerID = b.CustomerID
WHERE year(a.OrderDate) = 2013
GROUP BY a.CustomerID) cde
GROUP BY DATEDIFF(day,cde.first_purchase,'2013-12-31')/cde.purchased_quantity 
ORDER BY frequency

-- -- Percentile for frequency -- F1 is the highest, F5 is the lowest

SELECT fre_temp.*,
	NTILE(5) OVER(ORDER BY frequency DESC) F_S

FROM (
SELECT DATEDIFF(day,cde.first_purchase,'2013-12-31')/cde.purchased_quantity frequency, count(*) AS numorder
FROM 
(SELECT a.CustomerID, MIN(a.OrderDate) AS first_purchase, COUNT(*) AS purchased_quantity
FROM AdventureWorks2019.Sales.SalesOrderHeader a
INNER JOIN AdventureWorks2019.Sales.Customer b
ON a.CustomerID = b.CustomerID
WHERE year(a.OrderDate) = 2013
GROUP BY a.CustomerID) cde
GROUP BY DATEDIFF(day,cde.first_purchase,'2013-12-31')/cde.purchased_quantity 
) AS fre_temp

-- Calculate the money the customer has purchased since the first purchased - M1 is the highest, M5 is the lowest
SELECT purchase.*,
	NTILE(5) OVER(ORDER BY purchase.totalpurchase DESC) M_S
FROM (
SELECT a.CustomerID, MIN(a.OrderDate) AS first_purchase, SUM(TotalDue) AS totalpurchase
FROM AdventureWorks2019.Sales.SalesOrderHeader a
INNER JOIN AdventureWorks2019.Sales.Customer b
ON a.CustomerID = b.CustomerID
WHERE year(a.OrderDate) = 2013
GROUP BY a.CustomerID) as purchase

SELECT * FROM AdventureWorks2019.Sales.SalesOrderHeader


-- Combine 3 categories

WITH rfm_raw AS (
	SELECT a.CustomerID, 
		DATEDIFF(day,MAX(a.orderdate),'2013-12-31') R,
		MIN(a.OrderDate) AS first_purchase, 
		DATEDIFF(day,min(a.OrderDate),'2013-12-31')/count(*) F,
		SUM(TotalDue) AS M
	FROM AdventureWorks2019.Sales.SalesOrderHeader a
	INNER JOIN AdventureWorks2019.Sales.Customer b
	ON a.CustomerID = b.CustomerID
	WHERE year(a.OrderDate) = 2013
	GROUP BY a.CustomerID
	),
	calc_rfm AS (
	SELECT r.*,
			NTILE(3) OVER (ORDER BY R ASC) as R_S,
            NTILE(3) OVER (ORDER BY F DESC) as F_S,
            NTILE(3) OVER (ORDER BY M DESC) as M_S
	FROM rfm_raw r
	)
SELECT rfm.*,rfm_segment.rfm_segment
FROM calc_rfm rfm 
JOIN (SELECT 1 AS R_S, 1 AS F_S, 1 AS M_S, 'Champions' AS rfm_segment UNION ALL
		SELECT 1 AS R_S, 1 AS F_S, 2 AS M_S, 'Potential1' AS rfm_segment UNION ALL
		SELECT 1 AS R_S, 1 AS F_S, 3 AS M_S, 'Potential1' AS rfm_segment UNION ALL	
		SELECT 1 AS R_S, 2 AS F_S, 1 AS M_S, 'Potential1' AS rfm_segment UNION ALL
		SELECT 1 AS R_S, 3 AS F_S, 1 AS M_S, 'Potential1' AS rfm_segment UNION ALL
		SELECT 1 AS R_S, 2 AS F_S, 2 AS M_S, 'Potential2' AS rfm_segment UNION ALL
		SELECT 1 AS R_S, 2 AS F_S, 3 AS M_S, 'Potential2' AS rfm_segment UNION ALL
		SELECT 1 AS R_S, 3 AS F_S, 2 AS M_S, 'Potential2' AS rfm_segment UNION ALL
		SELECT 1 AS R_S, 3 AS F_S, 3 AS M_S, 'Potential2' AS rfm_segment UNION ALL
		SELECT 2 AS R_S, 1 AS F_S, 1 AS M_S, 'Needing_attention1' AS rfm_segment UNION ALL
		SELECT 2 AS R_S, 2 AS F_S, 1 AS M_S, 'Needing_attention2' AS rfm_segment UNION ALL
		SELECT 2 AS R_S, 3 AS F_S, 1 AS M_S, 'Needing_attention2' AS rfm_segment UNION ALL
		SELECT 2 AS R_S, 3 AS F_S, 2 AS M_S, 'Needing_attention2' AS rfm_segment UNION ALL
		SELECT 2 AS R_S, 1 AS F_S, 3 AS M_S, 'Needing_attention2' AS rfm_segment UNION ALL
		SELECT 2 AS R_S, 1 AS F_S, 2 AS M_S, 'Needing_attention2' AS rfm_segment UNION ALL
		SELECT 2 AS R_S, 3 AS F_S, 3 AS M_S, 'Needing_attention2' AS rfm_segment UNION ALL
		SELECT 2 AS R_S, 2 AS F_S, 3 AS M_S, 'Needing_attention2' AS rfm_segment UNION ALL
		SELECT 2 AS R_S, 2 AS F_S, 2 AS M_S, 'Needing_attention2' AS rfm_segment UNION ALL
		SELECT 3 AS R_S, 1 AS F_S, 2 AS M_S, 'Lost1' AS rfm_segment UNION ALL
		SELECT 3 AS R_S, 2 AS F_S, 1 AS M_S, 'Lost1' AS rfm_segment UNION ALL
		SELECT 3 AS R_S, 3 AS F_S, 1 AS M_S, 'Lost1' AS rfm_segment UNION ALL
		SELECT 3 AS R_S, 1 AS F_S, 1 AS M_S, 'Lost1' AS rfm_segment UNION ALL
		SELECT 3 AS R_S, 3 AS F_S, 3 AS M_S, 'Lost2' AS rfm_segment UNION ALL
		SELECT 3 AS R_S, 3 AS F_S, 2 AS M_S, 'Lost2' AS rfm_segment UNION ALL
		SELECT 3 AS R_S, 2 AS F_S, 3 AS M_S, 'Lost2' AS rfm_segment UNION ALL
		SELECT 3 AS R_S, 2 AS F_S, 2 AS M_S, 'Lost2' AS rfm_segment UNION ALL
		SELECT 3 AS R_S, 1 AS F_S, 3 AS M_S, 'Lost2' AS rfm_segment) rfm_segment
	ON rfm.R_S=rfm_segment.R_S AND RFM.F_S = rfm_segment.F_S AND rfm.M_S=rfm_segment.M_S
	ORDER BY rfm_segment.rfm_segment
