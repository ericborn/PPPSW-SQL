--larc at TAB by LARC type
--july 2016 to now
--broken down by location

drop table #temp1

DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

SET @Start_Date_1 = '20160701'
SET @End_Date_1 = '20180131'

--**********Start data Table Creation***********
--Creates list of all encounters, dx and SIM codes during time period
SELECT DISTINCT pp.person_id, p.sex, pp.service_date, location_name, service_item_id, service_item_desc
INTO #temp1
FROM patient_procedure pp
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN person	p			 ON pp.person_id = p.person_id
JOIN location_mstr lm ON lm.location_id = pp.location_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1) 
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --Clinical services and Lab locations are excluded
						 --'966B30EA-F24F-48D6-8346-948669FDCE6E' Online services included in totals

--drop table #t2

SELECT DISTINCT person_id, location_name, service_item_id, service_item_desc, service_date
INTO #t2
FROM #temp1
WHERE Service_Item_id LIKE '%59840A%'
OR	 Service_Item_id LIKE '%59841[C-N]%'

--select * from #t2

SELECT location_name, pp.service_item_id, pp.service_item_desc
,COUNT(pp.service_item_id) AS [count]
--,pp.service_date
,CONCAT(MONTH(pp.service_date), '-', YEAR(pp.service_date)) AS [time]
--,CONCAT(DATEPART(MM, t.service_date), '-', DATEPART(YYYY, t.service_date)) AS [MY]
--CAST(VARCHAR  DATEADD(MONTH, DATEDIFF(MONTH, 0, pp.service_date), 0) AS [date], pp.service_item_id, pp.service_item_desc
FROM #t2 t
JOIN patient_procedure pp ON t.service_date = pp.service_date AND t.person_id = pp.person_id
WHERE pp.Service_Item_id IN ('J7297','J7298','J7300','J7301','J7302','J7307') --IUC
AND location_name != 'FA Family Planning Planned Parent'
GROUP BY location_name, pp.service_item_id, pp.service_item_desc, YEAR(pp.service_date), MONTH(pp.service_date)--, CONCAT(DATEPART(MM, t.service_date), '-', DATEPART(YYYY, t.service_date))
ORDER BY location_name, [time], pp.service_item_id