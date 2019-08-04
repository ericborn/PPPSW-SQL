--============================================= 
-- Author: Eric Born
-- Create Date: 06/01/2017
-- Numerator: Number of females 15-44 at risk of UP who were using Tier I and Tier II birth control at their last visit
-- Denominator: Total unique females 15-44 at risk of unintended pregnancy
-- Modified by:
-- Modifications:
-- =============================================

--***Drop temp tables***
--DROP TABLE #temp1
--DROP TABLE #main
--DROP TABLE #bcm

DECLARE @Start_Date_1 DATETIME
DECLARE @End_Date_1 DATETIME

--SET @Start_Date_1 = @Start_Date
--SET @End_Date_1 = @End_Date

SET @Start_Date_1 = '20171001'
SET @End_Date_1 = '20171231'

--**********Start data Table Creation***********
--Creates list of all encounters, dx and SIM codes during time period
SELECT DISTINCT pe.person_id, p.sex, pp.service_date, p.person_nbr, p.date_of_birth, im.txt_birth_control_visitend AS 'BCM'
INTO #temp1
FROM ngprod.dbo.patient_procedure pp
JOIN ngprod.dbo.patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN ngprod.dbo.person	p			 ON pp.person_id = p.person_id
JOIN ngprod.dbo.master_im_ im		 ON im.enc_id = pp.enc_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1) 
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND p.sex = 'f'
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --Clinical services and Lab locations are excluded
						 --'966B30EA-F24F-48D6-8346-948669FDCE6E' Online services included in totals

--***Create main reporting table***
CREATE TABLE #main
(
	 person_id UNIQUEIDENTIFIER
	,person_nbr VARCHAR(30)
	,BCM VARCHAR(100)
	,DOS DATE
	,age INT
)

--***Insert distinct patients and latest visit date into table***
INSERT INTO #main
SELECT DISTINCT t.person_id, t.person_nbr, NULL, t.service_date, NULL
FROM #temp1 t
INNER JOIN
	(SELECT person_id, MAX(service_date) AS MAXDATE
	 FROM #temp1
	 GROUP BY person_id) grouped
ON t.person_id = grouped.person_id AND t.service_date = grouped.MAXDATE 

--Built to number rows by patient in the event of two encounters in one day and one not having BCM at end of visit filled out
SELECT t.person_id, ROW_NUMBER() OVER(PARTITION BY t.person_id ORDER BY t.person_id) AS [number], t.BCM
INTO #bcm
FROM #temp1 t
JOIN #main m ON m.person_id = t.person_id AND t.service_date = m.DOS

ALTER TABLE #bcm
ADD [bcm2] VARCHAR(100)

--Move bcm in row 2 into new bcm column
UPDATE #bcm
SET bcm2 = bcm
--select * from #bcm
WHERE person_id in
(SELECT person_id
 FROM #bcm
 WHERE number = '2'
) AND number = '2'

--Delete rows that contained second bcm from second encounter in same day
DELETE FROM #bcm
WHERE number = '2'

--Evaluate if first bcm is blank to use second
UPDATE #main
SET #main.BCM = NULLIF(b.bcm, b.bcm2)
FROM #bcm b
WHERE b.person_id = #main.person_id

--***Delete patients who are seeking pregnancy or cannot become pregnant***
DELETE FROM #main
WHERE bcm IN
(
 'Pregnant/Partner Pregnant'
,'Seeking pregnancy'
,'Female Sterilization'
,'Vasectomy'
,'Infertile'
,'Same sex partner'
)

--Set age by comparing DOS to DOB
UPDATE #main
SET age = CAST((CONVERT(INT,CONVERT(CHAR(8),DOS,112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar)
FROM #main m
JOIN ngprod.dbo.person p ON p.person_id = m.person_id

--***Delete patients below 15 or over 44***
DELETE FROM #main
WHERE age < 15 OR age > 44

--Drop person_id for cleaner output
ALTER TABLE #main
DROP COLUMN person_id

select * 
from #main
ORDER BY person_nbr