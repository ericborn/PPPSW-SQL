drop table #temp1
drop table #temp2

DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

--SET @Start_Date_1 = '20150701' --FY 15-16
--SET @End_Date_1 = '20160630'

SET @Start_Date_1 = '20160701'
SET @End_Date_1 = '20160731'

--**********Start data Table Creation***********
--Creates list of all encounters, dx and SIM codes during time period
SELECT pp.enc_id, pp.person_id, p.sex,
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
						 --'966B30EA-F24F-48D6-8346-948669FDCE6E' Online services included in totals

SELECT DISTINCT
(SELECT COUNT(DISTINCT person_id) 
FROM #temp1
WHERE service_item_id LIKE '%J7300%') AS 'Paragard'

,(SELECT COUNT(DISTINCT person_id)
FROM #temp1
WHERE (service_item_id LIKE '%J7297%' OR service_item_id LIKE '%J7298%' OR service_item_id LIKE '%J7301%' OR service_item_id LIKE '%J7302%'))  AS 'Hormonal'

,(SELECT COUNT(DISTINCT person_id)
FROM #temp1
WHERE (service_item_id LIKE '%J7307%'))  AS 'Implant'