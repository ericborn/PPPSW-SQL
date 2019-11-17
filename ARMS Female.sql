DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

--SET @Start_Date_1 = @Start_Date
--SET @End_Date_1   = @End_Date

SET @Start_Date_1 = '20151001'
SET @End_Date_1 = '20160930'

--**********Start temp table creation***********
--Creates list of all encounters, dx and SIM codes during time period
SELECT pp.location_id, pp.enc_id, pp.person_id,
       pp.diagnosis_code_id_1, pp.diagnosis_code_id_2, pp.diagnosis_code_id_3, pp.diagnosis_code_id_4, 
       pp.service_item_id, pp.service_date, p.date_of_birth, p.race, p.sex--, pe.cob1_payer_id, pp.amount
INTO #temp1
FROM ngprod.dbo.patient_procedure pp
JOIN ngprod.dbo.patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN ngprod.dbo.person	p			 ON pp.person_id = p.person_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1)
--AND pp.location_id = @location_1
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')

--grabs most current enc for each patient
SELECT t.enc_id, t.person_id, t.service_date
INTO #date
FROM #temp1 t
INNER JOIN
	(SELECT person_id, MAX(service_date) AS MAXDATE
	 FROM #temp1
	 GROUP BY person_id) grouped
ON t.person_id = grouped.person_id AND t.service_date = grouped.MAXDATE

--Table containing all female contraception patients
SELECT DISTINCT person_id
INTO #fcon
FROM #temp1
WHERE service_item_id IN
	(
		 'AUBRA','Brevicon','CHATEAL','Cyclessa','Desogen','DesogenNC','Gildess','Levora','LEVORANC','LYZA','Mgestin'
		,'MGESTINNC','Micronor','Micronornc','Modicon','NO777','NORTREL','OCEPT','ON135','ON135NC','ON777','ON777NC'
		,'ORCYCLEN','ORCYCLENNC','OTRICYCLEN','OTRINC','RECLIPSEN','Tarina','TRILO','TRILONC' --Pills
		,'J7304','X7728','X7728-ins','X7728-pt' --Patch
		,'J7303' --Ring
		,'J1050' --Depo
		,'J7297','J7298','J7300','J7301','J7302' --IUC
		,'J7307' --Implant
		,'C005' --Diaphragm
		,'B008' --Female Condom
		,'C003' --Female Condom
		,'C001' --Cervical Cap
		,'C006' --Foam
		,'FILM','SPONGE','DENTAL'
	) AND sex = 'F'

--Gathers female patients with a birth control visit type
SELECT DISTINCT t.person_id, t.enc_id, t.service_item_id
INTO #bcm
FROM #temp1 t
JOIN ngprod.dbo.master_im_ m on t.enc_id = m.enc_id
WHERE chiefcomplaint1 IN 
('Reversible Contraception', 'BCM Change', 'Refill/Supplies'
,'Depo re-start','Depo Restart','Dmpa refill','DMPA Restart','DMPA Restart'
,'IUC','IUC retrieval','implant chk','Implant removal','Iuc removal','IUD check','IUD Removal'
,'OC Refill','iuc chk','Implant Insert','Implant Removal/Re-Insert','IUC Insert') 
OR chiefcomplaint2 IN 
('Reversible Contraception', 'BCM Change', 'Refill/Supplies'
,'Depo re-start','Depo Restart','Dmpa refill','DMPA Restart','DMPA Restart'
,'IUC','IUC retrieval','implant chk','Implant removal','Iuc removal','IUD check','IUD Removal'
,'OC Refill','iuc chk','Implant Insert','Implant Removal/Re-Insert','IUC Insert') 
OR chiefcomplaint3 IN 
('Reversible Contraception', 'BCM Change', 'Refill/Supplies'
,'Depo re-start','Depo Restart','Dmpa refill','DMPA Restart','DMPA Restart'
,'IUC','IUC retrieval','implant chk','Implant removal','Iuc removal','IUD check','IUD Removal'
,'OC Refill','iuc chk','Implant Insert','Implant Removal/Re-Insert','IUC Insert') 
OR chiefcomplaint5 IN 
('Reversible Contraception', 'BCM Change', 'Refill/Supplies'
,'Depo re-start','Depo Restart','Dmpa refill','DMPA Restart','DMPA Restart'
,'IUC','IUC retrieval','implant chk','Implant removal','Iuc removal','IUD check','IUD Removal'
,'OC Refill','iuc chk','Implant Insert','Implant Removal/Re-Insert','IUC Insert') 
OR chiefcomplaint6 IN 
('Reversible Contraception', 'BCM Change', 'Refill/Supplies'
,'Depo re-start','Depo Restart','Dmpa refill','DMPA Restart','DMPA Restart'
,'IUC','IUC retrieval','implant chk','Implant removal','Iuc removal','IUD check','IUD Removal'
,'OC Refill','iuc chk','Implant Insert','Implant Removal/Re-Insert','IUC Insert') 
AND sex = 'f'

--Gathers distinct females who had a BCM visit type and received condoms but not another type of BC
SELECT DISTINCT person_id
INTO #bcm1
FROM #bcm
WHERE service_item_id IN
('24CON-NC','10CON','30CON','30CON-NC','C002','12CON-NC','C002-INS','C002-PT','12CON','24CON','10CON'
,'48CON','10CON-NC','30CON','24CON-NC','12CON','C002','12CON','24CON','24CON','30CON-NC','12CON-NC','12CON','C002NC')
AND service_item_id not IN
	(
		 'AUBRA','Brevicon','CHATEAL','Cyclessa','Desogen','DesogenNC','Gildess','Levora','LEVORANC','LYZA','Mgestin'
		,'MGESTINNC','Micronor','Micronornc','Modicon','NO777','NORTREL','OCEPT','ON135','ON135NC','ON777','ON777NC'
		,'ORCYCLEN','ORCYCLENNC','OTRICYCLEN','OTRINC','RECLIPSEN','Tarina','TRILO','TRILONC' --Pills
		,'J7304','X7728','X7728-ins','X7728-pt' --Patch
		,'J7303' --Ring
		,'J1050' --Depo
		,'J7297','J7298','J7300','J7301','J7302' --IUC
		,'J7307' --Implant
		,'C005' --Diaphragm
		,'B008' --Female Condom
		,'C003' --Female Condom
		,'C001' --Cervical Cap
		,'C006' --Foam
		,'FILM','SPONGE','DENTAL'
	)
--inserts the patients who received condoms at a b/c visit into the #fcon table
INSERT INTO #fcon (person_id)
SELECT DISTINCT person_id 
FROM #bcm1

select DISTINCT t.person_id, fi.family_annual_income AS [income], fi.family_size_nbr AS [size], 'fpl' = NULL
INTO #fpl
FROM #temp1 t
JOIN ngprod.dbo.practice_person_family_info fi ON t.person_id = fi.person_id
WHERE fi.modify_timestamp = (SELECT MAX(modify_timestamp)
                   from ngprod.dbo.practice_person_family_info fi2
                   where fi.person_id = fi2.person_id)

--Calculate FPL
UPDATE #fpl
SET fpl =
	(
		CASE
			WHEN size = 1 AND (income BETWEEN 0.00 AND 11880.00)  THEN '100'
			WHEN size = 1 AND (income BETWEEN 11881.00 AND 16400.00)  THEN '138'
			WHEN size = 1 AND (income BETWEEN 16401.00 AND 17820.00)  THEN '150'
			WHEN size = 1 AND (income BETWEEN 17821.00 AND 23760.00)  THEN '200'
			WHEN size = 1 AND (income BETWEEN 23761.00 AND 29699.00)  THEN '249'
			WHEN size = 1 AND (income BETWEEN 29700.00 AND 47549.00)  THEN '399'
			WHEN size = 1 AND (income BETWEEN 47550.00 AND 9999999.00)  THEN '400'

			WHEN size = 2 AND (income BETWEEN 0.00 AND 16020.00)  THEN '100'
			WHEN size = 2 AND (income BETWEEN 16021.00 AND 22100.00)  THEN '138'
			WHEN size = 2 AND (income BETWEEN 22101.00 AND 24030.00)  THEN '150'
			WHEN size = 2 AND (income BETWEEN 24031.00 AND 32040.00)  THEN '200'
			WHEN size = 2 AND (income BETWEEN 32041.00 AND 40050.00)  THEN '249'
			WHEN size = 2 AND (income BETWEEN 40051.00 AND 64099.00)  THEN '399'
			WHEN size = 2 AND (income BETWEEN 64100.00 AND 9999999.00)  THEN '400'

			WHEN size = 3 AND (income BETWEEN 0 AND 20160.00)  THEN '100'
			WHEN size = 3 AND (income BETWEEN 20161.00 AND 27800.00)  THEN '138'
			WHEN size = 3 AND (income BETWEEN 27801 AND 30240.00)  THEN '150'
			WHEN size = 3 AND (income BETWEEN 30240 AND 40320.00)  THEN '200'
			WHEN size = 3 AND (income BETWEEN 40321 AND 50399.00)  THEN '249'
			WHEN size = 3 AND (income BETWEEN 50400 AND 84649.00)  THEN '399'
			WHEN size = 3 AND (income BETWEEN 84650.00 AND 9999999.00)  THEN '400'

			WHEN size = 4 AND (income BETWEEN 0 AND 24300.00)  THEN '100'
			WHEN size = 4 AND (income BETWEEN 24301.00 AND 33600.00)  THEN '138'
			WHEN size = 4 AND (income BETWEEN 33601 AND 36450.00)  THEN '150'
			WHEN size = 4 AND (income BETWEEN 36451 AND 48600.00)  THEN '200'
			WHEN size = 4 AND (income BETWEEN 48601 AND 60749.00)  THEN '249'
			WHEN size = 4 AND (income BETWEEN 60750 AND 97199.00)  THEN '399'
			WHEN size = 4 AND (income BETWEEN 97200 AND 9999999.00)  THEN '400'

			WHEN size = 5 AND (income BETWEEN 0 AND 28440.00)  THEN '100'
			WHEN size = 5 AND (income BETWEEN 28441.00 AND 39250.00)  THEN '138'
			WHEN size = 5 AND (income BETWEEN 39251 AND 42660.00)  THEN '150'
			WHEN size = 5 AND (income BETWEEN 42661 AND 56880.00)  THEN '200'
			WHEN size = 5 AND (income BETWEEN 56881 AND 71099.00)  THEN '249'
			WHEN size = 5 AND (income BETWEEN 71100 AND 113799.00)  THEN '399'
			WHEN size = 5 AND (income BETWEEN 113800 AND 9999999.00)  THEN '400'

			WHEN size = 6 AND (income BETWEEN 0 AND 32580.00)  THEN '100'
			WHEN size = 6 AND (income BETWEEN 32581 AND 44950.00)  THEN '138'
			WHEN size = 6 AND (income BETWEEN 44951 AND 48870.00)  THEN '150'
			WHEN size = 6 AND (income BETWEEN 48871 AND 65160.00)  THEN '200'
			WHEN size = 6 AND (income BETWEEN 65161 AND 81449.00)  THEN '249'
			WHEN size = 6 AND (income BETWEEN 81450 AND 130299.00)  THEN '399'
			WHEN size = 6 AND (income BETWEEN 130300 AND 9999999.00)  THEN '400'

			WHEN size = 7 AND (income BETWEEN 0 AND 36730.00)  THEN '100'
			WHEN size = 7 AND (income BETWEEN 36729 AND 50700.00)  THEN '138'
			WHEN size = 7 AND (income BETWEEN 50701 AND 55095.00)  THEN '150'
			WHEN size = 7 AND (income BETWEEN 55096 AND 73460.00)  THEN '200'
			WHEN size = 7 AND (income BETWEEN 73461 AND 91824.00)  THEN '249'
			WHEN size = 7 AND (income BETWEEN 91825 AND 146899.00)  THEN '399'
			WHEN size = 7 AND (income BETWEEN 146900 AND 9999999.00)  THEN '400'

			WHEN size = 8 AND (income BETWEEN 0 AND 40890.00)  THEN '100'
			WHEN size = 8 AND (income BETWEEN 40891 AND 59450.00)  THEN '138'
			WHEN size = 8 AND (income BETWEEN 59451 AND 61335.00)  THEN '150'
			WHEN size = 8 AND (income BETWEEN 61336 AND 81780.00)  THEN '200'
			WHEN size = 8 AND (income BETWEEN 81781 AND 102249.00)  THEN '249'
			WHEN size = 7 AND (income BETWEEN 102250 AND 163549.00)  THEN '399'
			WHEN size = 8 AND (income BETWEEN 163550 AND 9999999.00)  THEN '400'
			
			WHEN income IS NULL THEN '9'
			--WHEN income = '' THEN '9'
			ELSE '100'
		END
	)
FROM #fpl

--AB patients
SELECT DISTINCT person_id
INTO #ab
FROM #temp1 t
WHERE (service_item_id LIKE '%59840A%' 
    OR service_item_id LIKE '%59841[C-N]%' 
    OR service_item_id LIKE '%S0199%')

--drop table #demo
--***Main demographics table***
SELECT DISTINCT t.person_id
		,'age' = CAST((CONVERT(INT,CONVERT(CHAR(8),d.service_date,112))-CONVERT(CHAR(8),p.date_of_birth,112))/10000 AS varchar)
		,t.sex
		,p.language
		,'White' = ''
		,'White_Hispanic' = ''
		,'Black' = ''
		,'Black_Hispanic' = ''
		,'Native-American' = ''
		,'Native-American_Hispanic' = ''
		,'Asian/Pacific Islander' = ''
		,'Asian/Pacific Islander_Hispanic' = ''
		,'Multiracial' = ''
		,'Multiracial_Hispanic' = ''
		,'Other' = ''
		,'Other_Hispanic' = ''
		,'Unknown' = ''
		,'contraceptive' = ''
		,'AB' = ''
		,'FPL' = '000'
INTO #demo
FROM #temp1 t
JOIN ngprod.dbo.person p	ON t.person_id = p.person_id
JOIN #date d				ON t.person_id = d.person_id
--***End demo table***

--***Start Age***
UPDATE #demo
SET age =
	(
		CASE
			WHEN age BETWEEN 0  AND 14 THEN '>15'
			WHEN age BETWEEN 15 AND 17 THEN '15-17'
			WHEN age BETWEEN 18 AND 19 THEN '18-19'
			WHEN age BETWEEN 20 AND 24 THEN '20-24'
			WHEN age BETWEEN 25 AND 29 THEN '25-29'
			WHEN age BETWEEN 30 AND 34 THEN '30-34'
			WHEN age BETWEEN 35 AND 39 THEN '35-39'
			WHEN age BETWEEN 40 AND 44 THEN '40-44'
			ELSE							'45+'
		END
	)
FROM #demo
--***End Age***

--***Start Language***
UPDATE #demo
SET language =
	(
		CASE
			WHEN language LIKE '%engl%'			   THEN 'English'
			WHEN language LIKE '%span%'			   THEN 'Spanish'
			WHEN language = '' OR language IS NULL 
			OR language LIKE '%unknown%' THEN 'Unknown'
			ELSE										'Other'						
		END
	)
FROM #demo
--***End Language***

--***Start Race***
UPDATE #demo
SET White = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race LIKE '%white%' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [White_Hispanic] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race LIKE '%white%' AND ethnicity = 'Hispanic or Latino'
)

UPDATE #demo
SET [Black] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '2- African American' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [Black_Hispanic] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '2- African American' AND ethnicity = 'Hispanic or Latino'
)

UPDATE #demo
SET [Native-American] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '5- Native American' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [Native-American_Hispanic] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '5- Native American' AND ethnicity = 'Hispanic or Latino'
)

UPDATE #demo
SET [Asian/Pacific Islander] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE (race = '3- Asian' AND ethnicity != 'Hispanic or Latino')
	OR (race = '4- Pacific Islander' AND ethnicity != 'Hispanic or Latino')
)

UPDATE #demo
SET [Asian/Pacific Islander_Hispanic] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE (race = '3- Asian' AND ethnicity = 'Hispanic or Latino')
	OR (race = '4- Pacific Islander' AND ethnicity = 'Hispanic or Latino')
)

UPDATE #demo
SET [Multiracial] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race LIKE '%multi%' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [Multiracial_Hispanic] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE (race LIKE '%multi%') AND ethnicity = 'Hispanic or Latino'
)

UPDATE #demo
SET [Other] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race LIKE '%other%' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [Other_Hispanic] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race LIKE '%other%' AND ethnicity = 'Hispanic or Latino'
)

UPDATE #demo
SET [Unknown] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race LIKE '%unkno%'
)

UPDATE #demo
SET [Unknown] = 'Y'
WHERE [white] = '' AND [White_Hispanic] = '' AND [black] = '' AND [Black_Hispanic] = '' AND [Native-American] = '' 
AND [Native-American_Hispanic] = '' AND [Asian/Pacific Islander] = '' AND [Asian/Pacific Islander_Hispanic] = '' 
AND [Multiracial] = '' AND [Multiracial_Hispanic] = '' AND [Other] = '' AND [Other_Hispanic] = '' 

--select * from #demo
--***End Race***

--***Start Contra***
UPDATE #demo
SET [contraceptive] = 'Y'
WHERE #demo.person_id IN
(
	SELECT f.person_id
	FROM #fcon f
	JOIN #demo d ON d.person_id = f.person_id
)
--***End Contra***

--***Start AB***
UPDATE #demo
SET [AB] = 'Y'
WHERE #demo.person_id IN
(
	SELECT a.person_id
	FROM #ab a
	JOIN #demo d ON d.person_id = a.person_id
)
--***End AB***

--***Start FPL***
UPDATE #demo
SET #demo.FPL = f.fpl
FROM #demo d
JOIN #fpl f ON d.person_id = f.person_id
--***End FPL***

--***************************************
--**
--** Female Clients
--**
--***************************************
SELECT DISTINCT
'01 - Under 15' AS 'Age'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [White] = 'y' AND [Age] = '>15') AS [White]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [White_Hispanic] = 'y' AND [Age] = '>15') AS [White_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Black] = 'y' AND [Age] = '>15') AS [Black]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Black_Hispanic] = 'y' AND [Age] = '>15') AS [Black_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Native-American] = 'y' AND [Age] = '>15') AS [Native-American]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Native-American_Hispanic] = 'y' AND [Age] = '>15') AS [Native-American_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Asian/Pacific Islander] = 'y' AND [Age] = '>15') AS [Asian/Pacific Islander]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Asian/Pacific Islander_Hispanic] = 'y' AND [Age] = '>15') AS [Asian/Pacific Islander_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Multiracial] = 'y' AND [Age] = '>15') AS [Multiracial]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Multiracial_Hispanic] = 'y' AND [Age] = '>15') AS [Multiracial_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Other] = 'y' AND [Age] = '>15') AS [Other]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Other_Hispanic] = 'y' AND [Age] = '>15') AS [Other_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Unknown] = 'y' AND [Age] = '>15') AS [Unknown]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '>15') AS [Total]
INTO #female

INSERT INTO #female
SELECT DISTINCT
'02 - 15-17' AS 'Age'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [White] = 'y' AND [Age] = '15-17') AS [White]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [White_Hispanic] = 'y' AND [Age] = '15-17') AS [White_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Black] = 'y' AND [Age] = '15-17') AS [Black]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Black_Hispanic] = 'y' AND [Age] = '15-17') AS [Black_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Native-American] = 'y' AND [Age] = '15-17') AS [Native-American]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Native-American_Hispanic] = 'y' AND [Age] = '15-17') AS [Native-American_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Asian/Pacific Islander] = 'y' AND [Age] = '15-17') AS [Asian/Pacific Islander]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Asian/Pacific Islander_Hispanic] = 'y' AND [Age] = '15-17') AS [Asian/Pacific Islander_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Multiracial] = 'y' AND [Age] = '15-17') AS [Multiracial]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Multiracial_Hispanic] = 'y' AND [Age] = '15-17') AS [Multiracial_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Other] = 'y' AND [Age] = '15-17') AS [Other]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Other_Hispanic] = 'y' AND [Age] = '15-17') AS [Other_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Unknown] = 'y' AND [Age] = '15-17') AS [Unknown]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '15-17') AS [Total]

INSERT INTO #female
SELECT DISTINCT
'03 - 18-19' AS 'Age'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '18-19' AND [White] = 'y') AS [White]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '18-19' AND [White_Hispanic] = 'y') AS [White_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '18-19' AND [Black] = 'y') AS [Black]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '18-19' AND [Black_Hispanic] = 'y') AS [Black_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '18-19' AND [Native-American] = 'y') AS [Native-American]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '18-19' AND [Native-American_Hispanic] = 'y') AS [Native-American_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '18-19' AND [Asian/Pacific Islander] = 'y') AS [Asian/Pacific Islander]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '18-19' AND [Asian/Pacific Islander_Hispanic] = 'y') AS [Asian/Pacific Islander_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '18-19' AND [Multiracial] = 'y') AS [Multiracial]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '18-19' AND [Multiracial_Hispanic] = 'y') AS [Multiracial_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '18-19' AND [Other] = 'y') AS [Other]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '18-19' AND [Other_Hispanic] = 'y') AS [Other_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '18-19' AND [Unknown] = 'y') AS [Unknown]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '18-19') AS [Total]

INSERT INTO #female
SELECT DISTINCT
'04 - 20-24' AS 'Age'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [White] = 'y' AND [Age] = '20-24') AS [White]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [White_Hispanic] = 'y' AND [Age] = '20-24') AS [White_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Black] = 'y' AND [Age] = '20-24') AS [Black]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Black_Hispanic] = 'y' AND [Age] = '20-24') AS [Black_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Native-American] = 'y' AND [Age] = '20-24') AS [Native-American]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Native-American_Hispanic] = 'y' AND [Age] = '20-24') AS [Native-American_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Asian/Pacific Islander] = 'y' AND [Age] = '20-24') AS [Asian/Pacific Islander]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Asian/Pacific Islander_Hispanic] = 'y' AND [Age] = '20-24') AS [Asian/Pacific Islander_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Multiracial] = 'y' AND [Age] = '20-24') AS [Multiracial]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Multiracial_Hispanic] = 'y' AND [Age] = '20-24') AS [Multiracial_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Other] = 'y' AND [Age] = '20-24') AS [Other]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Other_Hispanic] = 'y' AND [Age] = '20-24') AS [Other_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Unknown] = 'y' AND [Age] = '20-24') AS [Unknown]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '20-24') AS [Total]

INSERT INTO #female
SELECT DISTINCT
'05 - 25-29' AS 'Age'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [White] = 'y' AND [Age] = '25-29') AS [White]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [White_Hispanic] = 'y' AND [Age] = '25-29') AS [White_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Black] = 'y' AND [Age] = '25-29') AS [Black]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Black_Hispanic] = 'y' AND [Age] = '25-29') AS [Black_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Native-American] = 'y' AND [Age] = '25-29') AS [Native-American]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Native-American_Hispanic] = 'y' AND [Age] = '25-29') AS [Native-American_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Asian/Pacific Islander] = 'y' AND [Age] = '25-29') AS [Asian/Pacific Islander]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Asian/Pacific Islander_Hispanic] = 'y' AND [Age] = '25-29') AS [Asian/Pacific Islander_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Multiracial] = 'y' AND [Age] = '25-29') AS [Multiracial]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Multiracial_Hispanic] = 'y' AND [Age] = '25-29') AS [Multiracial_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Other] = 'y' AND [Age] = '25-29') AS [Other]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Other_Hispanic] = 'y' AND [Age] = '25-29') AS [Other_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Unknown] = 'y' AND [Age] = '25-29') AS [Unknown]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '25-29') AS [Total]

INSERT INTO #female
SELECT DISTINCT
'06 - 30-34' AS 'Age'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [White] = 'y' AND [Age] = '30-34') AS [White]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [White_Hispanic] = 'y' AND [Age] = '30-34') AS [White_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Black] = 'y' AND [Age] = '30-34') AS [Black]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Black_Hispanic] = 'y' AND [Age] = '30-34') AS [Black_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Native-American] = 'y' AND [Age] = '30-34') AS [Native-American]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Native-American_Hispanic] = 'y' AND [Age] = '30-34') AS [Native-American_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Asian/Pacific Islander] = 'y' AND [Age] = '30-34') AS [Asian/Pacific Islander]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Asian/Pacific Islander_Hispanic] = 'y' AND [Age] = '30-34') AS [Asian/Pacific Islander_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Multiracial] = 'y' AND [Age] = '30-34') AS [Multiracial]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Multiracial_Hispanic] = 'y' AND [Age] = '30-34') AS [Multiracial_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Other] = 'y' AND [Age] = '30-34') AS [Other]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Other_Hispanic] = 'y' AND [Age] = '30-34') AS [Other_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Unknown] = 'y' AND [Age] = '30-34') AS [Unknown]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '30-34') AS [Total]

INSERT INTO #female
SELECT DISTINCT
'07 - 35-39' AS 'Age'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [White] = 'y' AND [Age] = '35-39') AS [White]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [White_Hispanic] = 'y' AND [Age] = '35-39') AS [White_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Black] = 'y' AND [Age] = '35-39') AS [Black]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Black_Hispanic] = 'y' AND [Age] = '35-39') AS [Black_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Native-American] = 'y' AND [Age] = '35-39') AS [Native-American]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Native-American_Hispanic] = 'y' AND [Age] = '35-39') AS [Native-American_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Asian/Pacific Islander] = 'y' AND [Age] = '35-39') AS [Asian/Pacific Islander]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Asian/Pacific Islander_Hispanic] = 'y' AND [Age] = '35-39') AS [Asian/Pacific Islander_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Multiracial] = 'y' AND [Age] = '35-39') AS [Multiracial]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Multiracial_Hispanic] = 'y' AND [Age] = '35-39') AS [Multiracial_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Other] = 'y' AND [Age] = '35-39') AS [Other]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Other_Hispanic] = 'y' AND [Age] = '35-39') AS [Other_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Unknown] = 'y' AND [Age] = '35-39') AS [Unknown]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '35-39') AS [Total]

INSERT INTO #female
SELECT DISTINCT
'08 - 40-44' AS 'Age'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [White] = 'y' AND [Age] = '40-44') AS [White]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [White_Hispanic] = 'y' AND [Age] = '40-44') AS [White_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Black] = 'y' AND [Age] = '40-44') AS [Black]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Black_Hispanic] = 'y' AND [Age] = '40-44') AS [Black_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Native-American] = 'y' AND [Age] = '40-44') AS [Native-American]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Native-American_Hispanic] = 'y' AND [Age] = '40-44') AS [Native-American_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Asian/Pacific Islander] = 'y' AND [Age] = '40-44') AS [Asian/Pacific Islander]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Asian/Pacific Islander_Hispanic] = 'y' AND [Age] = '40-44') AS [Asian/Pacific Islander_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Multiracial] = 'y' AND [Age] = '40-44') AS [Multiracial]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Multiracial_Hispanic] = 'y' AND [Age] = '40-44') AS [Multiracial_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Other] = 'y' AND [Age] = '40-44') AS [Other]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Other_Hispanic] = 'y' AND [Age] = '40-44') AS [Other_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Unknown] = 'y' AND [Age] = '40-44') AS [Unknown]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '40-44') AS [Total]

INSERT INTO #female
SELECT DISTINCT
'09 - 45+' AS 'Age'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [White] = 'y' AND [Age] = '45+') AS [White]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [White_Hispanic] = 'y' AND [Age] = '45+') AS [White_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Black] = 'y' AND [Age] = '45+') AS [Black]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Black_Hispanic] = 'y' AND [Age] = '45+') AS [Black_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Native-American] = 'y' AND [Age] = '45+') AS [Native-American]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Native-American_Hispanic] = 'y' AND [Age] = '45+') AS [Native-American_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Asian/Pacific Islander] = 'y' AND [Age] = '45+') AS [Asian/Pacific Islander]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Asian/Pacific Islander_Hispanic] = 'y' AND [Age] = '45+') AS [Asian/Pacific Islander_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Multiracial] = 'y' AND [Age] = '45+') AS [Multiracial]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Multiracial_Hispanic] = 'y' AND [Age] = '45+') AS [Multiracial_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Other] = 'y' AND [Age] = '45+') AS [Other]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Other_Hispanic] = 'y' AND [Age] = '45+') AS [Other_Hispanic]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Unknown] = 'y' AND [Age] = '45+') AS [Unknown]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Age] = '45+') AS [Total]

INSERT INTO #female
SELECT DISTINCT
'10 - Unknown' AS 'Age'
,0 AS [White]
,0 AS [White (Hispanic) contra]
,0 AS [Black]
,0 AS [Black (Hispanic) contra]
,0 AS [Native-American]
,0 AS [Native-American (Hispanic) contra]
,0 AS [Asian/Pacific Islander]
,0 AS [Asian/Pacific Islander (Hispanic) contra]
,0 AS [Multiracial]
,0 AS [Multiracial (Hispanic) contra]
,0 AS [Other]
,0 AS [Other (Hispanic) contra]
,0 AS [Unknown]
,0 AS [Total]

INSERT INTO #female
SELECT DISTINCT
'11 - Total' AS 'Age'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [White] = 'y') AS [White contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [White_Hispanic] = 'y') AS [White Hispanic contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Black] = 'y') AS [Black contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Black_Hispanic] = 'y') AS [Black Hispanic contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Native-American] = 'y') AS [Native-American contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Native-American_Hispanic] = 'y') AS [Native-American Hispanic contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Asian/Pacific Islander] = 'y') AS [Asian/Pacific Islander contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Asian/Pacific Islander_Hispanic] = 'y') AS [Asian/Pacific Islander Hispanic contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Multiracial] = 'y') AS [Multiracial contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Multiracial_Hispanic] = 'y') AS [Multiracial (Hispanic) contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Other] = 'y') AS [Other contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Other_Hispanic] = 'y') AS [Other Hispanic contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [Unknown] = 'y') AS [Unknown contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F') AS [Total contra]

SELECT * FROM #female