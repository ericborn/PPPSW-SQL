--***Declare and set variables***
DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

SET @Start_Date_1 = '20170101'
SET @End_Date_1 = '20171231'
--drop table #ct

--Positive CT
SELECT DISTINCT
		 person_nbr
		,location_name
		,p.sex
		,[age] = CAST((CONVERT(INT,CONVERT(CHAR(8),'20170615',112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar)
	INTO #CT
	FROM lab_results_obx obx
		JOIN lab_results_obr_p obr ON obx.unique_obr_num = obr.unique_obr_num
		JOIN lab_nor nor ON obr.ngn_order_num = nor.order_num
		JOIN lab_order_tests lot ON nor.order_num = lot.order_num  
		JOIN patient_encounter pe ON nor.enc_id = pe.enc_id
		JOIN NGProd.dbo.person	p			  ON pe.person_id = p.person_id
		JOIN NGProd.dbo.patient_procedure pp ON pp.enc_id = pe.enc_id
		JOIN ngprod.dbo.location_mstr lm ON lm.location_id = pe.location_id
	WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1)
		AND obx.abnorm_flags IN ('H','HH', '>', 'L', 'LL', '<', 'A', 'AA', 'U', 'D', 'B', 'W', 'R', 'I')    
		--AND obx.result_desc LIKE '%CT%' -- commented out 20170908 TArmstrong
		AND obx.result_desc IN ('','CT','CHLAMYDIA TRACHOMATIS RNA, TMA','CHLAMYDIA TRACHOMATIS RNA, TMA, RECTAL','Chlamydia trachomatis, NAA',
							'CHLAMYDIA TRACHOMATIS RNA, TMA, THROAT')
		AND obx.observ_value IN ('POSITIVE','DETECTED') 
		AND obr.date_time_reported = (SELECT  MAX(t0.date_time_reported) 
									 FROM lab_results_obr_p (nolock) t0 
									 WHERE obr.person_id=t0.person_id AND t0.test_desc=obr.test_desc 
									 AND obr.ngn_order_num=t0.ngn_order_num)
		AND (obx.observ_value LIKE '%positive%' or obx.observ_value LIKE '%detected%') -- commented out 20170908 TArmstrong
		AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
		AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
		GROUP BY person_nbr, location_name, sex, date_of_birth

UPDATE #ct
SET age =
	(
		CASE
			WHEN age BETWEEN 0 AND 14  THEN '<15'
			WHEN age BETWEEN 15 AND 17 THEN '15-17'
			WHEN age BETWEEN 18 AND 19 THEN '18-19'
			WHEN age BETWEEN 20 AND 24 THEN '20-24'
			WHEN age BETWEEN 25 AND 29 THEN '25-29'
			ELSE '30+'
		END
	)
FROM #ct

SELECT location_name, sex, age, COUNT(*) AS [count]
FROM #ct
GROUP BY location_name, sex, age
ORDER BY location_name, age, sex

--Positive GC
SELECT DISTINCT
	 person_nbr
	,location_name
	,p.sex
	--,[age] = CAST((CONVERT(INT,CONVERT(CHAR(8),'20170615',112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar)
INTO #GC
FROM lab_results_obx obx
		JOIN lab_results_obr_p obr ON obx.unique_obr_num = obr.unique_obr_num
		JOIN lab_nor nor ON obr.ngn_order_num = nor.order_num
		JOIN lab_order_tests lot ON nor.order_num = lot.order_num  
		JOIN patient_encounter pe ON nor.enc_id = pe.enc_id
		JOIN NGProd.dbo.person	p			  ON pe.person_id = p.person_id
		JOIN NGProd.dbo.patient_procedure pp ON pp.enc_id = pe.enc_id
		JOIN ngprod.dbo.location_mstr lm ON lm.location_id = pe.location_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1)
		AND obx.abnorm_flags IN ('H','HH', '>', 'L', 'LL', '<', 'A', 'AA', 'U', 'D', 'B', 'W', 'R', 'I')    
		--AND obx.result_desc LIKE '%CT%' -- commented out 20170908 TArmstrong
		AND obx.result_desc IN ('GC','NEISSERIA GONORRHOEAE RNA, TMA','NEISSERIA GONORRHOEAE (GC) CULTURE','NEISSERIA GONORRHOEAE RNA, TMA, RECTAL',
							'NEISSERIA GONORRHOEAE RNA, TMA, THROAT','Neisseria gonorrhoeae, NAA')
		AND obx.observ_value IN ('POSITIVE','DETECTED') 
		AND obr.date_time_reported = (SELECT  MAX(t0.date_time_reported) 
									 FROM lab_results_obr_p (nolock) t0 
									 WHERE obr.person_id=t0.person_id AND t0.test_desc=obr.test_desc 
									 AND obr.ngn_order_num=t0.ngn_order_num)
		AND (obx.observ_value LIKE '%positive%' or obx.observ_value LIKE '%detected%') -- commented out 20170908 TArmstrong
		AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
		AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
GROUP BY person_nbr, location_name, sex, date_of_birth
 
SELECT location_name, sex, COUNT(*) AS [count]
FROM #gc
GROUP BY location_name, sex
ORDER BY location_name, sex

--drop table #hiv
--Positive HIV
SELECT DISTINCT
	 person_nbr
	,result_desc
	,observ_value
	,location_name
	,p.sex
INTO #hiv
FROM lab_results_obx obx
	JOIN lab_results_obr_p obr ON obx.unique_obr_num = obr.unique_obr_num
	JOIN lab_nor nor ON obr.ngn_order_num = nor.order_num
	JOIN lab_order_tests lot ON nor.order_num = lot.order_num  
	JOIN patient_encounter pe ON nor.enc_id = pe.enc_id
	JOIN NGProd.dbo.person	p			  ON pe.person_id = p.person_id
	JOIN NGProd.dbo.patient_procedure pp ON pp.enc_id = pe.enc_id
	JOIN ngprod.dbo.location_mstr lm ON lm.location_id = pe.location_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1)
	AND obx.abnorm_flags IN ('H','HH', '>', 'L', 'LL', '<', 'A', 'AA', 'U', 'D', 'B', 'W', 'R', 'I')    
	AND obx.result_desc LIKE '%HIV%' -- commented out 20170908 TArmstrong
	AND obx.result_desc NOT IN ('','CT','CHLAMYDIA TRACHOMATIS RNA, TMA','CHLAMYDIA TRACHOMATIS RNA, TMA, RECTAL','Chlamydia trachomatis, NAA',
								'CHLAMYDIA TRACHOMATIS RNA, TMA, THROAT')
	AND obx.result_desc NOT IN ('GC','NEISSERIA GONORRHOEAE RNA, TMA','NEISSERIA GONORRHOEAE (GC) CULTURE','NEISSERIA GONORRHOEAE RNA, TMA, RECTAL',
							'NEISSERIA GONORRHOEAE RNA, TMA, THROAT','Neisseria gonorrhoeae, NAA')
	AND obx.observ_value IN ('POSITIVE','REPEATEDLY REACTIVE') 
	AND obr.date_time_reported = (SELECT  MAX(t0.date_time_reported) 
									FROM lab_results_obr_p (nolock) t0 
									WHERE obr.person_id=t0.person_id AND t0.test_desc=obr.test_desc 
									AND obr.ngn_order_num=t0.ngn_order_num)
	AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
	AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
	AND service_item_id = 'L099' 

--select * from #hiv

SELECT location_name, COUNT(*) AS [count]
FROM #hiv
GROUP BY location_name
ORDER BY location_name



