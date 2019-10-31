SELECT DISTINCT service_item_id, service_item_desc, COUNT(service_item_id) AS 'count'
FROM patient_procedure pp
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
WHERE service_date >= '20150101' AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y') 
AND service_item_desc NOT LIKE '%tray%'
GROUP BY service_item_id, service_item_desc
ORDER BY service_item_desc DESC