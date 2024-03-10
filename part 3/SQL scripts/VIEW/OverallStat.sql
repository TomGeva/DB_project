CREATE VIEW OverallStat AS 
    /*
        calculate income statistics for each seed over all kinds of sales in the last quarter
    */
    SELECT      Seed = SeedIncome.Seed,
				Season = S.Season,
				Size = S.Size,
				Sun_Amount = S.Sun_amount,
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
				JOIN dbo.SEEDS as S
						ON S.Name = SeedIncome.Seed
    GROUP BY    Seed, PRD.Price - PRD.Discount, Season, Size, Sun_Amount


