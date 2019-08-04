--drop table #temp1

DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

SET @Start_Date_1 = '20160101'
SET @End_Date_1 = '20161231'

--Creates list of all encounters, dx and SIM codes during time period
SELECT pp.location_id, pp.enc_id, pp.person_id, pe.enc_nbr,
       pp.service_item_id, pp.service_date, pp.diagnosis_code_id_1, pp.diagnosis_code_id_2, pp.diagnosis_code_id_3, pp.diagnosis_code_id_4 
INTO #temp1
FROM patient_procedure pp
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN person	p			  ON pp.person_id = p.person_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1)
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')

SELECT DISTINCT enc_id, service_item_id, diagnosis_code_id_1, diagnosis_code_id_2, diagnosis_code_id_3, diagnosis_code_id_4  --33310
--enc_nbr, service_date 
FROM #temp1
WHERE service_item_id = '87210' 
AND (diagnosis_code_id_1 = 'N76.0' OR diagnosis_code_id_2 = 'N76.0' OR diagnosis_code_id_3 = 'N76.0' OR diagnosis_code_id_4 = 'N76.0')

 SELECT DISTINCT enc_id, service_item_id, diagnosis_code_id_1, diagnosis_code_id_2, diagnosis_code_id_3, diagnosis_code_id_4  --33310
--enc_nbr, service_date 
FROM #temp1
WHERE service_item_id = '87210' AND
 (diagnosis_code_id_1 LIKE 'A59.0[1-3]' OR diagnosis_code_id_2 LIKE 'A59.0[1-3]' 
 OR diagnosis_code_id_3 LIKE 'A59.0[1-3]' OR diagnosis_code_id_4 LIKE 'A59.0[1-3]')

SELECT DISTINCT enc_id, service_item_id, diagnosis_code_id_1, diagnosis_code_id_2, diagnosis_code_id_3, diagnosis_code_id_4  --33310
--enc_nbr, service_date 
FROM #temp1
WHERE service_item_id = '87210' 
AND (diagnosis_code_id_1 = 'B37.3' OR diagnosis_code_id_2 = 'B37.3' OR diagnosis_code_id_3 = 'B37.3' OR diagnosis_code_id_4 = 'B37.3')


'N76.0' --BV
'B37.3' --Yeast
'A59.01' --Trich
SELECT COUNT(ENC_ID) --1212
--enc_nbr, service_date 
FROM #temp1
WHERE service_item_id = '81000'

SELECT COUNT(ENC_ID) --68654
--enc_nbr, service_date 
FROM #temp1
WHERE service_item_id = '81025k'

SELECT COUNT(ENC_ID) --54500
--enc_nbr, service_date 
FROM #temp1
WHERE service_item_id = '86703'

SELECT COUNT(ENC_ID) --7545
--enc_nbr, service_date 
FROM #temp1
WHERE service_item_id = '85018'

SELECT COUNT(ENC_ID) --12459
--enc_nbr, service_date 
FROM #temp1
WHERE service_item_id = '81002'

select * from patient_procedure
WHERE diagnosis_code_id_1 LIKE '%a59%'