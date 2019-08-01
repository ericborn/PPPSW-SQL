--============================================= 
-- Author: Eric Born
-- Create Date: 09/01/2017
-- Numerator: Number of females 15-44 who had an abortion within 1 year of their last non-abortion visit
-- Denominator: All females 15-44 at risk of UP who had a visit in the analysis period, excluding females who had an abortion visit on the same day
--				excluding visits where patient had a positive pregnancy test
-- Modified by:
-- Modifications:
-- =============================================

--***Drop temp tables***
--DROP TABLE #temp1
--DROP TABLE #year_plus
--DROP TABLE #preg
--DROP TABLE #main
--DROP TABLE #ab
--DROP TABLE #ab_max

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

--Creates list of all encounters and SIM codes during the year following the defined time period
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

--***Find all AB related visits during report period***
SELECT DISTINCT person_nbr, service_date
INTO #ab
FROM #temp1 t
WHERE 
   (
	 Service_Item_id = '59840A'
OR	 Service_Item_id LIKE '59841[C-N]'
OR	 Service_Item_id = 'S0199'
OR	 Service_Item_id = 'S0199A'
OR	 Service_Item_id = '99214PME'
	)
GROUP BY  person_nbr, service_date

--***Identify all positive pregnancy test patients***
SELECT DISTINCT t.person_nbr, t.service_date
INTO #preg
FROM #temp1 t
JOIN ngprod.dbo.order_ o ON o.encounterID = t.enc_id
WHERE service_item_id = '81025K' AND actText LIKE '%preg%' AND obsValue = 'positive'

--***Create main table***
--Does not include encounters since there can be multiple in a day
CREATE TABLE #main
(
	 [person_id] UNIQUEIDENTIFIER
	,[person_nbr] VARCHAR(30)
	,[age] INT
	,[Visit_Date] DATE
	,[AB_Date] DATE
)

--***Insert all unique patient visits into the table who had a visit during the reporting period***
INSERT INTO #main 
SELECT DISTINCT 
	 person_id
	,person_nbr
	,NULL
	,service_date
	,NULL
FROM #temp1

--***Remove all visits where a positive pregnancy test was found***
DELETE 
FROM #main
WHERE EXISTS
(
SELECT *
FROM #preg p
WHERE p.person_nbr = #main.person_nbr AND p.service_date = #main.[Visit_Date]
)

--***Deletes from main table if patient had a MAB/TAB/PME on the same day***
DELETE 
FROM #main
WHERE EXISTS
(
SELECT *
FROM #ab a
WHERE a.person_nbr = #main.person_nbr AND a.service_date = #main.[Visit_Date]
)

--***Calculate age at from DOS***
UPDATE #main
SET age = CAST((CONVERT(INT,CONVERT(CHAR(8),[Visit_Date],112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar)
FROM #main f
JOIN ngprod.dbo.person p ON p.person_id = f.person_id

--***Delete patients below 15 or over 44***
DELETE FROM #main
WHERE age < 15 OR age > 44

--***Find all AB related visits within 1 year after the reporting period***
SELECT DISTINCT person_nbr, service_date
INTO #ab_max
FROM #year_plus
WHERE 
   (
	 Service_Item_id = '59840A'
OR	 Service_Item_id LIKE '59841[C-N]'
OR	 Service_Item_id = 'S0199'
OR	 Service_Item_id = 'S0199A'
OR	 Service_Item_id = '99214PME'
	)
GROUP BY  person_nbr, service_date

--***Update main with most recent ab date***
UPDATE #main
SET [AB_Date] = a.service_date
FROM #ab_max a
JOIN #main m ON m.person_nbr = a.person_nbr
WHERE a.person_nbr = m.person_nbr 
AND a.service_date <= DATEADD(year, 1, m.Visit_date)

--***Output gathers patients earliest date during reporting period***
SELECT DISTINCT person_nbr, visit_date, AB_Date
FROM #main m
INNER JOIN
	(SELECT person_id, MIN(visit_date) AS MINDATE
	 FROM #main
	 GROUP BY person_id) grouped
ON m.person_id = grouped.person_id AND m.visit_date = grouped.MINDATE 