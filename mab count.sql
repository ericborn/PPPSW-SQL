DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

SET @Start_Date_1 = '20160701'
SET @End_Date_1 = '20170630'

--**********Start data Table Creation***********
--Creates list of all encounters, dx and SIM codes during time period
SELECT pp.enc_id, pp.person_id, lm.location_name,
       pp.service_item_id, pp.service_date, p.date_of_birth, p.race, p.sex, units
INTO #temp1
FROM patient_procedure pp
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN location_mstr lm     ON lm.location_id = pp.location_id
JOIN person	p			  ON pp.person_id = p.person_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1)
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --Clinical services and Lab locations are excluded

select COUNT(enc_id) 
from #temp1
where (service_item_id LIKE '%S0199%' --MAB
OR service_item_id LIKE '%S0199A%') --MAB 
AND location_name LIKE 'RIVER%'
