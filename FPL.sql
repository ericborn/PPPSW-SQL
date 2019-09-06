--select * from practice_person_family_info

--***Declare and set variables***
DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

SET @Start_Date_1 = '20160701'
SET @End_Date_1 = '20170630'

--select distinct pp.person_id, p.ethnicity, p.race, p.age, pm.financial_class
--FROM person p
--JOIN patient_procedure pp ON pp.person_id = p.person_id
--JOIN payer_mstr pm		ON pe.cob1_payer_id = pm.payer_id
--WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1)

--**********Start data Table Creation***********
--Creates enc table
SELECT pe.create_timestamp, pe.enc_id, pe.person_id--, fi.family_size_nbr, fi.family_annual_income
INTO #enc
FROM patient_encounter pe
JOIN practice_person_family_info fi ON pe.person_id = fi.person_id
JOIN person	p			  ON pe.person_id = p.person_id
WHERE (pe.create_timestamp >= @Start_Date_1 AND pe.create_timestamp <= @End_Date_1) AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')

--finds latest enc for all patients
SELECT DISTINCT enc.enc_id, enc.person_id, enc.create_timestamp
INTO #enc2
FROM #enc enc
INNER JOIN
	(SELECT person_id, MAX(create_timestamp) AS MAXDATE
	 FROM #enc
	 GROUP BY person_id) grouped
ON enc.person_id = grouped.person_id AND enc.create_timestamp = grouped.MAXDATE

select DISTINCT e.*, fi.family_annual_income, fi.family_size_nbr
INTO #e3
FROM #enc2 e
JOIN practice_person_family_info fi ON e.person_id = fi.person_id
WHERE fi.modify_timestamp = (SELECT MAX(modify_timestamp)
                   from practice_person_family_info fi2
                   where fi.person_id = fi2.person_id)

--Main demographics table
SELECT DISTINCT 
		 e3.person_id
		,e3.enc_id
		,'age' = CAST((CONVERT(INT,CONVERT(CHAR(8),e3.create_timestamp,112))-CONVERT(CHAR(8),p.date_of_birth,112))/10000 AS varchar)
		,'sex' = p.sex
		,'white' = ''
		,'african-american' = ''
		,'asian' = ''
		,'pacific islander' = ''
		,'native-american' = ''
		,'race-other' = ''
		,'race-unknown' = ''
		,'hispanic' = ''
		,'Multi-Racial' = ''
		,'commercial' = ''
		,'fpact' = ''
		,'cash' = ''
		,'medi-cal' = ''
		,'size' = e3.family_size_nbr
		,'income' = CAST(e3.family_annual_income AS INT)
		,'fpl' = '0'
INTO #demo
FROM #e3 e3
JOIN person p			ON p.person_id	= e3.person_id

--***Start Age***
UPDATE #demo
SET age =
	(
		CASE
			WHEN age BETWEEN 0  AND 12 THEN '12 & under'
			WHEN age BETWEEN 13 AND 14 THEN '13-14'
			WHEN age BETWEEN 15 AND 17 THEN '15-17'
			WHEN age BETWEEN 18 AND 19 THEN '18-19'
			WHEN age BETWEEN 20 AND 24 THEN '20-24'
			WHEN age BETWEEN 25 AND 29 THEN '25-29'
			WHEN age BETWEEN 30 AND 34 THEN '30-34'
			WHEN age BETWEEN 35 AND 39 THEN '35-39'
			WHEN age BETWEEN 40 AND 44 THEN '40-44'
			WHEN age BETWEEN 45 AND 49 THEN '45-49'
			WHEN age BETWEEN 50 AND 54 THEN '50-54'
			ELSE							'<55'
		END
	)
FROM #demo
--***End Age***

--***Start FPL check***
UPDATE #demo
SET fpl =
	(
		CASE
			WHEN size = 1 AND (income BETWEEN 0 AND 29700.00)  THEN 'Y'
			WHEN size = 2 AND (income BETWEEN 0 AND 40050.00)  THEN 'Y'
			WHEN size = 3 AND (income BETWEEN 0 AND 50400.00)  THEN 'Y'
			WHEN size = 4 AND (income BETWEEN 0 AND 60750.00)  THEN 'Y'
			WHEN size = 5 AND (income BETWEEN 0 AND 71100.00)  THEN 'Y'
			WHEN size = 6 AND (income BETWEEN 0 AND 81450.00)  THEN 'Y'
			WHEN size = 7 AND (income BETWEEN 0 AND 91825.00)  THEN 'Y'
			WHEN size = 8 AND (income BETWEEN 0 AND 102225.00) THEN 'Y'
			ELSE 'N'
		END
	)
FROM #demo
--***End FPL check***

--***Start Race***
UPDATE #demo
SET white = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '1- white' AND ethnicity != 'Hispanic or Latino'
)

UPDATE #demo
SET [african-american] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '2- African American' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET asian = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '3- Asian' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [pacific islander] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '4- Pacific Islander' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [native-american] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '5- Native American' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [race-unknown] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE (race LIKE '6- unkno%') AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [race-other] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE (race LIKE '7-Other') AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [Multi-Racial] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '6-Multi-racial' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [race-unknown] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE (race IS NULL OR race = '') AND ethnicity != 'Hispanic or Latino'
)
--***End Race***

--***Start ethnicity***
UPDATE #demo
SET hispanic = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE ethnicity = 'Hispanic or Latino'
)
UPDATE #demo
SET hispanic = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race LIKE '%Hispanic or Latino%'
)

UPDATE #demo
SET [race-unknown] = 'Y'
WHERE #demo.enc_id IN
(
	SELECT d.enc_id 
	FROM #demo d
	WHERE d.white != 'Y' 
	AND d.hispanic != 'Y' 
	AND d.[race-other] != 'Y'
	AND d.[race-unknown] != 'Y' 
	AND d.[african-american] != 'Y'
	AND d.[Multi-Racial] != 'Y' 
	AND d.asian != 'Y'
	AND d.[pacific islander] != 'Y' 
	AND d.[native-american] != 'Y'
)
--***End ethnicity***

--***Start fin class*** 
UPDATE #demo
SET [medi-cal] = 'Y'
WHERE #demo.enc_id IN
(
	select pe.enc_id
	FROM patient_encounter pe
	JOIN #demo d ON d.enc_id = pe.enc_id
	JOIN payer_mstr pm		ON pe.cob1_payer_id = pm.payer_id
	WHERE (pm.financial_class = '484A05B3-D5C8-415B-A8EE-3D14A7AF11D6' --Medi-Cal Managed Care-4130
	OR	   pm.financial_class = 'C5BDDA12-DDC9-4CFF-A0A3-9749C7DD353D')--Medi-Cal-4120
	AND pe.enc_id = d.enc_id
) 

UPDATE #demo
SET commercial = 'Y'
WHERE #demo.enc_id IN
(
	select pe.enc_id
	FROM patient_encounter pe
	JOIN #demo d ON pe.enc_id = d.enc_id
	JOIN payer_mstr pm		ON pe.cob1_payer_id = pm.payer_id
	WHERE (pm.financial_class = '8E5D6C7E-A34E-4B3C-8C0A-B2F1D2E20285' --Commercial Ins Exchange-4330
	OR	   pm.financial_class = '332DF613-7C43-4287-9050-9949B4142B0C')--Commercial Ins Non-Exchange-4310
	AND pe.enc_id = d.enc_id
) 

UPDATE #demo
SET fpact = 'Y'
WHERE #demo.enc_id IN
(
	select pe.enc_id
	FROM patient_encounter pe
	JOIN #demo d ON d.enc_id = pe.enc_id
	JOIN payer_mstr pm		ON pe.cob1_payer_id = pm.payer_id
	WHERE pm.financial_class = 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF' --Family PACT-4110
	AND pe.enc_id = d.enc_id
) 

UPDATE #demo
SET cash = 'Y'
WHERE #demo.enc_id IN
(
	SELECT d.enc_id 
	FROM #demo d
	WHERE d.[medi-cal] != 'Y' 
	AND d.fpact != 'Y' 
	AND d.commercial != 'Y'
)

SELECT DISTINCT
 (SELECT COUNT (*) FROM #demo WHERE [medi-cal] = 'Y') AS 'Medi-Cal'
,(SELECT COUNT (*) FROM #demo WHERE commercial = 'Y') AS 'Commercial'
,(SELECT COUNT (*) FROM #demo WHERE fpact = 'Y') AS 'Fpact'
,(SELECT COUNT (*) FROM #demo WHERE cash = 'Y') AS 'Cash'
INTO #payer_count
FROM #demo
--***end fin class***
--select * from #demo
--***Start uninsured count table*** 
SELECT DISTINCT
 (SELECT COUNT (person_id) FROM #demo WHERE white = 'Y' AND (fpact = 'Y' OR cash = 'Y')) AS 'White'
,(SELECT COUNT (person_id) FROM #demo WHERE hispanic = 'Y' AND (fpact = 'Y' OR cash = 'Y')) AS 'Hispanic'
,(SELECT COUNT (person_id) FROM #demo WHERE [race-other] = 'Y' AND (fpact = 'Y' OR cash = 'Y')) AS 'Race-Other'
,(SELECT COUNT (person_id) FROM #demo WHERE [race-unknown] = 'Y' AND (fpact = 'Y' OR cash = 'Y')) AS 'race-Unknown'
,(SELECT COUNT (person_id) FROM #demo WHERE [african-american] = 'Y' AND (fpact = 'Y' OR cash = 'Y')) AS 'African-American'
,(SELECT COUNT (person_id) FROM #demo WHERE [Multi-Racial] = 'Y' AND (fpact = 'Y' OR cash = 'Y')) AS 'Multi-Racial'
,(SELECT COUNT (person_id) FROM #demo WHERE asian = 'Y' AND (fpact = 'Y' OR cash = 'Y')) AS 'Asian'
,(SELECT COUNT (person_id) FROM #demo WHERE [pacific islander] = 'Y' AND (fpact = 'Y' OR cash = 'Y')) AS 'Pacific Islander'
,(SELECT COUNT (person_id) FROM #demo WHERE [native-american] = 'Y' AND (fpact = 'Y' OR cash = 'Y')) AS 'Native American'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '12 & under' AND (fpact = 'Y' OR cash = 'Y')) AS '12 & under'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '13-14' AND (fpact = 'Y' OR cash = 'Y')) AS '13-24'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '15-17' AND (fpact = 'Y' OR cash = 'Y')) AS '15-17'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '18-19' AND (fpact = 'Y' OR cash = 'Y')) AS '18-19'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '20-24' AND (fpact = 'Y' OR cash = 'Y')) AS '20-24'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '25-29' AND (fpact = 'Y' OR cash = 'Y')) AS '25-29'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '30-34' AND (fpact = 'Y' OR cash = 'Y')) AS '30-34'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '35-39' AND (fpact = 'Y' OR cash = 'Y')) AS '35-39'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '40-44' AND (fpact = 'Y' OR cash = 'Y')) AS '40-44'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '45-49' AND (fpact = 'Y' OR cash = 'Y')) AS '45-49'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '50-54' AND (fpact = 'Y' OR cash = 'Y')) AS '50-54'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '<55' AND (fpact = 'Y' OR cash = 'Y')) AS '55 & above'
,(SELECT COUNT (person_id) FROM #demo WHERE sex = 'F'  AND (fpact = 'Y' OR cash = 'Y')) AS Female
,(SELECT COUNT (person_id) FROM #demo WHERE sex = 'M' AND (fpact = 'Y' OR cash = 'Y')) AS Male
,(SELECT COUNT (person_id) FROM #demo WHERE (sex != 'M' AND sex != 'F') AND (fpact = 'Y' OR cash = 'Y')) AS [Other]
INTO #uninsured_count
FROM #demo
--***End uninsured count table*** 

--***Start under 250% FPL count table***
SELECT DISTINCT
 (SELECT COUNT (person_id) FROM #demo WHERE white = 'Y' AND fpl = 'Y') AS 'White'
,(SELECT COUNT (person_id) FROM #demo WHERE hispanic = 'Y' AND fpl = 'Y') AS 'Hispanic'
,(SELECT COUNT (person_id) FROM #demo WHERE [race-other] = 'Y' AND fpl = 'Y') AS 'Race-Other'
,(SELECT COUNT (person_id) FROM #demo WHERE [race-unknown] = 'Y' AND fpl = 'Y') AS 'race-Unknown'
,(SELECT COUNT (person_id) FROM #demo WHERE [african-american] = 'Y' AND fpl = 'Y') AS 'African-American'
,(SELECT COUNT (person_id) FROM #demo WHERE [Multi-Racial] = 'Y' AND fpl = 'Y') AS 'Multi-Racial'
,(SELECT COUNT (person_id) FROM #demo WHERE asian = 'Y' AND fpl = 'Y') AS 'Asian'
,(SELECT COUNT (person_id) FROM #demo WHERE [pacific islander] = 'Y' AND fpl = 'Y') AS 'Pacific Islander'
,(SELECT COUNT (person_id) FROM #demo WHERE [native-american] = 'Y' AND fpl = 'Y') AS 'Native American'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '12 & under' AND fpl = 'Y') AS '12 & under'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '13-14' AND fpl = 'Y') AS '13-24'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '15-17' AND fpl = 'Y') AS '15-17'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '18-19' AND fpl = 'Y') AS '18-19'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '20-24' AND fpl = 'Y') AS '20-24'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '25-29' AND fpl = 'Y') AS '25-29'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '30-34' AND fpl = 'Y') AS '30-34'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '35-39' AND fpl = 'Y') AS '35-39'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '40-44' AND fpl = 'Y') AS '40-44'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '45-49' AND fpl = 'Y') AS '45-49'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '50-54' AND fpl = 'Y') AS '50-54'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '<55' AND fpl = 'Y') AS '55 & above'
,(SELECT COUNT (person_id) FROM #demo WHERE sex = 'F'  AND fpl = 'Y') AS Female
,(SELECT COUNT (person_id) FROM #demo WHERE sex = 'M' AND fpl = 'Y') AS Male
,(SELECT COUNT (person_id) FROM #demo WHERE (sex != 'M' AND sex != 'F') AND fpl = 'Y') AS [Other]
INTO #underFPL_count
FROM #demo
--***End under 250% FPL count table***
--select * from #demo
--drop table #underFPL_count
--select * from #payer_count
SELECT * FROM #uninsured_count
SELECT * FROM #underFPL_count

