--============================================= 
-- Author: Eric Born
-- Create Date: 02/07/2018
-- Numerator: Number of patients who had an abnormal pap which required a colpo and received it within 3 months
-- Denominator: Total patients who had an abnormal pap
-- Modified by: Eric Born
-- Modifications: Added additional colpo codes 57455 and 58110
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
SELECT DISTINCT pe.person_id, p.person_nbr, pp.service_date, pe.enc_id
INTO #temp1
FROM ngprod.dbo.patient_procedure pp
JOIN ngprod.dbo.patient_encounter pe  ON pp.enc_id = pe.enc_id
JOIN ngprod.dbo.person	p			  ON pp.person_id = p.person_id
JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = pe.enc_id
JOIN ngprod.dbo.lab_results_obr_p obr ON obr.ngn_order_num = nor.order_num
JOIN ngprod.dbo.lab_results_obx obx   ON obx.unique_obr_num = obr.unique_obr_num
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1) 
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND obr.test_desc like 'PAP%'
AND nor.delete_ind != 'Y'			-- no deleted labs
AND nor.ngn_status = 'Signed-off'	-- Signed off results only
AND nor.ngn_status != 'Cancelled'	-- no cancelled labs
AND nor.test_status != 'Cancelled'	-- no cancelled tests
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD', --Clinical services and Lab locations are excluded
						   '966B30EA-F24F-48D6-8346-948669FDCE6E')-- Online services excluded included in totals

--DELETE ALL PATIENTS WHO HAD COLPO AND PAP ON SAME DAY
DELETE FROM #temp1
FROM #temp1 
JOIN ngprod.dbo.patient_procedure pp ON pp.enc_id = #temp1.enc_id
WHERE service_item_id IN ('57454','57455','58110') AND pp.service_date = #temp1.service_date

CREATE TABLE #temp2 (
 person_id UNIQUEIDENTIFIER
,person_nbr VARCHAR(12)
,pap_date DATE
,hpv VARCHAR(1)
,result VARCHAR(50)
,colpo_date DATE
)

--Insert all atypical glandular patiets into table
INSERT INTO #temp2
SELECT DISTINCT t.person_id, t.person_nbr, t.service_date, NULL, 'atypical glandular', NULL
FROM #temp1 t
JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = t.enc_id
JOIN ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num = nor.order_num
JOIN ngprod.dbo.lab_results_obx obx on obx.unique_obr_num = obr.unique_obr_num
WHERE obx.result_comment like '%atypical glandular cells of undeter%'

--***Commented out EB 2/1/2018***
--***Not needed as one of the results that requires Colpo***
--Insert all atypical endocervical patiets into table
--INSERT INTO #temp2
--SELECT DISTINCT t.person_id, t.person_nbr, t.service_date, NULL, 'atypical endocervical', NULL
--FROM #temp1 t
--JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = t.enc_id
--JOIN ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num = nor.order_num
--JOIN ngprod.dbo.lab_results_obx obx on obx.unique_obr_num = obr.unique_obr_num
--WHERE obx.result_comment like '%atypical endocervical%'

--Insert all ASC cannot exclude high-grade patiets into table
INSERT INTO #temp2
SELECT DISTINCT t.person_id, t.person_nbr, t.service_date, NULL, 'cannot exclude', NULL
FROM #temp1 t
JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = t.enc_id
JOIN ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num = nor.order_num
JOIN ngprod.dbo.lab_results_obx obx on obx.unique_obr_num = obr.unique_obr_num
WHERE obx.result_comment like '%cannot exclude%'

--Insert all patiets with endrometrial cells age 40+ into table
INSERT INTO #temp2
SELECT DISTINCT t.person_id, t.person_nbr, t.service_date, NULL, 'age 40 or over', NULL
FROM #temp1 t
JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = t.enc_id
JOIN ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num = nor.order_num
JOIN ngprod.dbo.lab_results_obx obx on obx.unique_obr_num = obr.unique_obr_num
WHERE obx.result_comment like '%age 40 or over%'

--Insert low grade squamous intraepithelial lesions into table
INSERT INTO #temp2
SELECT DISTINCT t.person_id, t.person_nbr, t.service_date, NULL, 'low-grade squamous intraepithelial lesion', NULL
FROM #temp1 t
JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = t.enc_id
JOIN ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num = nor.order_num
JOIN ngprod.dbo.lab_results_obx obx on obx.unique_obr_num = obr.unique_obr_num
WHERE obx.result_comment like '%low-grade squamous intraepithelial lesion%'

--Insert High grade squamous intraepithelial lesions into table
INSERT INTO #temp2
SELECT DISTINCT t.person_id, t.person_nbr, t.service_date, NULL, 'high-grade squamous intraepithelial lesion', NULL
FROM #temp1 t
JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = t.enc_id
JOIN ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num = nor.order_num
JOIN ngprod.dbo.lab_results_obx obx on obx.unique_obr_num = obr.unique_obr_num
WHERE obx.result_comment like '%high-grade squamous intraepithelial lesion%'
OR    obx.result_comment like '%high grade squamous intraepithelial lesion%'

--Insert all HPV positive patiets into table
INSERT INTO #temp2
SELECT DISTINCT t.person_id, t.person_nbr, t.service_date, 'Y', NULL, NULL
FROM #temp1 t
JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = t.enc_id
JOIN ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num = nor.order_num
JOIN ngprod.dbo.lab_results_obx obx on obx.unique_obr_num = obr.unique_obr_num
WHERE result_desc LIKE '%HPV%' AND observ_value = 'positive'
AND t.person_id NOT IN (SELECT t2.person_id from #temp2 t2)

--Update all NIL
UPDATE #temp2
SET result = 'NIL'
FROM #temp1 t
JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = t.enc_id
JOIN ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num = nor.order_num
JOIN ngprod.dbo.lab_results_obx obx on obx.unique_obr_num = obr.unique_obr_num
JOIN #temp2 t2 ON t2.person_id = t.person_id
WHERE result_comment LIKE '%negative for intra%'
AND [hpv] = 'y' 

--Update ASCUS
UPDATE #temp2
SET result = 'ASCUS'
--select result_comment
FROM #temp1 t
JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = t.enc_id
JOIN ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num = nor.order_num
JOIN ngprod.dbo.lab_results_obx obx on obx.unique_obr_num = obr.unique_obr_num
JOIN #temp2 t2 ON t2.person_id = t.person_id
WHERE result_comment LIKE '%atypical squamous cells%'
AND [hpv] = 'y'

--Update all patients who had previous result and have HPV
UPDATE #temp2
SET hpv = 'Y'
FROM #temp1 t
JOIN ngprod.dbo.lab_nor nor			  ON nor.enc_id = t.enc_id
JOIN ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num = nor.order_num
JOIN ngprod.dbo.lab_results_obx obx on obx.unique_obr_num = obr.unique_obr_num
JOIN #temp2 t2 ON t2.person_id = t.person_id
WHERE result_desc LIKE '%HPV%' AND observ_value = 'positive'

--Update table when colpo found within 90 days of PAP
UPDATE #temp2
SET colpo_date = pp.service_date
FROM ngprod.dbo.patient_procedure pp
JOIN #temp2 t2 ON t2.person_id = pp.person_id
WHERE pp.service_date BETWEEN t2.pap_date AND DATEADD(DD, 91,t2.pap_date)
AND pp.service_item_id IN ('57454','57455','58110')

--Update HPV to 'N' instead of null
UPDATE #temp2
SET hpv = 'N'
WHERE hpv IS NULL

--Output
SELECT person_nbr, pap_date, hpv, result, colpo_date
FROM #temp2
ORDER BY person_nbr