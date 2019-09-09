SELECT COUNT(distinct brsq.enc_id)
FROM patient_encounter pe
JOIN person p ON p.person_id = pe.person_id
LEFT JOIN PPPS_BRSQ_ brsq
	ON pe.enc_id = brsq.enc_id
WHERE pe.create_timestamp >= '20161001' and pe.create_timestamp <= '20170930' 
AND p.sex = 'F' 