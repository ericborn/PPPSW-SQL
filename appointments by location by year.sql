--by enc
drop table #enc

DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

SET @Start_Date_1 = '20160101'
SET @End_Date_1 = '20161231'

--Build enc table by person per location per day
;WITH enc AS (
SELECT DISTINCT pe.person_id, pe.enc_id, pp.service_date, pe.location_id,
RN = ROW_NUMBER() OVER (PARTITION BY pe.person_id, CONVERT(VARCHAR(8),enc_timestamp,112) ORDER BY pe.person_id)
FROM patient_encounter pe
JOIN person p  ON pe.person_id = p.person_id
 
JOIN patient_procedure pp ON pp.enc_id = pe.enc_id
JOIN location_mstr lm ON lm.location_id = pe.location_id
WHERE (service_date >= @Start_Date_1 AND service_date <= @End_Date_1)
AND (billable_ind = 'Y' AND clinical_ind = 'Y')
AND  p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND  pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD'
						   ,'096B6FF0-ED48-4A6C-95F6-8D37E1474394', '7E8F1E17-1FC5-4019-B510-B7D3EC453D82') 
)
SELECT person_id, enc_id, service_date, location_id
INTO #enc --
FROM enc
WHERE RN = 1

select COUNT(enc_id) AS 'Appointments', location_name 
from #enc e
JOIN location_mstr lm ON lm.location_id = e.location_id
group by location_name
order by location_name

/****************************************************/
--by appointment
DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

SET @Start_Date_1 = '20160101'
SET @End_Date_1 = '20161231'

select DISTINCT COUNT(appt_id) AS 'Appointments', location_name
from appointments a
JOIN person p  ON a.person_id = p.person_id
JOIN location_mstr lm ON lm.location_id = a.location_id
where (appt_date >= @Start_Date_1 AND appt_date <= @End_Date_1)
AND  p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND appt_kept_ind = 'y' AND cancel_ind = 'n' AND resched_ind = 'n' AND a.delete_ind = 'n'
GROUP BY location_name
ORDER BY location_name

/****************************************************/