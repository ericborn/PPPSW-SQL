--drop table #temp1
--drop table #bcm
--drop table #bcm2
--drop table #h
--drop table #demo
--drop table #demo_count

--***Declare and set variables***
DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime
DECLARE @Location_1 varchar(40)

SET @Start_Date_1 = '20170101'
SET @End_Date_1 = '20170331'
SET @Location_1 = '9EA2DE96-E929-499E-819B-4128A72CBC7B' --ec
--9EA2DE96-E929-499E-819B-4128A72CBC7B --EC
--select * from location_mstr
--**********Start data Table Creation***********
--Creates list of all encounters, dx and SIM codes during time period
SELECT pp.enc_id, pp.person_id, 
       pp.diagnosis_code_id_1, pp.diagnosis_code_id_2, pp.diagnosis_code_id_3, pp.diagnosis_code_id_4, 
       pp.service_item_id, pp.service_date, pp.location_id
INTO #temp1
FROM ngprod.dbo.patient_procedure pp
JOIN ngprod.dbo.patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN ngprod.dbo.person	p			  ON pp.person_id = p.person_id
JOIN ngprod.dbo.location_mstr lm	  ON pp.location_id = lm.location_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1) 
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND   lm.location_id = @Location_1

--Creates BCM at end of visit table and groups by desired categories
select t.service_date, t.enc_id, t.person_id, p.sex, im.txt_birth_control_visitend AS 'BCM'
INTO #bcm
FROM #temp1 t
JOIN ngprod.dbo.master_im_ im ON t.enc_id = im.enc_id
JOIN ngprod.dbo.person p ON p.person_id = t.person_id 
--order by BCM, Age

--Grabs method from latest encounter date
SELECT BCM, bcm.enc_id, bcm.person_id, bcm.sex, bcm.service_date
INTO #bcm2
FROM #bcm bcm
INNER JOIN
	(SELECT person_id, MAX(service_date) AS MAXDATE
	 FROM #bcm
	 GROUP BY person_id) grouped
ON bcm.person_id = grouped.person_id AND bcm.service_date = grouped.MAXDATE

--***Start demographics table***
select DISTINCT lm.location_name
		,per.person_id
		,'age' = CAST((CONVERT(INT,CONVERT(CHAR(8),b.service_date,112))-CONVERT(CHAR(8),per.date_of_birth,112))/10000 AS varchar)
		,'sex' = per.sex
		,'ct' = 'N'
		,'pap' = 'N'
		,'BMI' = 'N'
		,'smoking' = 'N'
		,'cessation' = ''
		,'contra' = ''
		,'LARC' = ''
INTO #demo
FROM #temp1 t2
JOIN ngprod.dbo.person per		 ON per.person_id	= t2.person_id
JOIN #bcm2 b					 ON B.person_id = t2.person_id
JOIN ngprod.dbo.location_mstr lm ON t2.location_id = lm.location_id
--***End demographics table***

--***CT Screening***
UPDATE #demo
SET ct = 'Y'
WHERE #demo.person_id IN
(
SELECT DISTINCT pp.person_id
FROM ngprod.dbo.patient_procedure pp
JOIN #temp1 t ON t.person_id = pp.person_id
WHERE pp.service_date >= DATEADD(YEAR, -1, t.service_date)
   AND pp.service_item_id IN ('L031','L069','L071','L073','L103','L104','L105', '87491') --CT
   AND sex = 'F'
)

--***Start PAP***
UPDATE #demo
SET pap = 'Y'
WHERE #demo.person_id IN
(
SELECT DISTINCT pp.person_id
FROM ngprod.dbo.patient_procedure pp
JOIN #temp1 t ON t.person_id = pp.person_id
--JOIN #bcm2 b ON b.person_id = pp.person_id
WHERE pp.service_date >= DATEADD(YEAR, -3, t.service_date)
   AND (pp.service_item_id LIKE '%L079%'
   OR pp.service_item_id LIKE '%L124%'
   OR pp.service_item_id LIKE '%L034%') --PAP
   --order by pp.service_date
)

SELECT DISTINCT hm.person_id, CONVERT(VARCHAR(8),last_pap,112) AS 'last_pap'
INTO #h
FROM health_maint_ hm
JOIN #temp1 t ON t.person_id = hm.person_id

UPDATE #h
SET last_pap = 19000101
WHERE last_pap = '' or last_pap IS NULL

--***last_pap is stored as VARCHAR not DATE, need to find a way to convert***
UPDATE #demo
SET pap = 'Y'
WHERE #demo.person_id IN
(
SELECT DISTINCT hm.person_id
FROM #h hm
JOIN #temp1 t ON t.person_id = hm.person_id
--JOIN #bcm2 b ON b.person_id = hm.person_id
WHERE hm.last_pap >= CONVERT(VARCHAR, DATEADD(YEAR, -3, t.service_date),120)
)

--***Start BMI update***
UPDATE #demo
SET bmi = 'Y'
WHERE #demo.person_id IN
(
SELECT vs.person_id
FROM ngprod.dbo.vital_signs_ vs
JOIN #bcm2 b ON b.person_id = vs.person_id
WHERE vs.create_timestamp >= DATEADD(YEAR, -2, b.service_date)
AND BMI_calc IS NOT NULL
)
--***End BMI update***

--***Start Smoking Cessation***
--Set smokers to yes
UPDATE #demo
SET [smoking] = 'Y'
WHERE #demo.person_id IN
(
SELECT sc.person_id
FROM ngprod.dbo.soc_hx_tob_use_ sc
JOIN #demo d ON d.person_id = sc.person_id
WHERE opt_tobacco_use_status = 'yes'
)
--Set cessation to yes
UPDATE #demo
SET [cessation] = 'Y'
WHERE #demo.person_id IN
(
SELECT sc.person_id
FROM ngprod.dbo.soc_hx_tob_use_ sc
JOIN #demo d ON d.person_id = sc.person_id
JOIN #bcm2 b ON b.person_id = d.person_id
JOIN ngprod.dbo.Social_Hx_ sh ON sc.person_id = sh.person_id
WHERE sc.txt_last_updated >= DATEADD(YEAR, -1, b.service_date) --ensure smoking status was updated within last year
AND sh.create_timestamp >= DATEADD(YEAR, -1, b.service_date) --ensure cessation was updated within last year
AND opt_tobacco_use_status = 'yes' --check only smokers
AND sh.chk_tobacco_cessation = 1 --check for cessation discussed
)
--***End Smoking Cessation***

--***Start Contraception by BCM at end of visit***
--Female only
UPDATE #demo
SET contra = 'Y'
WHERE #demo.person_id IN
(
SELECT b.person_id
FROM #bcm2 b
JOIN #demo d ON b.person_id = d.person_id
WHERE BCM IN ('Oral (POP)','ORAL (CHC)','Injection','Ring','Patch','IUC (Copper)','IUC (Levonorgestrel)','Implant') AND b.sex = 'F'
)
--***End Contraception by BCM at end of visit***

--***Start LARC by BCM at end of visit***
UPDATE #demo
SET LARC = 'Y'
WHERE #demo.person_id IN
(
SELECT b.person_id
FROM #bcm2 b
JOIN #demo d ON b.person_id = d.person_id
WHERE BCM IN ('IUC (Copper)','IUC (Levonorgestrel)','Implant') AND b.sex = 'F'
)
--***End LARC by BCM at end of visit***

--***Creates counts for all measures***
SELECT DISTINCT
 (SELECT COUNT (*) FROM #demo WHERE age BETWEEN 16 AND 20 AND ct = 'Y' AND sex = 'f') AS 'CT16_Y' --CT
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 16 AND 20 AND sex = 'f') AS 'CT16_total' --CT
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 21 AND 24 AND ct = 'Y' AND sex = 'f') AS 'CT21_Y' --CT
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 21 AND 24 AND sex = 'f') AS 'CT21_total' --CT
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 16 AND 24 AND ct = 'Y' AND sex = 'f') AS 'CT_total_Y' --CT
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 16 AND 24 AND sex = 'f') AS 'CT_total' --CT

,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 21 AND 24 AND pap = 'Y' AND sex = 'F') AS 'PAP21' --PAP
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 21 AND 24 AND sex = 'F') AS 'PAP21_total'
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 25 AND 29 AND pap = 'Y' AND sex = 'F') AS 'PAP25' --PAP
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 25 AND 29 AND sex = 'F') AS 'PAP25_total'
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 30 AND 34 AND pap = 'Y' AND sex = 'F') AS 'PAP30' --PAP
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 30 AND 34 AND sex = 'F') AS 'PAP30_total'
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 35 AND 39 AND pap = 'Y' AND sex = 'F') AS 'PAP35' --PAP
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 35 AND 39 AND sex = 'F') AS 'PAP35_total'
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 40 AND 44 AND pap = 'Y' AND sex = 'F') AS 'PAP40' --PAP
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 40 AND 44 AND sex = 'F') AS 'PAP40_total'
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 45 AND 49 AND pap = 'Y' AND sex = 'F') AS 'PAP45' --PAP
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 45 AND 49 AND sex = 'F') AS 'PAP45_total'
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 50 AND 54 AND pap = 'Y' AND sex = 'F') AS 'PAP50' --PAP
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 50 AND 54 AND sex = 'F') AS 'PAP50_total'
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 55 AND 64 AND pap = 'Y' AND sex = 'F') AS 'PAP55' --PAP
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 55 AND 64 AND sex = 'F') AS 'PAP55_total'
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 21 AND 64 AND pap = 'Y' AND sex = 'F') AS 'PAP_total' --PAP
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 21 AND 64 AND sex = 'F') AS 'P_total'

,(SELECT COUNT (*) FROM #demo WHERE age = 16 AND pap = 'Y' AND sex = 'F') AS 'PAP16' --Inappropriate PAP
,(SELECT COUNT (*) FROM #demo WHERE age = 16 AND sex = 'F') AS 'PAP16_total'
,(SELECT COUNT (*) FROM #demo WHERE age = 17 AND pap = 'Y' AND sex = 'F') AS 'PAP17' --Inappropriate PAP
,(SELECT COUNT (*) FROM #demo WHERE age = 17 AND sex = 'F') AS 'PAP17_total'
,(SELECT COUNT (*) FROM #demo WHERE age = 18 AND pap = 'Y' AND sex = 'F') AS 'PAP18' --Inappropriate PAP
,(SELECT COUNT (*) FROM #demo WHERE age = 18 AND sex = 'F') AS 'PAP18_total'
,(SELECT COUNT (*) FROM #demo WHERE age = 19 AND pap = 'Y' AND sex = 'F') AS 'PAP19' --Inappropriate PAP
,(SELECT COUNT (*) FROM #demo WHERE age = 19 AND sex = 'F') AS 'PAP19_total'
,(SELECT COUNT (*) FROM #demo WHERE age = 20 AND pap = 'Y' AND sex = 'F') AS 'PAP20' --Inappropriate PAP
,(SELECT COUNT (*) FROM #demo WHERE age = 20 AND sex = 'F') AS 'PAP20_total'

,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 18 AND 74 AND BMI = 'Y') AS 'BMI_Y' --BMI
,(SELECT COUNT (*) FROM #demo WHERE age BETWEEN 18 AND 74) AS 'BMI_total'

,(SELECT COUNT (*) FROM #demo WHERE age >= 18 AND smoking = 'Y' AND cessation = 'Y') AS 'smoking_Y' --smoking
,(SELECT COUNT (*) FROM #demo WHERE age >= 18 AND smoking = 'Y') AS 'smoking_total'

,(SELECT COUNT (*) FROM #demo WHERE (age BETWEEN 15 AND 19) AND contra = 'Y' AND sex = 'F') AS 'contra15' --contraception
,(SELECT COUNT (*) FROM #demo WHERE (age BETWEEN 15 AND 19) AND sex = 'F') AS 'contra15_total'
,(SELECT COUNT (*) FROM #demo WHERE (age BETWEEN 20 AND 44) AND contra = 'Y' AND sex = 'F') AS 'contra20' --contraception
,(SELECT COUNT (*) FROM #demo WHERE (age BETWEEN 20 AND 44) AND sex = 'F') AS 'contra20_total'

,(SELECT COUNT (*) FROM #demo WHERE (age BETWEEN 15 AND 19) AND larc = 'Y' AND sex = 'F') AS 'larc15' --contraception
,(SELECT COUNT (*) FROM #demo WHERE (age BETWEEN 15 AND 19) AND sex = 'F') AS 'larc15_total'
,(SELECT COUNT (*) FROM #demo WHERE (age BETWEEN 20 AND 44) AND larc = 'Y' AND sex = 'F') AS 'larc20' --contraception
,(SELECT COUNT (*) FROM #demo WHERE (age BETWEEN 20 AND 44) AND sex = 'F') AS 'larc20_total'
INTO #demo_count
FROM #demo

SELECT * FROM #demo_count

--select * from #demo
--where age >= 18


--select * from #demo
--where age <= '20' and pap = 'y'


--select * from patient_procedure
--where person_id = 'E2CE5390-F5BE-4D2B-8062-85CB99CE7F2F'

--select * from person
--where person_id = 'E2CE5390-F5BE-4D2B-8062-85CB99CE7F2F'