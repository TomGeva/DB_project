CREATE VIEW income_per_seed_from_designs_per_order AS 
    /*
        find the income and quantity of each seed for each garden design sold in the last quarter
    */
    SELECT      Seed = C.Seed,
                TotalIncome = (PRD.Price - PRD.Discount) * DSG.Quantity * C.Quantity / SUM(C.Quantity) OVER (PARTITION BY DSG.Name, DSG.DesignID),
                QuantitySold = C.Quantity*DSG.Quantity
    FROM        dbo.DESIGNS AS DSG
                JOIN dbo.CHOSENS AS C
                    ON DSG.DesignID = C.Design AND DSG.Name = C.Garden
                JOIN dbo.GARDENS AS G
                    ON DSG.Name = G.Name
                JOIN dbo.PRODUCTS AS PRD
                    ON G.Name = PRD.Name
                JOIN dbo.ORDERS AS O
                    ON DSG.OrderID = O.OrderID
    WHERE       DATEDIFF(QUARTER, O.OrderDate, GETDATE()) = 1

