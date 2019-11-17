--Processed date
SELECT DISTINCT processed_date, facility_lab_name AS 'Clinic' --281008
,SUBSTRING(medical_record_nbr, PATINDEX('%[^0]%', medical_record_nbr+'.'), LEN(medical_record_nbr)) AS 'MRN'
FROM claims c
JOIN claim_requests cr ON cr.claim_id = c.claim_id
WHERE processed_date >= '20160701' AND processed_date <= '20170630'
AND facility_lab_name NOT IN ('Online Health Services','Clinical Services Planned Parenthood', 'PPPSW Lab')
GROUP BY processed_date, facility_lab_name, medical_record_nbr
ORDER BY processed_date, facility_lab_name

--Service date
SELECT DISTINCT service_date, location_name --251285
,SUBSTRING(med_rec_nbr, PATINDEX('%[^0]%', med_rec_nbr+'.'), LEN(med_rec_nbr)) AS 'MRN'
FROM patient_encounter pe
JOIN patient_procedure pp ON pp.enc_id = pe.enc_id
JOIN location_mstr lm ON lm.location_id = pe.location_id
JOIN patient p ON p.person_id = pe.person_id
WHERE service_date >= '20160701' AND service_date <= '20170630'
AND location_name NOT IN ('Online Health Services','Clinical Services Planned Parenthood')
GROUP BY med_rec_nbr, service_date, location_name
ORDER BY service_date, location_name
