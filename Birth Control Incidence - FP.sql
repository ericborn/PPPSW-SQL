--============================================= 
-- Author: Eric Born
-- Create Date: 07/01/2017
-- Numerator: Number of unique females 15-44 at risk of unintended pregnancy (UP)* who were dispensed Tier I birth control and did not have an AB that day
--			  Number of unique females 15-44 at risk of unintended pregnancy (UP)* who were dispensed Tier II birth control and did not have an AB that day
-- Denominator: Total unique females 15-44 at risk of UP who had a visit where Tier I and Tier II birth control was dispensed in the analysis period and did not have an AB that day
-- Modified by:
-- Modifications:
-- =============================================

--***Drop temp tables***
--DROP TABLE #fcon	
--DROP TABLE #temp1
--DROP TABLE #med
--DROP TABLE #ab

DECLARE @Start_Date_1 DATETIME
DECLARE @End_Date_1 DATETIME

--SET @Start_Date_1 = @Start_Date
--SET @End_Date_1 = @End_Date

SET @Start_Date_1 = '20171001'
SET @End_Date_1 = '20171231'

--**********Start data Table Creation***********
--Creates list of all encounters, dx and SIM codes during time period
SELECT pp.enc_id, pp.person_id, p.sex, pp.service_item_id, pp.service_date, pe.enc_nbr, p.person_nbr, p.date_of_birth,
pp.diagnosis_code_id_1, pp.diagnosis_code_id_2, pp.diagnosis_code_id_3, pp.diagnosis_code_id_4
INTO #temp1
FROM ngprod.dbo.patient_procedure pp
JOIN ngprod.dbo.patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN ngprod.dbo.person	p			 ON pp.person_id = p.person_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1) 
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND p.sex = 'f'
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --Clinical services and Lab locations are excluded
						 --'966B30EA-F24F-48D6-8346-948669FDCE6E' Online services included in totals

--***Find all AB related visits during report period***
SELECT DISTINCT person_nbr, service_date
INTO #ab
FROM #temp1
WHERE 
   (
	 Service_Item_id = '59840A'
OR	 Service_Item_id LIKE '59841[C-N]'
OR	 Service_Item_id = 'S0199'
OR	 Service_Item_id = 'S0199A'
OR	 Service_Item_id = '99214PME'
	)
GROUP BY  person_nbr, service_date

CREATE TABLE #med
(
 person_id UNIQUEIDENTIFIER
,enc_id UNIQUEIDENTIFIER
,person_nbr VARCHAR(30)
,enc_nbr VARCHAR(30)
,service_item_id VARCHAR(100)
,DOS DATE
,age INT
,bcm VARCHAR(30)
,tier VARCHAR(3)
)

--***Insert all encounters where BC was ERX'ed***
INSERT INTO #med
SELECT DISTINCT t.person_id, t.enc_id, t.person_nbr, t.enc_nbr, medication_name, t.service_date
,NULL, NULL, NULL
FROM ngprod.dbo.erx_message_history H 
JOIN ngprod.dbo.patient_medication PM on H.person_id = PM.person_id AND H.medication_id = PM.uniq_id AND h.provider_id = PM.provider_id --158274
JOIN #temp1 t ON t.enc_id = PM.enc_id
WHERE
	   medication_name LIKE '%AUBRA%' --Pill types
	OR medication_name LIKE '%AVIANE%'
	OR medication_name LIKE '%Brevicon%'
	OR medication_name LIKE '%CHATEAL%'
	OR medication_name LIKE '%Cyclessa%'
	OR medication_name LIKE '%Desogen%'
	OR medication_name LIKE '%Gildess%'
	OR medication_name LIKE '%Levora%'
	OR medication_name LIKE '%Lutera%'
	OR medication_name LIKE '%LYZA%'
	OR medication_name LIKE '%Loestrin%'
	OR medication_name LIKE '%Mgestin%'
	OR medication_name LIKE '%Micronor%'
	OR medication_name LIKE '%Microgest%'
	OR medication_name LIKE '%Modicon%'
	OR medication_name LIKE '%NORTREL%'
	OR medication_name LIKE '%OCEPT%'
	OR medication_name LIKE '%ON135%'
	OR medication_name LIKE '%ON777%'
	OR medication_name LIKE '%ORCYCLEN%'
	OR medication_name LIKE '%OTRICYCLEN%'
	OR medication_name LIKE '%ORTHO%'
	OR medication_name LIKE '%RECLIPSEN%'
	OR medication_name LIKE '%Tarina%'
	OR medication_name LIKE '%TRILO%'
	OR medication_name LIKE '%YAZ%'
	OR medication_name LIKE '%nuvaring%' --ring
	OR medication_name LIKE '%XULANE%' --patch
	OR medication_name LIKE '%diaphragm%' --diaphragm
	OR medication_name LIKE '%dental%' --dental dam
	OR medication_name LIKE '%film%' --film
	OR medication_name LIKE '%sponge%' --film

--***********FINDING LATEST ENCOUNTER THEN LOOKING FOR BCM IN THAT ENCOUNTER
--***********SHOULD BE FINDING LATEST BCM AT LATEST ENCOUNTER WITH BCM
--***********ALSO IS UPDATING ALL ENCOUNTERS WITH BCM TO LATEST DATE INSTEAD OF DATE WHERE BCM WAS DISPENSED
--***Insert most recent visit for all female patients who received BC during period***
INSERT INTO #med
SELECT DISTINCT t.person_id, t.enc_id, t.person_nbr, t.enc_nbr, t.service_item_id, t.service_date
,NULL, NULL, NULL
FROM #temp1 t
--INNER JOIN
--	(SELECT person_id, MAX(service_date) AS MAXDATE
--	 FROM #temp1
--	 GROUP BY person_id) grouped
--ON t.person_id = grouped.person_id AND t.service_date = grouped.MAXDATE 
--WHERE
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
		,'C005' --Diaphragm
		,'B008' --Female Condom
		,'C003' --Female Condom
		,'C001' --Cervical Cap
		,'C006' --Foam
		,'FILM','SPONGE','DENTAL'
	) 

--select * from #med where person_id = '6ACD18F6-9CB6-489C-9EDF-AEB4EB0B1B39'
	 
--***Deletes from main table if patient had a MAB/TAB on the same day***
DELETE 
FROM #med
WHERE EXISTS
(
SELECT *
FROM #ab a
WHERE a.person_nbr = #med.person_nbr AND a.service_date = #med.DOS
)	

--Updates ring from erx name to internal SIM code for elimination of meds appearing in both med module and ERX
UPDATE #med
SET service_item_id = 'J7303'
WHERE service_item_id = 'NuvaRing 0.12 mg -0.015 mg/24 hr vaginal'

--Finds most recent contraception visit
SELECT DISTINCT m.person_id, m.enc_id, m.person_nbr, m.enc_nbr, m.service_item_id, m.DOS, m.age, m.bcm, m.tier
INTO #fcon
FROM #med m
INNER JOIN
	(SELECT person_id, MAX(DOS) AS MAXDATE
	 FROM #med
	 GROUP BY person_id) grouped
ON m.person_id = grouped.person_id AND m.DOS = grouped.MAXDATE 
--JOIN #temp1 t ON pm.person_id = t.person_id
--WHERE service_item_id = 'NuvaRing 0.12 mg -0.015 mg/24 hr vaginal' --OR service_item_id = 'J7303'
ORDER BY person_nbr

--***Calculate age at last DOS***
UPDATE #fcon
SET age = CAST((CONVERT(INT,CONVERT(CHAR(8),DOS,112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar)
FROM #fcon f
JOIN ngprod.dbo.person p ON p.person_id = f.person_id

--***Delete patients below 15 or over 44***
DELETE FROM #fcon
WHERE age < 15 OR age > 44

--***Gather BCM at end of visit based on enc_id***
UPDATE #fcon
SET bcm = m.txt_birth_control_visitend
FROM NGProd.dbo.master_im_ m
JOIN #fcon f ON m.enc_id = f.enc_id

--***Delete patients who are seeking pregnancy or cannot become pregnant***
DELETE FROM #fcon
WHERE bcm IN
(
 'Pregnant/Partner Pregnant'
,'Seeking pregnancy'
,'Female Sterilization'
,'Vasectomy'
,'Infertile'
,'Same sex partner'
)

--***Updates the tier of patients BCM***
UPDATE #fcon
SET tier = 1
WHERE service_item_id IN
(
'J7297','J7298','J7300','J7301','J7302' --IUC
,'J7307' --Implant
)

UPDATE #fcon
SET tier = 2
WHERE service_item_id IN
(
'AUBRA','Brevicon','CHATEAL','Cyclessa','Desogen','DesogenNC','Gildess','Levora','LEVORANC','LYZA','Mgestin'
,'MGESTINNC','Micronor','Micronornc','Modicon','NO777','NORTREL','OCEPT','ON135','ON135NC','ON777','ON777NC'
,'ORCYCLEN','ORCYCLENNC','OTRICYCLEN','OTRINC','RECLIPSEN','Tarina','TRILO','TRILONC' --Pills
,'J7304','X7728','X7728-ins','X7728-pt' --Patch
,'J7303' --Ring
,'J1050' --Depo
)

--***Updates Tier for ERX patients***
UPDATE #fcon
SET tier = 2
WHERE 
	   service_item_id LIKE '%AUBRA%' --Pill types
	OR service_item_id LIKE '%AVIANE%'
	OR service_item_id LIKE '%Brevicon%'
	OR service_item_id LIKE '%CHATEAL%'
	OR service_item_id LIKE '%Cyclessa%'
	OR service_item_id LIKE '%Desogen%'
	OR service_item_id LIKE '%Gildess%'
	OR service_item_id LIKE '%Levora%'
	OR service_item_id LIKE '%Lutera%'
	OR service_item_id LIKE '%LYZA%'
	OR service_item_id LIKE '%Loestrin%'
	OR service_item_id LIKE '%Mgestin%'
	OR service_item_id LIKE '%Micronor%'
	OR service_item_id LIKE '%Microgest%'
	OR service_item_id LIKE '%Modicon%'
	OR service_item_id LIKE '%NORTREL%'
	OR service_item_id LIKE '%OCEPT%'
	OR service_item_id LIKE '%ON135%'
	OR service_item_id LIKE '%ON777%'
	OR service_item_id LIKE '%ORCYCLEN%'
	OR service_item_id LIKE '%OTRICYCLEN%'
	OR service_item_id LIKE '%ORTHO%'
	OR service_item_id LIKE '%RECLIPSEN%'
	OR service_item_id LIKE '%Tarina%'
	OR service_item_id LIKE '%TRILO%'
	OR service_item_id LIKE '%YAZ%'
	OR service_item_id LIKE '%nuvaring%' --ring
	OR service_item_id LIKE '%XULANE%' --patch

UPDATE #fcon
SET tier = 4
WHERE tier IS NULL

--***Used to check if charts made it into the pull who had TAB/MAB code on same day***
--select * 
--from #fcon f
--JOIN patient_procedure pp ON pp.service_date = f.DOS AND pp.person_id = f.person_id
--WHERE 
--	 pp.Service_Item_id LIKE '%59840A%'
--OR	 pp.Service_Item_id LIKE '%59841[C-N]%'
--OR	 pp.Service_Item_id LIKE '%S0199%'
--OR	 pp.Service_Item_id LIKE '%S0199A%'
--OR	 pp.Service_Item_id LIKE '%99214PME%'

ALTER TABLE #fcon
DROP COLUMN person_id

ALTER TABLE #fcon
DROP COLUMN enc_id

SELECT * FROM #fcon

SELECT DISTINCT
 (SELECT COUNT(*) FROM #fcon WHERE tier = 1) AS 'Tier 1 Total'
,(SELECT COUNT(*) FROM #fcon WHERE tier = 2) AS 'Tier 2 Total'