--============================================= 
-- Author: Eric Born
-- Create Date: 06/01/2017
-- Numerator: Number of unique females 15-44  who had a LARC removed within 3 months of insertion at an abortion visit
-- Denominator: Total unique females 15-44 who had a LARC inserted at an abortion visit
-- Modified by:
-- Modifications:
-- =============================================

--***Drop temp tables***
--DROP TABLE #temp1
--DROP TABLE #main
--DROP TABLE #larc
--DROP TABLE #rem

--***Declare and set our variables***
DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 datetime

--3 Months
SET @Start_Date_1 = '20170701'
SET @End_Date_1 = '20170930'

--1 Year
--SET @Start_Date_1 = '20161001'
--SET @End_Date_1 = '20161231'

--**********Start data Table Creation***********
--Creates list of all encounters, dx and SIM codes during time period
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
AND (Service_Item_id = '59840A'
 OR	 Service_Item_id LIKE '59841[C-N]'
 OR  Service_Item_id = 'S0199'
 OR	 Service_Item_id = 'S0199A'
 OR	 Service_Item_id = '99214PME') AND pp.delete_ind = 'N'

SELECT DISTINCT p.person_id, person_nbr, p.service_item_id, p.service_date
INTO #larc
FROM #temp1 t
JOIN ngprod.dbo.patient_procedure p ON t.person_id = p.person_id AND t.service_date = p.service_date
WHERE p.service_item_id IN ('J7297', 'J7298' ,'J7300' ,'J7301' ,'J7302', 'J7307') AND p.delete_ind = 'N'
--select * from #larc

--***Create main table***
CREATE TABLE #main
(
	 [person_id] UNIQUEIDENTIFIER
	,[person_nbr] VARCHAR(30)
	,[age] INT
	,[LARC_Type] VARCHAR (100)
	,[LARC_Insert_Date] DATE
	,[LARC_Status] VARCHAR (10) 
	,[LARC_Removal_Date] DATE
	,[LARC_Duration] INT
)

--***Insert all of the related encounters into the table***
INSERT INTO #main 
SELECT DISTINCT 
	 person_id
	,person_nbr
	,NULL
	,service_item_id
	,service_date
	,'In'
	,NULL
	,NULL
FROM #larc

--***Calculate age at from DOS***
UPDATE #main
SET age = CAST((CONVERT(INT,CONVERT(CHAR(8),LARC_Insert_date,112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar)
FROM #main f
JOIN ngprod.dbo.person p ON p.person_id = f.person_id

--***Delete patients below 15 or over 44***
DELETE FROM #main
WHERE age < 15 OR age > 44

--***Update device name***
UPDATE #main
SET [LARC_Type] = 
	CASE
		WHEN [LARC_Type] = 'J7297' THEN 'Liletta'
		WHEN [LARC_Type] = 'J7298' THEN 'Mirena'
		WHEN [LARC_Type] = 'J7300' THEN 'ParaGuard'
		WHEN [LARC_Type] = 'J7301' THEN 'Skyla'
		WHEN [LARC_Type] = 'J7302' THEN 'Mirena'
		WHEN [LARC_Type] = 'J7307' THEN 'Nexplanon'
		ELSE NULL
	END

--***Update Removal Date***
UPDATE #main
SET LARC_Removal_Date = pp.service_date
FROM ngprod.dbo.patient_procedure pp
JOIN #main m ON m.person_id = pp.person_id
WHERE pp.service_date > m.LARC_Insert_Date
AND service_item_id IN 
(
 '11976' --Implant Removal
,'11977' --Implant Removal
,'58301' --IUD Removal
) 

--Set status to removed when date is present
UPDATE #main
SET LARC_Status = 'Removed'
WHERE LARC_Removal_Date IS NOT NULL

--Calculate Date diff from insert to current date or removal date
SELECT person_id, DATEDIFF(mm, LARC_Insert_date, LARC_Removal_Date) AS [Rem_diff],
DATEDIFF(mm, LARC_Insert_date, GETDATE()) AS [Cur_diff]
INTO #rem
FROM #main

--***Update main with LARC duration where device was removed***
UPDATE #main
SET LARC_Duration = [Rem_diff]
FROM #rem r
WHERE #main.person_id = r.person_id AND LARC_Removal_Date IS NOT NULL

--***Update main with LARC duration where device was NOT removed***
UPDATE #main
SET LARC_Duration = Cur_diff
FROM #rem r
WHERE #main.person_id = r.person_id AND LARC_Removal_Date IS NULL

--Drop person id column for clean output
ALTER TABLE #main
DROP COLUMN person_id

SELECT * FROM #main
order by person_nbr