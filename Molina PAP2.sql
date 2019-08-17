--drop table #temp1
--drop table #temp2
--drop table #lab

DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

--SET @Start_Date_1 = '20140101'
--SET @End_Date_1 = '20150621'

SET @Start_Date_1 = '20130101'
SET @End_Date_1 = '20170106'

--**********Start data Table Creation***********
--Creates list of all encounters, dx and SIM codes during time period
SELECT pp.enc_id, pp.person_id, p.first_name, p.last_name, p.middle_name, p.date_of_birth, p.ssn, pm.national_provider_id AS 'NPI',
       pp.diagnosis_code_id_1, pp.diagnosis_code_id_2, pp.diagnosis_code_id_3, pp.diagnosis_code_id_4, 
       pp.service_item_id, pp.service_date, pat.med_rec_nbr AS 'MRN', LEFT(perpay.policy_nbr, 9) AS 'Patient Medicaid Number'
INTO #temp1
FROM patient_procedure pp
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN patient pat ON pp.person_id = pat.person_id
JOIN person	p			  ON pp.person_id = p.person_id
JOIN provider_mstr pm ON pm.provider_id = pp.provider_id
JOIN payer_mstr pay		ON pe.cob1_payer_id = pay.payer_id
JOIN person_payer perpay	ON pp.person_id = perpay.person_id AND pay.payer_id = perpay.payer_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1)
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND (pe.clinical_ind = 'Y' AND pe.billable_ind = 'Y')
AND pay.payer_name IN ('Molina Covered CA','Molina Medical Ctr Medi-Cal Managed Care','Molina Medical Center Commercial')
--AND pay.payer_name IN ('California Health And Wellness')

--SELECT DISTINCT t1.enc_id, t1.person_id, t1.first_name, t1.last_name, t1.middle_name, t1.date_of_birth, t1.ssn, t1.NPI,
--       t2.service_item_id, t1.service_date, t1.MRN, t1.diagnosis_code_id_1, t1.diagnosis_code_id_2, t1.diagnosis_code_id_3, t1.diagnosis_code_id_4
----INTO #temp2
--FROM #temp1 t1
--INNER JOIN #temp1 t2
--ON t1.enc_id = t2.enc_id
--GROUP BY enc_id, person_id, first_name, last_name, middle_name, date_of_birth, ssn, NPI,
--       service_item_id, service_date, MRN

--select distinct * 
--from #temp2
--order by person_id

--Creates temp 2 and concatenates same encounters on multiple rows into a single with all service items 
--SELECT DISTINCT enc_id, person_id, first_name, last_name, middle_name, date_of_birth, ssn, NPI,
--       service_date, MRN,
--	(SELECT DISTINCT ' ' + t2.service_item_id
--	FROM #temp1 t2
--	WHERE t2.enc_id = t1.enc_id
--	FOR XML PATH('')) [Service_Item],
--	(SELECT DISTINCT '' + t2.diagnosis_code_id_1 + ' ' + t2.diagnosis_code_id_2 + ' ' + t2.diagnosis_code_id_3 + ' ' + t2.diagnosis_code_id_4
--	FROM #temp1 t2
--	WHERE t2.enc_id = t1.enc_id
--	FOR XML PATH('')) [dx]
--INTO #temp2
--FROM #temp1 t1
--GROUP BY enc_id, person_id, first_name, last_name, middle_name, date_of_birth, ssn, NPI,
--       service_item_id, service_date, MRN

--***********************ENCOUNTER DATA TABLE***********************
SELECT DISTINCT t.MRN, [Patient Medicaid Number], t.last_name, t.first_name, t.middle_name, t.date_of_birth --2332
,t.ssn, t.npi, '' AS 'Claim number', t.service_date, t.diagnosis_code_id_1, t.diagnosis_code_id_2, t.diagnosis_code_id_3, t.diagnosis_code_id_4,
'' AS [RevenueCode], '' AS [OccuranceCode], '' AS [ProcedureCode]
,CASE
	WHEN t.service_item_id LIKE '%L079%' THEN '88104'
	WHEN t.service_item_id LIKE '%L034%' THEN '88108'
	WHEN t.service_item_id LIKE '%L124%' THEN '88104'
END AS 'CPT'
FROM #temp1 t
JOIN lab_nor nor			ON t.enc_id	= nor.enc_id
JOIN lab_results_obr_p obr  ON nor.order_num	= obr.ngn_order_num
JOIN lab_results_obx obx	ON obx.unique_obr_num	= obr.unique_obr_num
--JOIN person_payer perpay	ON t.person_id = perpay.person_id AND pay.payer_id = perpay.payer_id
WHERE (service_item_id LIKE '%L079%' OR service_item_id LIKE '%L034%' OR service_item_id LIKE '%L124%')
AND obr.test_desc LIKE '%pap%' AND obx.result_desc LIKE '%DIAGNOSIS%'
order by service_date

--***********************LAB DATA TABLE***********************
SELECT DISTINCT t.MRN, [Patient Medicaid Number], t.last_name, t.first_name, t.middle_name, t.date_of_birth --2327
,t.ssn, t.npi, '' AS 'Claim number', t.service_date
,CASE
	WHEN service_item_id LIKE '%L079%' THEN '88104'
	WHEN service_item_id LIKE '%L124%' THEN '88104'
	WHEN service_item_id LIKE '%L034%' THEN '88108'
END AS 'CPT'
, obr.loinc_code AS 'LOINC'
,CASE
	WHEN obx.result_comment LIKE 'NEGATIVE%' THEN 'Negative'
	WHEN obx.result_comment LIKE 'EPITHELIAL%' THEN 'Cell Abnormality'
	ELSE 'Unsatisfactory'
END AS 'Result'
--,LEFT (CONCAT (obx.result_desc, ' ', obx.result_comment), 100) AS 'Result'
FROM #temp1 t
JOIN lab_nor nor			ON t.enc_id	= nor.enc_id
JOIN lab_results_obr_p obr  ON nor.order_num	= obr.ngn_order_num
JOIN lab_results_obx obx	ON obx.unique_obr_num	= obr.unique_obr_num
WHERE (service_item_id LIKE '%L079%' OR service_item_id LIKE '%L034%')
AND (obr.test_desc LIKE '%pap%' AND obx.result_desc LIKE '%DIAGNOSIS%')
order by MRN




select * from payer_mstr