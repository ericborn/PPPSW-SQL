--***Start ENC Payer***
--18104

SELECT DISTINCT pe.enc_id, lm.location_name,pe.create_timestamp, ngprod.dbo.zz_pp_ufn_GetAge(ps.date_of_birth,pe.billable_timestamp)as age, --pm.payer_name, 
pp.service_item_id, pp.service_item_desc, [finclass] = null, pe.cob1_payer_id
INTO #temp2
from patient_procedure pp
join patient_encounter pe on pe.enc_id = pp.enc_id
join location_mstr lm on lm.location_id = pe.location_id
join person ps on ps.person_id = pe.person_id
--join payer_mstr pm on pm.payer_id = pe.cob1_payer_id
where (pp.service_item_id like '%J7300%' or pp.service_item_id like '%J7297%' or pp.service_item_id like '%J7298%' or pp.service_item_id like '%J7301%'
or pp.service_item_id like '%J7302%' or pp.service_item_id like '%J7307%') and pe.create_timestamp >= '2016-05-01 00:00:00.000'

--select * from payer_mstr

--SELECT pp.enc_id, pp.person_id, p.sex,
--       pp.diagnosis_code_id_1, pp.diagnosis_code_id_2, pp.diagnosis_code_id_3, pp.diagnosis_code_id_4, 
--       pp.service_item_id, pp.service_date, pp.location_id, cob1_payer_id
--INTO #temp1
--FROM patient_procedure pp
--JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
--JOIN person	p			 ON pp.person_id = p.person_id
--WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1) 
--AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
--AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
--AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --Clinical services and Lab locations are excluded
--						 --'966B30EA-F24F-48D6-8346-948669FDCE6E' Online services included in totals


UPDATE #temp2
SET [finClass] = '4110'
WHERE #temp2.cob1_payer_id IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #temp2 t ON t.cob1_payer_id = pm.payer_id
WHERE financial_class = 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF'
)
--Medi-Cal Managed Care-4130
UPDATE #temp2
SET [finClass] = '4130'
WHERE #temp2.cob1_payer_id IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #temp2 t ON t.cob1_payer_id = pm.payer_id
WHERE financial_class = '484A05B3-D5C8-415B-A8EE-3D14A7AF11D6'
)
--Medi-cal
UPDATE #temp2
SET [finClass] = '4120'
WHERE #temp2.cob1_payer_id IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #temp2 t ON t.cob1_payer_id = pm.payer_id
WHERE financial_class = 'C5BDDA12-DDC9-4CFF-A0A3-9749C7DD353D'
)
--Commercial
UPDATE #temp2
SET [finClass] = '4300'
WHERE #temp2.cob1_payer_id IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #temp2 t ON t.cob1_payer_id = pm.payer_id
WHERE financial_class = '8E5D6C7E-A34E-4B3C-8C0A-B2F1D2E20285' OR financial_class = '332DF613-7C43-4287-9050-9949B4142B0C'
)
--Cash does not have a financial class so it will be represented as NULL in the payer_id column
UPDATE #temp2
SET [finClass] = '0000'
WHERE #temp2.cob1_payer_id IS NULL

alter table #temp2
drop column cob1_payer_id, enc_id

select * from #temp2
order by create_timestamp
