--drop table #temp1
--drop table #temp2
--drop table #pap

DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

--SET @Start_Date_1 = '20150101'
--SET @End_Date_1 = '20150621'

SET @Start_Date_1 = '20140101'
SET @End_Date_1 = '20161121'

--**********Start data Table Creation***********
--Creates list of all encounters, dx and SIM codes during time period
SELECT pp.enc_id, pp.person_id, 
       pp.diagnosis_code_id_1, pp.diagnosis_code_id_2, pp.diagnosis_code_id_3, pp.diagnosis_code_id_4, 
       pp.service_item_id, pp.service_date
INTO #temp1
FROM patient_procedure pp
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN person	p			  ON pp.person_id = p.person_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1)
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND (pe.clinical_ind = 'Y' AND pe.billable_ind = 'Y')

--Creates temp 2 and concatenates same encounters on multiple rows into a single with all service items 
--drop table #
SELECT enc_id, person_id, service_date,
	(SELECT ' ' + t2.service_item_id
	FROM #temp1 t2
	WHERE t2.enc_id = t1.enc_id
	FOR XML PATH('')) [Service_Item],
	(SELECT ' ' + t2.diagnosis_code_id_1 + ' ' + t2.diagnosis_code_id_2 + ' ' + t2.diagnosis_code_id_3 + ' ' + t2.diagnosis_code_id_4
	FROM #temp1 t2
	WHERE t2.enc_id = t1.enc_id
	FOR XML PATH('')) [dx]
INTO #temp2
FROM #temp1 t1
GROUP BY t1.enc_id, t1.person_id, service_date

SELECT DISTINCT pe.enc_nbr, pm.payer_name AS 'payer', t.service_date --pp.policy_nbr, 
FROM #temp2 t
JOIN encounter_payer ep ON t.enc_id	    = ep.enc_id
JOIN patient_encounter pe ON pe.enc_id = t.enc_id
JOIN payer_mstr pm		ON pe.cob1_payer_id = pm.payer_id
--JOIN person_payer pp	ON pp.person_id = t.person_id AND pp.payer_id = pm.payer_id
WHERE Service_Item LIKE '%L079%' AND pm.payer_name IN ('Molina Covered CA'
													  ,'Molina Medical Ctr Medi-Cal Managed Care'
													  ,'Molina Medical Center Commercial')

select * from patient_encounter

SELECT DISTINCT
 (SELECT COUNT (*) FROM #pap WHERE [payer] = 'Desert Oasis Health Care') AS 'Desert Oasis Health Care'
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Molina Medical Ctr Medi-Cal Managed Care') AS 'Molina Medical Ctr Medi-Cal Managed Care'  
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Cigna Chattanooga Commercial') AS 'Cigna Chattanooga Commercial'  
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Cigna San Diego Commercial') AS 'Cigna San Diego Commercial'
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Blue Cross Commercial') AS 'Blue Cross Commercial'  
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Healthnet Commercial') AS 'Healthnet Commercial' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Vantage Medi-Cal Managed Care') AS 'Vantage Medi-Cal Managed Care' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Inland Empire Health Plan Commercial') AS 'Inland Empire Health Plan Commercial' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Childrens Phys MG-Radys Medi-Cal Managed') AS 'Childrens Phys MG-Radys Medi-Cal Managed' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Healthnet Medi-Cal Managed Care') AS 'Healthnet Medi-Cal Managed Care' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Primary Care Assoc Med Grp Commercial') AS 'Primary Care Assoc Med Grp Commercial' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Inland Empire Health Plan Medi-Cal Manag') AS 'Inland Empire Health Plan Medi-Cal Manag' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Molina Medical Center Commercial') AS 'Molina Medical Center Commercial' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Multicultural Med Grp Medi-Cal Managed C') AS 'Multicultural Med Grp Medi-Cal Managed C' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Community Health Group Medi-Cal Managed') AS 'Community Health Group Medi-Cal Managed' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'LaSalle Medical Assoc Commercial') AS 'LaSalle Medical Assoc Commercial' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Care First Health Plan Medi-Cal Managed') AS 'Care First Health Plan Medi-Cal Managed' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'ZZDO NOT USE Plan Now Pay Later "D"') AS 'ZZDO NOT USE Plan Now Pay Later "D"' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'LA Care Health Plan Commercial') AS 'LA Care Health Plan Commercial' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Blue Shield Of California Commercial') AS 'Blue Shield Of California Commercial' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Molina Covered CA')  AS 'Molina Covered CA' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Healthnet Covered CA')  AS 'Healthnet Covered CA' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Misc Ins')  AS 'Misc Ins' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Exclusive Care Commercial') AS 'Exclusive Care Commercial' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'United Healthcare Salt Lake Commercial') AS 'United Healthcare Salt Lake Commercial' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Aetna San Diego Commercial') AS 'Aetna San Diego Commercial' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Blue Cross Covered Ca')  AS 'Blue Cross Covered Ca' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Family PACT') AS 'Family PACT' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Alpha Care Medi-Cal Managed Care')  AS 'Alpha Care Medi-Cal Managed Care' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Tricare Commercial')  AS 'Tricare Commercial' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Inland Valley IPA Commercial') AS 'Inland Valley IPA Commercial' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Aetna Lexington Commercial') AS 'Aetna Lexington Commercial' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'United Healthcare Commercial') AS 'United Healthcare Commercial' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Cigna HealthPartners Commercial')  AS 'Cigna HealthPartners Commercial' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Inland Faculty Medical Group Commercial')  AS 'Inland Faculty Medical Group Commercial' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Medi-Cal')  AS 'Medi-Cal' 
,(SELECT COUNT (*) FROM #pap WHERE [payer] = 'Blue Shield Covered CA') AS 'Blue Shield Covered CA' 
FROM #pap