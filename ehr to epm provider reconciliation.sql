SELECT DISTINCT pe.enc_nbr, pm.description AS 'EPM Rendering', pm2.description AS 'EHR Rendering'
FROM patient_procedure pp
JOIN charges c ON pp.enc_id = c.source_id
JOIN provider_mstr pm ON pm.provider_id = rendering_id
JOIN provider_mstr pm2 ON pm2.provider_id = pp.provider_id
JOIN patient_encounter pe ON pe.enc_id = pp.enc_id
WHERE service_date >= '20170101' and pp.provider_id != rendering_id
order by enc_nbr