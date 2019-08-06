--drop table #temp1
--drop table #temp2
--drop table #bcm
--drop table #bcm2
--drop table #total
--drop table #demo
--drop table #demo_count

--***Declare and set variables***
DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

SET @Start_Date_1 = '20160701'
SET @End_Date_1 = '20170630'

--**********Start data Table Creation***********
--Creates list of all encounters, dx and SIM codes during time period
SELECT DISTINCT pp.person_id, lm.location_name
INTO #temp1
FROM patient_procedure pp
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN person	p			  ON pp.person_id = p.person_id
JOIN location_mstr lm	  ON lm.location_id = pp.location_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1)
AND pp.location_id IN 
(
 '4A785292-DBEB-4D9F-B80A-49E0F7B4999A'		--Carlsbad Planned Parenthood
,'0565487A-C88D-484C-9759-3DF762EA0695'		--Chula Vista Planned Parenthood
,'782C0260-7552-426E-87D6-38F073F40DAD'		--City Heights Planned Parenthood
,'A0D201B2-7AD9-40DD-8A0B-F270478B1736'		--College Ave Planned Parenthood
,'9EA2DE96-E929-499E-819B-4128A72CBC7B'		--El Cajon Planned Parenthood
,'6FAF7F6A-0424-41B0-8B13-D2678C76898A'		--Escondido Planned Parenthood
,'DA5FCD52-AFBE-47F9-A2A2-D96601252CDF'		--Euclid Ave Planned Parenthood
,'6CB12D65-A88C-405C-89C0-7FE677C9D638'		--FA Family Planning Planned Parent
,'68C7DDB4-834A-4ABC-B3EB-87BF71D60F41'		--FA Surgical Services Planned Pare
,'05483D36-4D7C-49B7-8FF1-7AE9FA0E2825'		--Kearny Mesa Planned Parenthood
,'D89E78A1-F4E4-4DC5-8A7A-BCC316E3A747'		--Mira Mesa Planned Parenthood
,'239055AA-220B-4F4B-BC82-0A40825A2F2C'		--Mission Bay Planned Parenthood
,'8CA933B0-8657-4B7C-8B03-F54916ED5103'		--MV Express Planned Parenthood
,'9B706667-0AC8-4BAB-AC72-63B0075D05BF'		--Vista Planned Parenthood
,'5E5D55D7-22BC-40C0-A307-E1CD056CC782'		--Pacific Beach Express Planned Parenthood
,'3A067539-F112-4304-931D-613F7C4F26FD'
)
GROUP BY pp.person_id, lm.location_name

select COUNT(person_id), location_name 
from #temp1
group by location_name
order by location_name

--Creates temp 2 and concatenates same encounters on multiple rows into a single with all service items 
--drop table #
--SELECT enc_id, person_id, service_date,
--	(SELECT ' ' + t2.service_item_id
--	FROM #temp1 t2
--	WHERE t2.enc_id = t1.enc_id
--	FOR XML PATH('')) [Service_Item],
--	(SELECT ' ' + t2.diagnosis_code_id_1 + ' ' + t2.diagnosis_code_id_2 + ' ' + t2.diagnosis_code_id_3 + ' ' + t2.diagnosis_code_id_4
--	FROM #temp1 t2
--	WHERE t2.enc_id = t1.enc_id
--	FOR XML PATH('')) [dx]
--INTO #temp2
--FROM #temp1 t1
--GROUP BY t1.enc_id, t1.person_id, service_date

--Creates BCM at end of visit table and groups by desired categories
select pe.create_timestamp, pe.enc_id, pe.person_id, p.sex, im.txt_birth_control_visitend AS 'BCM', pe.location_id
INTO #bcm
FROM patient_encounter pe
JOIN master_im_ im ON pe.enc_id = im.enc_id
JOIN person p ON p.person_id = pe.person_id 
WHERE (pe.create_timestamp >= @Start_Date_1 AND pe.create_timestamp <= @End_Date_1) AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
order by BCM, Age

--Grabs method from latest encounter date
SELECT BCM, bcm.enc_id, bcm.person_id, bcm.sex, bcm.create_timestamp, bcm.location_id
INTO #bcm2
FROM #bcm bcm
INNER JOIN
	(SELECT person_id, MAX(create_timestamp) AS MAXDATE
	 FROM #bcm
	 GROUP BY person_id) grouped
ON bcm.person_id = grouped.person_id AND bcm.create_timestamp = grouped.MAXDATE

--Main demographics table
select DISTINCT per.person_id
		,b.location_id
		,'age' = CAST((CONVERT(INT,CONVERT(CHAR(8),b.create_timestamp,112))-CONVERT(CHAR(8),per.date_of_birth,112))/10000 AS varchar)
		,'sex' = per.sex
		,'white' = ''
		,'african-american' = ''
		,'asian' = ''
		,'pacific islander' = ''
		,'native-american' = ''
		,'race-other' = ''
		,'race-unknown' = ''
		,'hispanic' = ''
		,'Multi-Racial' = ''
INTO #demo
FROM #temp1 t1
JOIN person per			ON per.person_id	= t1.person_id
JOIN #bcm2 b			ON B.person_id = t1.person_id
WHERE (b.create_timestamp >= @Start_Date_1 AND b.create_timestamp <= @End_Date_1)
AND per.person_id = t1.person_id
AND b.location_id IN (
 '8CA933B0-8657-4B7C-8B03-F54916ED5103'
,'4A785292-DBEB-4D9F-B80A-49E0F7B4999A'
,'782C0260-7552-426E-87D6-38F073F40DAD'
,'5E5D55D7-22BC-40C0-A307-E1CD056CC782'
,'0565487A-C88D-484C-9759-3DF762EA0695'
,'A0D201B2-7AD9-40DD-8A0B-F270478B1736'
,'9EA2DE96-E929-499E-819B-4128A72CBC7B'
,'6FAF7F6A-0424-41B0-8B13-D2678C76898A'
,'05483D36-4D7C-49B7-8FF1-7AE9FA0E2825'
,'DA5FCD52-AFBE-47F9-A2A2-D96601252CDF'
,'6CB12D65-A88C-405C-89C0-7FE677C9D638'
,'68C7DDB4-834A-4ABC-B3EB-87BF71D60F41'
,'D89E78A1-F4E4-4DC5-8A7A-BCC316E3A747'
,'239055AA-220B-4F4B-BC82-0A40825A2F2C'
,'9B706667-0AC8-4BAB-AC72-63B0075D05BF') --only SD health centers

--**********End data Table Creation**********
--select * from #demo
--drop table #demo
--***Start Age***
UPDATE #demo
SET age =
	(
		CASE
			WHEN age BETWEEN 0  AND 17 THEN '>18'
			WHEN age BETWEEN 18 AND 24 THEN '18-24'
			WHEN age BETWEEN 25 AND 29 THEN '25-29'
			WHEN age BETWEEN 30 AND 34 THEN '30-34'
			WHEN age BETWEEN 35 AND 49 THEN '35-49'
			ELSE							'<50'
		END
	)
FROM #demo
--***End Age***

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
WHERE #demo.person_id IN
(
	SELECT d.person_id 
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

--***Creates counts for all demographics***
SELECT DISTINCT
 (SELECT COUNT (person_id) FROM #demo WHERE white = 'Y') AS 'White'
,(SELECT COUNT (person_id) FROM #demo WHERE hispanic = 'Y') AS 'Hispanic'
,(SELECT COUNT (person_id) FROM #demo WHERE [race-unknown] = 'Y') AS 'Race-Unknown'
,(SELECT COUNT (person_id) FROM #demo WHERE [race-other] = 'Y') AS 'Race-Other'
,(SELECT COUNT (person_id) FROM #demo WHERE [african-american] = 'Y') AS 'African American'
,(SELECT COUNT (person_id) FROM #demo WHERE asian = 'Y') AS 'Asian'
,(SELECT COUNT (person_id) FROM #demo WHERE [pacific islander] = 'Y') AS 'Pacific Islander'
,(SELECT COUNT (person_id) FROM #demo WHERE [native-american] = 'Y') AS 'Native American'
,(SELECT COUNT (person_id) FROM #demo WHERE [Multi-Racial] = 'Y' ) AS 'Multi-Racial'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '>18') AS 'Under 18'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '18-24') AS '18-24'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '25-29') AS '25-29'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '30-34') AS '30-34'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '35-49') AS '35-49'
,(SELECT COUNT (person_id) FROM #demo WHERE age = '<50') AS '50+'
,(SELECT COUNT (person_id) FROM #demo WHERE sex = 'F') AS Female
,(SELECT COUNT (person_id) FROM #demo WHERE sex = 'M') AS Male
,(SELECT COUNT (person_id) FROM #demo WHERE sex != 'M' AND sex != 'F') AS [Other]
,(SELECT COUNT ([white] + [hispanic] + [race-unknown] + [race-other] + [african-american] + [asian] + [native-american] 
+ [pacific islander] + [Multi-Racial]) FROM #demo) AS [Total Patients]
INTO #demo_count
FROM #demo
--***End counts for all demographics***
--drop table #demo_count
SELECT * FROM #demo_count