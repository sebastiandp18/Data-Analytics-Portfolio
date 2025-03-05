-- Creación de datasets a través de consultas utilizando la base de datos AdventureWorks2017
-- Los datos se encuentran en la base de datos OLTP (Producción) y el objetivo aquí es Extraer, Transformar y Cargar los datos en las herramientas software de destino, para realizar modelos estadísticos de series temporales, regresión lineal y clasificación (regresión logística).

USE AdventureWorks2017

-- PARTE I (1º CONSULTA): DATASET SERIES TEMPORALES. Obtener un dataset que arroje las series temporales de las ventas globales de la empresa para el período comprendido entre 2011 y 2014, creando una consulta para agrupar los valores de las ventas por período temporal (días, semanas, meses, etc).
SELECT 
    SOH.OrderDate AS OrderDate,  -- Agrupar por día
    SUM(SOD.LineTotal) AS TotalSales  -- Sumatorio de ventas
FROM 
    Sales.SalesOrderHeader AS SOH
INNER JOIN 
    Sales.SalesOrderDetail AS SOD ON SOH.SalesOrderID = SOD.SalesOrderID
WHERE 
    SOH.OrderDate BETWEEN '20110101' AND '20141231'
GROUP BY 
    SOH.OrderDate  -- Agrupar por día
ORDER BY 
    SOH.OrderDate;

-- PARTE I (2º CONSULTA): DATASET SERIES TEMPORALES.
SELECT 
    GlobalSales.OrderDate,
    GlobalSales.TotalSales,
    US_Sales.US_Sales,
    Europe_Sales.Europe_Sales,
    Pacific_Sales.Pacific_Sales
FROM 
    (
        SELECT 
            SOH.OrderDate AS OrderDate,
            SUM(SOD.LineTotal) AS TotalSales
        FROM 
           Sales.SalesOrderHeader SOH
        INNER JOIN 
            Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
        WHERE 
            SOH.OrderDate BETWEEN '20110101' AND '20141231'
        GROUP BY 
            SOH.OrderDate
    ) AS GlobalSales
LEFT JOIN 
    (
        SELECT 
            SOH.OrderDate AS OrderDate,
            SUM(SOD.LineTotal) AS US_Sales
        FROM 
            Sales.SalesOrderHeader SOH
        INNER JOIN 
            Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
		INNER JOIN 
            Sales.SalesTerritory ST ON SOH.TerritoryID = ST.TerritoryID
        WHERE 
            SOH.OrderDate BETWEEN '20110101' AND '20141231'
            AND ST.[Group] = 'North America'
        GROUP BY 
            SOH.OrderDate
    ) AS US_Sales ON GlobalSales.OrderDate = US_Sales.OrderDate
LEFT JOIN 
    (
        SELECT 
           SOH.OrderDate AS OrderDate,
            SUM(SOD.LineTotal) AS Europe_Sales
        FROM 
            Sales.SalesOrderHeader SOH
        INNER JOIN 
            Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
		INNER JOIN 
            Sales.SalesTerritory ST ON SOH.TerritoryID = ST.TerritoryID
        WHERE 
            SOH.OrderDate BETWEEN '20110101' AND '20141231'
            AND ST.[Group] = 'Europe'
        GROUP BY 
            SOH.OrderDate
    ) AS Europe_Sales ON GlobalSales.OrderDate = Europe_Sales.OrderDate
LEFT JOIN 
    (
        SELECT 
            SOH.OrderDate AS OrderDate,
            SUM(SOD.LineTotal) AS Pacific_Sales
        FROM 
            Sales.SalesOrderHeader SOH
        INNER JOIN 
            Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
		INNER JOIN 
            Sales.SalesTerritory ST ON SOH.TerritoryID = ST.TerritoryID
        WHERE 
            SOH.OrderDate BETWEEN '20110101' AND '20141231'
            AND ST.[Group] = 'Pacific'
        GROUP BY 
            SOH.OrderDate
    ) AS Pacific_Sales ON GlobalSales.OrderDate = Pacific_Sales.OrderDate
ORDER BY 
    GlobalSales.OrderDate;

-- PARTE II: DATASET DE CLIENTES PARA REGRESIÓN LINEAL. Obtener el gasto acumulado de todos los clientes (personas y no tiendas) y sus diferentes variables demográficas (edad, país, ingresos, educación, etc).
SELECT 
    P.BusinessEntityID AS CustomerID,
    PD.Education,
    PD.Occupation,
    PD.Gender,
    PD.MaritalStatus,
    PD.TotalChildren,
    PD.NumberChildrenAtHome,
    PD.NumberCarsOwned,
    PD.YearlyIncome,
    ST.Name AS TerritoryName,
    ST.CountryRegionCode,
    ST.[Group] AS SalesGroup,
    DATEDIFF(YEAR, PD.BirthDate, GETDATE()) AS Age,
    SUM(SOH.TotalDue) AS TotalSpent
FROM 
    Sales.SalesOrderHeader AS SOH
--escribimos inner ya que queremos clientes que hayan comprado
INNER JOIN 
    Sales.Customer AS C 
	ON SOH.CustomerID = C.CustomerID
--combinamos los datos personales con la tabla de ventas
INNER JOIN 
    Person.Person AS P 
	ON C.PersonID = P.BusinessEntityID
--obtenemos la información de dónde se han producido esas ventas
INNER JOIN 
    Sales.SalesTerritory AS ST 
	ON SOH.TerritoryID = ST.TerritoryID
--obtenemos los datos demográficos de los clientes
INNER JOIN 
    Sales.vPersonDemographics AS PD 
	ON P.BusinessEntityID = PD.BusinessEntityID
--ahora queremos filtrar por tipo de cliente que sea individuo ('in')
WHERE 
    P.PersonType = 'IN'
--agrupamos para evitar valores duplicados de clientes
GROUP BY 
    P.BusinessEntityID,
    PD.Education,
    PD.Occupation,
    PD.Gender,
    PD.MaritalStatus,
    PD.TotalChildren,
    PD.NumberChildrenAtHome,
    PD.NumberCarsOwned,
    PD.YearlyIncome,
    ST.Name,
    ST.CountryRegionCode,
    ST.[Group],
    PD.BirthDate
ORDER BY 
    TotalSpent asc
    

-- PARTE III: DATASET DE CLIENTES PARA CLASIFICACIÓN (REGRESIÓN LOGÍSTICA). Tenemos la consulta de gasto medio, sin embargo, también es necesario obtener información sobre cuáles clientes han adquirido una bicicleta y cuáles no (pueden adquirir otro tipo como piezas o equipamiento). Para ello incluimos una variable extra, la cual tomaría valor 1 en caso de que hayan adquirido al menos una bicicleta y 0 si no han adquirido ninguna. Una vez realizada la consulta, procedemos a incorporarla en la consulta principal (gasto medio), a través de una subconsulta denominada BikePurchase utilizando como claves de conexión el CustomerID, con la finalidad de poder obtener ese atributo adicional que nos permite identificar los clientes que han adquirido una o más bicicletas.
SELECT 
    P.BusinessEntityID AS CustomerID,
    PD.Education,
    PD.Occupation,
    PD.Gender,
    PD.MaritalStatus,
    PD.TotalChildren,
    PD.NumberChildrenAtHome,
    PD.NumberCarsOwned,
    PD.YearlyIncome,
    PD.DateFirstPurchase,
    ST.[Name] AS TerritoryName,
    ST.CountryRegionCode,
    ST.[Group] AS SalesGroup,
    DATEDIFF(YEAR, PD.BirthDate, GETDATE()) AS Age,
    SUM(SOH.TotalDue) AS TotalSpent,
    ISNULL(BP.BikePurchase, 0) AS BikePurchase  -- Reemplaza NULL por 0
FROM 
    Sales.SalesOrderHeader SOH
INNER JOIN 
    Sales.Customer C ON SOH.CustomerID = C.CustomerID
INNER JOIN 
    Person.Person P ON C.PersonID = P.BusinessEntityID
INNER JOIN 
    Sales.SalesTerritory ST ON SOH.TerritoryID = ST.TerritoryID
INNER JOIN 
    Sales.vPersonDemographics PD ON P.BusinessEntityID = PD.BusinessEntityID
LEFT JOIN 
    (
        SELECT 
            C.CustomerID,
            1 AS BikePurchase
        FROM 
            Sales.SalesOrderDetail SOD
        INNER JOIN 
            Production.Product P ON SOD.ProductID = P.ProductID
        INNER JOIN 
            Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
        INNER JOIN 
            Sales.Customer C ON SOH.CustomerID = C.CustomerID
        WHERE 
            P.ProductSubcategoryID IN (1, 2, 3)  -- Subcategorías de bicicletas
        GROUP BY 
            C.CustomerID
    ) BP ON C.CustomerID = BP.CustomerID
WHERE 
    P.PersonType = 'IN'  -- Filtra solo individuos (no tiendas)
GROUP BY 
    P.BusinessEntityID,
    PD.Education,
    PD.Occupation,
    PD.Gender,
    PD.MaritalStatus,
    PD.TotalChildren,
    PD.NumberChildrenAtHome,
    PD.NumberCarsOwned,
    PD.YearlyIncome,
    PD.DateFirstPurchase,
    ST.[Name],
    ST.CountryRegionCode,
    ST.[Group],
    PD.BirthDate,
    BP.BikePurchase
ORDER BY 
    TotalSpent DESC;