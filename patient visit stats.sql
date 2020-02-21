USE [NGProd]

--DROP TABLE #temp1

DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

SET @Start_Date_1 = '20150101'
SET @End_Date_1 = '20171231'

--**********Start data Table Creation***********
--Creates list of all encounters, dx and SIM codes during time period
SELECT DISTINCT pp.person_id, pe.enc_id, p.sex, pp.service_date, pp.location_id, race, ethnicity, [n/e] = 'n'
INTO #temp1
FROM patient_procedure pp
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN person	p			 ON pp.person_id = p.person_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1) 
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --Clinical services and Lab locations are excluded
						 --'966B30EA-F24F-48D6-8346-948669FDCE6E' Online services included in totals

--CREATE TABLE #min
--(
-- person_id UNIQUEIDENTIFIER
--,min_date DATE
--)

--INSERT INTO #max
--SELECT DISTINCT person_id, NULL
--FROM #temp1



--UPDATE #temp1
--SET [n/e] = 'e'
--WHERE person_id IN
--(
--SELECT pp.person_id
--FROM patient_procedure pp
--JOIN #temp1 t ON pp.person_id = t.person_id
--WHERE t.service_date BETWEEN DATEADD(YEAR, -3, 
--)


--UPDATE #temp2
--SET colpo_date = pp.service_date
--FROM ngprod.dbo.patient_procedure pp
--JOIN #temp2 t2 ON t2.person_id = pp.person_id
--WHERE pp.service_date BETWEEN t2.pap_date AND DATEADD(DD, 91,t2.pap_date)
--AND pp.service_item_id = '57454'


--Counts visits by person by year
WITH #temp1_CTE (person_id, location_id)
AS
(
SELECT person_id, location_id 
FROM #temp1
--WHERE person_id = '6D504C03-46E3-4B31-A2A3-00010D2A77E5'
--order by person_id
)
SELECT person_id, COUNT(person_id)AS Visits--, VisitYear
INTO #year2
FROM #temp1_CTE
GROUP BY person_id

--AVG is rounding down to 1
--select CAST(AVG(visits) AS DECIMAL(10,2)) AS Average, VisitYear
--from #year
--GROUP BY VisitYear


--select visits, VisitYear
--from #year2
--where VisitYear = 2015 AND visits = 1
--order by VisitYear


select COUNT(visits)
from #year2
where visits > 3