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

/* 
    For each seed, how many of it were ordered within a garden as quantity, in the last month.
    NOTE TO SELF: IS GOOD. NEED TO ADD MORE DATA THAT'S RELEVANT FOR THIS QUERY.
*/
SELECT      [Seed Name] = PLT.Seed, 
            [Total Seed Quantitity Ordered] = SUM(PLT.Quantity)
FROM        dbo.ORDERS AS O
            JOIN dbo.INCLUSIONS AS I
                ON O.OrderID = I.OrderID
            JOIN dbo.GARDENS AS G
                ON I.Name = G.Name 
            JOIN dbo.PLANTEDS AS PLT
                ON PLT.Garden = G.Name
WHERE       DATEDIFF(day, O.OrderDate, GETDATE()) <= 30 /* orders from the last 30 days */
GROUP BY    PLT.Seed
ORDER BY    [Total Seed Quantitity Ordered] DESC



/*  
    Find TOP 5 companies by total orders price.
    The motivation of knowing this information: Suggesting benefits and products for corporate clients that frequently buy things from the site for the last 6 months
 */ 
SELECT      TOP 5
            Company = DTS.Company, 
            [Total Orders Price] = SUM( CASE WHEN PRD.Price IS NOT NULL THEN (PRD.Price - PRD.Discount) * I.Quantity ELSE 0 END) + 
                                    SUM( CASE WHEN PRD1.Price IS NOT NULL THEN (PRD1.Price - PRD1.Discount) * DSG.Quantity ELSE 0 END), 
            Orders = COUNT(O.OrderID)
FROM        dbo.ORDERS AS O
            JOIN dbo.DETAILS AS DTS
                ON (O.Address = DTS.Address AND O.Name = DTS.Name) 
            LEFT JOIN dbo.INCLUSIONS AS I
                ON I.OrderID = O.OrderID
            JOIN dbo.PRODUCTS AS PRD
                ON PRD.Name = I.Name
            LEFT JOIN dbo.DESIGNS AS DSG
                ON O.OrderID = DSG.OrderID
            JOIN dbo.GARDENS AS G
                ON G.Name = DSG.Name
            JOIN dbo.PRODUCTS AS PRD1
                ON PRD1.Name = G.Name
WHERE       DTS.Company IS NOT NULL /* only corporate clients */
            AND DATEDIFF(MONTH, O.OrderDate, GETDATE()) <= 6 /* orders from the last 6 months */
GROUP BY    DTS.Company
ORDER BY    [Total Orders Price] DESC



/* PART 2 - QUERIES WITH NESTING */

/*
    Find popular search words. (List)
    Motivaition: Detect trends and popular products
*/

SELECT      TOP 10 
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

/* 
    Queary 1, removing details of someone, and if it is not mentioned in the database that it (the details) is in reference of anyone or any order delete it
    economical goal: save money by using less of the database and therefor paying for less.
*/



/* 
    Query 2, what are the top 10 seeds that were ordered within a garden this year, from gardens and from garden designs
*/



/* PART 4 - Window Functions */

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

ORDER BY    State, City, total_ordered_quantity DESC

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
;



/* PART 5 - WITH QUERY */

/* 
    IDEAS
    Inspect Shopping trends by: 
            * Orders and OrdersPrice per weekday and month of the year.
            * Search to Order time per weekday and month of the year.
            * Popular Seed Category.
            * Which seed category is search for per state and city? and compare it to orders of that category in State and City.
                Motivation: Seed preferences according to geographical area and how does the search engine helps to get more orders.\
    THE FOLLOWING CODE IS FOR THE LAST IDEA
*/

WITH geo_for_search (State, City) AS (
    SELECT      DISTINCT
                CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[2]', 'varchar(128)')), '') AS varchar(128)) AS State,
                CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[3]', 'varchar(128)')), '') AS varchar(128)) AS City
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

