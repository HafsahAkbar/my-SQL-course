SELECT
    TOP 25 p.TransactionDate
    , p.Price
    , p.PostCode
    , p.PAON
    , pt.PropertyTypeName
FROM
    PricePaidSW12 p
LEFT JOIN PropertyTypeLookup pt ON p.PropertyType = pt.PropertyTypeCode
WHERE
    p.Street = 'ORMELEY ROAD'
ORDER BY
    p.TransactionDate DESC;
    -- top 25 transactions on ormely road, joiing multiple tables, showing data on price, postcode etc