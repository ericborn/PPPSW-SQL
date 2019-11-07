--============================================= 
-- Author: Eric Born
-- Create Date: 09/01/2017
-- Numerator: Number of visits where risk factors were present and patients were tested in all appropriate locations
--			  (vaginal, urine, rectal, pharyngeal) per their reported exposure site(s) during the analysis period
-- Denominator: Total patients where risk factors were present in the analysis period
-- Modified by:
-- Modifications:
-- =============================================

--***Drop temp tables***
--drop table #Enc_Tank

-- Declare AND SET Variables
DECLARE @Start_Date date
DECLARE @End_Date date

SET @Start_Date = '20171001'
SET @End_Date   = '20171231'

--***Create main table***
CREATE TABLE #Enc_Tank (
 person_id UNIQUEIDENTIFIER
,Gender VARCHAR(8)
,mrn VARCHAR(12)
,enc_id UNIQUEIDENTIFIER
,enc_nbr NUMERIC (12)
,location_name VARCHAR(40)
,DOS DATE
,last_test DATE
,diff INT
,risk VARCHAR (1)
,txt_current_sexual_activity VARCHAR (200)
,Anal_insertive VARCHAR (1)
,Anal_receptive VARCHAR (1)
,oral_insertive VARCHAR (1)
,oral_receptive VARCHAR (1)
,vaginal_insertive VARCHAR (1)
,vaginal_receptive VARCHAR (1)
,Rectal_swab VARCHAR (1)
,Pharyngeal_swab VARCHAR (1)
,Urine_sample VARCHAR (1)
,Vaginal_swab VARCHAR (1)
,appropriate VARCHAR (1)
)

--Insert patients into main table
INSERT INTO #Enc_Tank
SELECT 
	pe.person_id,
	ps.sex,
	SUBSTRING(pt.med_rec_nbr, PATINDEX('%[^0]%', pt.med_rec_nbr+'.'), LEN(pt.med_rec_nbr)) AS MRN,
	pe.enc_id,
	pe.enc_nbr,
	lm.location_name,
	pe.billable_timestamp,
	NULL,
	NULL,
	NULL,
	txt_current_sexual_activity,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL
	
FROM	 ngprod.dbo.patient_encounter pe
	JOIN ngprod.dbo.location_mstr lm	   ON lm.location_id = pe.location_id
	JOIN ngprod.dbo.person ps			   ON ps.persON_id = pe.person_id
	JOIN ngprod.dbo.patient pt			   ON pt.persON_id = pe.person_id
	JOIN ngprod.dbo.hpi_sti_screening_ hpi ON hpi.enc_id = pe.enc_id
	     
WHERE (pe.billable_timestamp >= @Start_Date AND pe.billable_timestamp <= @End_Date)
	AND pe.billable_ind = 'Y'
	AND pe.clinical_ind = 'Y'
	AND ps.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
	AND pe.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --Clinical services AND Lab locations are excluded

--***Updates main table with patients sexual activity based on answers to screening question
--anal insertive
UPDATE #enc_tank 
SET anal_insertive = 'Y' 
FROM #enc_tank tank
WHERE txt_current_sexual_activity LIKE '%anal insertive%'

--anal receptive
UPDATE #enc_tank 
SET anal_receptive = 'Y' 
FROM #enc_tank tank
WHERE txt_current_sexual_activity LIKE '%anal receptive%'

--Female anal receptive
UPDATE #enc_tank 
SET anal_receptive = 'Y' 
FROM #enc_tank tank
WHERE txt_current_sexual_activity LIKE '%anal%' and
tank.gender = 'f'

--Oral insertive
UPDATE #enc_tank 
SET oral_insertive = 'Y' 
FROM #enc_tank tank
WHERE txt_current_sexual_activity LIKE '%oral insertive%'

--Oral receptive
UPDATE #enc_tank 
SET oral_receptive = 'Y' 
FROM #enc_tank tank
WHERE txt_current_sexual_activity LIKE '%oral Receptive%'

--Female oral receptive
UPDATE #enc_tank 
SET oral_receptive = 'Y' 
FROM #enc_tank tank
WHERE txt_current_sexual_activity LIKE '%oral%' and
tank.gender = 'f'

--vaginal receptive
UPDATE #enc_tank 
SET Vaginal_receptive = 'Y' 
FROM #enc_tank tank
WHERE txt_current_sexual_activity LIKE '%vaginal%' AND Gender = 'f'

--vaginal insertive
UPDATE #enc_tank 
SET vaginal_insertive = 'Y' 
FROM #enc_tank tank
WHERE txt_current_sexual_activity LIKE '%vaginal%' AND Gender = 'm'

--Rectal Swab
UPDATE #enc_tank 
SET rectal_swab = 'Y' 
FROM #enc_tank tank
JOIN ngprod.dbo.lab_nor nor ON nor.persON_id = tank.person_id
JOIN ngprod.dbo.lab_order_tests lot ON lot.order_num = nor.order_num
JOIN ngprod.dbo.lab_test_aoe_answer aoe ON aoe.order_num = nor.order_num
WHERE aoe.test_data_value LIKE '%Rectal%' 
AND CONVERT(date,tank.dos) = CONVERT(date,lot.collectiON_time)
AND nor.ngn_status = 'Signed-Off'

--Pharyngeal Swab
UPDATE #enc_tank 
SET pharyngeal_swab = 'Y' 
FROM #enc_tank tank
JOIN ngprod.dbo.lab_nor nor ON nor.persON_id = tank.person_id
JOIN ngprod.dbo.lab_order_tests lot ON lot.order_num = nor.order_num
JOIN ngprod.dbo.lab_test_aoe_answer aoe ON aoe.order_num = nor.order_num
WHERE aoe.test_data_value LIKE '%Pharyngeal%'
AND CONVERT(date,tank.dos) = CONVERT(date,lot.collectiON_time)
AND nor.ngn_status = 'Signed-Off'

--Urine
UPDATE #enc_tank 
SET urine_sample = 'Y' 
FROM #enc_tank tank
JOIN ngprod.dbo.lab_nor nor ON nor.persON_id = tank.person_id
JOIN ngprod.dbo.lab_order_tests lot ON lot.order_num = nor.order_num
JOIN ngprod.dbo.lab_test_aoe_answer aoe ON aoe.order_num = nor.order_num
WHERE aoe.test_data_value LIKE '%Urine%'
AND CONVERT(date,tank.dos) = CONVERT(date,lot.collectiON_time)
AND nor.ngn_status LIKE 'Signed-Off'

--Vaginal Swab
UPDATE #enc_tank 
SET vaginal_swab = 'Y' 
FROM #enc_tank tank
JOIN ngprod.dbo.lab_nor nor ON nor.persON_id = tank.person_id
JOIN ngprod.dbo.lab_order_tests lot ON lot.order_num = nor.order_num
JOIN ngprod.dbo.lab_test_aoe_answer aoe ON aoe.order_num = nor.order_num
WHERE aoe.test_data_value LIKE '%Vaginal%'
AND CONVERT(date,tank.dos) = CONVERT(date,lot.collectiON_time)
AND nor.ngn_status = 'Signed-Off'

--Find previous GC/CT test
SELECT DISTINCT nor.person_id, MAX(CONVERT(date,lot.collection_time)) AS 'last'
INTO #last
FROM #enc_tank tank
JOIN ngprod.dbo.lab_nor nor ON nor.person_id = tank.person_id
JOIN ngprod.dbo.lab_order_tests lot ON lot.order_num = nor.order_num
JOIN ngprod.dbo.lab_test_aoe_answer aoe ON aoe.order_num = nor.order_num
WHERE 
  (aoe.test_data_value LIKE '%Vaginal%' 
OR aoe.test_data_value LIKE '%Urine%' 
OR aoe.test_data_value LIKE '%Pharyngeal%' 
OR aoe.test_data_value LIKE '%Rectal%')
AND CONVERT(date,tank.dos) > CONVERT(date,lot.collection_time)
AND nor.ngn_status = 'Signed-Off'
GROUP BY nor.person_id

--update main tank with previous test
UPDATE #enc_tank 
SET last_test = [last]
FROM #last l
JOIN #Enc_Tank e ON e.person_id = l.person_id

--Determine length of time between the original date of service and last test
UPDATE #enc_tank
SET [diff] = DATEDIFF(DAY, e.DOS, l.[last])
FROM #last l
JOIN #Enc_Tank e ON e.person_id = l.person_id
--***End Data section***

--***Start Risk section***
UPDATE #enc_tank
SET risk = 'Y'
WHERE diff <= -366 
OR diff IS NULL

--***Updates risk column based on answers to risk screening questionare***
--1=no 2=yes
--1=men 2=women 3=both
UPDATE #enc_tank
SET risk = 'Y'
FROM #enc_tank tank
JOIN ngprod.dbo.hpi_sti_screening_ hpi ON hpi.enc_id = tank.enc_id
WHERE 
   opt_new_partner = 2
OR opt_multiple_partners = 2
OR opt_partner_monogomous = 1
OR opt_known_exposure = 2
OR opt_sexual_favors = 1
OR opt_incarceration = 2 --Partner 
OR opt_patient_incarceration = 2 --Patient
OR opt_anonymous_partners = 2
OR (opt_sexual_partners = 3 AND Gender = 'M') --Both
OR (opt_sexual_partners = 1 AND Gender = 'M') --Men

--***Drop all enc where no risk factor present***
DELETE FROM #Enc_Tank
WHERE risk IS NULL

--select * from #Enc_Tank
--***End Risk section***

--***Begin appropriate Testing section***
--Male Insertive ONly
UPDATE #enc_tank
SET appropriate = 'Y'
FROM #enc_tank
WHERE Gender = 'M'
AND ([anal_insertive] = 'Y' OR [vaginal_insertive] = 'Y') --***Add oral insert??***
AND [Anal_receptive] IS NULL AND [oral_receptive] IS NULL
AND [Pharyngeal_swab] IS NULL AND [Vaginal_swab]  IS NULL AND Urine_sample = 'Y' AND Rectal_swab IS NULL

--Male Insertive AND anal receptive
UPDATE #enc_tank
SET appropriate = 'Y'
FROM #enc_tank
WHERE Gender = 'M'
AND ([anal_insertive] = 'Y' OR [vaginal_insertive] = 'Y') --***Add oral insert??***
AND [Anal_receptive] = 'y' AND [oral_receptive] IS NULL
AND [Pharyngeal_swab] IS NULL AND [Vaginal_swab]  IS NULL AND Urine_sample = 'Y' AND Rectal_swab = 'y'

--Male Insertive AND anal AND oral receptive
UPDATE #enc_tank
SET appropriate = 'Y'
FROM #enc_tank
WHERE Gender = 'M'
AND ([anal_insertive] = 'Y' OR [vaginal_insertive] = 'Y') --***Add oral insert??***
AND [Anal_receptive] = 'y' AND [oral_receptive] = 'y'
AND [Pharyngeal_swab] = 'y' AND [Vaginal_swab]  IS NULL AND Urine_sample = 'Y' AND Rectal_swab = 'y'

--Female Vaginal receptive
UPDATE #enc_tank
SET appropriate = 'Y'
FROM #enc_tank
WHERE gender = 'f' 
AND [Anal_receptive] IS NULL AND [oral_receptive] IS NULL AND [vaginal_receptive] = 'Y'
AND [Rectal_swab] IS NULL AND [Pharyngeal_swab] IS NULL AND ([Vaginal_swab] = 'Y' OR Urine_sample = 'Y')


--Male Anal receptive
UPDATE #enc_tank
SET appropriate = 'Y'
FROM #enc_tank
WHERE gender = 'M' 
AND [Anal_receptive] = 'Y' AND [oral_receptive] IS NULL AND [vaginal_receptive] IS NULL
AND [Rectal_swab] = 'Y' AND [Pharyngeal_swab] IS NULL AND [Vaginal_swab]  IS NULL AND Urine_sample IS NULL
AND [anal_insertive] IS NULL AND [vaginal_insertive] IS NULL 

--Female Anal receptive
UPDATE #enc_tank
SET appropriate = 'Y'
FROM #enc_tank
WHERE gender = 'f' 
AND [Anal_receptive] = 'Y' AND [oral_receptive] IS NULL AND [vaginal_receptive] IS NULL
AND [Rectal_swab] = 'Y' AND [Pharyngeal_swab] IS NULL AND [Vaginal_swab]  IS NULL AND Urine_sample IS NULL

--Male Oral receptive
UPDATE #enc_tank
SET appropriate = 'Y'
FROM #enc_tank
WHERE gender = 'M'
AND [oral_receptive] = 'Y' AND [vaginal_receptive] IS NULL AND [Anal_receptive] IS NULL
AND [Pharyngeal_swab] = 'Y' AND [Vaginal_swab]  IS NULL AND Urine_sample IS NULL AND Rectal_swab IS NULL
AND [anal_insertive] IS NULL AND [vaginal_insertive] IS NULL 

--Female Oral receptive
UPDATE #enc_tank
SET appropriate = 'Y'
FROM #enc_tank
WHERE gender = 'f' 
AND [oral_receptive] = 'Y' AND [vaginal_receptive] IS NULL AND [Anal_receptive] IS NULL
AND [Pharyngeal_swab] = 'Y' AND [Vaginal_swab]  IS NULL AND Urine_sample IS NULL AND Rectal_swab IS NULL

--Female Oral AND Vaginal receptive
UPDATE #enc_tank
SET appropriate = 'Y'
FROM #enc_tank
WHERE gender = 'f'
AND [oral_receptive] = 'Y' AND [vaginal_receptive] = 'Y' AND [Anal_receptive] IS NULL
AND [Pharyngeal_swab] = 'Y' AND ([Vaginal_swab] = 'Y' OR Urine_sample = 'y') AND Rectal_swab IS NULL

--Female Oral AND Vaginal AND anal receptive
UPDATE #enc_tank
SET appropriate = 'Y'
FROM #enc_tank
WHERE gender = 'f'
AND [oral_receptive] = 'Y' AND [vaginal_receptive] = 'Y' AND [Anal_receptive] = 'Y'
AND [Pharyngeal_swab] = 'Y' AND ([Vaginal_swab] = 'Y' OR Urine_sample = 'y') AND Rectal_swab = 'Y'

--Male Oral AND anal receptive
UPDATE #enc_tank
SET appropriate = 'Y'
FROM #enc_tank
WHERE gender = 'M' 
AND [oral_receptive] = 'Y' AND [vaginal_receptive] IS NULL AND [Anal_receptive] = 'Y'
AND [Pharyngeal_swab] = 'Y' AND [Vaginal_swab] IS NULL AND Urine_sample IS NULL AND Rectal_swab = 'Y'
AND [anal_insertive] IS NULL AND [vaginal_insertive] IS NULL 

--Female Oral AND anal receptive
UPDATE #enc_tank
SET appropriate = 'Y'
FROM #enc_tank
WHERE gender = 'f' 
AND [oral_receptive] = 'Y' AND [vaginal_receptive] IS NULL AND [Anal_receptive] = 'Y'
AND [Pharyngeal_swab] = 'Y' AND [Vaginal_swab] IS NULL AND Urine_sample IS NULL AND Rectal_swab = 'Y'

--Vaginal AND anal receptive
UPDATE #enc_tank
SET appropriate = 'Y'
FROM #enc_tank
WHERE gender = 'f'
AND [oral_receptive] IS NULL AND [vaginal_receptive] = 'Y' AND [Anal_receptive] = 'Y'
AND [Pharyngeal_swab] IS NULL AND ([Vaginal_swab] = 'Y' OR Urine_sample = 'Y') AND Rectal_swab = 'Y'

--Female No sexual activity but tested
UPDATE #enc_tank
SET appropriate = 'Y'
FROM #enc_tank
WHERE gender = 'f' 
AND [oral_receptive] IS NULL AND [vaginal_receptive] IS NULL AND [Anal_receptive] IS NULL
AND [Pharyngeal_swab] IS NULL AND ([Vaginal_swab] = 'Y' OR Urine_sample = 'Y') AND Rectal_swab IS NULL

--Male No sexual activity but tested
UPDATE #enc_tank
SET appropriate = 'Y'
FROM #enc_tank
WHERE gender = 'm' 
AND [oral_receptive] IS NULL AND [Anal_receptive] IS NULL
AND [oral_insertive] IS NULL AND [Anal_insertive] IS NULL AND [vaginal_insertive] IS NULL
AND [Pharyngeal_swab] IS NULL AND [Vaginal_swab] IS NULL AND Urine_sample = 'Y' AND Rectal_swab IS NULL

--***End appropriate testing section***

--***Drop person/enc id for clean output***
ALTER TABLE #Enc_Tank
DROP COLUMN person_id

ALTER TABLE #Enc_Tank
DROP COLUMN enc_id

SELECT *
FROM #Enc_Tank tank