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
SELECT      chn.Seed, 
            SUM(chn.Quantity) AS total_seed_quan_ordered
FROM        dbo.ORDERS AS ord
            INNER JOIN dbo.INCLUSIONS AS inc
                ON ord.OrderID = inc.OrderID
            INNER JOIN dbo.GARDENS AS grd
                ON inc.Name = grd.Name 
            INNER JOIN dbo.CHOSENS AS chn
                ON chn.Garden = grd.Name

WHERE       DATEDIFF(day, ord.OrderDate, GETDATE()) <= 30 /* orders from the last 30 days */
GROUP BY    chn.Seed
ORDER BY    2 DESC
;


/*  
    Find TOP 5 companies by total orders price.
    The motivation of knowing this information: Suggesting benefits and products for corporate clients.
 */ 
SELECT      TOP 5
            dts.Company, 
            SUM((prd.Price - (prd.Price * prd.Discount/100)) * inc.Quantity) AS total_orders_price,
            COUNT(ord.OrderID) AS count_orders
FROM        dbo.ORDERS AS ord
            INNER JOIN dbo.DETAILS AS dts
                ON (ord.Address = dts.Address AND ord.Name = dts.Name)
            INNER JOIN dbo.INCLUSIONS AS inc
                ON inc.OrderID = ord.OrderID
            INNER JOIN dbo.PRODUCTS AS prd
                ON prd.Name = inc.Name
            
WHERE       dts.Company IS NOT NULL /* only corporate clients */
GROUP BY    dts.Company
ORDER BY    2 DESC
;


/* PART 2 - QUERIES WITH NESTING */

/*
    Find popular search words.
    Motivaition: Detect trends and popular products
*/

SELECT      words.search_word, COUNT(*) AS count_appearances
FROM    
            (
                SELECT LOWER(value) AS search_word
                FROM        dbo.SEARCHES
                CROSS APPLY STRING_SPLIT(Search_text, ' ')
            ) words

WHERE       LEN(words.search_word) > 3
GROUP BY    words.search_word
ORDER BY    2
;


/*
    Which week days had the most orders above the average price?
    Motivation: Post advertisments and discounts on the website on those week days.
*/

SELECT      DATENAME(WEEKDAY, ord.OrderDate) AS order_week_day, COUNT(*) AS num_of_orders
FROM        dbo.ORDERS AS ord    
            INNER JOIN dbo.INCLUSIONS AS inc
                ON inc.OrderID = ord.OrderID
            INNER JOIN dbo.PRODUCTS AS prd
                ON prd.Name = inc.Name
WHERE       (prd.Price - (prd.Price * prd.Discount / 100)) * inc.Quantity > ( /* select orders that their total price is above average */

                                            SELECT  AVG(ord_prices.order_price) AS avg_order_price /* calculate average order price */
                                            FROM
                                                (   /* calculate total price for each order */
                                                    SELECT  inc1.OrderID, SUM((prd1.Price - (prd1.Price * prd1.Discount/100)) * inc1.Quantity) AS order_price
                                                    FROM dbo.INCLUSIONS AS inc1
                                                    INNER JOIN dbo.PRODUCTS AS prd1
                                                        ON prd1.Name = inc1.Name
                                                    GROUP BY inc1.OrderID         

                                                ) AS ord_prices
                                            
                                            )
GROUP BY    DATENAME(WEEKDAY, ord.OrderDate)
;


/* PART 3 - Upgraded Nested Queries */


/* PART 4 - Window Functions */

/* 
    Present TOP 3 seeds (with climate details: sun amount and season) that were sold within per State and City.
    Motivation: Adjust seed marketing per geography / Think of new seeds to sell.

    NOTE: MIGHT NEED SOME CHANGES IN THE TABLES BECAUSE OF THE ADDITION OF "DESIGN" WEAK ENTITY.

*/

SELECT ordered_quants.*
FROM
(
    SELECT      ord_geo.OrderID, ord_geo.State, ord_geo.City, 
                chn.Seed, sd.Season, sd.Sun_amount, SUM(chn.Quantity) AS total_ordered_quantity,
                Rank() over (Partition BY ord_geo.State, ord_geo.City Order BY SUM(chn.Quantity) DESC) AS quantity_rank
    FROM        (
                SELECT      OrderID, 
                            CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[2]', 'varchar(128)')), '') AS varchar(128)) AS State,
                            CAST(COALESCE(LTRIM(CAST(('<X>'+REPLACE(Address,',' ,'</X><X>')+'</X>') AS XML).value('(/X)[3]', 'varchar(128)')), '') AS varchar(128)) AS City
                FROM        dbo.ORDERS
                ) AS ord_geo
                INNER JOIN  dbo.INCLUSIONS AS inc
                    ON inc.OrderID = ord_geo.OrderID
                INNER JOIN dbo.CHOSENS AS chn
                    ON chn.Garden = inc.Name
                INNER JOIN dbo.SEEDS AS sd
                    ON sd.Name = chn.Seed
    GROUP BY    ord_geo.OrderID, ord_geo.State, ord_geo.City, chn.Seed, sd.Season, sd.Sun_amount
) AS ordered_quants

WHERE       ordered_quants.quantity_rank <= 3

ORDER BY    ordered_quants.State, ordered_quants.City, ordered_quants.total_ordered_quantity DESC
;


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

