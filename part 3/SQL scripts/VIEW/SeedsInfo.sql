CREATE VIEW SeedsInfo AS 
    SELECT  Seed = sd.Name, 
            sd.Season, 
            [Seed Size] = sd.[Size], 
            [Sun Amount] = sd.Sun_amount, 
            [Seed Type] = STRING_AGG([Type], ', ') 
    FROM dbo.SEEDS AS sd
    INNER JOIN dbo.SEED_TYPES tp
        ON sd.Name = tp.Name
    GROUP BY sd.Name, sd.Season, sd.[Size], sd.Sun_amount