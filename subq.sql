/*
SQL Course
Subqueries Lesson 1 - Self-Contained Subqueries
 
A self-contained subquery is independent of the outer query
It can be executed stand-alone.
It is executed once and the result is used by the outer query.  (As a result, it is generally more efficient than a correlated subquery
*/

/*
This is a scalar subquery returning a single value to use in the WHERE <column> =
List the patient stays with the highest tariff
*/
SELECT
    ps.PatientId
	, ps.Hospital
    , ps.Ward
	, ps.Tariff
FROM
    PatientStay ps
WHERE
	ps.ward in (
    SELECT Distinct Ward
from PatientStay
where ward like '%Surgery' );

/*
This  subquery returns a one column list to use in the WHERE <column> IN (...)
List the patient stays in Surgery wards
*/
SELECT
    ps.PatientId
	, ps.Hospital
	, ps.Ward
	, ps.Tariff
FROM
    PatientStay ps
WHERE
	ps.Ward IN (
	SELECT DISTINCT Ward
FROM dbo.PatientStay
WHERE Ward LIKE '%Surgery' 
	);

/*
* This subqueries are based on a different table to the outer query
*/
SELECT
    h.Hospital
	, h.[Type]
	, h.Reach
FROM
    DimHospital h
WHERE h.Hospital IN (
	SELECT DISTINCT ps.Hospital
FROM PatientStay ps
WHERE ps.Ward = 'Ophthalmology' AND ps.AdmittedDate = '2024-02-26'
	);

SELECT
    *
FROM
    PatientStay ps
WHERE
	ps.Hospital IN (
	SELECT h.Hospital
FROM DimHospital h
WHERE h.[Type] = 'Teaching'
	);

SELECT
    ps.AdmittedDate,
    ps.PatientId
FROM
    PatientStay ps
    INNER JOIN DimHospital dh
    on ps.Hospital = dh.Hospital
where dh.[TYPE] = 'teaching'
/*
This  subquery returns a table so use in the FROM ...
Calculate budget hospital tariffs as 10% more than actuals
*/

SELECT
    hosp.Hospital
	, hosp.HospitalTariff
	, hosp.HospitalTariff * 1.1 AS BudgetTariff
FROM
    (
	SELECT
        ps.Hospital
		, SUM(ps.Tariff) AS HospitalTariff
    FROM
        PatientStay ps
    GROUP BY
		ps.Hospital) hosp;

/*
This subquery returns a table so use in the FROM ...
Calculate the total tariff of the 10 most expensive patients 
i.e. those with the highest tariff 
(Ignore the possible complication that there may be some ties.)
*/
SELECT
    SUM(Top10Patients.Tariff) AS Top10Tariff
FROM
    (
	SELECT
        TOP 10
        ps.PatientId
		, ps.Tariff
    FROM
        PatientStay ps
    ORDER BY
		ps.Tariff DESC) Top10Patients;


with
    cte
    as
    (
        sELECT
            TOP 10
            ps.PatientId
		, ps.Tariff
        FROM
            PatientStay ps
        ORDER BY
		ps.Tariff DESC
    )
select SUM(cte.tariff)
from cte


/*
Aside: Another way to do first example (scalar subquery) uses SQL variables
*/
DECLARE @MaxTariff AS INT = (
	SELECT MAX(ps2.Tariff)
FROM PatientStay ps2
	);

SELECT @MaxTariff;

SELECT
    *
FROM
    PatientStay ps
WHERE
	ps.Tariff = @MaxTariff;



---temp table approach

SELECT
    top 10
    ps.PatientId,
    ps.Tariff
into #Top10Patients
From PatientStay ps
order by 
ps.tariff DESC 

SELECT * FROM #Top10Patients





/*
SQL Course
Subqueries Lesson 3
Compare IN  EXISTS and other methods of finding missing values
Land Registry Price Paid dataset
 
Question: which postcodes in SW12 have not had a single property sale since the Land Registry records begin?
Table PostcodeSW12, from the ONS, contains every postcode in SW12
The pcds column matches the PricePaidSW12.PostCode column. pcds is a unique key.
This is the post code format with a single space between the two parts.
The PostcodeSW12 contains lots of other attributes for the post code e.g. lat and long
*/
 
-- sample the data
 
SELECT TOP 10 * FROM PostcodeSW12;
 
SELECT TOP 10 * FROM PricePaidSW12;
 
 
/*
NOT IN self-contained query approach
*/

SELECT pcds FROM PostcodeSW12 c WHERE c.pcds not IN ( SELECT DISTINCT PostCode FROM PricePaidSW12 );
 
/*
NOT EXISTS correlated query approach
*/

SELECT
    pcds
FROM PostcodeSW12 c
WHERE NOT EXISTS
    (SELECT 1 FROM PricePaidSW12 WHERE PostCode = c.pcds);
 
  /*
LEFT JOIN approach
 
The LEFT JOIN returns all rows from the PostcodeSW12 table and will return a NULL value for any column on PricePaidSW12
where there is no match.
The query filters rows where a PricePaidSW12 column IS NULL and so returns the postcode without sales
*/
SELECT
    c.pcds
FROM PostcodeSW12 c
    LEFT JOIN PricePaidSW12 p ON c.pcds = p.PostCode
WHERE p.Price IS NULL;
 
/*
EXCEPT approach
*/
SELECT
    pcds
FROM
    PostcodeSW12
EXCEPT
SELECT
    DISTINCT p.PostCode
FROM
    PricePaidSW12 p;
 
-- This statement suggested by a student
SELECT pc.pcds
       , (
           SELECT COUNT(*)FROM PricePaidSW12 pp WHERE pp.PostCode = pc.pcds
       ) AS NumberOfSales
       , (
           SELECT AVG(PP.Price)FROM PricePaidSW12 pp WHERE pp.PostCode = pc.pcds
       ) AS AveragePrice
FROM PostcodeSW12 pc
ORDER BY NumberOfSales DESC;
 
-- more usual formulation with join
SELECT
    pc.pcds
    , COUNT(*) AS NumberOfSales
    , AVG(pp.Price) AS AveragePrice
FROM
    PostcodeSW12 pc
INNER JOIN PricePaidSW12 pp ON pc.pcds = pp.PostCode
GROUP BY
    pcds
ORDER BY
    NumberOfSales DESC;