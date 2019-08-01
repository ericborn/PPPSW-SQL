--drop table #a
--drop table #a
DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

--SET @Start_Date_1 = '20150101'
--SET @End_Date_1 = '20150330'

SET @Start_Date_1 = '20150101'
SET @End_Date_1 = '20151231'

SELECT p.person_nbr, lm.location_name--, CONVERT(varchar(8),m.create_timestamp,112) AS [date]
,'age' = CAST((CONVERT(INT,CONVERT(CHAR(8),'20150601',112))-CONVERT(CHAR(8),p.date_of_birth,112))/10000 AS varchar)
INTO #a
FROM master_im_ m
JOIN person p ON p.person_id = m.person_id
JOIN patient_encounter pe ON m.enc_id = pe.enc_id
JOIN location_mstr lm ON lm.location_id = pe.location_id
WHERE (m.create_timestamp >= @Start_Date_1 AND m.create_timestamp <= @End_Date_1)
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND (p.sex = 'F' AND P.date_of_birth > '19591231') --max age f=55
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND txt_birth_control_visitend IN ('Sponge', 'Cervical cap/Diaphragm', 'Female Condom', 'Female Sterilization', 'FAM/NFP',
'Implant','Injection', 'Patch', 'IUC (Copper)', 'IUC (Levonorgestrel)', 'Male Condom', 'Oral (CHC)', 'Oral (POP)', 'Spermicide',
'Ring', 'Vasectomy', 'Other Methods', 'Partner Method')
AND pe.location_id NOT IN ('096B6FF0-ED48-4A6C-95F6-8D37E1474394', '518024FD-A407-4409-9986-E6B3993F9D37')
GROUP BY p.person_nbr, lm.location_name, date_of_birth

--SELECT *
--INTO #t
--FROM #a
--GROUP BY person_nbr, date, location_name, age
--ORDER BY person_nbr, date

SELECT DISTINCT
 (SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Carlsbad Planned Parenthood') AS 'Carlsbad'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Carlsbad Planned Parenthood' AND age < 20) AS 'Carlsbad <20'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Chula Vista Planned Parenthood') AS 'Chula Vista'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Chula Vista Planned Parenthood' AND age < 20) AS 'Chula Vista <20'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'City Heights Planned Parenthood') AS 'City Heights'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'City Heights Planned Parenthood' AND age < 20) AS 'City Heights <20'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Coachella Valley Planned Parenthood') AS 'Coachella Valley'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Coachella Valley Planned Parenthood' AND age < 20) AS 'Coachella Valley <20'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'College Ave Planned Parenthood') AS 'College Ave'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'College Ave Planned Parenthood' AND age < 20) AS 'College Ave <20'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'El Cajon Planned Parenthood') AS 'El Cajon'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'El Cajon Planned Parenthood' AND age < 20) AS 'El Cajon <20'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Escondido Planned Parenthood') AS 'Escondido'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Escondido Planned Parenthood' AND age < 20) AS 'Escondido <20'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Euclid Ave Planned Parenthood') AS 'Euclid Ave'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Euclid Ave Planned Parenthood' AND age < 20) AS 'Euclid Ave <20'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'FA Family Planning Planned Parent') AS 'FAFP'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'FA Family Planning Planned Parent' AND age < 20) AS 'FAFP <20'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'FA Surgical Services Planned Pare') AS 'FASS'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'FA Surgical Services Planned Pare' AND age < 20) AS 'FASS <20'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Imperial Valley Planned Parenthood') AS 'IV'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Imperial Valley Planned Parenthood' AND age < 20) AS 'IV <20'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Kearny Mesa Planned Parenthood') AS 'Kearny Mesa'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Kearny Mesa Planned Parenthood' AND age < 20) AS 'Kearny Mesa <20'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Mira Mesa Planned Parenthood') AS 'Mira Mesa'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Mira Mesa Planned Parenthood' AND age < 20) AS 'Mira Mesa <20'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Mission Bay Planned Parenthood') AS 'Mission Bay'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Mission Bay Planned Parenthood' AND age < 20) AS 'Mission Bay <20'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Moreno Valley Planned Parenthood') AS 'Moreno Valley'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Moreno Valley Planned Parenthood' AND age < 20) AS 'Moreno Valley <20'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'MV Express Planned Parenthood') AS 'MV Express'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'MV Express Planned Parenthood' AND age < 20) AS 'MV Express <20'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Pacific Beach Express Planned Parenthood') AS 'Pacific Beach Express'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Pacific Beach Express Planned Parenthood' AND age < 20) AS 'Pacific Beach Express <20'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Rancho Mirage Planned Parenthood') AS 'Rancho Mirage'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Rancho Mirage Planned Parenthood' AND age < 20) AS 'Rancho Mirage <20'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Riverside Planned Parenthood') AS 'RSFP'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Riverside Planned Parenthood' AND age < 20) AS 'RSFP <20'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'RS Surgical Services Planned Parenthood') AS 'RSSS'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'RS Surgical Services Planned Parenthood' AND age < 20) AS 'RSSS <20'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Vista Planned Parenthood') AS 'Vista'
,(SELECT COUNT(person_nbr) FROM #a WHERE location_name = 'Vista Planned Parenthood' AND age < 20) AS 'Vista <20'
,(SELECT COUNT(person_nbr) FROM #a) AS 'Total Patients'