--============================================= 
-- Author: Eric Born
-- Create Date: 07/01/2017
-- Numerator: Number of patients who had a positive GC/CT result and received treatment within 30 days
-- Denominator: Total patients who had a positive GC/CT result
-- Modified by:
-- Modifications:
-- =============================================

--***Drop temp tables***
--drop table #pos

-- Declare AND SET Variables
DECLARE @Start_Date date
DECLARE @End_Date date

SET @Start_Date = '20170901'
SET @End_Date   = '20171130'

--***Begin Data section***
CREATE TABLE #pos (
 person_id UNIQUEIDENTIFIER
,mrn VARCHAR(12)
,enc_id UNIQUEIDENTIFIER
,enc_nbr NUMERIC (12)
,DOS DATE
,GC VARCHAR(1)
,CT VARCHAR(1)
,Azith VARCHAR(1)
,Azi_Date DATE
,Ceft VARCHAR(1)
,Genta VARCHAR(1)
,Treated VARCHAR(1)
)

--***Only gather patients who had a positive GC or CT test during reporting period***
INSERT INTO #pos
SELECT DISTINCT
	pe.person_id,
	SUBSTRING(pt.med_rec_nbr, PATINDEX('%[^0]%', pt.med_rec_nbr+'.'), LEN(pt.med_rec_nbr)) AS MRN,
	pe.enc_id,
	pe.enc_nbr,
	pe.billable_timestamp
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL
	,NULL	
FROM	 ngprod.dbo.patient_encounter pe
	JOIN ngprod.dbo.person ps			  ON ps.person_id = pe.person_id
	JOIN ngprod.dbo.patient pt			  ON pt.person_id = pe.person_id
	JOIN ngprod.dbo.lab_nor nor			  ON pe.enc_id = nor.enc_id
	JOIN ngprod.dbo.lab_results_obr_p obr ON obr.ngn_order_num	= nor.order_num
	JOIN ngprod.dbo.lab_results_obx obx   ON obx.unique_obr_num	= obr.unique_obr_num
	JOIN ngprod.dbo.lab_order_tests lot   ON nor.order_num		= lot.order_num      
WHERE (pe.billable_timestamp >= @Start_Date AND pe.billable_timestamp <= @End_Date)
	AND pe.billable_ind = 'Y'
	AND pe.clinical_ind = 'Y'
	AND ps.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
	AND pe.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --Clinical services AND Lab locations are excluded
	AND (obx.result_desc LIKE '%GC%' OR obx.result_desc LIKE '%CT%')
	AND (obx.observ_value LIKE '%positive%' OR obx.observ_value LIKE 'detected%')
--***End Table creation***

--***Find positive CT results***
UPDATE #pos
SET CT = 'Y'
WHERE enc_id IN
(
SELECT 
		 pe.enc_id	       	       
	FROM 
			 ngprod.dbo.lab_results_obx obx
		JOIN ngprod.dbo.lab_results_obr_p obr ON obx.unique_obr_num	= obr.unique_obr_num
		JOIN ngprod.dbo.lab_nor nor			  ON obr.ngn_order_num	= nor.order_num
		JOIN ngprod.dbo.lab_order_tests lot	  ON nor.order_num		= lot.order_num  
		JOIN ngprod.dbo.patient_encounter pe  ON nor.enc_id			= pe.enc_id 
	WHERE 
	   obx.abnorm_flags IN ('H','HH', '>', 'L', 'LL', '<', 'A', 'AA', 'U', 'D', 'B', 'W', 'R', 'I')
	AND
	   obx.result_desc LIKE '%CT%'
	AND   
	   (obx.observ_value LIKE '%positive%' or obx.observ_value LIKE 'detected%')  
)

--***Find positive GC results***
UPDATE #pos
SET GC = 'Y'
WHERE enc_id IN
(
SELECT 
		 pe.enc_id	       	       
	FROM 
			 ngprod.dbo.lab_results_obx obx
		JOIN ngprod.dbo.lab_results_obr_p obr   ON obx.unique_obr_num	= obr.unique_obr_num
		JOIN ngprod.dbo.lab_nor nor				ON obr.ngn_order_num	= nor.order_num
		JOIN ngprod.dbo.lab_order_tests lot		ON nor.order_num		= lot.order_num  
		JOIN ngprod.dbo.patient_encounter pe	ON nor.enc_id			= pe.enc_id 
	WHERE 
	   obx.abnorm_flags IN ('H','HH', '>', 'L', 'LL', '<', 'A', 'AA', 'U', 'D', 'B', 'W', 'R', 'I')
	AND
	   obx.result_desc LIKE '%GC%'
	AND   
	   (obx.observ_value LIKE '%positive%' or obx.observ_value LIKE 'detected%')  
)

--***Start med updates***
--Azithromycin ERX within 30 days
UPDATE #pos
SET Azith = 'Y'
WHERE person_id IN (
SELECT pm.person_id
FROM ngprod.dbo.erx_message_history H 
JOIN ngprod.dbo.patient_medication PM ON H.person_id = PM.person_id AND H.medication_id = PM.uniq_id AND h.provider_id = PM.provider_id --158274
JOIN #pos p							  ON pm.person_id = p.person_id
WHERE h.create_timestamp BETWEEN p.dos AND DATEADD(DD, 31,p.dos)
AND medication_name LIKE 'azi%'
)

--Azithromycin dispensed within 30 days
UPDATE #pos
SET Azith = 'Y'
WHERE person_id IN (
SELECT pm.person_id
FROM ngprod.dbo.patient_medication PM
JOIN #pos p ON pm.person_id = p.person_id
WHERE create_timestamp BETWEEN p.dos AND DATEADD(DD, 31,p.dos)
AND medication_name LIKE 'azi%'
)

--Set Azithro date
UPDATE #pos 
SET azi_date = pm.start_date
FROM ngprod.dbo.patient_medication pm
JOIN #pos p ON pm.person_id = p.person_id
WHERE create_timestamp BETWEEN p.dos AND DATEADD(DD, 31,p.dos)
AND medication_name LIKE 'azi%'

--C1F7C7A5-C640-4C5A-95C1-682D2A5BDC56 person
--F5B1A6BE-87E6-42D7-90BA-30140C5F6F1A enc
--2017-05-08

--Ceftriaxlon ERX within 30 days
UPDATE #pos
SET ceft = 'Y'
WHERE person_id IN (
SELECT pm.person_id
FROM ngprod.dbo.erx_message_history H 
JOIN ngprod.dbo.patient_medication PM on H.person_id = PM.person_id AND H.medication_id = PM.uniq_id AND h.provider_id = PM.provider_id --158274
JOIN #pos p ON pm.person_id = p.person_id
WHERE h.create_timestamp BETWEEN p.dos AND DATEADD(DD, 31,p.dos)
AND medication_name LIKE 'ceft%'
)

--Ceftriaxlon dispensed within 30 days
UPDATE #pos
SET ceft = 'Y'
WHERE person_id IN (
SELECT pm.person_id
FROM ngprod.dbo.patient_medication PM
JOIN #pos p ON pm.person_id = p.person_id
WHERE create_timestamp BETWEEN p.dos AND DATEADD(DD, 31,p.dos)
AND medication_name LIKE 'ceft%'
)

--Gentamycin ERX within 30 days
UPDATE #pos
SET genta = 'Y'
WHERE person_id IN (
SELECT pm.person_id
FROM ngprod.dbo.erx_message_history H 
JOIN ngprod.dbo.patient_medication PM ON H.person_id = PM.person_id AND H.medication_id = PM.uniq_id AND h.provider_id = PM.provider_id --158274
JOIN #pos p							  ON pm.person_id = p.person_id
WHERE h.create_timestamp BETWEEN p.dos AND DATEADD(DD, 31,p.dos)
AND medication_name LIKE 'genta%'
)

--Gentamycin dispensed within 30 days
UPDATE #pos
SET genta = 'Y'
WHERE person_id IN (
SELECT pm.person_id
FROM ngprod.dbo.patient_medication PM
JOIN #pos p ON pm.person_id = p.person_id
WHERE create_timestamp BETWEEN p.dos AND DATEADD(DD, 31,p.dos)
AND medication_name LIKE 'genta%'
)

--***Set treated depending on STI and meds dispensed***
UPDATE #pos
SET Treated = 'Y'
WHERE GC = 'y' AND Azith = 'y' AND (Ceft = 'y' OR genta = 'y')

UPDATE #pos
SET Treated = 'Y'
WHERE CT = 'y' AND Azith = 'y'

UPDATE #pos
SET Treated = NULL
WHERE GC = 'y' AND CT = 'y' AND Ceft IS NULL AND genta IS NULL

--***Drop person/enc id for clean output***
ALTER TABLE	#pos
DROP COLUMN person_id

ALTER TABLE	#pos
DROP COLUMN enc_id

SELECT * FROM #pos