CREATE VIEW income_per_seed_as_simple_product AS 
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