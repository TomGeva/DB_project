/* tests */
SELECT TOP (1000) [Garden]
      ,[Seed]
      ,[Quantity]
  FROM [dbo].[CHOSENS]

SELECT TOP (1000) *
FROM dbo.ORDERS

SELECT TOP (1000) *
FROM dbo.GARDENS

SELECT TOP (1000) *
FROM dbo.PRODUCTS


/* PART 1 - 2 QUERIES WITH NO NESTING */

-- need one more, first is good, second has double counting and cannot be without nesting

/* 
    for every seed, what is the quantity that was ordered as a part of a designed garden, in the last month and in the same month a year before
*/
SELECT      [Seed Name] = C.Seed, 
            [Seed Quantitity Of Last Month] = SUM(CASE WHEN DATEDIFF(MONTH, O.OrderDate, GETDATE()) = 1 THEN C.Quantity*DSG.Quantity ELSE 0 END),
            [Seed Quantitity Of Year Before] = SUM(CASE WHEN DATEDIFF(MONTH, O.OrderDate, GETDATE()) = 13 THEN C.Quantity*DSG.Quantity ELSE 0 END)
FROM        dbo.ORDERS AS O
            JOIN dbo.DESIGNS as DSG
                ON O.OrderID = DSG.OrderID
            JOIN dbo.CHOSENS AS C
                ON DSG.Name = C.Garden AND DSG.DesignID = C.Design 
GROUP BY    C.Seed
HAVING      SUM(CASE WHEN DATEDIFF(MONTH, O.OrderDate, GETDATE()) = 1 THEN C.Quantity*DSG.Quantity ELSE 0 END) > 0
            OR SUM(CASE WHEN DATEDIFF(MONTH, O.OrderDate, GETDATE()) = 13 THEN C.Quantity*DSG.Quantity ELSE 0 END) > 0
ORDER BY    [Seed Quantitity Of Last Month] DESC, [Seed Quantitity Of Year Before]

/*
    How many purcheses were made with each personalized garden type from the past year?
    Motivation: To estimarte how many gardens to build this year from each type.
*/

SELECT D.Name,
        [Total Orders] = COUNT(*)
FROM DBO.DESIGNS AS D JOIN DBO.ORDERS AS O ON D.OrderID = O.OrderID
WHERE DATEDIFF(DAY,O.OrderDate, GETDATE()) <= 365 
GROUP BY D.Name
ORDER BY [Total Orders] DESC


/* PART 2 - QUERIES WITH NESTING */

-- complete

/*
    find popular search words.
    Motivaition: detect popular products and trends that could be incorporated into advertisement.
*/

SELECT      TOP 15 
            W.searchWord, 
            Appearances = COUNT(*)
FROM        (
                SELECT  searchWord = LOWER(value)
                FROM    dbo.SEARCHES
                CROSS APPLY STRING_SPLIT(Search_text, ' ')
            ) AS W
WHERE       LEN(W.searchWord) > 3
GROUP BY    W.searchWord
ORDER BY    Appearances DESC


/*
    Which months of the year are the buissiest on avg? 
    Motivation: Post advertisments and discounts on the website on those months.
*/

SELECT      [Average Orders] = AVG(Orders),
            [Month]
FROM        (
            SELECT      Orders = COUNT(*),
                        [Year] = YEAR(O.OrderDate),
                        [Month] = DATENAME(MONTH, O.OrderDate)
            FROM        dbo.ORDERS AS O
            WHERE       DATEDIFF(MONTH, O.OrderDate, GETDATE()) <= 60 /* orders from the last 5 years */
            GROUP BY    YEAR(O.OrderDate), DATENAME(MONTH, O.OrderDate)
            ) As OMonth
GROUP BY    [Month]
HAVING      AVG(Orders) > ( /* select months that their average orders is above the average of all months */
                SELECT  AVG(Orders1)
                FROM    (
                        SELECT      Orders1 = COUNT(*),
                                    [Year1] = YEAR(O1.OrderDate),
                                    [Month1] = DATENAME(MONTH, O1.OrderDate)
                        FROM        dbo.ORDERS AS O1
                        WHERE       DATEDIFF(MONTH, O1.OrderDate, GETDATE()) <= 60 /* orders from the last 5 years */
                        GROUP BY    YEAR(O1.OrderDate), DATENAME(MONTH, O1.OrderDate)
                        ) As OAVG
            )
ORDER BY    [Average Orders] DESC

/* PART 3 - Upgraded Nested Queries */

-- complete

/* 
    Queary 1, deletion of relations between products, if in last 3 years there were no orders that include the 2 products that have a relation metioned about them, the relation should be deleted
    this, not including seeds that are a part of a garden.
*/

DELETE  FROM dbo.RELATIONS
WHERE   CONCAT(Product1, Product2) NOT IN   (
                                                SELECT  CONCAT(RLT.Product1, RLT.Product2)
                                                FROM    dbo.RELATIONS AS RLT
                                                        JOIN dbo.INCLUSIONS AS I1
                                                            ON RLT.Product1 = I1.Name
                                                        JOIN dbo.INCLUSIONS AS I2
                                                            ON RLT.Product2 = I2.Name
                                                        JOIN dbo.ORDERS AS O
                                                            ON I1.OrderID = O.OrderID
                                                WHERE I1.OrderID = I2.OrderID AND DATEDIFF(YEAR,O.OrderDate, GETDATE()) BETWEEN 1 AND 3
                                            )


/* to reset RELATIONS */
DELETE FROM dbo.RELATIONS
INSERT INTO dbo.RELATIONS (Product1, Product2) SELECT * FROM dbo.RELATIONS_

/* 
    Query 2, Yearly-Quarter performance report of seeds of type Root Vegetables
*/

SELECT      [Seed_Name] = Seed,
            [Year] = YEAR(OrderDate),
            [Quarter] = DATEPART(QUARTER, OrderDate),
            [Total Quantity] = SUM(Quantity),
            [Total Orders] = COUNT(OrderID),
            [Avg Quantity per Order] = ROUND(AVG(CAST(Quantity AS FLOAT)),2)
FROM    (
            SELECT      Seed = C.Seed,
                        OrderID = O.OrderID,
                        OrderDate = O.OrderDate,
                        Quantity = C.Quantity*DSG.Quantity,
                        [Type] = ST.[Type]
            FROM        dbo.CHOSENS AS C
                        JOIN dbo.DESIGNS AS DSG
                            ON C.Design = DSG.DesignID
                        JOIN dbo.ORDERS AS O
                            ON DSG.OrderID = O.OrderID
                        JOIN dbo.SEEDS AS SD
                            ON C.Seed = SD.Name
                        JOIN dbo.SEED_TYPES AS ST
                            ON SD.Name = ST.Name
        UNION 
            SELECT      Seed = I.Name,
                        OrderID = O.OrderID,
                        OrderDate = O.OrderDate,
                        Quantity = I.Quantity,
                        [Type] = ST.[Type]
            FROM        dbo.INCLUSIONS AS I
                        JOIN dbo.ORDERS AS O
                            ON I.OrderID = O.OrderID
                        JOIN dbo.SEEDS AS SD
                            ON I.Name = SD.Name
                        JOIN dbo.SEED_TYPES AS ST
                            ON SD.Name = ST.Name
        UNION 
            SELECT      Seed = PLT.Seed,
                        OrderID = O.OrderID,
                        OrderDate = O.OrderDate,
                        Quantity = PLT.Quantity*I.Quantity,
                        [Type] = ST.[Type]
            FROM        dbo.PLANTEDS AS PLT
                        JOIN dbo.GARDENS AS G
                            ON PLT.Garden = G.Name
                        JOIN dbo.PRODUCTS AS PRD
                            ON G.Name = PRD.Name
                        JOIN dbo.INCLUSIONS AS I
                            ON PRD.Name = I.Name
                        JOIN dbo.ORDERS AS O
                            ON I.OrderID = O.OrderID
                        JOIN dbo.SEEDS AS SD
                            ON PLT.Seed = SD.Name
                        JOIN dbo.SEED_TYPES AS ST
                            ON SD.Name = ST.Name
        ) AS SDByOrd
        WHERE       DATEDIFF(QUARTER, OrderDate, GETDATE()) <= 4 AND DATEDIFF(QUARTER, OrderDate, GETDATE()) > 0 AND [Type] = 'Root Vegetables'
GROUP BY    Seed, YEAR(OrderDate), DATEPART(QUARTER, OrderDate)
ORDER BY    YEAR(OrderDate), DATEPART(QUARTER, OrderDate), [Total Quantity] DESC

/* PART 4 - Window Functions */

/*
    Query 1
    Per State: Rank the cities by total sales - for management / marketing.
                Also, show the cumulative distribution of each city order-wise for:
                marketing focus or supply-chain management - drivers and trucks allocation
*/
SELECT      ordcities.State, ordcities.City, ordcities.Orders_per_City,
            city_rank_by_orders = ROW_NUMBER() over (Partition BY ordcities.State Order BY ordcities.Sales_per_City DESC),
            cume_dist = CUME_DIST() OVER (PARTITION BY State ORDER BY Orders_per_City)
FROM
(
            /* Calculate Sales per City */
            SELECT  State, City, Orders_per_City = COUNT(OrderID), Sales_per_City = SUM(order_price)
            FROM 
                    (   /* extract geography (State, City) for each order and calculate order price */
                        SELECT   OrderID, State, City, order_price = SUM(product_price)
                        FROM
                                (
                                    SELECT ord.OrderID, 
                                        CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[2]', 'varchar(128)')), '') AS varchar(128)) AS State,
                                        CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[3]', 'varchar(128)')), '') AS varchar(128)) AS City,
                                        product_price = inc.Quantity * (prd.Price - prd.Discount)
                                    FROM        dbo.ORDERS AS ord
                                    INNER JOIN dbo.INCLUSIONS AS inc
                                        ON ord.OrderID = inc.OrderID
                                    INNER JOIN dbo.PRODUCTS AS prd
                                        ON inc.Name = prd.Name
                                    ) AS ords
                        GROUP BY    OrderID, State, City
                    ) AS ordState
            GROUP BY State, City
) AS ordcities
ORDER BY    State, city_rank_by_orders


/* 
    Query 2
    Per User: Calculate Avg. Days gap between orders and amount of days since last order.
                With this information, estimate the time to the next order a user will make.
    Also calculate total Avg. Days gap between orders.
    Motivation: Market analysis, detect demand rate and plan manufacturing rates / advertisment
*/
SELECT *
FROM 
    (
    SELECT  DISTINCT Email, Last_Order_Date = MAX(OrderDate) OVER (PARTITION BY Email),
            Orders_Per_User = COUNT(OrderID) OVER (PARTITION BY Email),
            Total_Avg_orders_time_gap = AVG(Difference_in_Days) OVER (),
            Avg_User_Orders_time_gap = AVG(Difference_in_Days) OVER (PARTITION BY Email), 
            Days_from_Last_User_Order,
            Estimated_Days_to_Next_Order = AVG(Difference_in_Days) OVER (PARTITION BY Email) - Days_from_Last_User_Order    
    FROM
        (
            SELECT Ord.Email, Ord.OrderID, Ord.OrderDate, LEAD(Ord.OrderDate) Over(Partition BY Email ORDER BY Email) AS Next_Order_Date,
                DATEDIFF(day, ord.OrderDate, LEAD(Ord.OrderDate) Over(Partition BY Email ORDER BY Email)) AS Difference_in_Days,
                Last_User_Order_Date = LAST_VALUE(OrderDate) OVER (PARTITION BY Email ORDER BY Email),
                Days_from_Last_User_Order = DATEDIFF(day, LAST_VALUE(OrderDate) OVER (PARTITION BY Email ORDER BY Email), GETDATE())
            FROM dbo.ORDERS AS ord
            WHERE ord.Email IS NOT NULL 
        ) AS next_ords
    ) AS C
WHERE       Estimated_Days_to_Next_Order > 0
ORDER BY    Estimated_Days_to_Next_Order DESC



/* PART 5 - WITH QUERY */

/*
    Report of seed profitability in the Last quarter, in comparison to the base price of the seed, overall the sales and seperated over designed gardens and premade gardens.
*/
WITH
income_per_seed_from_designs_per_order AS (
    /*
        find the income and quantity of each seed for each garden design sold in the last quarter
    */
    SELECT      Seed = C.Seed,
                TotalIncome = (PRD.Price - PRD.Discount) * DSG.Quantity * C.Quantity / SUM(C.Quantity) OVER (PARTITION BY DSG.Name, DSG.DesignID),
                QuantitySold = C.Quantity*DSG.Quantity
    FROM        DESIGNS AS DSG
                JOIN dbo.CHOSENS AS C
                    ON DSG.DesignID = C.Design AND DSG.Name = C.Garden
                JOIN dbo.GARDENS AS G
                    ON DSG.Name = G.Name
                JOIN dbo.PRODUCTS AS PRD
                    ON G.Name = PRD.Name
                JOIN dbo.ORDERS AS O
                    ON DSG.OrderID = O.OrderID
    WHERE       DATEDIFF(QUARTER, O.OrderDate, GETDATE()) = 1
),
income_per_seed_from_premade_per_order AS (
    /*
        find the income and quantity of each seed for each premade garden sold in the last quarter
    */
    SELECT      Seed = PLT.Seed,
                TotalIncome = (PRD.Price - PRD.Discount) * I.Quantity * PLT.Quantity / SUM(PLT.Quantity) OVER (PARTITION BY O.OrderID, I.Name),
                QuantitySold = PLT.Quantity*I.Quantity
    FROM        dbo.INCLUSIONS AS I
                JOIN dbo.PRODUCTS AS PRD
                    ON I.Name = PRD.Name
                JOIN dbo.GARDENS AS G
                    ON I.Name = G.Name
                JOIN dbo.PLANTEDS AS PLT
                    ON G.Name = PLT.Garden
                JOIN dbo.ORDERS AS O
                    ON I.OrderID = O.OrderID
    WHERE       DATEDIFF(QUARTER, O.OrderDate, GETDATE()) = 1
),
income_per_seed_as_simple_product AS (
    /*
        find the income and quantity of each seed for each sell of seeds in the last quarter
    */
    SELECT      Seed = I.Name,
                TotalIncome = (PRD.Price - PRD.Discount) * I.Quantity,
                QuantitySold = I.Quantity
    FROM        dbo.INCLUSIONS AS I
                JOIN dbo.PRODUCTS AS PRD
                    ON I.Name = PRD.Name
                JOIN dbo.ORDERS AS O
                    ON I.OrderID = O.OrderID
    WHERE       I.Name IN (SELECT Name FROM dbo.SEEDS) AND DATEDIFF(QUARTER, O.OrderDate, GETDATE()) = 1
),
OverallStat AS (
    /*
        calculate income statistics for each seed over all kinds of sales in the last quarter
    */
    SELECT      Seed = SeedIncome.Seed,
                TotalIncome = SUM(SeedIncome.TotalIncome),
                QuantitySold = SUM(SeedIncome.QuantitySold),
                AvgPriceUnit = SUM(SeedIncome.TotalIncome)/SUM(SeedIncome.QuantitySold),
                BasePrice = PRD.Price - PRD.Discount
    FROM
                (
                    SELECT      Seed,
                                TotalIncome,
                                QuantitySold
                    FROM        income_per_seed_from_designs_per_order
                    UNION
                    SELECT      Seed,
                                TotalIncome,
                                QuantitySold
                    FROM        income_per_seed_from_premade_per_order
                    UNION
                    SELECT      Seed,
                                TotalIncome,
                                QuantitySold
                    FROM        income_per_seed_as_simple_product
                ) AS SeedIncome
                JOIN    dbo.PRODUCTS AS PRD
                            ON SeedIncome.Seed = PRD.Name
    GROUP BY    Seed, PRD.Price - PRD.Discount
),
DesignStat AS (
    /*
        calculate income statistics for each seed over seeds sold as a part of a part of a designed garden in the last quarter
    */
    SELECT      Seed = design.Seed, 
                TotalIncome = SUM(design.TotalIncome),
                QuantitySold = SUM(design.QuantitySold),
                AvgPriceUnit = SUM(design.TotalIncome)/SUM(design.QuantitySold),
                BasePrice = PRD.Price - PRD.Discount
    FROM        income_per_seed_from_designs_per_order AS design
                JOIN dbo.PRODUCTS AS PRD
                    ON design.Seed = PRD.Name
    GROUP BY    Seed, PRD.Price - PRD.Discount
),
PremadeStat AS (
    /*
        calculate income statistics for each seed over seeds sold as a part of a part of a premade garden in the last quarter
    */
    SELECT      Seed = premade.Seed, 
                TotalIncome = SUM(premade.TotalIncome),
                QuantitySold = SUM(premade.QuantitySold),
                AvgPriceUnit = SUM(premade.TotalIncome)/SUM(premade.QuantitySold),
                BasePrice = PRD.Price - PRD.Discount
    FROM        income_per_seed_from_premade_per_order AS premade
                JOIN dbo.PRODUCTS AS PRD
                    ON premade.Seed = PRD.Name
    GROUP BY    Seed, PRD.Price - PRD.Discount
)
/*
    present report of seed profitability in the last quarter in an appropriate format
*/
SELECT      Seed = OST.Seed,
            [Total Income] = OST.TotalIncome,
            [Quantity Sold] = OST.QuantitySold,
            [Avg Price per Unit] = OST.AvgPriceUnit,
            [Profit %] = CONCAT(CAST((OST.AvgPriceUnit - OST.BasePrice) / OST.BasePrice * 100 AS varchar(7)), '%'),
            [Designed - Avg Price per Unit] = CASE WHEN DST.QuantitySold IS NULL THEN OST.BasePrice ELSE DST.AvgPriceUnit END,
            [Designed - Profit %] = CONCAT(CAST((DST.AvgPriceUnit - DST.BasePrice) / DST.BasePrice * 100 AS varchar(7)), '%'),
            [Premade - Avg Price per Unit] = PST.AvgPriceUnit,
            [Premade - Profit %] = CONCAT(CAST((PST.AvgPriceUnit - PST.BasePrice) / PST.BasePrice * 100 AS VARCHAR(7)), '%')
FROM        OverallStat AS OST
            LEFT JOIN DesignStat AS DST
                ON OST.Seed = DST.Seed
            LEFT JOIN PremadeStat AS PST
                ON OST.Seed = PST.Seed
ORDER BY    OST.AvgPriceUnit DESC





/* ----------------- QUERIES FOR POWERBI ----------------- */

/*
    For the Business Report:
    The WITH query from PART 5 but with SEED INFO added
*/
WITH
income_per_seed_from_designs_per_order AS (
    /*
        find the income and quantity of each seed for each garden design sold in the last quarter
    */
    SELECT      Seed = C.Seed,
                TotalIncome = (PRD.Price - PRD.Discount) * DSG.Quantity * C.Quantity / SUM(C.Quantity) OVER (PARTITION BY DSG.Name, DSG.DesignID),
                QuantitySold = C.Quantity*DSG.Quantity
    FROM        DESIGNS AS DSG
                JOIN dbo.CHOSENS AS C
                    ON DSG.DesignID = C.Design AND DSG.Name = C.Garden
                JOIN dbo.GARDENS AS G
                    ON DSG.Name = G.Name
                JOIN dbo.PRODUCTS AS PRD
                    ON G.Name = PRD.Name
                JOIN dbo.ORDERS AS O
                    ON DSG.OrderID = O.OrderID
    WHERE       DATEDIFF(QUARTER, O.OrderDate, GETDATE()) = 1
),
income_per_seed_from_premade_per_order AS (
    /*
        find the income and quantity of each seed for each premade garden sold in the last quarter
    */
    SELECT      Seed = PLT.Seed,
                TotalIncome = (PRD.Price - PRD.Discount) * I.Quantity * PLT.Quantity / SUM(PLT.Quantity) OVER (PARTITION BY O.OrderID, I.Name),
                QuantitySold = PLT.Quantity*I.Quantity
    FROM        dbo.INCLUSIONS AS I
                JOIN dbo.PRODUCTS AS PRD
                    ON I.Name = PRD.Name
                JOIN dbo.GARDENS AS G
                    ON I.Name = G.Name
                JOIN dbo.PLANTEDS AS PLT
                    ON G.Name = PLT.Garden
                JOIN dbo.ORDERS AS O
                    ON I.OrderID = O.OrderID
    WHERE       DATEDIFF(QUARTER, O.OrderDate, GETDATE()) = 1
),
income_per_seed_as_simple_product AS (
    /*
        find the income and quantity of each seed for each sell of seeds in the last quarter
    */
    SELECT      Seed = I.Name,
                TotalIncome = (PRD.Price - PRD.Discount) * I.Quantity,
                QuantitySold = I.Quantity
    FROM        dbo.INCLUSIONS AS I
                JOIN dbo.PRODUCTS AS PRD
                    ON I.Name = PRD.Name
                JOIN dbo.ORDERS AS O
                    ON I.OrderID = O.OrderID
    WHERE       I.Name IN (SELECT Name FROM dbo.SEEDS) AND DATEDIFF(QUARTER, O.OrderDate, GETDATE()) = 1
),
OverallStat AS (
    /*
        calculate income statistics for each seed over all kinds of sales in the last quarter
    */
    SELECT      Seed = SeedIncome.Seed,
                TotalIncome = SUM(SeedIncome.TotalIncome),
                QuantitySold = SUM(SeedIncome.QuantitySold),
                AvgPriceUnit = SUM(SeedIncome.TotalIncome)/SUM(SeedIncome.QuantitySold),
                BasePrice = PRD.Price - PRD.Discount
    FROM
                (
                    SELECT      Seed,
                                TotalIncome,
                                QuantitySold
                    FROM        income_per_seed_from_designs_per_order
                    UNION
                    SELECT      Seed,
                                TotalIncome,
                                QuantitySold
                    FROM        income_per_seed_from_premade_per_order
                    UNION
                    SELECT      Seed,
                                TotalIncome,
                                QuantitySold
                    FROM        income_per_seed_as_simple_product
                ) AS SeedIncome
                JOIN    dbo.PRODUCTS AS PRD
                            ON SeedIncome.Seed = PRD.Name
    GROUP BY    Seed, PRD.Price - PRD.Discount
),
DesignStat AS (
    /*
        calculate income statistics for each seed over seeds sold as a part of a part of a designed garden in the last quarter
    */
    SELECT      Seed = design.Seed, 
                TotalIncome = SUM(design.TotalIncome),
                QuantitySold = SUM(design.QuantitySold),
                AvgPriceUnit = SUM(design.TotalIncome)/SUM(design.QuantitySold),
                BasePrice = PRD.Price - PRD.Discount
    FROM        income_per_seed_from_designs_per_order AS design
                JOIN dbo.PRODUCTS AS PRD
                    ON design.Seed = PRD.Name
    GROUP BY    Seed, PRD.Price - PRD.Discount
),
PremadeStat AS (
    /*
        calculate income statistics for each seed over seeds sold as a part of a part of a premade garden in the last quarter
    */
    SELECT      Seed = premade.Seed, 
                TotalIncome = SUM(premade.TotalIncome),
                QuantitySold = SUM(premade.QuantitySold),
                AvgPriceUnit = SUM(premade.TotalIncome)/SUM(premade.QuantitySold),
                BasePrice = PRD.Price - PRD.Discount
    FROM        income_per_seed_from_premade_per_order AS premade
                JOIN dbo.PRODUCTS AS PRD
                    ON premade.Seed = PRD.Name
    GROUP BY    Seed, PRD.Price - PRD.Discount
),
SeedsInfo AS (
    SELECT  Seed = sd.Name, 
            sd.Season, 
            [Seed Size] = sd.[Size], 
            [Sun Amount] = sd.Sun_amount, 
            [Seed Type] = STRING_AGG([Type], ', ') 
    FROM dbo.SEEDS AS sd
    INNER JOIN dbo.SEED_TYPES tp
        ON sd.Name = tp.Name
    GROUP BY sd.Name, sd.Season, sd.[Size], sd.Sun_amount
)
/*
    present report of seed profitability in the last quarter in an appropriate format
*/
SELECT      Seed = OST.Seed,
            INF.[Seed Size],
            INF.Season,
            INF.[Sun Amount],
            INF.[Seed Type],
            [Total Income] = OST.TotalIncome,
            [Quantity Sold] = OST.QuantitySold,
            [Avg Price per Unit] = OST.AvgPriceUnit,
            [Profit %] = CONCAT(CAST((OST.AvgPriceUnit - OST.BasePrice) / OST.BasePrice * 100 AS varchar(7)), '%'),
            [Designed - Avg Price per Unit] = CASE WHEN DST.QuantitySold IS NULL THEN OST.BasePrice ELSE DST.AvgPriceUnit END,
            [Designed - Profit %] = CONCAT(CAST((DST.AvgPriceUnit - DST.BasePrice) / DST.BasePrice * 100 AS varchar(7)), '%'),
            [Premade - Avg Price per Unit] = PST.AvgPriceUnit,
            [Premade - Profit %] = CONCAT(CAST((PST.AvgPriceUnit - PST.BasePrice) / PST.BasePrice * 100 AS VARCHAR(7)), '%')
FROM        OverallStat AS OST
            LEFT JOIN DesignStat AS DST
                ON OST.Seed = DST.Seed
            LEFT JOIN PremadeStat AS PST
                ON OST.Seed = PST.Seed
            INNER JOIN SeedsInfo AS INF
                ON OST.Seed = INF.Seed
ORDER BY    OST.AvgPriceUnit DESC




/* 
    FOR DASHBOARD
*/

/*
    Query 1 - for KPI: Sales ($) in the last 12 months and last Sales trend
*/

/* Calculate total sales in the last year */
WITH total_sales_last_year AS (
    SELECT  total_sales = SUM(product_price)
    FROM
        (
                SELECT  ord.OrderID, 
                        product_price = inc.Quantity * (prd.Price - prd.Discount)
                FROM        dbo.ORDERS AS ord
                INNER JOIN dbo.INCLUSIONS AS inc
                    ON ord.OrderID = inc.OrderID
                INNER JOIN dbo.PRODUCTS AS prd
                    ON inc.Name = prd.Name
                WHERE DATEDIFF(DAY, ord.OrderDate, GETDATE()) <= 365 /*choose last year*/

                UNION
                /* add sales of custom designed gardens */
                SELECT      ord.OrderID,
                            product_price = (prd.Price - prd.Discount)* dsg.Quantity
                FROM        dbo.DESIGNS AS dsg
                INNER JOIN  dbo.GARDENS AS g
                    ON dsg.Name = g.Name
                INNER JOIN dbo.ORDERS AS ord
                    ON dsg.OrderID = ord.OrderID
                INNER JOIN dbo.PRODUCTS AS prd
                    ON g.Name = prd.Name
                WHERE DATEDIFF(DAY, ord.OrderDate, GETDATE()) <= 365 /*choose last year*/
        ) AS ords
),
/* Calculate the last sales trend (sales are up or down)? */
last_sales_trend AS (
    /* Calculate Sales per month and trend for each previous month.
        Then select the month that's closest to the current month and show it's trend */          
    SELECT  TOP 1
            [Month],
            [Months From Today],
            sls.Sales,
            [Previous Month Sales] = LEAD(sls.Sales) Over(ORDER BY [Months From Today]),
            Trend = CASE WHEN Sales - LEAD(sls.Sales) Over(ORDER BY [Months From Today]) > 0 THEN '+' ELSE '-' END
    FROM
    (
    SELECT  ords.[Month],
            [Months From Today],
            [Sales] = SUM(product_price)
    FROM
        (   /* calculate total sales last year by month */
                SELECT  ord.OrderID, 
                        [Month] = DATENAME(MONTH, ord.OrderDate),
                        [Months from Today] = DATEDIFF(MONTH, ord.OrderDate, GETDATE()),
                        product_price = inc.Quantity * (prd.Price - prd.Discount)
                FROM        dbo.ORDERS AS ord
                INNER JOIN dbo.INCLUSIONS AS inc
                    ON ord.OrderID = inc.OrderID
                INNER JOIN dbo.PRODUCTS AS prd
                    ON inc.Name = prd.Name
                WHERE DATEDIFF(DAY, ord.OrderDate, GETDATE()) <= 365 /*choose last year*/

                UNION
                /* add sales of custom designed gardens */
                SELECT      ord.OrderID,
                            [Month] = DATENAME(MONTH, ord.OrderDate),
                            [Months from Today] = DATEDIFF(MONTH, ord.OrderDate, GETDATE()),
                            product_price = (prd.Price - prd.Discount)* dsg.Quantity
                FROM        dbo.DESIGNS AS dsg
                INNER JOIN  dbo.GARDENS AS g
                    ON dsg.Name = g.Name
                INNER JOIN dbo.ORDERS AS ord
                    ON dsg.OrderID = ord.OrderID
                INNER JOIN dbo.PRODUCTS AS prd
                    ON g.Name = prd.Name
                WHERE DATEDIFF(DAY, ord.OrderDate, GETDATE()) <= 365 /*choose last year*/
        ) AS ords
    GROUP BY  ords.[Months from Today], ords.[Month]

    ) AS sls
    ORDER BY [Months From Today]
)
SELECT sls.total_sales, 
        trd.Trend
FROM total_sales_last_year AS sls,
     last_sales_trend AS trd
;


/*
    Query 2 - for KPI: Ratio Sales ($) from Gardens sold, out of the general sales,
                        for all times.
*/

WITH
sales_from_premade_gardens AS (
    SELECT  [Premae_Garden_Sales] = SUM(product_price)
    FROM
        (
                SELECT  ord.OrderID,
                        product_price = inc.Quantity * (prd.Price - prd.Discount)
                FROM        dbo.ORDERS AS ord
                INNER JOIN dbo.INCLUSIONS AS inc
                    ON ord.OrderID = inc.OrderID
                JOIN dbo.PRODUCTS AS prd
                    ON inc.Name = prd.Name
                JOIN dbo.GARDENS AS G
                    ON inc.Name = G.Name
            
        ) AS ords
),
sales_from_custom_gardens AS (
    SELECT  [Custom_Garden_Sales] = SUM(product_price)
    FROM
        (
                SELECT      ord.OrderID, dsg.name, dsg.DesignID,
                            product_price = (prd.Price - prd.Discount)*Quantity
                FROM        dbo.DESIGNS AS dsg
                INNER JOIN  dbo.GARDENS AS g
                    ON dsg.Name = g.Name
                INNER JOIN dbo.ORDERS AS ord
                    ON dsg.OrderID = ord.OrderID
                INNER JOIN dbo.PRODUCTS AS prd
                    ON g.Name = prd.Name
                
        ) AS ords
),
total_sales AS (
    SELECT  total_sales = SUM(product_price)
    FROM
        (
                SELECT  ord.OrderID, 
                        product_price = inc.Quantity * (prd.Price - prd.Discount)
                FROM        dbo.ORDERS AS ord
                INNER JOIN dbo.INCLUSIONS AS inc
                    ON ord.OrderID = inc.OrderID
                INNER JOIN dbo.PRODUCTS AS prd
                    ON inc.Name = prd.Name

                UNION
                /* add sales of custom designed gardens */
                SELECT      ord.OrderID,
                            product_price = (prd.Price - prd.Discount)* dsg.Quantity
                FROM        dbo.DESIGNS AS dsg
                INNER JOIN  dbo.GARDENS AS g
                    ON dsg.Name = g.Name
                INNER JOIN dbo.ORDERS AS ord
                    ON dsg.OrderID = ord.OrderID
                INNER JOIN dbo.PRODUCTS AS prd
                    ON g.Name = prd.Name
        ) AS ords
)
SELECT  [Gardens Sales Ratio] = ((pre.Premae_Garden_Sales + cus.Custom_Garden_Sales)/tot.total_sales)*100
FROM    sales_from_premade_gardens AS pre,
        sales_from_custom_gardens AS cus,
        total_sales AS tot   
;


/*
    Query 3 - KPI 3 & 4: # of states with positive/negative change in sales since last year 
                        and show the avg.change in $.
    NOTE: for the demonstration, the comparison will be between 2022 and 2023.
*/

WITH
/* calculate total sales by this and last year */
sales_per_year_state AS (
    SELECT  [State],
            [Year],
            [Sales] = SUM(product_price)
        FROM
        (
                SELECT  ord.OrderID, 
                        CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[2]', 'varchar(128)')), '') AS varchar(128)) AS State,
                        CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[3]', 'varchar(128)')), '') AS varchar(128)) AS City,
                        [Year] = DATEPART(Year, ord.OrderDate),
                        product_price = inc.Quantity * (prd.Price - prd.Discount)
                FROM        dbo.ORDERS AS ord
                INNER JOIN dbo.INCLUSIONS AS inc
                    ON ord.OrderID = inc.OrderID
                INNER JOIN dbo.PRODUCTS AS prd
                    ON inc.Name = prd.Name
                WHERE DATEPART(Year, ord.OrderDate) IN (2022, 2023)

                UNION
                /* add sales of custom designed gardens */
                SELECT      ord.OrderID,
                            CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[2]', 'varchar(128)')), '') AS varchar(128)) AS State,
                            CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[3]', 'varchar(128)')), '') AS varchar(128)) AS City,
                            [Year] = DATEPART(Year, ord.OrderDate),
                            product_price = (prd.Price - prd.Discount)* dsg.Quantity
                FROM        dbo.DESIGNS AS dsg
                INNER JOIN  dbo.GARDENS AS g
                    ON dsg.Name = g.Name
                INNER JOIN dbo.ORDERS AS ord
                    ON dsg.OrderID = ord.OrderID
                INNER JOIN dbo.PRODUCTS AS prd
                    ON g.Name = prd.Name
                WHERE DATEPART(Year, ord.OrderDate) IN (2022, 2023)

        ) AS ords
        GROUP BY [State], [Year]
),
/* add last year's sales to the same row */
last_year_sales AS (
    SELECT [State], 
            Sales,
            [Last Year Sales] = LAG(Sales) OVER(PARTITION BY [State] ORDER BY [Year])
    FROM sales_per_year_state
),
/* compute sales delta */
sales_delta AS (
    SELECT  *,
            [Sales Delta] = Sales - [Last Year Sales],
            Trend = CASE WHEN Sales - [Last Year Sales] > 0 THEN '+' ELSE '-' END
    FROM last_year_sales
    WHERE [Last Year Sales] IS NOT NULL /* remove rows with no previous year */
)
/* Count Positive Delta and Negative Delta and Avg.Change in Sales */
SELECT  Trend, 
        [Number of States] = COUNT([State]), 
        [Avg. Sales Delta] = AVG([sales delta])
FROM sales_delta
GROUP BY Trend
;



/* 
    Trend Query #1 - Per State and City: show the cumulative distribution of each city and state for
                marketing focus. The divition for State and City seperately is for drill down.
    NOTE: It takes relatively long time to run, around ~1 min.

*/

WITH
/* extract geography for each order */
orders_geo AS (
    SELECT  ord.OrderID,
            CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[2]', 'varchar(128)')), '') AS varchar(128)) AS State,
            CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[3]', 'varchar(128)')), '') AS varchar(128)) AS City
    FROM    dbo.ORDERS AS ord
),
/* calculate cumulative distribution of order numbers per state and city */
cume_dist_city AS (
    SELECT  [State], 
            City,   
            orders_per_city,
            cume_dist_City = ROUND(CUME_DIST() OVER (PARTITION BY State ORDER BY orders_per_city),3)
    FROM    (
                SELECT  [State], 
                        City,   
                        orders_per_city = COUNT(OrderID)
                FROM orders_geo
                GROUP BY State, City
            ) AS ords
),
/* calculate cumulative distribution of order numbers per state */
cume_dist_state AS (
    SELECT  [State],
            orders_per_state,
            cume_dist_state = ROUND(CUME_DIST() OVER (ORDER BY orders_per_state),3)
    FROM    (
                SELECT  [State],    
                        orders_per_state = COUNT(OrderID)
                FROM orders_geo
                GROUP BY [State]
            ) AS ords
)
/* Present all the data together */
SELECT  geo.State, 
        st.orders_per_state,
        st.cume_dist_state,
        geo.City,
        ct.orders_per_city,
        ct.cume_dist_City
FROM    ( /* create a unique list of State and City */
            SELECT  DISTINCT 
                    [State],
                    City
            FROM orders_geo 
        ) AS geo
INNER JOIN cume_dist_state AS st
    ON geo.State = st.State
INNER JOIN cume_dist_city AS ct
    ON (geo.State = ct.State AND geo.City = ct.City) 
;





/*
    Trend Query #2 - Sales by month and geography last year.
                     Also allows drill down here (whether in geography, whether in month)
*/


    SELECT  [State],
            City,
            ords.[Month],
            [Months From Today],
            [Sales] = SUM(product_price)
    FROM
        (       /* calculate total sales last year */
                SELECT  ord.OrderID, 
                        CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[2]', 'varchar(128)')), '') AS varchar(128)) AS State,
                        CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[3]', 'varchar(128)')), '') AS varchar(128)) AS City,
                        [Month] = DATENAME(MONTH, ord.OrderDate),
                        [Months from Today] = DATEDIFF(MONTH, ord.OrderDate, GETDATE()),
                        product_price = inc.Quantity * (prd.Price - prd.Discount)
                FROM        dbo.ORDERS AS ord
                INNER JOIN dbo.INCLUSIONS AS inc
                    ON ord.OrderID = inc.OrderID
                INNER JOIN dbo.PRODUCTS AS prd
                    ON inc.Name = prd.Name
                WHERE DATEDIFF(DAY, ord.OrderDate, GETDATE()) <= 365 /*choose last year*/

                UNION
                /* add sales of custom designed gardens */
                SELECT      ord.OrderID,
                            CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[2]', 'varchar(128)')), '') AS varchar(128)) AS State,
                            CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[3]', 'varchar(128)')), '') AS varchar(128)) AS City,
                            [Month] = DATENAME(MONTH, ord.OrderDate),
                            [Months from Today] = DATEDIFF(MONTH, ord.OrderDate, GETDATE()),
                            product_price = (prd.Price - prd.Discount)* dsg.Quantity
                FROM        dbo.DESIGNS AS dsg
                INNER JOIN  dbo.GARDENS AS g
                    ON dsg.Name = g.Name
                INNER JOIN dbo.ORDERS AS ord
                    ON dsg.OrderID = ord.OrderID
                INNER JOIN dbo.PRODUCTS AS prd
                    ON g.Name = prd.Name
                WHERE DATEDIFF(DAY, ord.OrderDate, GETDATE()) <= 365 /*choose last year*/

        ) AS ords
    GROUP BY  [State], City, ords.[Months from Today], ords.[Month]
    ORDER BY [State], [Months From Today]
    