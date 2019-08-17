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
		,'white' = ''
		,'white (hispanic)' = ''
		,'black' = ''
		,'black (hispanic)' = ''
		,'native-american' = ''
		,'native-american (hispanic)' = ''
		,'asian/pacific islander' = ''
		,'asian/pacific islander (hispanic)' = ''
		,'multiracial' = ''
		,'multiracial (hispanic)' = ''
		,'race-other' = ''
		,'race-other (hispanic)' = ''
		,'race-unknown' = ''
		,'contraceptive' = ''
		,'AB' = ''
		,'FPL' = '000'
INTO #demo
FROM #temp1 t
JOIN ngprod.dbo.person p	ON t.person_id = p.person_id
JOIN #date d				ON t.person_id = d.person_id
--***End demo table***

--select * from #demo

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
			WHEN language = '' OR language IS NULL THEN 'Unknown'
			ELSE										'Other'						
		END
	)
FROM #demo
--***End Language***

--***Start Race***
UPDATE #demo
SET white = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '1- white' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [white (hispanic)] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '1- white' AND ethnicity = 'Hispanic or Latino'
)

UPDATE #demo
SET [black] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '2- African American' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [black (hispanic)] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '2- African American' AND ethnicity != 'Hispanic or Latino'
)

UPDATE #demo
SET [native-american] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '5- Native American' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [native-american (hispanic)] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '5- Native American' AND ethnicity = 'Hispanic or Latino'
)

UPDATE #demo
SET [asian/pacific islander] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE (race = '3- Asian' AND ethnicity != 'Hispanic or Latino')
	OR (race = '4- Pacific Islander' AND ethnicity != 'Hispanic or Latino')
)

UPDATE #demo
SET [asian/pacific islander (hispanic)] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE (race = '3- Asian' AND ethnicity = 'Hispanic or Latino')
	OR (race = '4- Pacific Islander' AND ethnicity = 'Hispanic or Latino')
)

UPDATE #demo
SET [multiracial] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race LIKE 'multi' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [multiracial] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE (race LIKE 'multi' OR race LIKE '7%') AND ethnicity = 'Hispanic or Latino'
)

UPDATE #demo
SET [race-other] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race LIKE '%other%' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [race-other (hispanic)] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race LIKE '%other%' AND ethnicity != 'Hispanic or Latino'
)

UPDATE #demo
SET [race-unknown] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM ngprod.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race LIKE '%unkno%'
)

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
--** Female Contraception Clients
--**
--***************************************
--drop table #femaleContra
SELECT DISTINCT
'Under 15' AS 'Age'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [white] = 'y' AND [contraceptive] = 'y' AND [age] = '>15') AS [white]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [white (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '>15') AS [white (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [black] = 'y' AND [contraceptive] = 'y' AND [age] = '>15') AS [black]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [black (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '>15') AS [black (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [native-american] = 'y' AND [contraceptive] = 'y' AND [age] = '>15') AS [native-american]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [native-american (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '>15') AS [native-american (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [asian/pacific islander] = 'y' AND [contraceptive] = 'y' AND [age] = '>15') AS [asian/pacific islander]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [asian/pacific islander (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '>15') AS [asian/pacific islander (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [multiracial] = 'y' AND [contraceptive] = 'y' AND [age] = '>15') AS [multiracial]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [multiracial (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '>15') AS [multiracial (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-other] = 'y' AND [contraceptive] = 'y' AND [age] = '>15') AS [race-other]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-other (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '>15') AS [race-other (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-unknown] = 'y' AND [contraceptive] = 'y' AND [age] = '>15') AS [race-unknown]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [contraceptive] = 'y' AND [age] = '>15') AS [total]
INTO #femaleContra

INSERT INTO #femaleContra
SELECT DISTINCT
'15-17' AS 'Age'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [white] = 'y' AND [contraceptive] = 'y' AND [age] = '15-17') AS [white]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [white (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '15-17') AS [white (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [black] = 'y' AND [contraceptive] = 'y' AND [age] = '15-17') AS [black]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [black (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '15-17') AS [black (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [native-american] = 'y' AND [contraceptive] = 'y' AND [age] = '15-17') AS [native-american]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [native-american (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '15-17') AS [native-american (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [asian/pacific islander] = 'y' AND [contraceptive] = 'y' AND [age] = '15-17') AS [asian/pacific islander]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [asian/pacific islander (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '15-17') AS [asian/pacific islander (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [multiracial] = 'y' AND [contraceptive] = 'y' AND [age] = '15-17') AS [multiracial]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [multiracial (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '15-17') AS [multiracial (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-other] = 'y' AND [contraceptive] = 'y' AND [age] = '15-17') AS [race-other]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-other (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '15-17') AS [race-other (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-unknown] = 'y' AND [contraceptive] = 'y' AND [age] = '15-17') AS [race-unknown]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [contraceptive] = 'y' AND [age] = '15-17') AS [total]

INSERT INTO #femaleContra
SELECT DISTINCT
'18-19' AS 'Age'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [white] = 'y' AND [contraceptive] = 'y' AND [age] = '18-19') AS [white]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [white (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '18-19') AS [white (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [black] = 'y' AND [contraceptive] = 'y' AND [age] = '18-19') AS [black]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [black (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '18-19') AS [black (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [native-american] = 'y' AND [contraceptive] = 'y' AND [age] = '18-19') AS [native-american]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [native-american (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '18-19') AS [native-american (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [asian/pacific islander] = 'y' AND [contraceptive] = 'y' AND [age] = '18-19') AS [asian/pacific islander]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [asian/pacific islander (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '18-19') AS [asian/pacific islander (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [multiracial] = 'y' AND [contraceptive] = 'y' AND [age] = '18-19') AS [multiracial]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [multiracial (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '18-19') AS [multiracial (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-other] = 'y' AND [contraceptive] = 'y' AND [age] = '18-19') AS [race-other]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-other (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '18-19') AS [race-other (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-unknown] = 'y' AND [contraceptive] = 'y' AND [age] = '18-19') AS [race-unknown]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [contraceptive] = 'y' AND [age] = '18-19') AS [total]

INSERT INTO #femaleContra
SELECT DISTINCT
'20-24' AS 'Age'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [white] = 'y' AND [contraceptive] = 'y' AND [age] = '20-24') AS [white]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [white (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '20-24') AS [white (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [black] = 'y' AND [contraceptive] = 'y' AND [age] = '20-24') AS [black]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [black (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '20-24') AS [black (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [native-american] = 'y' AND [contraceptive] = 'y' AND [age] = '20-24') AS [native-american]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [native-american (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '20-24') AS [native-american (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [asian/pacific islander] = 'y' AND [contraceptive] = 'y' AND [age] = '20-24') AS [asian/pacific islander]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [asian/pacific islander (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '20-24') AS [asian/pacific islander (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [multiracial] = 'y' AND [contraceptive] = 'y' AND [age] = '20-24') AS [multiracial]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [multiracial (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '20-24') AS [multiracial (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-other] = 'y' AND [contraceptive] = 'y' AND [age] = '20-24') AS [race-other]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-other (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '20-24') AS [race-other (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-unknown] = 'y' AND [contraceptive] = 'y' AND [age] = '20-24') AS [race-unknown]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [contraceptive] = 'y' AND [age] = '20-24') AS [total]

INSERT INTO #femaleContra
SELECT DISTINCT
'25-29' AS 'Age'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [white] = 'y' AND [contraceptive] = 'y' AND [age] = '25-29') AS [white]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [white (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '25-29') AS [white (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [black] = 'y' AND [contraceptive] = 'y' AND [age] = '25-29') AS [black]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [black (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '25-29') AS [black (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [native-american] = 'y' AND [contraceptive] = 'y' AND [age] = '25-29') AS [native-american]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [native-american (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '25-29') AS [native-american (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [asian/pacific islander] = 'y' AND [contraceptive] = 'y' AND [age] = '25-29') AS [asian/pacific islander]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [asian/pacific islander (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '25-29') AS [asian/pacific islander (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [multiracial] = 'y' AND [contraceptive] = 'y' AND [age] = '25-29') AS [multiracial]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [multiracial (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '25-29') AS [multiracial (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-other] = 'y' AND [contraceptive] = 'y' AND [age] = '25-29') AS [race-other]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-other (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '25-29') AS [race-other (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-unknown] = 'y' AND [contraceptive] = 'y' AND [age] = '25-29') AS [race-unknown]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [contraceptive] = 'y' AND [age] = '25-29') AS [total]

INSERT INTO #femaleContra
SELECT DISTINCT
'30-34' AS 'Age'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [white] = 'y' AND [contraceptive] = 'y' AND [age] = '30-34') AS [white]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [white (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '30-34') AS [white (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [black] = 'y' AND [contraceptive] = 'y' AND [age] = '30-34') AS [black]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [black (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '30-34') AS [black (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [native-american] = 'y' AND [contraceptive] = 'y' AND [age] = '30-34') AS [native-american]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [native-american (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '30-34') AS [native-american (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [asian/pacific islander] = 'y' AND [contraceptive] = 'y' AND [age] = '30-34') AS [asian/pacific islander]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [asian/pacific islander (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '30-34') AS [asian/pacific islander (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [multiracial] = 'y' AND [contraceptive] = 'y' AND [age] = '30-34') AS [multiracial]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [multiracial (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '30-34') AS [multiracial (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-other] = 'y' AND [contraceptive] = 'y' AND [age] = '30-34') AS [race-other]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-other (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '30-34') AS [race-other (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-unknown] = 'y' AND [contraceptive] = 'y' AND [age] = '30-34') AS [race-unknown]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [contraceptive] = 'y' AND [age] = '30-34') AS [total]

INSERT INTO #femaleContra
SELECT DISTINCT
'35-39' AS 'Age'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [white] = 'y' AND [contraceptive] = 'y' AND [age] = '35-39') AS [white]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [white (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '35-39') AS [white (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [black] = 'y' AND [contraceptive] = 'y' AND [age] = '35-39') AS [black]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [black (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '35-39') AS [black (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [native-american] = 'y' AND [contraceptive] = 'y' AND [age] = '35-39') AS [native-american]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [native-american (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '35-39') AS [native-american (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [asian/pacific islander] = 'y' AND [contraceptive] = 'y' AND [age] = '35-39') AS [asian/pacific islander]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [asian/pacific islander (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '35-39') AS [asian/pacific islander (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [multiracial] = 'y' AND [contraceptive] = 'y' AND [age] = '35-39') AS [multiracial]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [multiracial (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '35-39') AS [multiracial (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-other] = 'y' AND [contraceptive] = 'y' AND [age] = '35-39') AS [race-other]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-other (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '35-39') AS [race-other (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-unknown] = 'y' AND [contraceptive] = 'y' AND [age] = '35-39') AS [race-unknown]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [contraceptive] = 'y' AND [age] = '35-39') AS [total]

INSERT INTO #femaleContra
SELECT DISTINCT
'40-44' AS 'Age'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [white] = 'y' AND [contraceptive] = 'y' AND [age] = '40-44') AS [white]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [white (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '40-44') AS [white (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [black] = 'y' AND [contraceptive] = 'y' AND [age] = '40-44') AS [black]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [black (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '40-44') AS [black (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [native-american] = 'y' AND [contraceptive] = 'y' AND [age] = '40-44') AS [native-american]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [native-american (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '40-44') AS [native-american (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [asian/pacific islander] = 'y' AND [contraceptive] = 'y' AND [age] = '40-44') AS [asian/pacific islander]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [asian/pacific islander (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '40-44') AS [asian/pacific islander (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [multiracial] = 'y' AND [contraceptive] = 'y' AND [age] = '40-44') AS [multiracial]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [multiracial (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '40-44') AS [multiracial (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-other] = 'y' AND [contraceptive] = 'y' AND [age] = '40-44') AS [race-other]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-other (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '40-44') AS [race-other (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-unknown] = 'y' AND [contraceptive] = 'y' AND [age] = '40-44') AS [race-unknown]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [contraceptive] = 'y' AND [age] = '40-44') AS [total]

INSERT INTO #femaleContra
SELECT DISTINCT
'45+' AS 'Age'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [white] = 'y' AND [contraceptive] = 'y' AND [age] = '45+') AS [white]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [white (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '45+') AS [white (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [black] = 'y' AND [contraceptive] = 'y' AND [age] = '45+') AS [black]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [black (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '45+') AS [black (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [native-american] = 'y' AND [contraceptive] = 'y' AND [age] = '45+') AS [native-american]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [native-american (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '45+') AS [native-american (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [asian/pacific islander] = 'y' AND [contraceptive] = 'y' AND [age] = '45+') AS [asian/pacific islander]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [asian/pacific islander (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '45+') AS [asian/pacific islander (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [multiracial] = 'y' AND [contraceptive] = 'y' AND [age] = '45+') AS [multiracial]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [multiracial (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '45+') AS [multiracial (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-other] = 'y' AND [contraceptive] = 'y' AND [age] = '45+') AS [race-other]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-other (hispanic)] = 'y' AND [contraceptive] = 'y' AND [age] = '45+') AS [race-other (hispanic)]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-unknown] = 'y' AND [contraceptive] = 'y' AND [age] = '45+') AS [race-unknown]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [contraceptive] = 'y' AND [age] = '45+') AS [total]

INSERT INTO #femaleContra
SELECT DISTINCT
'Unknown' AS 'Age'
,0 AS [white]
,0 AS [white (hispanic) contra]
,0 AS [black]
,0 AS [black (hispanic) contra]
,0 AS [native-american]
,0 AS [native-american (hispanic) contra]
,0 AS [asian/pacific islander]
,0 AS [asian/pacific islander (hispanic) contra]
,0 AS [multiracial]
,0 AS [multiracial (hispanic) contra]
,0 AS [race-other]
,0 AS [race-other (hispanic) contra]
,0 AS [race-unknown]
,0 AS [total]

INSERT INTO #femaleContra
SELECT DISTINCT
'Total' AS 'Age'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [white] = 'y' AND [contraceptive] = 'y') AS [white contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [white (hispanic)] = 'y' AND [contraceptive] = 'y') AS [white hispanic contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [black] = 'y' AND [contraceptive] = 'y') AS [black contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [black (hispanic)] = 'y' AND [contraceptive] = 'y') AS [black hispanic contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [native-american] = 'y' AND [contraceptive] = 'y') AS [native-american contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [native-american (hispanic)] = 'y' AND [contraceptive] = 'y') AS [native-american hispanic contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [asian/pacific islander] = 'y' AND [contraceptive] = 'y') AS [asian/pacific islander contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [asian/pacific islander (hispanic)] = 'y' AND [contraceptive] = 'y') AS [asian/pacific islander hispanic contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [multiracial] = 'y' AND [contraceptive] = 'y') AS [multiracial contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [multiracial (hispanic)] = 'y' AND [contraceptive] = 'y') AS [multiracial (hispanic) contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-other] = 'y' AND [contraceptive] = 'y') AS [race-other contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-other (hispanic)] = 'y' AND [contraceptive] = 'y') AS [race-other hispanic contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [race-unknown] = 'y' AND [contraceptive] = 'y') AS [race-unknown contra]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F' AND [contraceptive] = 'y') AS [total contra]

SELECT * FROM #femaleContra
