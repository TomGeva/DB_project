
CREATE VIEW   income_per_seed_from_premade_per_order AS
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
