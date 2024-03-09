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

/*
5. for each self design garden and for every month in the last 3 months, what is the amount of designs made and how many unique seeds were included within the designs in average.
6. for each quarter of the year for the last 3 years, who are the 3 most active users (in terms of orders and searches as long as they made an order), what type of product did they order the most of (seed, premade garden, self design garden, simple product) and what is the average price of their orders.
7. what are the 10 most/least justified relations in the last year. (a relation is more justified if the 2 products within this relation were ordered togehter in the same order the most)
 */




/* PART 1 - 2 QUERIES WITH NO NESTING */

-- need one more, first is good, second has double counting and cannot be without nesting

/* 
    for every seed, what is the quantity that was ordered as a part of a designed garden, in the last month and in the same month a year before
    NOTE TO SELF: IS GOOD. NEED TO ADD MORE DATA THAT'S RELEVANT FOR THIS QUERY.
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
    who are the 5 companies that pay the most by total orders price.
    Motivation: Suggesting benefits and products for corporate clients that frequently buy things from the site for the last 6 months
*/ 

/* NOT GOOD..., HAS DOUBLE COUNTING, to avoid double counting we need nesting...*/
SELECT      TOP 5
            Company = DTS.Company, 
            [Total Orders Price] = SUM( CASE WHEN PRD.Price IS NOT NULL THEN (PRD.Price - PRD.Discount) * I.Quantity ELSE 0 END) + 
                                   SUM( CASE WHEN PRD1.Price IS NOT NULL THEN (PRD1.Price - PRD1.Discount) * DSG.Quantity ELSE 0 END), 
            Orders = COUNT(O.OrderID)
FROM        dbo.ORDERS AS O
            LEFT JOIN dbo.INCLUSIONS AS I
                ON I.OrderID = O.OrderID
            LEFT JOIN dbo.PRODUCTS AS PRD
                ON PRD.Name = I.Name
            LEFT JOIN dbo.DESIGNS AS DSG
                ON O.OrderID = DSG.OrderID
            LEFT JOIN dbo.GARDENS AS G
                ON G.Name = DSG.Name
            LEFT JOIN dbo.PRODUCTS AS PRD1
                ON PRD1.Name = G.Name
            LEFT JOIN dbo.DETAILS AS DTS
                ON (O.Address = DTS.Address AND O.Name = DTS.Name)
WHERE       DTS.Company IS NOT NULL
            AND DATEDIFF(MONTH, O.OrderDate, GETDATE()) <= 6
GROUP BY    DTS.Company
ORDER BY    [Total Orders Price] DESC



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
    needed: a use of 4 different window functions, each in atleast 2 different queries, preferably 2 queries both with all 4 functions.
    the queries must not be possible perform without window functions.

    currently used functions:
        Function Name   |   Query1 used in   |   Query2 used in
    - 
    - 
    - 
    - 
*/

/* 
    Present TOP 3 seeds (with climate details: sun amount and season) that were sold within each State and City.
    Motivation: Adjust seed and garden marketing per geography in style of discounts, advertisments and more.

    NOTE: MIGHT NEED SOME CHANGES IN THE TABLES BECAUSE OF THE ADDITION OF "DESIGN" WEAK ENTITY.

*/

SELECT * 
FROM
(
    SELECT      ordState.State, 
                inc.Name, sd.Season, sd.Sun_amount, total_ordered_quantity = SUM(inc.Quantity),
                ROW_NUMBER() over (Partition BY ordState.State Order BY SUM(inc.Quantity) DESC) AS quantity_rank
    FROM        (
                    SELECT      OrderID, 
                                CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[2]', 'varchar(128)')), '') AS varchar(128)) AS State
                    FROM        dbo.ORDERS
                ) AS ordState
                INNER JOIN  dbo.INCLUSIONS AS inc
                    ON inc.OrderID = ordState.OrderID
                INNER JOIN dbo.SEEDS AS sd
                    ON sd.Name = inc.Name
    GROUP BY    ordState.State, inc.Name, sd.Season, sd.Sun_amount
) AS ordered_quants

WHERE       quantity_rank <= 3

ORDER BY    State, total_ordered_quantity DESC

/* 
    Per User: Calculate Avg. Days gap between orders and amount of days since last order.
                With this information, estimate the time to the next order a user will make.
    Also calculate total Avg. Days gap between orders.
    Motivation: Market analysis, detect demand rate and plan manufacturing rates / advertisment
*/

SELECT  Email, OrderID, OrderDate,
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

/* PART 5 - WITH QUERY */

/*
    Income comparison report of items or types of items
    Motivation: Detect which items are the most profitable and which are the least, and adjust marketing and production accordingly.
    include in the report: 
        - income payment per item whether it is sold as included within a premade garden, a self design garden or as simple product on its own. (which is around 4 and 6 columns of information about them)
        - popularity trends and how they affect the income. (need to think how to calculate this, maybe using the connection between the items within the same order or something.)

needs more planning, after planning should start implementing, and reasoning why cannot be made simply without using with clause.

*/


/* 
    IDEAS
    Inspect Shopping trends by: 
            * Orders and OrdersPrice per weekday and month of the year.
            * Search to Order time per weekday and month of the year.
            * Popular Seed Category.
            * Which seed category is search for per state and city? and compare it to orders of that category in State and City.
                Motivation: Seed preferences according to geographical area and how does the search engine helps to get more orders.
    THE FOLLOWING CODE IS FOR THE LAST IDEA
*/

WITH 
geo_for_search AS (
    SELECT      DISTINCT
                [State] = CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[2]', 'varchar(128)')), '') AS varchar(128)),
                City = CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[3]', 'varchar(128)')), '') AS varchar(128))
    FROM        dbo.DETAILS
),
geo_for_order () AS (

),
 searched_seed_cat ([Type], cat_search_count) AS (
    SELECT      st.[Type], COUNT(CONCAT(res.IP_address, res.SearchDT)) AS cat_search_count
    FROM        dbo.RESULTS AS res
    INNER JOIN  dbo.SEED_TYPES AS st
        ON res.Name = st.Name
    GROUP BY    st.[Type]
),
ordered_seed_cat () AS (

)
SELECT *
FROM searched_seed_cat
;




 /* TYUUUUUUUUTAAAAA ***DRAFT*** */
/* Amount of searches that led to an order within 5 minutes.
    The goal of this query is to check how good the search engine 
    of the website works.
    NOTE TO SELF: 
                we need to show a comparison with how many orders
                DIDNT lead to an order within this time range. (maybe with CASE).
                Another option - Calculate the Avg./Median/SD of diff minutes
                between search and order. but this are nested...
*/

SELECT      DATENAME(WEEKDAY, ord.OrderDate) AS order_week_day,
            COUNT(CONCAT(rs.IP_address, rs.SearchDT)) AS searches_lead_to_orders
FROM        dbo.RESULTS AS rs
            INNER JOIN INCLUSIONS AS inc
                ON rs.Name = inc.Name
            INNER JOIN ORDERS AS ord
                ON inc.OrderID = ord.OrderID
WHERE       DATEDIFF(N, rs.SearchDT, ord.OrderDate) < 5
GROUP BY    DATENAME(WEEKDAY, ord.OrderDate)
ORDER BY    2 DESC
;


/* 
    Segmentate orders that included Gardens, By geography.
    Order by count in descending order.
    # extract city from text (the value after the 3rd ,): COALESCE(LTRIM(CAST(('<X>'+REPLACE(ord.Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[3]', 'varchar(128)')), '')
*/
SELECT      
            CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(ord.Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[3]', 'varchar(128)')), '') AS varchar(128)) AS city,
            COUNT(inc.OrderID) AS count_garden_orders
FROM        dbo.INCLUSIONS AS inc
            INNER JOIN dbo.GARDENS AS grd
                ON inc.Name = grd.Name
            INNER JOIN dbo.ORDERS AS ord
                ON inc.OrderID = ord.OrderID
GROUP BY    CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(ord.Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[3]', 'varchar(128)')), '') AS varchar(128))
ORDER BY    2 DESC
;

