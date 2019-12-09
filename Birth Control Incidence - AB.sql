--============================================= 
-- Author: Eric Born
-- Create Date: 07/01/2017
-- Numerator: Number of unique females 15-44 at risk of unintended pregnancy (UP)* who were dispensed Tier I birth control after an AB visit
--			  Number of unique females 15-44 at risk of unintended pregnancy (UP)* who were dispensed Tier II birth control after an AB visit
-- Denominator: Total unique females 15-44 at risk of UP who had a visit where Tier I and Tier II birth control was dispensed in the analysis period after an AB visit
-- Modified by:
-- Modifications:
-- =============================================

--***Drop temp tables***
--DROP TABLE #temp1
--DROP TABLE #pme
--DROP TABLE #main
--DROP TABLE #med
--DROP TABLE #main1

DECLARE @Start_Date_1 DATETIME
DECLARE @End_Date_1 DATETIME

--SET @Start_Date_1 = @Start_Date
--SET @End_Date_1 = @End_Date

SET @Start_Date_1 = '20171001'
SET @End_Date_1 = '20171231'

--**********Start data Table Creation***********
--Creates list of all encounters, dx and SIM codes during time period
SELECT pp.enc_id, pp.person_id, p.sex, pp.service_item_id, pp.service_date, pe.enc_nbr, p.person_nbr, p.date_of_birth
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
AND (Service_Item_id = '59840A'
 OR	 Service_Item_id LIKE '59841[C-N]'
 OR  Service_Item_id = 'S0199'
 OR	 Service_Item_id = 'S0199A')

 --***Creates list of all encounters, dx and SIM codes during time period***
SELECT pp.enc_id, pp.person_id, p.sex, pp.service_item_id, pp.service_date, pe.enc_nbr, p.person_nbr, p.date_of_birth
INTO #pme
FROM ngprod.dbo.patient_procedure pp 
JOIN ngprod.dbo.patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN ngprod.dbo.person	p			 ON pp.person_id = p.person_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1) 
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND p.sex = 'f'
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --Clinical services and Lab locations are excluded
						 --'966B30EA-F24F-48D6-8346-948669FDCE6E' Online services included in totals
AND (Service_Item_id = '99214PME')

CREATE TABLE #med
(
 enc_id UNIQUEIDENTIFIER
,person_id UNIQUEIDENTIFIER
,person_nbr VARCHAR(30)
,service_item_id VARCHAR(100)
,service_date DATE
)

--***Insert all encounters where BC was dispensed***
INSERT INTO #med
SELECT DISTINCT p.enc_id, p.person_id, person_nbr, p.service_item_id, p.service_date
FROM #temp1 t
JOIN ngprod.dbo.patient_procedure p ON t.person_id = p.person_id AND t.service_date = p.service_date 
WHERE p.service_item_id IN
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
	)  AND p.delete_ind = 'N'

--***Insert all encounters where BC was ERX'ed***
INSERT INTO #med
SELECT DISTINCT t.enc_id, t.person_id, t.person_nbr, medication_name, t.service_date
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

CREATE TABLE #pmemed
(
 enc_id UNIQUEIDENTIFIER
,person_id UNIQUEIDENTIFIER
,person_nbr VARCHAR(30)
,service_item_id VARCHAR(100)
,service_date DATE
)

--***Insert all encounters where BC was dispensed at a PME visit***
INSERT INTO #pmemed
SELECT DISTINCT p.enc_id, p.person_id, person_nbr, pp.service_item_id, p.service_date
FROM #pme p
JOIN ngprod.dbo.patient_procedure pp ON pp.person_id = p.person_id AND pp.service_date = p.service_date 
WHERE pp.service_item_id IN
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
	)  AND pp.delete_ind = 'N'

--***Insert all encounters where BC was ERX'ed at a PME visit***
INSERT INTO #pmemed
SELECT DISTINCT p.enc_id, p.person_id, p.person_nbr, medication_name, p.service_date
FROM ngprod.dbo.erx_message_history H 
JOIN ngprod.dbo.patient_medication PM on H.person_id = PM.person_id AND H.medication_id = PM.uniq_id AND h.provider_id = PM.provider_id --158274
JOIN #pme p ON p.enc_id = PM.enc_id
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

--***Create main reporting table***
CREATE TABLE #main
(
	 person_id UNIQUEIDENTIFIER
	,person_nbr VARCHAR(30)
	,service_item_id VARCHAR(100)
	,DOS DATE
	,age INT
	--,BCM VARCHAR(100)
	,tier VARCHAR(3)
)

--***Insert distinct people into main table***
INSERT INTO #main
SELECT DISTINCT person_id, person_nbr, NULL, service_date, NULL, NULL--, NULL
FROM #temp1 t

--Update main table with BCM given on AB or PME day
UPDATE #main
SET #main.service_item_id = m.service_item_id
FROM #med m
WHERE m.person_nbr = #main.person_nbr 
AND m.service_date = #main.DOS

UPDATE #main
SET #main.service_item_id = p.service_item_id
FROM #pmemed p
WHERE p.person_nbr = #main.person_nbr 
AND #main.service_item_id IS NULL

--***Calculate age from DOS***
UPDATE #main
SET age = CAST((CONVERT(INT,CONVERT(CHAR(8),DOS,112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar)
FROM #main f
JOIN ngprod.dbo.person p ON p.person_id = f.person_id

--***Delete patients below 15 or over 44***
DELETE FROM #main
WHERE age < 15 OR age > 44

--select distinct bcm from #main
--***Updates the tier for Implant/IUC***
UPDATE #main
SET tier = 1
WHERE service_item_id IN
(
'J7297','J7298','J7300','J7301','J7302' --IUC
,'J7307' --Implant
)

--***Updates Tier for Pill/Patch/Ring patients***
UPDATE #main
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

UPDATE #main
SET #main.service_item_id = 'Condoms'
FROM ngprod.dbo.patient_procedure pp
JOIN #main m ON m.person_id = pp.person_id AND m.DOS = pp.service_date
WHERE m.service_item_id IS NULL 
AND pp.service_item_id IN (
 '10CON'
,'10CON-NC'
,'C002NC'
,'C002'
,'12CON-NC'
,'C003'
,'24CON-NC'
,'C033'
,'48CON'
,'24CON'
,'30CON'
,'30CON-NC')

--***Updates Tier for ERX patients***
UPDATE #main
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

UPDATE #main
SET tier = 3
WHERE 	
	   service_item_id LIKE '%diaphragm%' --diaphragm
	OR service_item_id LIKE '%dental%' --dental dam
	OR service_item_id LIKE '%film%' --film
	OR service_item_id LIKE '%sponge%' --film
	OR service_item_id LIKE 'Condoms' --film

UPDATE #main
SET tier = 4
WHERE tier IS NULL

--Pull all non-null values
SELECT *
INTO #main1
FROM #main
WHERE service_item_id IS NOT NULL

--select * from #main
--Pull most recent null value where person was not included from first pull
INSERT INTO #main1
SELECT m.person_id, person_nbr, service_item_id, DOS, age, tier 
FROM #main m
INNER JOIN
	(SELECT person_id, MAX(DOS) AS MAXDATE
	 FROM #main
	 GROUP BY person_id) grouped
ON m.person_id = grouped.person_id AND m.DOS = grouped.MAXDATE
WHERE m.person_nbr NOT IN 
(
SELECT person_nbr FROM #main1
)

--Raw output
--Grabs most recent to keep patients unique in the case of having bc dispensed at both the MAB and PME visit
--person_nbr 666192 is an example of this happening
SELECT person_nbr, service_item_id, DOS, age, tier 
FROM #main1 m
INNER JOIN
	(SELECT person_id, MAX(DOS) AS MAXDATE
	 FROM #main1
	 GROUP BY person_id) grouped
ON m.person_id = grouped.person_id AND m.DOS = grouped.MAXDATE
ORDER BY person_nbr

--***Just counts based on BC tier***
SELECT DISTINCT
 (SELECT COUNT(*) FROM #main1 WHERE tier = 1) AS 'Tier 1 Total'
,(SELECT COUNT(*) FROM #main1 WHERE tier = 2) AS 'Tier 2 Total'
,(SELECT COUNT(*) FROM #main1 WHERE tier = 3) AS 'Tier 3 Total'
,(SELECT COUNT(*) FROM #main1 WHERE tier = 4) AS 'Tier 4 Total'