--drop table #temp1
--drop table #temp2
--drop table #enc
--drop table #enc2
--drop table #demo
--drop table #ins

DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime
DECLARE @Location_1 varchar(max)

--SET @Start_Date_1 = @Start_Date
--SET @End_Date_1   = @End_Date
--SET @Location_1   = @Location

SET @Start_Date_1 = '20160601'
SET @End_Date_1 = '20160630'
SET @Location_1 = 'A0D201B2-7AD9-40DD-8A0B-F270478B1736'

--Creates list of all encounters, dx and SIM codes during time period
SELECT pp.location_id, pp.enc_id, pp.person_id, 
       pp.diagnosis_code_id_1, pp.diagnosis_code_id_2, pp.diagnosis_code_id_3, pp.diagnosis_code_id_4, 
       pp.service_item_id, pp.service_date, p.date_of_birth, p.race
INTO #temp1
FROM patient_procedure pp
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN person	p			  ON pp.person_id = p.person_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1)
AND pp.location_id = @location_1
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')

--Creates temp 2 and concatenates same encounters on multiple rows into a single with all service items 
--drop table #
SELECT location_id, enc_id, person_id, service_date,
	(SELECT ' ' + t2.service_item_id
	FROM #temp1 t2
	WHERE t2.enc_id = t1.enc_id
	FOR XML PATH('')) [Service_Item],
	(SELECT ' ' + t2.diagnosis_code_id_1 + ' ' + t2.diagnosis_code_id_2 + ' ' + t2.diagnosis_code_id_3 + ' ' + t2.diagnosis_code_id_4
	FROM #temp1 t2
	WHERE t2.enc_id = t1.enc_id
	FOR XML PATH('')) [dx]
INTO #temp2
FROM #temp1 t1
GROUP BY t1.enc_id, t1.person_id, service_date, location_id

--grabs all enc during time period at specified location
select pe.create_timestamp, pe.enc_id, pe.person_id
INTO #enc
FROM patient_encounter pe
WHERE (pe.create_timestamp >= @Start_Date_1 AND pe.create_timestamp <= @End_Date_1)
AND   pe.location_id = @location_1

--grabs most current enc for each patient
SELECT e.enc_id, e.person_id, e.create_timestamp
INTO #enc2
FROM #enc e
INNER JOIN
	(SELECT person_id, MAX(create_timestamp) AS MAXDATE
	 FROM #enc
	 GROUP BY person_id) grouped
ON e.person_id = grouped.person_id AND e.create_timestamp = grouped.MAXDATE

--***Main demographics table***
select  DISTINCT t.person_id
		,'age' = CAST((CONVERT(INT,CONVERT(CHAR(8),e.create_timestamp,112))-CONVERT(CHAR(8),per.date_of_birth,112))/10000 AS varchar)
		,'sex' = per.sex
		,'white' = ''
		,'african-american' = ''
		,'asian' = ''
		,'pacific islander' = ''
		,'native-american' = ''
		,'race-other' = ''
		,'hispanic' = ''
INTO #demo
FROM #temp2 t
JOIN person per			ON t.person_id		= per.person_id
JOIN #enc2 e			ON t.person_id		= e.person_id
--***End demo table***
--***Start insurance table***
select   pe.enc_id
		,'commercial' = ''
		,'fpact' = ''
		,'cash' = ''
		,'medi-cal' = ''
INTO #ins
FROM patient_encounter pe
JOIN encounter_payer ep ON pe.enc_id	    = ep.enc_id
JOIN payer_mstr pm		ON pe.cob1_payer_id = pm.payer_id
WHERE (pe.create_timestamp >= @Start_Date_1 AND pe.create_timestamp <= @End_Date_1)
AND   pe.location_id = @location_1 --in (SELECT data FROM dbo.ncs_Split (@Location_1,',')) --allow multi location select
--***End insurance table***
--**********END Table Create***********

--***Convert location ID to name***
SELECT location_name
,'a' AS [l]
INTO #loc
FROM location_mstr
WHERE location_id = @Location_1

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
SET [race-other] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE (race LIKE '6-%' OR race LIKE '7-Other') AND ethnicity != 'Hispanic or Latino'
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
--***End ethnicity***

--***Creates counts for all demographics***
SELECT DISTINCT
 (SELECT DISTINCT COUNT (person_id) FROM #demo WHERE white = 'Y') AS 'White'
,(SELECT DISTINCT COUNT (person_id) FROM #demo WHERE hispanic = 'Y') AS 'Hispanic'
,(SELECT COUNT (*) FROM #demo WHERE [race-other] = 'Y') AS 'Unknown'
,(SELECT COUNT (*) FROM #demo WHERE [african-american] = 'Y') AS 'African American'
,(SELECT COUNT (*) FROM #demo WHERE asian = 'Y' OR [pacific islander] = 'Y') AS 'Asian/Pacific Islander'
,(SELECT COUNT (*) FROM #demo WHERE [native-american] = 'Y') AS 'Native American'
,(SELECT COUNT (*) FROM #demo WHERE age = '>18') AS 'Under 18'
,(SELECT COUNT (*) FROM #demo WHERE age = '18-24') AS '18-24'
,(SELECT COUNT (*) FROM #demo WHERE age = '25-29') AS '25-29'
,(SELECT COUNT (*) FROM #demo WHERE age = '30-34') AS '30-34'
,(SELECT COUNT (*) FROM #demo WHERE age = '35-49') AS '35-49'
,(SELECT COUNT (*) FROM #demo WHERE age = '<50') AS '50+'
,(SELECT COUNT (*) FROM #demo WHERE sex = 'F') AS Female
,(SELECT COUNT (*) FROM #demo WHERE sex = 'M') AS Male
,(SELECT COUNT (*) FROM #demo WHERE sex != 'M' AND sex != 'F') AS [Other]
--,(SELECT COUNT (enc_id) FROM #demo) AS [Total Patient Visits]
,'a' AS [d]
INTO #demo_count
FROM #demo

--***Start fin class*** 
UPDATE #ins
SET [medi-cal] = 'Y'
WHERE #ins.enc_id IN
(
	select pe.enc_id
	FROM patient_encounter pe
	JOIN #ins i ON i.enc_id = pe.enc_id
	JOIN payer_mstr pm		ON pe.cob1_payer_id = pm.payer_id
	WHERE (pm.financial_class = '484A05B3-D5C8-415B-A8EE-3D14A7AF11D6' --Medi-Cal Managed Care-4130
	OR	   pm.financial_class = 'C5BDDA12-DDC9-4CFF-A0A3-9749C7DD353D')--Medi-Cal-4120
	AND pe.enc_id = i.enc_id
) 

UPDATE #ins
SET commercial = 'Y'
WHERE #ins.enc_id IN
(
	select pe.enc_id
	FROM patient_encounter pe
	JOIN #ins i ON pe.enc_id = i.enc_id
	JOIN payer_mstr pm		ON pe.cob1_payer_id = pm.payer_id
	WHERE (pm.financial_class = '8E5D6C7E-A34E-4B3C-8C0A-B2F1D2E20285' --Commercial Ins Exchange-4330
	OR	   pm.financial_class = '332DF613-7C43-4287-9050-9949B4142B0C')--Commercial Ins Non-Exchange-4310
	AND pe.enc_id = i.enc_id
) 

UPDATE #ins
SET fpact = 'Y'
WHERE #ins.enc_id IN
(
	select pe.enc_id
	FROM patient_encounter pe
	JOIN #ins i ON i.enc_id = pe.enc_id
	JOIN payer_mstr pm		ON pe.cob1_payer_id = pm.payer_id
	WHERE pm.financial_class = 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF' --Family PACT-4110
	AND pe.enc_id = i.enc_id
) 

UPDATE #ins
SET cash = 'Y'
WHERE #ins.enc_id IN
(
	SELECT i.enc_id 
	FROM #ins i
	WHERE i.[medi-cal] != 'Y' 
	AND i.fpact != 'Y' 
	AND i.commercial != 'Y'
)

SELECT DISTINCT
 (SELECT COUNT (*) FROM #ins WHERE [medi-cal] = 'Y') AS 'Medi-Cal'
,(SELECT COUNT (*) FROM #ins WHERE commercial = 'Y') AS 'Commercial'
,(SELECT COUNT (*) FROM #ins WHERE fpact = 'Y') AS 'Fpact'
,(SELECT COUNT (*) FROM #ins WHERE cash = 'Y') AS 'Cash'
,'a' AS [p]
INTO #payer_count
FROM #demo
--***end fin class*** 

--***Start service item***
--Wildcards used because Service_Item column is considered one long string so it will not find matches using equals or list
--***Start Cancer*** Combines both cancer screening procedures with Clinic breast exams
SELECT DISTINCT
 (SELECT COUNT (*) FROM #temp2 WHERE 
	(
		   Service_Item LIKE '%L079%' --pap
		OR Service_Item LIKE '%L124%' --pap
		OR Service_Item LIKE '%L034%' --pap
		--OR Service_Item LIKE '%L047%' --Biopsy
		--OR Service_Item LIKE '%57500%' --genital biopsy
		--OR Service_Item LIKE '%57500%' --vulva biopsy
		--OR Service_Item LIKE '%58100%' --endo biopsy
		--OR Service_Item LIKE '%58110%' --endo biopsy with colpo
		--OR Service_Item LIKE '%57454%' --colpo
		--OR Service_Item LIKE '%57460%' --leep Cancer screening?
	) 
 ) AS [Pap]
,(SELECT COUNT (*) FROM patient_encounter pe --CBE
	JOIN PhysExamExtPop_ peep ON peep.enc_id = pe.enc_id
	JOIN #temp2 t2 ON t2.enc_id = pe.enc_id 
	WHERE peep.ExamFindings LIKE '%Palpation%')
 AS [CBE]
 --***End Cancer***

--***Start preg test***
,(SELECT COUNT (*) FROM #temp2 WHERE 
	(   
		Service_Item LIKE '%81025K%' --Preg test
	) 
) AS [Pregnancy Test]
--***End preg test***

--***Start Contraception***
,(SELECT COUNT (*) FROM #temp2 WHERE 
	(
			   Service_Item LIKE '%AUBRA%' --Pill types
			OR Service_Item LIKE '%Brevicon%'
			OR Service_Item LIKE '%CHATEAL%'
			OR Service_Item LIKE '%Cyclessa%'
			OR Service_Item LIKE '%Desogen%'
			OR Service_Item LIKE '%Gildess%'
			OR Service_Item LIKE '%Levora%'
			OR Service_Item LIKE '%LYZA%'
			OR Service_Item LIKE '%Mgestin%'
			OR Service_Item LIKE '%Micronor%'
			OR Service_Item LIKE '%Modicon%'
			OR Service_Item LIKE '%OCEPT%'
			OR Service_Item LIKE '%ORCYCLEN%'
			OR Service_Item LIKE '%OTRICYCLEN%'
			OR Service_Item LIKE '%OTRINC%'
			OR Service_Item LIKE '%RECLIPSEN%'
			OR Service_Item LIKE '%Tarina%'
			OR Service_Item LIKE '%J7303%' --ring
			OR Service_Item LIKE '%J7304%' --patch
			OR Service_Item LIKE '%XULANE%' --patch
			OR Service_Item LIKE '%J730[0-2]%' --IUC
			OR Service_Item LIKE '%J7307%' --Implant
			OR Service_Item LIKE '%J1050%' --Depo
			OR Service_Item LIKE '%C003%' --diaphragm
			OR Service_Item LIKE '%C005%' --diaphragm
			OR Service_Item LIKE '%C006%' --foam
			OR Service_Item LIKE '%dental%' --dental dam
			OR Service_Item LIKE '%film%' --film
			OR Service_Item LIKE '%sponge%' --film
			--OR Service_Item LIKE '%[1-4][0-8]con%' --condoms excluded
		)
) AS [Contraception]
--***End Contraception***

--***Start STI Test***
,(SELECT COUNT (*) FROM #temp2 WHERE 
		(
		   Service_Item LIKE '%87491%' --CT
		OR Service_Item LIKE '%87591%' --GC
		OR Service_Item LIKE '%L104%' --oral
		OR Service_Item LIKE '%L105%' --anal
		OR Service_Item LIKE '%L071%' --vag/urine - quest
		OR Service_Item LIKE '%L033%' --herpes
		OR Service_Item LIKE '%L095%' --herpes
		OR Service_Item LIKE '%L110%' --herpes
		OR Service_Item LIKE '%L023%' --HIV
		OR Service_Item LIKE '%L099%' --HIV
		OR Service_Item LIKE '%86703%'--HIV
		OR Service_Item LIKE '%L106%' --culture
		OR Service_Item LIKE '%L026%' --Syph
		OR Service_Item LIKE '%L111%' --Syph
		OR Service_Item LIKE '%L030%' --Syph
		OR Service_Item LIKE '%L096%' --HPV
		)
) AS [STI Tests]
--***End STI Test***

--***Start STI Treatment***
,(SELECT COUNT (*) FROM #temp2 WHERE 
	(
		   Service_Item LIKE '%46900%' --destruction anal lesion
		OR Service_Item LIKE '%54050%' --destruction penile lesion
		OR Service_Item LIKE '%54056%' --destruction penile lesion
		OR Service_Item LIKE '%57061%' --destruction vaginal lesion
		OR Service_Item LIKE '%57065%' --destruction vaginal lesion
		OR Service_Item LIKE '%56501%' --destruction vulvar lesion
		OR Service_Item LIKE '%56515%' --destruction vaginal lesion
		OR Service_Item LIKE '%M088%' --acyclovir
		OR Service_Item LIKE '%M089%' --acyclovir
		OR Service_Item LIKE '%M093%' --acyclovir
		OR Service_Item LIKE '%M074%' --aldera
		OR Service_Item LIKE '%M045%' --Doxycycline
		OR Service_Item LIKE '%M047%' --Doxycycline
		OR Service_Item LIKE '%M049%' --Doxycycline
		)
) AS [STI Treatment]
--***End STI Treatment***

--***Start AB***
,(SELECT COUNT (*) FROM #temp2 WHERE 
	(
		   Service_Item LIKE '%59840A%' --TAB
		OR Service_Item LIKE '%59841[C-N]%' --TAB
		OR Service_Item LIKE '%S0199%' --MAB
		OR Service_Item LIKE '%S0199A%' --MAB
		)
) AS [AB Services]
,'a' AS [s]
--***End AB***
INTO #service_count
FROM #temp2
--***End service item***

--drop table #demo_count
--***Join all count tables together***
SELECT * 
FROM #payer_count pc
JOIN #demo_count dc ON dc.d = pc.p
JOIN #service_count sc ON sc.s = pc.p
JOIN #loc lc ON lc.l = pc.p