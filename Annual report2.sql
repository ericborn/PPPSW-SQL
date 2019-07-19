--drop table #temp1
--drop table #date
--drop table #bcm
--drop table #demo
--drop table #demo_count
--drop table #bcm2
--drop table #BCM_EOV_Count
--drop table #service_count
--drop table #total

--***Declare and set variables***
DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

SET @Start_Date_1 = '20170101'
SET @End_Date_1 = '20171231'

--**********Start data Table Creation***********
--Creates list of all encounters, dx and SIM codes during time period
SELECT pp.enc_id, pp.person_id, 
       pp.service_item_id, pp.service_date, p.date_of_birth, p.race, p.sex, units, ethnicity
INTO #temp1
FROM NGProd.dbo.patient_procedure pp
JOIN NGProd.dbo.patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN NGProd.dbo.person	p			  ON pp.person_id = p.person_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1)
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --Clinical services and Lab locations are excluded
--select * from location_mstr
SELECT distinct t.enc_id, t.person_id, t.service_date
INTO #date
FROM #temp1 t
INNER JOIN
	(SELECT person_id, MAX(service_date) AS MAXDATE
	 FROM #temp1
	 GROUP BY person_id) grouped
ON t.person_id = grouped.person_id AND t.service_date = grouped.MAXDATE

--Creates BCM at end of visit table and groups by desired categories
SELECT DISTINCT t.service_date, t.enc_id, t.person_id, im.txt_birth_control_visitend AS 'BCM'
INTO #bcm
FROM #temp1 t
JOIN NGProd.dbo.master_im_ im ON t.enc_id = im.enc_id
JOIN NGProd.dbo.person p ON p.person_id = t.person_id
INNER JOIN
	(SELECT person_id, MAX(service_date) AS MAXDATE
	 FROM #temp1
	 GROUP BY person_id) grouped
ON t.person_id = grouped.person_id AND t.service_date = grouped.MAXDATE

--Main demographics table
SELECT DISTINCT t.person_id
		,'age' = CAST((CONVERT(INT,CONVERT(CHAR(8),d.service_date,112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar)
		,'sex' = sex
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
FROM #temp1 t
JOIN #date d				ON t.person_id = d.person_id 

--**********End data Table Creation**********
--select * from #demo
--drop table #demo
--**********Start Page 1**********
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
	FROM NGProd.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '1- white' AND ethnicity != 'Hispanic or Latino'
)

UPDATE #demo
SET [african-american] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM NGProd.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '2- African American' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET asian = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM NGProd.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '3- Asian' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [pacific islander] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM NGProd.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '4- Pacific Islander' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [native-american] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM NGProd.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '5- Native American' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [race-unknown] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM NGProd.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE (race LIKE '6- unkno%') AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [race-other] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM NGProd.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE (race = '7- Other') AND ethnicity != 'Hispanic or Latino'
)

UPDATE #demo
SET [Multi-Racial] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM NGProd.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '6-Multi-racial' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [race-unknown] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM NGProd.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE (race IS NULL OR race = '' OR race = '6- Unknown/Declined To Specify') AND ethnicity != 'Hispanic or Latino'
)
--***End Race***

--***Start ethnicity***
UPDATE #demo
SET hispanic = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM NGProd.dbo.person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE ethnicity = 'Hispanic or Latino'
)
UPDATE #demo
SET hispanic = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM NGProd.dbo.person p
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
--select * from #demo
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
,(SELECT COUNT ([white] + [african-american] + [asian] + [pacific islander] + [native-american] + [race-other] + [race-unknown] 
+ [hispanic] + [Multi-Racial]) FROM #demo) AS [Total Patients]
,[b] = 'a'
INTO #demo_count
FROM #demo
--***End counts for all demographics***
--drop table #bcm2
--**********End Page 1**********
--**********Start Page 2**********
--***Start Contraception by BCM at end of visit***
--***Female Only***
SELECT DISTINCT person_id
,'OC EOV' = ''
,'Depo EOV' = ''
,'Ring EOV' = ''
,'Patch EOV' = ''
,'IUC EOV' = ''
,'Implant EOV' = ''
,'Perm EOV' = ''
,'Condom EOV' = ''
,'Other EOV' = ''
,'none EOV' = ''
,'no method needed EOV' = ''
INTO #bcm2
FROM #demo
WHERE sex = 'f'

--***Update table with BCM at end of visit***
UPDATE #bcm2
SET [OC EOV] = 'y'
WHERE person_id IN
(
SELECT DISTINCT person_id
FROM #bcm 
WHERE BCM LIKE 'Oral%'
)

UPDATE #bcm2
SET [Depo EOV] = 'y'
WHERE person_id IN
(
SELECT DISTINCT person_id
FROM #bcm 
WHERE BCM = 'injection'
) AND 
(   [OC EOV] = '' 
AND [ring EOV] = ''
AND [patch EOV] = ''
AND [iuc EOV] = ''
AND [Implant EOV] = ''
AND [perm EOV] = ''
AND [Condom EOV] = ''
AND [Other EOV] = ''
AND [none EOV] = ''
AND [no method needed EOV] = ''
)

UPDATE #bcm2
SET [Ring EOV] = 'y'
WHERE person_id IN
(
SELECT DISTINCT person_id
FROM #bcm 
WHERE BCM = 'ring'
) AND 
(   [OC EOV] = '' 
AND [Depo EOV] = ''
AND [patch EOV] = ''
AND [iuc EOV] = ''
AND [Implant EOV] = ''
AND [perm EOV] = ''
AND [Condom EOV] = ''
AND [Other EOV] = ''
AND [none EOV] = ''
AND [no method needed EOV] = ''
)


UPDATE #bcm2
SET [patch EOV] = 'y'
WHERE person_id IN
(
SELECT DISTINCT person_id
FROM #bcm 
WHERE BCM = 'patch'
)AND 
(   [OC EOV] = '' 
AND [Depo EOV] = ''
AND [Ring EOV] = ''
AND [iuc EOV] = ''
AND [Implant EOV] = ''
AND [perm EOV] = ''
AND [Condom EOV] = ''
AND [Other EOV] = ''
AND [none EOV] = ''
AND [no method needed EOV] = ''
)

UPDATE #bcm2
SET [IUC EOV] = 'y'
WHERE person_id IN
(
SELECT DISTINCT person_id
FROM #bcm 
WHERE BCM LIKE 'iuc%'
)AND 
(   [OC EOV] = '' 
AND [Depo EOV] = ''
AND [Ring EOV] = ''
AND [patch EOV] = ''
AND [Implant EOV] = ''
AND [perm EOV] = ''
AND [Condom EOV] = ''
AND [Other EOV] = ''
AND [none EOV] = ''
AND [no method needed EOV] = ''
)

UPDATE #bcm2
SET [Implant EOV] = 'y'
WHERE person_id IN
(
SELECT DISTINCT person_id
FROM #bcm 
WHERE BCM = 'implant'
)AND 
(   [OC EOV] = '' 
AND [Depo EOV] = ''
AND [Ring EOV] = ''
AND [patch EOV] = ''
AND [IUC EOV] = ''
AND [perm EOV] = ''
AND [Condom EOV] = ''
AND [Other EOV] = ''
AND [none EOV] = ''
AND [no method needed EOV] = ''
)

UPDATE #bcm2
SET [Perm EOV] = 'y'
WHERE person_id IN
(
SELECT DISTINCT person_id
FROM #bcm 
WHERE 
   BCM = 'Female Sterilization' 
OR BCM = 'Vasectomy'
)AND 
(   [OC EOV] = '' 
AND [Depo EOV] = ''
AND [Ring EOV] = ''
AND [patch EOV] = ''
AND [IUC EOV] = ''
AND [Implant EOV] = ''
AND [Condom EOV] = ''
AND [Other EOV] = ''
AND [none EOV] = ''
AND [no method needed EOV] = ''
)

UPDATE #bcm2
SET [Condom EOV] = 'y'
WHERE person_id IN
(
SELECT DISTINCT person_id
FROM #bcm 
WHERE BCM = 'male condom'
)AND 
(   [OC EOV] = '' 
AND [Depo EOV] = ''
AND [Ring EOV] = ''
AND [patch EOV] = ''
AND [IUC EOV] = ''
AND [Implant EOV] = ''
AND [Perm EOV] = ''
AND [Other EOV] = ''
AND [none EOV] = ''
AND [no method needed EOV] = ''
)

UPDATE #bcm2
SET [Other EOV] = 'y'
WHERE person_id IN
(
SELECT DISTINCT person_id
FROM #bcm 
WHERE 
   BCM = 'Other Methods'
OR BCM = 'Spermicide' 
OR BCM = 'Sponge' 
OR BCM = 'Cervical cap/Diaphragm' 
OR BCM = 'Partner Method'
OR BCM = 'Female Condom'
OR BCM = 'FAM/NFP' 
)AND 
(   [OC EOV] = '' 
AND [Depo EOV] = ''
AND [Ring EOV] = ''
AND [patch EOV] = ''
AND [IUC EOV] = ''
AND [Implant EOV] = ''
AND [Perm EOV] = ''
AND [Condom EOV] = ''
AND [none EOV] = ''
AND [no method needed EOV] = ''
)

UPDATE #bcm2
SET [none EOV] = 'y'
WHERE person_id IN
(
SELECT DISTINCT person_id
FROM #bcm 
WHERE 
   BCM = 'No Method' 
OR BCM IS NULL
)AND 
(   [OC EOV] = '' 
AND [Depo EOV] = ''
AND [Ring EOV] = ''
AND [patch EOV] = ''
AND [IUC EOV] = ''
AND [Implant EOV] = ''
AND [Perm EOV] = ''
AND [Condom EOV] = ''
AND [Other EOV] = ''
AND [no method needed EOV] = ''
)

UPDATE #bcm2
SET [no method needed EOV] = 'y'
WHERE person_id IN
(
SELECT DISTINCT person_id
FROM #bcm 
WHERE 
   BCM = 'No Method Needed'
OR BCM = 'Abstinence'
OR BCM = 'Infertile'
OR BCM = 'Pregnant/Partner Pregnant'
OR BCM = 'Same Sex Partner'
OR BCM = 'Seeking pregnancy'
)AND 
(   [OC EOV] = '' 
AND [Depo EOV] = ''
AND [Ring EOV] = ''
AND [patch EOV] = ''
AND [IUC EOV] = ''
AND [Implant EOV] = ''
AND [Perm EOV] = ''
AND [Condom EOV] = ''
AND [Other EOV] = ''
AND [none EOV] = ''
)

UPDATE #bcm2
SET [none EOV] = 'y'
WHERE
(
	[OC EOV] = ''
AND [Depo EOV] = ''
AND [ring EOV] = ''
AND [patch EOV] = ''
AND [iuc EOV] = ''
AND [Implant EOV] = ''
AND [perm EOV] = ''
AND [Condom EOV] = ''
AND [Other EOV] = ''
AND [none EOV] = ''
AND [no method needed EOV] = ''
)

--drop table #BCM_EOV_Count
SELECT DISTINCT
 (SELECT COUNT(DISTINCT person_id) FROM #bcm2 WHERE [OC EOV] = 'y') AS 'OC EOV'
,(SELECT COUNT(DISTINCT person_id) FROM #bcm2 WHERE [Depo EOV] = 'y') AS 'Depo EOV'
,(SELECT COUNT(DISTINCT person_id) FROM #bcm2 WHERE [ring EOV] = 'y') AS 'Ring EOV'
,(SELECT COUNT(DISTINCT person_id) FROM #bcm2 WHERE [patch EOV] = 'y') AS 'Patch EOV'
,(SELECT COUNT(DISTINCT person_id) FROM #bcm2 WHERE [iuc EOV] = 'y') AS 'IUC EOV'
,(SELECT COUNT(DISTINCT person_id) FROM #bcm2 WHERE [Implant EOV] = 'y') AS 'Implant EOV'
,(SELECT COUNT(DISTINCT person_id) FROM #bcm2 WHERE [perm EOV] = 'y') AS 'Permanent Methods EOV'
,(SELECT COUNT(DISTINCT person_id) FROM #bcm2 WHERE [Condom EOV] = 'y') AS 'Male Condom EOV'
,(SELECT COUNT(DISTINCT person_id) FROM #bcm2 WHERE [Other EOV] = 'y') AS 'Other Methods EOV'
,(SELECT COUNT(DISTINCT person_id) FROM #bcm2 WHERE [none EOV] = 'y') AS 'No Method EOV'
,(SELECT COUNT(DISTINCT person_id) FROM #bcm2 WHERE [no method needed EOV] = 'y') AS 'No Method Needed EOV'
,[c] = 'a'
INTO #BCM_EOV_Count
--***End Contraception by BCM at end of visit***
--**********End Page 2**********

--**********Start Page 3**********
--***Start Contraception***
--***Count of cycles Dispensed***
SELECT DISTINCT
--(SELECT distinct units, count(units)--SUM(units)
(SELECT SUM(units)
 FROM #temp1 t1
 WHERE 
	(
		   t1.service_item_id LIKE '%AUBRA%' --Pill types
		OR t1.service_item_id LIKE '%Brevicon%'
		OR t1.service_item_id LIKE '%CHATEAL%'
		OR t1.service_item_id LIKE '%Cyclessa%'
		OR t1.service_item_id LIKE '%Desogen%'
		OR t1.service_item_id LIKE '%Gildess%'
		OR t1.service_item_id LIKE '%Levora%'
		OR t1.service_item_id LIKE '%LYZA%'
		OR t1.service_item_id LIKE '%Mgestin%'
		OR t1.service_item_id LIKE '%Micronor%'
		OR t1.service_item_id LIKE '%Modicon%'
		OR t1.service_item_id LIKE '%OCEPT%'
		OR t1.service_item_id LIKE '%ON135%'
		OR t1.service_item_id LIKE '%ON777%'
		OR t1.service_item_id LIKE '%ORCYCLEN%'
		OR t1.service_item_id LIKE '%OTRICYCLEN%'
		OR t1.service_item_id LIKE '%OTRINC%'
		OR t1.service_item_id LIKE '%RECLIPSEN%'
		OR t1.service_item_id LIKE '%Tarina%'
		OR t1.service_item_id LIKE '%TRILO%'
	) 
 )AS OC

,(SELECT --(Patch)
	CAST(SUM(
		CASE
			WHEN units BETWEEN 12 AND 39 THEN units / 3
			ELSE units
		END
	   ) AS DECIMAL(25,0)) 
FROM #temp1 t1
WHERE (service_item_id = 'J7304' OR service_item_id = 'xulane') AND units > 0
 ) AS [Patch]

,(SELECT SUM(units)
FROM #temp1 t1
WHERE service_item_id = 'J7303'
 ) AS [Ring]

--One depo injection lasts for three cycles. 
--Since we are tracking cycles the total number of injections in multiplied by 3
,(SELECT COUNT (person_id) * 3 FROM #temp1 WHERE service_item_id = 'J1050') AS Depo

,(SELECT COUNT (person_id) FROM #temp1 WHERE service_item_id = 'J7297') AS Liletta

,(SELECT COUNT (person_id) FROM #temp1 WHERE service_item_id IN ('J7302', 'J7298')) AS Mirena
 
,(SELECT COUNT (person_id) FROM #temp1 WHERE service_item_id = 'J7301') AS Skyla

,(SELECT COUNT (person_id) FROM #temp1 WHERE service_item_id = 'J7300') AS Paraguard

,(SELECT COUNT (person_id) FROM #temp1 WHERE service_item_id = 'J7307') AS Implant

,(SELECT COUNT (DISTINCT person_id) FROM #temp1 WHERE service_item_id 
IN('58670'--BTL
  ,'58565B','58565U') --Essure
 ) AS [Perm-Female]


,(SELECT COUNT (DISTINCT person_id) FROM #temp1 WHERE service_item_id = '55250') AS [Perm-Male]

,(SELECT SUM(units)
FROM #temp1
WHERE (service_item_id LIKE '%ella%' 
	OR service_item_id LIKE '%econtra%' 
	OR service_item_id LIKE '%next%'
	OR service_item_id LIKE '%X7722%' --Plan B
	  ) 
)AS EC
,[d] = 'a'
INTO #contra_count
--***End Contraception*** 

--***Start services***
--***GC/CT Combo tests counted as two since two tests are performed***
SELECT DISTINCT
 (SELECT COUNT (*) * 2 
 FROM #temp1 
 WHERE 
    service_item_id LIKE '%L071%' --GC/CT Combo
 OR service_item_id LIKE '%L103%'
 OR service_item_id LIKE '%L104%'
 OR service_item_id LIKE '%L105%'
 OR service_item_id LIKE '%L073%'
 ) 
  + 
  (SELECT COUNT (*) FROM #temp1 WHERE 
	service_item_id LIKE '%87491%' --CT
 OR service_item_id LIKE '%L031%'
 OR service_item_id LIKE '%L069%'
  )
  +
  (SELECT COUNT (*) FROM #temp1 WHERE 
	service_item_id LIKE '%87591%' --GC
 OR service_item_id LIKE '%L070%'
  )
AS [Chlamydia and Gonorrhea Tests]

,(SELECT COUNT (*) FROM #temp1 WHERE 
    service_item_id LIKE '%L023%' --HIV
 OR service_item_id LIKE '%L099%'
 OR service_item_id LIKE '%86703%'
 OR service_item_id LIKE '%87806%') 
AS HIV

,(SELECT COUNT (*) FROM #temp1 WHERE 
	
		   service_item_id IN ('L033', 'L095', 'L110') --herpes
	)
	+
	(SELECT COUNT (*) FROM #temp1 WHERE 
		service_item_id IN ('L034','L096','L124')	
	)
	+
	(SELECT COUNT (*) FROM #temp1 WHERE 
		   service_item_id = 'L026' --Syph
	)
	+
	(SELECT COUNT (*) FROM #temp1 WHERE 
		   service_item_id IN
		   ('L111', 'L112') --Trich
	)
AS [Other-STI]

,(SELECT COUNT (*) FROM #temp1 WHERE 
	service_item_id LIKE '%L079%' --PAP
 OR service_item_id LIKE '%L034%'
 OR service_item_id LIKE '%L124%') 
AS PAP

--,(SELECT COUNT (DISTINCT t.enc_id) 
--FROM pe_breast_ pb
--JOIN #temp1 t ON t.enc_id = pb.enc_id 
--AND (pb.palpr_nl = '1' or pb.palpL_nL = '1' or pb.palpb_nl = '1' 
--OR pb.palponly1 IS NOT NULL OR pb.palponly2 IS NOT NULL OR pb.palponly3 IS NOT NULL OR pb.palponly4 IS NOT NULL
--OR pb.palpb1 IS NOT NULL OR pb.palpb2 IS NOT NULL)) AS CBE

,(SELECT COUNT (DISTINCT t.enc_id) 
	FROM #temp1 t
	JOIN NGProd.dbo.PhysExamExtPop_ peep ON peep.enc_id = t.enc_id
	WHERE peep.ExamFindings LIKE '%Palpation%'
	AND	  SystemExamed = 'breast'
) AS CBE

--,(SELECT COUNT (DISTINCT t.enc_id) 
--	FROM NGProd.dbo.patient_encounter pe 
--	JOIN NGProd.dbo.PhysExamExtPop_ peep ON peep.enc_id = pe.enc_id
--	--JOIN #bcm b ON b.enc_id = pe.enc_id
--	JOIN #temp1 t ON t.enc_id = pe.enc_id
--	WHERE peep.ExamFindings LIKE '%Palpation%'
--	AND	  SystemExamed = 'breast'
--) AS CBE

--SELECT COUNT (*) FROM NGProd.dbo.patient_encounter pe 
--	JOIN NGProd.dbo.PhysExamExtPop_ peep ON peep.enc_id = pe.enc_id
--	JOIN #bcm b ON b.enc_id = pe.enc_id 
--	--JOIN #temp1 t ON t.enc_id = pe.enc_id
--	WHERE peep.ExamFindings LIKE '%Palpation%'


,(SELECT COUNT (*) FROM #temp1 WHERE
	service_item_id IN 
	(
		 '46900' --destruction anal lesion
		,'46910'
		,'46916'
		,'46917'
		,'46922'
		,'46924'
		,'54050' --destruction penile lesion
		,'54055'
		,'54056' --destruction penile lesion
		,'54057'
		,'54060'
		,'54065'
		,'56501' --destruction vulvar lesion
		,'56515' --destruction vaginal lesion ***
		,'57061' --destruction vaginal lesion
		,'57065' --destruction vaginal lesion ***
		
	)
) AS [HPV-Treatment]

,(SELECT COUNT (*) FROM #temp1 
  WHERE service_item_id LIKE '%90649%' OR service_item_id LIKE '%M091%') 
  AS [HPV-Vacc]

 -- select distinct service_item_id, service_item_desc 
 -- from patient_procedure
 -- where service_item_id IN 
	--(
	--	 '46900' --destruction anal lesion
	--	,'46910'
	--	,'46916'
	--	,'46917'
	--	,'46922'
	--	,'46924'
	--	,'54050' --destruction penile lesion
	--	,'54055'
	--	,'54056' --destruction penile lesion
	--	,'54057'
	--	,'54060'
	--	,'54065'
	--	,'56501' --destruction vulvar lesion
	--	,'56515' --destruction vaginal lesion ***
	--	,'57061' --destruction vaginal lesion
	--	,'57065' --destruction vaginal lesion ***
	--) order by service_item_id
--select service_date, service_item_id, service_item_desc 
--from patient_procedure
--where service_item_id = '56515'
--order by service_date desc

 -- SELECT COUNT (distinct enc_id) FROM #temp1 WHERE
	--service_item_id IN 
	--(
	--	 '57454', '56820', '56821', '57420', '57421', '57452', '57455', '47456','58110' --colpo
	--	,'57460', '57461' --leep
	--)

,(SELECT COUNT (*) FROM #temp1 WHERE
	service_item_id IN 
	(
		 '57454', '56820', '56821', '57420', '57421', '57452', '57455', '47456','58110' --colpo
		,'57460', '57461' --leep
	)
 ) AS [Colpo/Leep]

,(SELECT COUNT (*) FROM #temp1 WHERE 
	(
	   service_item_id LIKE '%S0199%' --MAB
	OR service_item_id LIKE '%S0199A%' --MAB
	)
) AS MAB

,(SELECT COUNT (*) FROM #temp1 WHERE 
	(
	   service_item_id LIKE '%59840A%' --TAB
	OR service_item_id LIKE '%59841[C-N]%' --TAB
	)
) AS TAB

,(SELECT COUNT (*) FROM #temp1 WHERE service_item_id LIKE '%81025K%') AS [Preg-Test]
,[e] = 'a'
INTO #service_count
FROM #temp1
--***End Services***

--***Start Summary of Services***
--***Section presents counts of visits where service took place***
--***Since all but contraception information in previous sections is counted as one per visit that data will be used here***
SELECT DISTINCT
(SELECT COUNT(DISTINCT enc_id) 
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
	,'58670' --BTL
	,'58671' --BTL
	,'58565' --Essure
	,'55250' --VAS
)) AS Contraception
,(SELECT [Chlamydia and Gonorrhea Tests] + HIV + [Other-STI] FROM #service_count) AS [STI Testing]
,(SELECT PAP + CBE + [HPV-Treatment] + [HPV-Vacc] + [Colpo/Leep] FROM #service_count) AS [Cancer Screening]
,(SELECT MAB + TAB FROM #service_count) AS [Abortion Services]
,(SELECT [Preg-Test] FROM #service_count) AS [Pregnancy Testing]
,[f] = 'a'
INTO #total
FROM #contra_count
--***End Summary of Services***
--**********End Page 3**********

SELECT * FROM #demo_count
SELECT * FROM #BCM_EOV_Count
SELECT * FROM #contra_count
SELECT * FROM #service_count
SELECT * FROM #total

--SELECT * 
--INTO #report
--FROM #demo_count d
--JOIN #BCM_EOV_Count b ON b.c = d.b
--JOIN #contra_count c ON c.d = d.b
--JOIN #service_count s ON s.e = d.b
--JOIN #total t ON t.f = d.b

--ALTER TABLE #report
--DROP COLUMN b

--ALTER TABLE #report
--DROP COLUMN c

--ALTER TABLE #report
--DROP COLUMN d

--ALTER TABLE #report
--DROP COLUMN e

--ALTER TABLE #report
--DROP COLUMN f

--select * from #report