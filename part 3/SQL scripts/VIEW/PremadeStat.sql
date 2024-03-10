CREATE VIEW PremadeStat AS 
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