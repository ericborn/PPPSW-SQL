--drop table #temp1

SELECT p.person_nbr, p.race
,'age' = CAST((CONVERT(INT,CONVERT(CHAR(8),pp.service_date,112))-CONVERT(CHAR(8),p.date_of_birth,112))/10000 AS varchar)
,pe.enc_nbr, pp.service_date, actText, obsValue, service_item_id
INTO #temp1
from patient_procedure pp
JOIN order_ o ON pp.enc_id = o.encounterID
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN person p ON p.person_id = pp.person_id
WHERE pp.service_date >= '20170201' AND pp.service_date <= '20170612'
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND service_item_id = '87806' AND actText LIKE '%Rapid HIV1/HIV2%'
AND obsValue IN ('Ab/Ag Reactive', 'Ag Reactive', 'Ab Reactive')
AND pp.location_id = 'A0D201B2-7AD9-40DD-8A0B-F270478B1736'

SELECT * FROM #temp1

select distinct obsValue
from patient_procedure pp
JOIN order_ o ON pp.enc_id = o.encounterID
where service_item_id = '87806' AND actText LIKE '%Rapid HIV1/HIV2%'

select   DISTINCT p.person_nbr
		,pe.enc_nbr
		,CONVERT(CHAR(8), nor.enc_timestamp, 112) AS 'Encounter Date'
		,t.actText AS 'PP Test'
		,t.obsValue AS 'PP Result'
		,CONVERT(CHAR(8), obr.date_time_reported, 112) AS 'Quest Date'
		,obx.result_desc AS 'Quest Test'
		,obx.observ_value 'Quest Result'	
FROM 
		lab_results_obx obx
		JOIN lab_results_obr_p obr  ON obx.unique_obr_num	= obr.unique_obr_num
		JOIN lab_nor nor			ON obr.ngn_order_num	= nor.order_num
		JOIN lab_order_tests lot	ON nor.order_num		= lot.order_num  
		JOIN #temp1 t				ON nor.enc_id			= t.enc_id
		JOIN person p				ON p.person_id			= t.person_id
		JOIN patient_encounter pe	ON pe.enc_id			= t.enc_id
WHERE result_desc LIKE 'HIV%'-- and observ_value = 'TNP'