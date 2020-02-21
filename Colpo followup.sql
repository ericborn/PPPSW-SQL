--============================================= 
-- Author: Eric Born
-- Create Date: 07/01/2017
-- Numerator: Number of patients who had an abnormal colpo (CIN 2+) and received a LEEP within 3 months
-- Denominator: Total patients who had an abnormal colpo
-- Modified by: Eric Born
-- Modifications: Added Colpo codes 57455 and 58110
-- =============================================

--***Drop temp tables***
--DROP TABLE #temp1
--DROP TABLE #temp2

DECLARE @Start_Date_1 DATETIME
DECLARE @End_Date_1 DATETIME

--SET @Start_Date_1 = @Start_Date
--SET @End_Date_1 = @End_Date

SET @Start_Date_1 = '20170701'
SET @End_Date_1 = '20170930'

--**********Start data Table Creation***********
--Creates list of all encounters, dx and SIM codes during time period
SELECT obr.test_desc, obx.result_comment, pe.person_id, p.person_nbr, pp.service_date ,pe.enc_id
INTO #temp1
FROM ngprod.dbo.patient_procedure pp
JOIN ngprod.dbo.patient_encounter pe  ON pp.enc_id = pe.enc_id
JOIN ngprod.dbo.person	p			  ON pp.person_id = p.person_id
JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = pe.enc_id
JOIN ngprod.dbo.lab_results_obr_p obr ON obr.ngn_order_num = nor.order_num
JOIN ngprod.dbo.lab_results_obx obx   ON obx.unique_obr_num = obr.unique_obr_num
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1) 
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND service_item_id IN ('57454','57455','58110')
AND nor.delete_ind != 'Y'			-- no deleted labs
AND nor.ngn_status = 'Signed-off'	-- Signed off results only
AND nor.ngn_status != 'Cancelled'	-- no cancelled labs
AND nor.test_status != 'Cancelled'	-- no cancelled tests
AND obr.test_desc = 'PATHOLOGY REPORT'
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --Clinical services and Lab locations are excluded

CREATE TABLE #temp2 (
 person_id UNIQUEIDENTIFIER
,person_nbr VARCHAR(12)
,Colpo_date DATE
,[Cryo/Leep] DATE
)

INSERT INTO #temp2
SELECT DISTINCT person_id, person_nbr, service_date, NULL--, NULL
FROM #temp1
WHERE result_comment LIKE '%diagnosis%'
AND (result_comment LIKE '%CIN 2%' OR result_comment LIKE '%CIN II%' OR result_comment LIKE '%CIN 3%' OR result_comment LIKE '%CIN III%')

UPDATE #temp2
SET [cryo/leep] = pp.service_date
FROM patient_procedure pp
JOIN #temp2 t2 ON t2.person_id = pp.person_id
WHERE pp.service_date BETWEEN t2.Colpo_date AND DATEADD(DD, 365,t2.Colpo_date)
AND (pp.service_item_id = '57460' OR pp.service_item_id = '57511')


SELECT person_nbr, colpo_date, [cryo/leep]
FROM #temp2
--where [cryo/leep] is not null
ORDER BY [cryo/leep]