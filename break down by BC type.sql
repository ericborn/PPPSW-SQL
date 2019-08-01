DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

SET @Start_Date_1 = '20170101'
SET @End_Date_1 = '20170331'

--**********Start data Table Creation***********
--Creates list of all encounters, dx and SIM codes during time period
SELECT pp.enc_id, pp.person_id,
       pp.diagnosis_code_id_1, pp.diagnosis_code_id_2, pp.diagnosis_code_id_3, pp.diagnosis_code_id_4, 
       pp.service_item_id, pp.service_date, pp.location_id, cob1_payer_id
INTO #temp1
FROM patient_procedure pp
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN person	p			 ON pp.person_id = p.person_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1) 
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --Clinical services and Lab locations are excluded
AND p.sex = 'f'						 --'966B30EA-F24F-48D6-8346-948669FDCE6E' Online services included in totals

SELECT pp.person_id, service_date
INTO #temp2
FROM patient_procedure pp
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN person	p			 ON pp.person_id = p.person_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1) 
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --Clinical services and Lab locations are excluded
AND p.sex = 'f'	
GROUP BY pp.person_id, service_date

SELECT DISTINCT
(SELECT COUNT(person_id) 
from #temp2) AS 'Total' 
,(SELECT COUNT(DISTINCT enc_id) 
from #temp1
where
		   service_item_id LIKE '%AUBRA%' --Pill types
		OR service_item_id LIKE '%Brevicon%'
		OR service_item_id LIKE '%CHATEAL%'
		OR service_item_id LIKE '%Cyclessa%'
		OR service_item_id LIKE '%Desogen%'
		OR service_item_id LIKE '%Gildess%'
		OR service_item_id LIKE '%Levora%'
		OR service_item_id LIKE '%LYZA%'
		OR service_item_id LIKE '%Mgestin%'
		OR service_item_id LIKE '%Micronor%'
		OR service_item_id LIKE '%MODICON%'
		OR service_item_id LIKE '%NO777%'
		OR service_item_id LIKE '%nortel%'
		OR service_item_id LIKE '%OCEPT%'
		OR service_item_id LIKE '%ON135%'
		OR service_item_id LIKE '%ON777%'
		OR service_item_id LIKE '%ORCYCLEN%'
		OR service_item_id LIKE '%OTRICYCLEN%'
		OR service_item_id LIKE '%OTRINC%'
		OR service_item_id LIKE '%RECLIPSEN%'
		OR service_item_id LIKE '%Tarina%'
		OR service_item_id LIKE '%Trilo%' --Pill types
) AS 'Pills'
,(SELECT COUNT(DISTINCT enc_id) 
from #temp1
where service_item_id = 'J7303') AS 'Ring' --Ring
,(SELECT COUNT(DISTINCT enc_id) 
from #temp1
where service_item_id = 'J7304' OR service_item_id = 'xulane') AS 'Patch' --Patch

,(SELECT COUNT(DISTINCT enc_id) 
from #temp1
where
service_item_id IN ('J7297', 'J7298', 'J7300', 'J7301', 'J7302')) AS 'IUC' --IUC

,(SELECT COUNT(DISTINCT enc_id) 
from #temp1
where
(service_item_id = 'J7307')) AS 'Implant' --implant

,(SELECT COUNT(DISTINCT enc_id) 
from #temp1
where
(service_item_id = 'J1050')) AS 'Depo' --depo