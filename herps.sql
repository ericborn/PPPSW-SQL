select DISTINCT enc_id from patient_procedure
where service_date >= '20151001' AND service_date >= '20160930'
AND service_item_id IN
(
'L033' ,'L095' ,'L110'
)


select DISTINCT ENC_id, service_item_id, service_item_desc 
from patient_procedure
where service_date >= '20151001' AND service_date >= '20160930'
AND service_item_id IN
(
'L033' ,'L095' ,'L110'
) order by enc_id
--group by service_item_id, service_item_desc
--2362
select unique_obr_num, result_desc, observ_value, abnorm_flags, obs_date_time, result_comment--, COUNT(observ_value) AS 'count'-- result_desc, abnorm_flags, observ_value
from lab_results_obx
where (obs_date_time >= '20151001' AND obs_date_time <= '20160930')
AND (result_desc LIKE '%hsv%' OR result_desc LIKE '%herp%') AND (abnorm_flags LIKE 'A' OR abnorm_flags = 'H')
--GROUP BY observ_value, abnorm_flags
order by obs_date_time

select unique_obr_num, result_desc, observ_value, abnorm_flags, obs_date_time, result_comment--, COUNT(observ_value) AS 'count'-- result_desc, abnorm_flags, observ_value
from lab_results_obx
where (obs_date_time >= '20151001' AND obs_date_time <= '20160930')
AND (result_desc LIKE '%hsv%' OR result_desc LIKE '%herp%') AND (abnorm_flags LIKE 'A' OR abnorm_flags = 'H')
--GROUP BY observ_value, abnorm_flags
order by observ_value

select * from lab_results_obx

SELECT 
		 obx.observ_value
		,obr.date_time_reported
		,obx.result_desc
		,'enc_timestamp' = CONVERT(CHAR(8), nor.enc_timestamp, 112)
	       	       
	--INTO #CT
	FROM 
		lab_results_obx obx
		JOIN lab_results_obr_p obr  ON obx.unique_obr_num	= obr.unique_obr_num
		JOIN lab_nor nor			ON obr.ngn_order_num	= nor.order_num
		JOIN lab_order_tests lot	ON nor.order_num		= lot.order_num  
		JOIN patient_encounter pe	ON nor.enc_id			= pe.enc_id 
	WHERE 
	   obx.abnorm_flags IN ('H','HH', '>', 'L', 'LL', '<', 'A', 'AA', 'U', 'D', 'B', 'W', 'R', 'I')
	AND
	   obx.result_desc LIKE '%hsv%'
	AND   
	   obr.date_time_reported = (SELECT  MAX(t0.date_time_reported) 
								 FROM lab_results_obr_p (nolock) t0 
								 WHERE obr.person_id=t0.person_id AND t0.test_desc=obr.test_desc 
								 AND obr.ngn_order_num=t0.ngn_order_num)  
	AND
	   (obx.observ_value LIKE '%positive%' or obx.observ_value LIKE '%detected%')                                         

	Set @Chlamydia			= (SELECT TOP 1 result_desc   FROM #CT)
	Set @ChlamydiaValue		= (SELECT Count(*)			  FROM #CT)
	Set @Spec_CT			= (SELECT TOP 1 Specimen	  FROM #CT)
	Set @CollectionDate_CT  = (SELECT TOP 1 enc_timestamp FROM #CT)
	IF (@ChlamydiaValue = 0)
		BEGIN
		  Set @ChlamydiaValue = 0
		END
	IF (@ChlamydiaValue > 0)
		BEGIN
		  Set @ChlamydiaValue = 1
		END