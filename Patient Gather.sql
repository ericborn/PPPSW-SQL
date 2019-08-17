--***Declare and set variables***
DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

--SET @Start_Date_1 = '20150701' --FY 15-16
--SET @End_Date_1 = '20160630'

SET @Start_Date_1 = '20151001'
SET @End_Date_1 = '20151231'

/* START FRESH */
--DROP TABLE #enc;
--DROP TABLE #fpl;
--DROP TABLE #charges;
--TRUNCATE TABLE PSW_OSHPD

--build enc table by location for joins
;WITH enc AS (
SELECT DISTINCT pe.person_id, pe.enc_id, pp.service_date, pe.location_id, guar_id, cob1_insured_person_id, cob1_payer_id, rendering_provider_id,
RN = ROW_NUMBER() OVER (PARTITION BY pe.person_id, CONVERT(VARCHAR(8),enc_timestamp,112) ORDER BY pe.person_id)
FROM patient_encounter pe
JOIN person p  ON pe.person_id = p.person_id
JOIN charges c ON pe.enc_id	   = c.source_id 
JOIN patient_procedure pp ON pp.enc_id = pe.enc_id
WHERE (service_date >= @Start_Date_1 AND service_date <= @End_Date_1)
--(begin_date_of_service >= @Start_Date_1 AND begin_date_of_service <= @End_Date_1) --and pe.location_id = @LocationID
AND (billable_ind = 'Y' AND clinical_ind = 'Y')
AND  p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND  pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') 
)
SELECT person_id, enc_id, service_date, location_id, guar_id, cob1_insured_person_id, cob1_payer_id, rendering_provider_id
--INTO #enc -- drop table #enc
FROM enc
WHERE RN = 1
order by person_id, service_date

--63526 patient encounter
--64341 charges
--64343 patient procedure

select * from charges