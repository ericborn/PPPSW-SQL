USE [NGProd]

DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

SET @Start_Date_1 = '20171001'
SET @End_Date_1 = '20171231'

--**********Start data Table Creation***********
--Creates list of all encounters, dx and SIM codes during time period
SELECT pp.enc_id, pp.person_id, p.sex,
       pp.diagnosis_code_id_1, pp.diagnosis_code_id_2, pp.diagnosis_code_id_3, pp.diagnosis_code_id_4, 
       pp.service_item_id, pp.service_date, pp.location_id, cob1_payer_id
INTO #temp1
FROM patient_procedure pp
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN person	p			 ON pp.person_id = p.person_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1) 
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --Clinical services and Lab locations are excluded
						 --'966B30EA-F24F-48D6-8346-948669FDCE6E' Online services included in totals

--***Start demographics table***
select DISTINCT per.person_id
	  ,'sex' = per.sex
	  ,'N/E' = 'N'
INTO #demo
FROM #temp1 t1
JOIN ngprod.dbo.person per		 ON per.person_id	= t1.person_id
--***End demographics table***

--Table containing all female contraception patients
SELECT DISTINCT person_id
INTO #fcon
FROM #temp1
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
	) AND sex = 'F'

--Gathers female patients with a birth control visit type
SELECT DISTINCT t.person_id, t.enc_id, t.service_item_id
INTO #bcm
FROM #temp1 t
JOIN master_im_ m ON t.enc_id = m.enc_id
WHERE chiefcomplaint1 IN 
('Reversible Contraception', 'BCM Change', 'Refill/Supplies'
,'Depo re-start','Depo Restart','Dmpa refill','DMPA Restart','DMPA Restart'
,'IUC','IUC retrieval','implant chk','Implant removal','Iuc removal','IUD check','IUD Removal'
,'OC Refill','iuc chk','Implant Insert','Implant Removal/Re-Insert','IUC Insert') 
OR chiefcomplaint2 IN 
('Reversible Contraception', 'BCM Change', 'Refill/Supplies'
,'Depo re-start','Depo Restart','Dmpa refill','DMPA Restart','DMPA Restart'
,'IUC','IUC retrieval','implant chk','Implant removal','Iuc removal','IUD check','IUD Removal'
,'OC Refill','iuc chk','Implant Insert','Implant Removal/Re-Insert','IUC Insert') 
OR chiefcomplaint3 IN 
('Reversible Contraception', 'BCM Change', 'Refill/Supplies'
,'Depo re-start','Depo Restart','Dmpa refill','DMPA Restart','DMPA Restart'
,'IUC','IUC retrieval','implant chk','Implant removal','Iuc removal','IUD check','IUD Removal'
,'OC Refill','iuc chk','Implant Insert','Implant Removal/Re-Insert','IUC Insert') 
OR chiefcomplaint5 IN 
('Reversible Contraception', 'BCM Change', 'Refill/Supplies'
,'Depo re-start','Depo Restart','Dmpa refill','DMPA Restart','DMPA Restart'
,'IUC','IUC retrieval','implant chk','Implant removal','Iuc removal','IUD check','IUD Removal'
,'OC Refill','iuc chk','Implant Insert','Implant Removal/Re-Insert','IUC Insert') 
OR chiefcomplaint6 IN 
('Reversible Contraception', 'BCM Change', 'Refill/Supplies'
,'Depo re-start','Depo Restart','Dmpa refill','DMPA Restart','DMPA Restart'
,'IUC','IUC retrieval','implant chk','Implant removal','Iuc removal','IUD check','IUD Removal'
,'OC Refill','iuc chk','Implant Insert','Implant Removal/Re-Insert','IUC Insert') 
AND sex = 'f'

--Gathers distinct females who had a BCM visit type and received condoms but not another type of BC
SELECT DISTINCT person_id
INTO #bcm1
FROM #bcm
WHERE service_item_id IN
('24CON-NC','10CON','30CON','30CON-NC','C002','12CON-NC','C002-INS','C002-PT','12CON','24CON','10CON'
,'48CON','10CON-NC','30CON','24CON-NC','12CON','C002','12CON','24CON','24CON','30CON-NC','12CON-NC','12CON','C002NC')
AND service_item_id NOT IN
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
--inserts the patients who received condoms at a b/c visit into the #fcon table
INSERT INTO #fcon (person_id)
SELECT DISTINCT person_id 
FROM #bcm1

--***Title X Table***
--*********NEEDS TO BE ONE PER PERSON PER DAY************
SELECT DISTINCT enc_id, person_id
INTO #x
FROM #temp1 
WHERE location_id NOT IN ('68C7DDB4-834A-4ABC-B3EB-87BF71D60F41', '966B30EA-F24F-48D6-8346-948669FDCE6E'
						 ,'518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --FASS, Online, Clinical services and Lab are excluded as they are non Title X centers
--All AB/MAB services are not covered by Title X
AND (diagnosis_code_id_1 != 'Z64.0'
AND  diagnosis_code_id_2 != 'Z64.0'
AND  diagnosis_code_id_3 != 'Z64.0'
AND  diagnosis_code_id_4 != 'Z64.0'
AND	 Service_Item_id NOT LIKE '%59840A%'
AND	 Service_Item_id NOT LIKE '%59841[C-N]%'
AND	 Service_Item_id NOT LIKE '%S0199%'
AND	 Service_Item_id NOT LIKE '%S0199A%'
	)

--Create fpl calculation table
select DISTINCT t.person_id, fi.family_annual_income AS [income], fi.family_size_nbr AS [size], 'fpl' = NULL
INTO #fpl
FROM #temp1 t
JOIN practice_person_family_info fi ON t.person_id = fi.person_id
WHERE fi.modify_timestamp = (SELECT MAX(modify_timestamp)
                   from practice_person_family_info fi2
                   where fi.person_id = fi2.person_id)

--Calculate FPL
UPDATE #fpl
SET fpl =
	(
		CASE
			WHEN size = 1 AND (income BETWEEN 0.00 AND 11880.00)  THEN '100'
			WHEN size = 1 AND (income BETWEEN 11881.00 AND 17820.00)  THEN '150'
			WHEN size = 1 AND (income BETWEEN 17821.00 AND 23760.00)  THEN '200'
			WHEN size = 1 AND (income BETWEEN 23761.00 AND 29700.00)  THEN '250'
			WHEN size = 1 AND (income BETWEEN 29701.00 AND 9999999.00)  THEN '251'

			WHEN size = 2 AND (income BETWEEN 0 AND 16020.00)  THEN '100'
			WHEN size = 2 AND (income BETWEEN 16021 AND 24030.00)  THEN '150'
			WHEN size = 2 AND (income BETWEEN 24031 AND 32040.00)  THEN '200'
			WHEN size = 2 AND (income BETWEEN 32041 AND 40050.00)  THEN '250'
			WHEN size = 2 AND (income BETWEEN 40051 AND 9999999.00)  THEN '251'

			WHEN size = 3 AND (income BETWEEN 0 AND 20160.00)  THEN '100'
			WHEN size = 3 AND (income BETWEEN 20161 AND 30240.00)  THEN '150'
			WHEN size = 3 AND (income BETWEEN 30240 AND 40320.00)  THEN '200'
			WHEN size = 3 AND (income BETWEEN 40321 AND 50400.00)  THEN '250'
			WHEN size = 3 AND (income BETWEEN 50401 AND 9999999.00)  THEN '251'

			WHEN size = 4 AND (income BETWEEN 0 AND 24300.00)  THEN '100'
			WHEN size = 4 AND (income BETWEEN 24301 AND 36450.00)  THEN '150'
			WHEN size = 4 AND (income BETWEEN 36451 AND 48600.00)  THEN '200'
			WHEN size = 4 AND (income BETWEEN 48601 AND 60750.00)  THEN '250'
			WHEN size = 4 AND (income BETWEEN 60751 AND 9999999.00)  THEN '251'

			WHEN size = 5 AND (income BETWEEN 0 AND 28440.00)  THEN '100'
			WHEN size = 5 AND (income BETWEEN 28441 AND 42660.00)  THEN '150'
			WHEN size = 5 AND (income BETWEEN 42661 AND 56880.00)  THEN '200'
			WHEN size = 5 AND (income BETWEEN 56881 AND 71100.00)  THEN '250'
			WHEN size = 5 AND (income BETWEEN 71101 AND 9999999.00)  THEN '251'

			WHEN size = 6 AND (income BETWEEN 0 AND 32580.00)  THEN '100'
			WHEN size = 6 AND (income BETWEEN 32581 AND 48870.00)  THEN '150'
			WHEN size = 6 AND (income BETWEEN 48871 AND 65160.00)  THEN '200'
			WHEN size = 6 AND (income BETWEEN 65161 AND 81450.00)  THEN '250'
			WHEN size = 6 AND (income BETWEEN 81451 AND 9999999.00)  THEN '251'

			WHEN size = 7 AND (income BETWEEN 0 AND 36730.00)  THEN '100'
			WHEN size = 7 AND (income BETWEEN 36731 AND 55095.00)  THEN '150'
			WHEN size = 7 AND (income BETWEEN 55096 AND 73460.00)  THEN '200'
			WHEN size = 7 AND (income BETWEEN 73461 AND 91825.00)  THEN '250'
			WHEN size = 7 AND (income BETWEEN 91826 AND 9999999.00)  THEN '251'

			WHEN size = 8 AND (income BETWEEN 0 AND 40890.00)  THEN '100'
			WHEN size = 8 AND (income BETWEEN 40891 AND 61335.00)  THEN '150'
			WHEN size = 8 AND (income BETWEEN 61336 AND 81780.00)  THEN '200'
			WHEN size = 8 AND (income BETWEEN 81781 AND 102225.00)  THEN '250'
			WHEN size = 8 AND (income BETWEEN 102226 AND 9999999.00)  THEN '251'
			ELSE '0'
		END
	)
FROM #fpl

--Total refills
SELECT DISTINCT enc_id
INTO #refill
FROM #temp1
WHERE service_item_id = '99499'
AND sex = 'f'

--Total supply pickups
--per QVOL instructions Supply pickup is defined as supply pickup plus any other visit where contraception was dispensed
SELECT DISTINCT enc_id
INTO #supply
FROM #temp1
WHERE service_item_id = '99499'
OR service_item_id IN
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
AND sex = 'f'

--***Start ENC Payer***
SELECT DISTINCT person_id, enc_id, cob1_payer_id, service_date, sex, [finClass] = NULL
INTO #temp2
FROM #temp1 t
WHERE t.enc_id NOT IN (SELECT r.enc_id FROM #refill r)
ORDER BY person_id

UPDATE #temp2
SET [finClass] = '4110'
WHERE #temp2.cob1_payer_id IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #temp2 t ON t.cob1_payer_id = pm.payer_id
WHERE financial_class = 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF'
)

--Medi-Cal Managed Care-4130
UPDATE #temp2
SET [finClass] = '4130'
WHERE #temp2.cob1_payer_id IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #temp2 t ON t.cob1_payer_id = pm.payer_id
WHERE financial_class = '484A05B3-D5C8-415B-A8EE-3D14A7AF11D6'
)

--Medi-cal
UPDATE #temp2
SET [finClass] = '4120'
WHERE #temp2.cob1_payer_id IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #temp2 t ON t.cob1_payer_id = pm.payer_id
WHERE financial_class = 'C5BDDA12-DDC9-4CFF-A0A3-9749C7DD353D'
)

--Commercial
UPDATE #temp2
SET [finClass] = '4300'
WHERE #temp2.cob1_payer_id IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #temp2 t ON t.cob1_payer_id = pm.payer_id
WHERE financial_class = '8E5D6C7E-A34E-4B3C-8C0A-B2F1D2E20285' OR financial_class = '332DF613-7C43-4287-9050-9949B4142B0C'
)

--Cash does not have a financial class so it will be represented as NULL in the payer_id column
UPDATE #temp2
SET [finClass] = '0000'
WHERE #temp2.cob1_payer_id IS NULL

SELECT person_id
	  ,MAX(finClass) AS [finClass]
	  ,service_date
	  ,sex
INTO #enc_pay
FROM #temp2
GROUP BY person_id, service_date, sex
ORDER BY person_id, service_date

--***Start insurance table by patient***
--Groups enc by payer and NULL finClass to be updated based upon payer
SELECT DISTINCT person_id, enc_id, service_date, 'finClass' = NULL
INTO #pay
FROM #temp1
GROUP BY person_id, enc_id, service_date
ORDER BY person_id

SELECT DISTINCT p.person_id,
	CASE
		WHEN MAX(cob1_payer_id) IS NOT NULL THEN cob1_payer_id
		ELSE NULL
	END AS 'payer'
INTO #lucky
FROM #pay p
JOIN patient_encounter pe ON p.enc_id = pe.enc_id
GROUP BY p.person_id, finClass, cob1_payer_id
ORDER BY person_id

SELECT *, 'finClass' = NULL
INTO #pay2
FROM #lucky

--Updates #pay with the encounters financial class
--Fpact
UPDATE #pay2
SET [finClass] = '4110'
WHERE #pay2.payer IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #pay2 p ON p.payer = pm.payer_id
WHERE financial_class = 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF'
)

--Medi-Cal Managed Care-4130
UPDATE #pay2
SET [finClass] = '4130'
WHERE #pay2.payer IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #pay2 p ON p.payer = pm.payer_id
WHERE financial_class = '484A05B3-D5C8-415B-A8EE-3D14A7AF11D6'
)

--Medi-cal
UPDATE #pay2
SET [finClass] = '4120'
WHERE #pay2.payer IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #pay2 p ON p.payer = pm.payer_id
WHERE financial_class = 'C5BDDA12-DDC9-4CFF-A0A3-9749C7DD353D'
)

--Commercial
UPDATE #pay2
SET [finClass] = '4300'
WHERE #pay2.payer IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #pay2 p ON p.payer = pm.payer_id
WHERE financial_class = '8E5D6C7E-A34E-4B3C-8C0A-B2F1D2E20285' OR financial_class = '332DF613-7C43-4287-9050-9949B4142B0C'
)

--Cash does not have a financial class so it will be represented as NULL in the payer_id column
UPDATE #pay2
SET [finClass] = '0000'
WHERE #pay2.payer IS NULL

--Uses max to select the payer with the highest designator
SELECT DISTINCT p.person_id,
	CASE
		WHEN MAX(finClass) = '4300' THEN 'Commercial'
		WHEN MAX(finClass) = '4130' THEN 'Medi-Cal Managed Care'
		WHEN MAX(finClass) = '4120' THEN 'Medi-Cal'
		WHEN MAX(finClass) = '4110' THEN 'Fpact'
		WHEN MAX(finClass) = '0'	THEN 'Cash'
		ELSE 'Cash'
	END AS 'finClass'
INTO #finClass
FROM #pay2 p
GROUP BY p.person_id
order by finClass

--All AB/MAB who pay cash
SELECT DISTINCT enc_id
INTO #ab_cash
FROM #temp1 t
WHERE (service_item_id LIKE '%59840A%' 
    OR service_item_id LIKE '%59841[C-N]%' 
    OR service_item_id LIKE '%S0199%'
	OR location_id = '68C7DDB4-834A-4ABC-B3EB-87BF71D60F41') 
	AND cob1_payer_id IS NULL

 --Paid Cash. exclude FASS, MAB, TAB
SELECT DISTINCT x.enc_id
INTO #x_cash
FROM #x x
JOIN #temp1 t ON t.enc_id = x.enc_id
WHERE cob1_payer_id IS NULL
--**********END Table Create***********

--Create New vs established table
--SELECT DISTINCT person_id, sex, 'N/E' = 'N'
--INTO #vis
--FROM #onevis

--Update New vs established table based upon newEstablished flag in master_im_ table
UPDATE #demo
SET [N/E] = 'E'
WHERE person_id IN
(
SELECT DISTINCT m.person_id 
FROM master_im_ m
JOIN #temp1 t ON t.enc_id = m.enc_id
INNER JOIN
	(SELECT person_id, MIN(service_date) AS MINDATE
	 FROM #temp1
	 GROUP BY person_id) grouped
ON t.person_id = grouped.person_id AND t.service_date = grouped.MINDATE
WHERE m.newEstablished = '2'
)

--***End fin class*** 
--*******Temp table end********* 

--***Start counts***
SELECT DISTINCT
--***Section 1: Visit and Patient Volume***
 (SELECT COUNT (*) FROM #enc_pay) AS '01 - Total visits' --Total visits minus refill visits
,(SELECT COUNT (person_id) FROM #enc_pay WHERE sex = 'f') AS '02 - female visits' --Total female visits minus refill visits
,((SELECT COUNT (person_id) FROM #enc_pay WHERE sex = 'm')) AS '03 - male visits' --Total male visits minus refill visits
,((SELECT COUNT (person_id) FROM #enc_pay WHERE sex != 'f' AND sex != 'm'))  AS 'other visits' --total other visits minus refill visits
,0 AS [04 - Primary Care Visits]

,(SELECT COUNT(DISTINCT person_id) FROM #demo WHERE [N/E] = 'N') AS '05 - Total new patients'
,(SELECT COUNT(DISTINCT person_id) FROM #demo WHERE [N/E] = 'E') AS '06 - Total established patients'

,(SELECT COUNT (DISTINCT person_id) FROM #temp1) AS '07 - Total patients'
,(SELECT COUNT (DISTINCT person_id) FROM #temp1 WHERE sex = 'f') AS '08 - Total female patients'
,(SELECT COUNT (DISTINCT person_id) FROM #temp1 WHERE sex = 'm') AS '09 - Total male patients'
,(SELECT COUNT (DISTINCT person_id) FROM #temp1 WHERE sex != 'f' AND sex != 'm') AS 'Total other patients'
,0 AS '10 - Total primary care patients'
--***Section 1: Visit and Patient Volume***

--***Section 2: Service Mix***
,(SELECT COUNT (DISTINCT enc_id) FROM #temp1 WHERE 
	(
		   service_item_id IN ('L103','L104','L105','L071','L073')--GC/CT combo

	)
) +
(SELECT COUNT (DISTINCT enc_id) FROM #temp1 WHERE 
	(
		   service_item_id IN ('87491','L031','L069')--CT

	)
) +
(SELECT COUNT (DISTINCT enc_id) FROM #temp1 WHERE 
	(
		   service_item_id IN ('87591','L070')--GC

	)
) +
(SELECT COUNT (DISTINCT enc_id) FROM #temp1 WHERE 
	(	
		   service_item_id IN ('L033','L095','L110') --herpes
	)
) +
(SELECT COUNT (DISTINCT enc_id) FROM #temp1 WHERE 
	(
		   service_item_id IN ('L023','L099','86703', '87806')--HIV
	)
) +
(SELECT COUNT (DISTINCT enc_id) FROM #temp1 WHERE 
	(
		   service_item_id IN ('L026','L111','L030') --Syph
	)
) +
(SELECT COUNT (DISTINCT enc_id) FROM #temp1 WHERE 
	(
		   service_item_id IN ('L096','L034','L124') --HPV
	)
) + 
(SELECT COUNT (*) FROM #temp1 WHERE 
		   service_item_id LIKE '%L111%' --Trich
		OR service_item_id LIKE '%L112%'
) AS '11 - STI tests'
--***End STI Test***

,(SELECT COUNT (DISTINCT enc_id) FROM #temp1 WHERE 

	service_item_id IN ('L079','L079NC','L124','L034') --pap
 ) AS '12 - PAP tests'

,(SELECT COUNT (DISTINCT t.enc_id) --CBE
	FROM #temp1 t
	JOIN PhysExamExtPop_ peep ON peep.enc_id = t.enc_id
	WHERE peep.ExamFindings LIKE '%Palpation%'
	AND	  SystemExamed = 'breast') AS '13 - Breast exams'

--,(SELECT COUNT (DISTINCT t1.enc_id) --CBE
--FROM pe_breast_ pb
--JOIN #temp1 t1 ON t1.enc_id = pb.enc_id 
--AND (pb.palpr_nl = '1' or pb.palpL_nL = '1' or pb.palpb_nl = '1' 
--OR pb.palponly1 IS NOT NULL OR pb.palponly2 IS NOT NULL OR pb.palponly3 IS NOT NULL OR pb.palponly4 IS NOT NULL
--OR pb.palpb1 IS NOT NULL OR pb.palpb2 IS NOT NULL) ) AS '13 - Breast exams'

,(SELECT COUNT(DISTINCT enc_id) FROM #temp1 WHERE
	service_item_id LIKE '%59840A%'
)AS '14 - 1st trimester surgical abortion procedures'

,(SELECT COUNT(DISTINCT enc_id) FROM #temp1 WHERE
	service_item_id LIKE '%59841[C-N]%'
)AS '15 - 2nd trimester surgical abortion procedures'

,(SELECT COUNT(DISTINCT enc_id) FROM #temp1 WHERE
	service_item_id LIKE '%S0199%'
)AS '16 - Medical abortion procedures'

,(SELECT COUNT(DISTINCT enc_id) FROM #temp1 WHERE
  (diagnosis_code_id_1 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_2 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_3 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_4 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00'))
AND (service_item_id LIKE '%59840A%')) AS '17 - 1st Trimester miscarriage Management procedures'

,(SELECT COUNT(DISTINCT enc_id) FROM #temp1 WHERE
  (diagnosis_code_id_1 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_2 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_3 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_4 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00'))
AND (service_item_id LIKE '%59841[C-N]%')) AS '18 - 2nd Trimester miscarriage Management procedures'

,(SELECT COUNT(DISTINCT enc_id) FROM #temp1 WHERE
  (diagnosis_code_id_1 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_2 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_3 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_4 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00'))
AND (service_item_id LIKE '%S0199%')) AS '19 - Medical miscarriage Management procedures'

--Person_id used to ensure only first appointment is grabbed since it is very unlikely same patient will have two first visits for EPEM during a reporting period
,(SELECT COUNT(DISTINCT person_id) FROM #temp1 WHERE 
  (diagnosis_code_id_1 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_2 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_3 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_4 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00'))
AND (service_item_id NOT LIKE '%59840A%' AND service_item_id NOT LIKE '%59841[C-N]%' AND service_item_id NOT LIKE '%S0199%')) AS '20 - Expectant management visits'

--COLPO/Endo Biopsy w/COLPO
,(SELECT COUNT(DISTINCT enc_id) FROM #temp1 WHERE
   service_item_id IN ('56605','57100','57454','57455','58110','L035','L047')
) AS '21 - Colposcopies and biopsies'

--LEEP and Cryo
,(SELECT COUNT(DISTINCT enc_id) FROM #temp1 WHERE
   service_item_id LIKE '57511' --Cryo
OR service_item_id LIKE '57460' --LEEP
) AS '22 - LEEP and cryo procedures'
--***Section 2: Service Mix***

--***Section 3: Contraception***
,(SELECT COUNT(DISTINCT person_id) FROM #fcon) AS '23 - Total Female Contraception Patients'

,(SELECT COUNT(DISTINCT enc_id) FROM #supply) AS '24 - Supply Pickup'

,0 AS '24a - Supply Pickup by commercial insurance patients'

,(SELECT SUM(quantity) FROM charges --(OC cycles)
 WHERE (begin_date_of_service >= @Start_Date_1 AND begin_date_of_service <= @End_Date_1) 
 AND (
		   service_item_id LIKE '%AUBRA%' --Pill types
		OR service_item_id LIKE '%Brevicon%'
		OR service_item_id LIKE '%CHATEAL%'
		OR service_item_id LIKE '%Cyclessa%'
		OR service_item_id LIKE '%Desogen%'
		OR service_item_id LIKE '%Gildess%'
		OR service_item_id LIKE '%Levora%'
		OR service_item_id LIKE '%LYZA%'
		OR service_item_id LIKE '%Mgestin%'
		OR service_item_id LIKE '%Micronor%'
		OR service_item_id LIKE '%MODICON%'
		OR service_item_id LIKE '%NO777%'
		OR service_item_id LIKE '%nortel%'
		OR service_item_id LIKE '%OCEPT%'
		OR service_item_id LIKE '%ON135%'
		OR service_item_id LIKE '%ON777%'
		OR service_item_id LIKE '%ORCYCLEN%'
		OR service_item_id LIKE '%OTRICYCLEN%'
		OR service_item_id LIKE '%OTRINC%'
		OR service_item_id LIKE '%RECLIPSEN%'
		OR service_item_id LIKE '%Tarina%'
		OR service_item_id LIKE '%Trilo%' --Pill types
	) AND quantity > 0 ) AS '25 - Oral contraception cycles dispensed'
	
,(SELECT SUM(quantity) FROM charges --(Ring)
 WHERE (begin_date_of_service >= @Start_Date_1 AND begin_date_of_service <= @End_Date_1)
 AND (service_item_id = 'J7303') AND quantity > 0) AS '26 - Nuvaring cycles dispensed'

,(SELECT DISTINCT --(Patch)
	CAST(SUM(
		CASE
			WHEN quantity BETWEEN 12 AND 39 THEN quantity / 3
			ELSE quantity
		END
	   ) AS DECIMAL(25,0)) 
FROM charges c
JOIN person p ON p.person_id = c.person_id
WHERE (begin_date_of_service >= @Start_Date_1 AND begin_date_of_service <= @End_Date_1)
AND (service_item_id = 'J7304' OR service_item_id = 'xulane') AND quantity > 0)  AS '27 - Evra Patch cycles dispensed'

,(SELECT COUNT(DISTINCT source_id) FROM charges --(IUC)
 WHERE (begin_date_of_service >= @Start_Date_1 AND begin_date_of_service <= @End_Date_1)
 AND service_item_id IN ('J7297', 'J7298', 'J7300', 'J7301', 'J7302')
 AND quantity > 0) AS '28 - Successful IUC insertion procedures DONE'

,(SELECT COUNT(DISTINCT source_id) FROM charges --(Implant)
 WHERE (begin_date_of_service >= @Start_Date_1 AND begin_date_of_service <= @End_Date_1)
 AND (service_item_id = 'J7307') AND quantity > 0) AS '29 - Contraceptive implant (Implanon) insertion procedures'

,(SELECT COUNT(DISTINCT source_id) FROM charges --(Depo)
 WHERE (begin_date_of_service >= @Start_Date_1 AND begin_date_of_service <= @End_Date_1)
 AND (service_item_id = 'J1050') AND quantity > 0) AS '30 - Hormonal injection (Depo-provera) procedures'

,(SELECT COUNT(DISTINCT enc_id) FROM #temp1
WHERE (service_item_id LIKE '%ella%' 
	OR service_item_id LIKE '%econtra%' 
	OR service_item_id LIKE '%next%'
	OR service_item_id LIKE '%X7722%' --Plan B
	  ) 
)AS '31 - Emergency contraception kits dispensed or sold'
--***Section 3: Contraception***

--***Section 4: Title X***
,'YES' AS '32 Yes/No Is there at least one health center at your affiliate that receives Title X funding?'
,(SELECT COUNT(DISTINCT enc_id) FROM #x) AS '33 - Title X center visits'

,(SELECT COUNT(DISTINCT x.enc_id) 
  FROM #x x
  JOIN #fpl f ON f.person_id = x.person_id
  WHERE [fpl] = '100') AS '34 - Title X center visits 100% or below FPL'

,(SELECT COUNT(DISTINCT x.enc_id) 
  FROM #x x
  JOIN #fpl f ON f.person_id = x.person_id
  WHERE [fpl] = '150') AS '35 - Title X center visits 101-150% FPL'

,(SELECT COUNT(DISTINCT x.enc_id) 
  FROM #x x
  JOIN #fpl f ON f.person_id = x.person_id
  WHERE [fpl] = '200') AS '36 - Title X center visits 151-200% FPL'

,(SELECT COUNT(DISTINCT x.enc_id) 
  FROM #x x
  JOIN #fpl f ON f.person_id = x.person_id
  WHERE [fpl] = '250') AS '37 - Title X center visits 201-250% FPL'

,(SELECT COUNT(DISTINCT x.enc_id) 
  FROM #x x
  JOIN #fpl f ON f.person_id = x.person_id
  WHERE [fpl] = '251') AS '38 - Title X center visits above 250% FPL'

,(SELECT COUNT(DISTINCT x.enc_id) 
  FROM #x x
  JOIN #fpl f ON f.person_id = x.person_id
  WHERE [fpl] = '0') AS '39 - Title X center visits Unknown income'

,0 AS '(40) At what % of the Federal Poverty Level do your clients slide to zero?'
,0 AS '(41) At what % of the Federal Poverty Level does your highest slide begin?'
--***Section 4: Title X***

--***Section 5: Visits by Primary Payer***
,(SELECT COUNT (*) FROM #enc_pay WHERE finClass = '4300') AS '42 - Commercial Insurance Visits'
,(SELECT COUNT (*) FROM #enc_pay WHERE finClass = '4120') AS '43 - Medicaid visits'
,(SELECT COUNT (*) FROM #enc_pay WHERE finClass = '4110') AS '44 - Medicaid Family Planning Waiver visits'
,(SELECT COUNT (*) FROM #enc_pay WHERE finClass = '4130') AS '45 - Medicaid Managed Care visits'
,0 AS '46 - Medicare visits'
,(SELECT COUNT (*) FROM #enc_pay WHERE finClass = '0' OR finClass IS NULL) AS '47 - Self pay visits' --3768

--All AB/MAB who pay cash
,(SELECT COUNT(DISTINCT enc_id) FROM #ab_cash) AS '47a - Self pay visits where patient fee is not supported by external grant(s)' 

 --Paid Cash. exclude FASS, MAB, TAB
,((SELECT COUNT (*) FROM #enc_pay WHERE finClass = '0' OR finClass IS NULL) - (SELECT COUNT(DISTINCT enc_id) FROM #ab_cash)) AS '47b Self pay visits associated with Title X' 

,0 AS '47c All other self pay visit' 
,0 AS '48 Visits with an unknown primary payer'
--***Section 5: Visits by Primary Payer***

--***Section 6: Payer Mix by Patient Type***
,(SELECT COUNT(DISTINCT f.person_id) 
FROM #finClass f
JOIN #fcon fc ON f.person_id = fc.person_id
WHERE f.finClass = 'Commercial')
AS '49 Female Contraception Patients - Commercial'

,(SELECT COUNT(DISTINCT f.person_id) 
FROM #finClass f
JOIN #fcon fc ON f.person_id = fc.person_id
WHERE f.finClass = 'Medi-Cal')
AS '49 Female Contraception Patients - Medicaid (traditional)'

,(SELECT COUNT(DISTINCT f.person_id) 
FROM #finClass f
JOIN #fcon fc ON f.person_id = fc.person_id
WHERE f.finClass = 'Fpact')
AS '49 Female Contraception Patients - Medicaid Family Planning'

,(SELECT COUNT(DISTINCT f.person_id) 
FROM #finClass f
JOIN #fcon fc ON f.person_id = fc.person_id
WHERE f.finClass = 'Medi-Cal Managed Care')
AS '49 Female Contraception Patients - Medicaid Managed Care'

,0 AS '49 Female Contraception Patients - Medicare'

,(SELECT COUNT(DISTINCT f.person_id) 
FROM #finClass f
JOIN #fcon fc ON f.person_id = fc.person_id
WHERE f.finClass = 'cash')
AS '49 Female Contraception Patients - Self Pay'

,0 AS '49 Female Contraception Patients - Unknown'

,(SELECT COUNT(DISTINCT person_id) 
FROM #fcon)
 AS '49 Female Contraception Patients - Total'

,(SELECT COUNT(DISTINCT f.person_id)
FROM #finClass f
JOIN #demo d ON d.person_id = f.person_id
WHERE f.finClass = 'Commercial' AND [N/E] = 'N') AS '49 New Patients - Commercial'

,(SELECT COUNT(DISTINCT f.person_id)
FROM #finClass f
JOIN #demo d ON d.person_id = f.person_id
WHERE f.finClass = 'Medi-Cal' AND [N/E] = 'N') AS '49 New Patients - Medicaid (traditional)'

,(SELECT COUNT(DISTINCT f.person_id)
FROM #finClass f
JOIN #demo d ON d.person_id = f.person_id
WHERE f.finClass = 'fpact' AND [N/E] = 'N') AS '49 New Patients - Medicaid Family Planning'

,(SELECT COUNT(DISTINCT f.person_id)
FROM #finClass f
JOIN #demo d ON d.person_id = f.person_id
WHERE f.finClass = 'Medi-Cal Managed Care' AND [N/E] = 'N') AS '49 New Patients - Medicaid Managed Care'

,0 AS '49 New Patients - Medicare'

,(SELECT COUNT(DISTINCT f.person_id)
FROM #finClass f
JOIN #demo d ON d.person_id = f.person_id
WHERE f.finClass = 'cash' AND [N/E] = 'N') AS '49 New Patients - Self Pay'

,0 AS '49 New Patients - Unknown'

,(SELECT COUNT(DISTINCT person_id)
FROM #demo d
WHERE [N/E] = 'N') AS '49 New Patients - Total'

,(SELECT COUNT(DISTINCT f.person_id) 
  FROM #finClass f WHERE f.finClass = 'Commercial') AS '49 Total Patients - Commercial'

,(SELECT COUNT(DISTINCT f.person_id) 
  FROM #finClass f WHERE f.finClass = 'Medi-Cal') AS '49 Total Patients - Medicaid (traditional)'

,(SELECT COUNT(DISTINCT f.person_id) 
  FROM #finClass f WHERE f.finClass = 'fpact') AS '49 Total Patients - Medicaid Family Planning'

,(SELECT COUNT(DISTINCT f.person_id) 
  FROM #finClass f WHERE f.finClass = 'Medi-Cal Managed Care') AS '49 Total Patients - Medicaid Managed Care'

,0 AS '49 Total Patients - Medicare'

,(SELECT COUNT(DISTINCT f.person_id) 
  FROM #finClass f WHERE f.finClass = 'cash') AS '49 Total Patients - Self Pay'
,0 AS 'Total Patients - Unknown'

,(SELECT COUNT(DISTINCT person_id)
FROM #finClass f
) AS '49 Total Patients - Total'
INTO #count

--drop table #count
select * from #count