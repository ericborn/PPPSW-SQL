--drop table #a

SELECT pm.description, specialty_code_1, COUNT(enc_id) AS [visit]
INTO #a
FROM patient_encounter pe
JOIN provider_mstr pm ON pm.provider_id = pe.rendering_provider_id
WHERE enc_timestamp >= '20170801' AND enc_timestamp <= '20170831'
AND (specialty_code_1 = 'np' OR specialty_code_1 = 'pa') AND pm.delete_ind = 'n'
GROUP BY pm.description, specialty_code_1

alter table #a ADD totes varchar(100)

SELECT description,
CASE
	WHEN specialty_code_1 = 'pa' AND visit > 5 THEN CAST(ROUND([visit] * 0.05, 0) AS DECIMAL (18,0))
	WHEN specialty_code_1 = 'np' AND visit > 5 THEN 5
	ELSE visit
END AS 'visit'
FROM #a