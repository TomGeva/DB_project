CREATE VIEW DesignStat AS 
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