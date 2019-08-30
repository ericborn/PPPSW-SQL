--============================================= 
-- Author: Eric Born
-- Create Date: 09/01/2017
-- Numerator: Number of females 15-44 who had an abortion within one year of their last abortion visit
-- Denominator: All females 15-44 who had an abortion visit during the analysis period
-- Modified by:
-- Modifications:
-- =============================================

--***Drop temp tables***
--DROP TABLE #temp1
--DROP TABLE #year_plus
--DROP TABLE #preg
--DROP TABLE #main
--DROP TABLE #ab1
--DROP TABLE #ab2

--***Declare and set our variables***
DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 datetime

SET @Start_Date_1 = '20161001'
SET @End_Date_1 = '20161231'

--**********Start data Table Creation***********
--Creates list of all encounters and SIM codes during time period
SELECT DISTINCT pp.enc_id, pp.person_id, p.sex, pp.service_date, pe.enc_nbr, p.person_nbr, p.date_of_birth, pp.service_item_id
INTO #temp1
FROM ngprod.dbo.patient_procedure pp
JOIN ngprod.dbo.patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN ngprod.dbo.person	p			 ON pp.person_id = p.person_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1) 
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND p.sex = 'f'
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD'
						  ,'966B30EA-F24F-48D6-8346-948669FDCE6E') --Clinical, Online services and Lab locations are excluded
AND    (
	 Service_Item_id = '59840A'
OR	 Service_Item_id LIKE '59841[C-N]'
OR	 Service_Item_id = 'S0199'
OR	 Service_Item_id = 'S0199A'
	)

--Creates list of all AB related encounters during the year following the defined time period
--Accomplished by using the last day of the previously defined reporting period then adding one year to that date as the furthest future date
SELECT DISTINCT pp.enc_id, pp.person_id, p.sex, pp.service_date, pe.enc_nbr, p.person_nbr, p.date_of_birth, pp.service_item_id
INTO #year_plus
FROM ngprod.dbo.patient_procedure pp
JOIN ngprod.dbo.patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN ngprod.dbo.person	p			 ON pp.person_id = p.person_id
WHERE (pp.service_date >= @End_Date_1 AND pp.service_date <= DATEADD(YEAR,1,@End_Date_1)) 
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND p.sex = 'f'
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD'
						  ,'966B30EA-F24F-48D6-8346-948669FDCE6E') --Clinical, Online services and Lab locations are excluded
AND    (
	 Service_Item_id = '59840A'
OR	 Service_Item_id LIKE '59841[C-N]'
OR	 Service_Item_id = 'S0199'
OR	 Service_Item_id = 'S0199A'
	)

--***Create main table***
CREATE TABLE #main
(
	 [person_id] UNIQUEIDENTIFIER
	,[person_nbr] VARCHAR(30)
	,[age] INT
	,[AB1] DATE
	,[AB2] DATE
	,[Diff] INT
)

--***Insert all of the related encounters into the table***
INSERT INTO #main 
SELECT DISTINCT 
	 person_id
	,person_nbr
	,NULL
	,NULL
	,NULL
	,NULL
FROM #temp1

--***Update main with most recent encounter***
UPDATE #main
SET [AB1] = MAXDATE
FROM #temp1 t
INNER JOIN
	(SELECT person_id, MAX(service_date) AS MAXDATE
	 FROM #temp1
	 GROUP BY person_id) grouped
ON t.person_id = grouped.person_id AND t.service_date = grouped.MAXDATE 
WHERE t.person_id = #main.person_id

--***Calculate age at from DOS***
UPDATE #main
SET age = CAST((CONVERT(INT,CONVERT(CHAR(8),[AB1],112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar)
FROM #main f
JOIN ngprod.dbo.person p ON p.person_id = f.person_id

--***Delete patients below 15 or over 44***
DELETE FROM #main
WHERE age < 15 OR age > 44

--***Update main with most recent encounter***
UPDATE #main
SET [AB2] = MINDATE
--SELECT m.person_nbr, MINDATE, m.AB1
FROM #year_plus y
JOIN #main m ON m.person_nbr = y.person_nbr
INNER JOIN
	(SELECT person_id, MIN(service_date) AS MINDATE
	 FROM #year_plus
	 GROUP BY person_id) grouped
ON y.person_id = grouped.person_id AND y.service_date = grouped.MINDATE 
WHERE m.person_nbr = y.person_nbr AND MINDATE > DATEADD(DAY, 29, m.AB1)
AND MINDATE < DATEADD(DAY, 365, m.AB1)

--Drop person_id column
ALTER TABLE #main
DROP COLUMN person_id

--Calculate the difference in days between the first and second abortion
UPDATE #main
SET diff = DATEDIFF(DAY, AB1, AB2)

--***Raw output***
--SELECT * FROM #main
--ORDER BY Diff desc

--***Total single and double AB's calculated output***
SELECT DISTINCT
 (SELECT COUNT(*) FROM #main WHERE AB2 IS NULL) AS 'One AB' 
,(SELECT COUNT(*) FROM #main WHERE AB2 IS NOT NULL) AS 'Two ABs' 
,(SELECT COUNT(*) FROM #main) AS 'Total patients' 
FROM #main