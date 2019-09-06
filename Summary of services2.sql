--drop table #temp1
--drop table #temp2
--drop table #enc
--drop table #enc2
--drop table #date
--drop table #demo
--drop table #pay
--drop table #finClass
--drop table #ins
--drop table #date
--drop table #loc
--drop table #demo_count
--drop table #service_count
--drop table #payer_count
--drop table #a

DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime
DECLARE @Location_1 varchar(40)

--SET @Start_Date_1 = @Start_Date
--SET @End_Date_1   = @End_Date
--SET @Location_1   = @Location

SET @Start_Date_1 = '20160101'
SET @End_Date_1 = '20161231'
SET @Location_1 = '0565487A-C88D-484C-9759-3DF762EA0695'

/*
0565487A-C88D-484C-9759-3DF762EA0695
782C0260-7552-426E-87D6-38F073F40DAD
ACB96567-0B1F-4AF7-81FC-598B26C3E3DC
A0D201B2-7AD9-40DD-8A0B-F270478B1736
9EA2DE96-E929-499E-819B-4128A72CBC7B
6FAF7F6A-0424-41B0-8B13-D2678C76898A
DA5FCD52-AFBE-47F9-A2A2-D96601252CDF
6CB12D65-A88C-405C-89C0-7FE677C9D638
68C7DDB4-834A-4ABC-B3EB-87BF71D60F41
5C8A71F3-7496-4C4F-86E8-AEE02ADECCF4
05483D36-4D7C-49B7-8FF1-7AE9FA0E2825
D89E78A1-F4E4-4DC5-8A7A-BCC316E3A747
239055AA-220B-4F4B-BC82-0A40825A2F2C
4BD8BD13-6076-4C78-AC9E-FEEC37F226D5
5E5D55D7-22BC-40C0-A307-E1CD056CC782
2E863B41-F3B9-4768-AC31-AA300DAA9003
C1CAF54E-57B5-4A9F-84E7-554A8EF4EADB
E53D4FEC-7778-4093-9C45-DC526C9CC8D3
9B706667-0AC8-4BAB-AC72-63B0075D05BF
*/

--select * from location_mstr order by location_name
--Creates list of all encounters, dx and SIM codes during time period
SELECT pp.location_id, pp.enc_id, pp.person_id,
       pp.diagnosis_code_id_1, pp.diagnosis_code_id_2, pp.diagnosis_code_id_3, pp.diagnosis_code_id_4, 
       pp.service_item_id, pp.service_date, p.date_of_birth, p.race, pp.payer_id, pp.amount
INTO #temp1
FROM patient_procedure pp
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN person	p			  ON pp.person_id = p.person_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1)
AND pp.location_id = @location_1
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')

--Creates temp 2 and concatenates same encounters on multiple rows into a single with all service items 
--drop table #
--SELECT location_id, enc_id, person_id, service_date,
--	(SELECT ' ' + t2.service_item_id
--	FROM #temp1 t2
--	WHERE t2.enc_id = t1.enc_id
--	FOR XML PATH('')) [Service_Item],
--	(SELECT ' ' + t2.diagnosis_code_id_1 + ' ' + t2.diagnosis_code_id_2 + ' ' + t2.diagnosis_code_id_3 + ' ' + t2.diagnosis_code_id_4
--	FROM #temp1 t2
--	WHERE t2.enc_id = t1.enc_id
--	FOR XML PATH('')) [dx]
--INTO #temp2
--FROM #temp1 t1
--GROUP BY t1.enc_id, t1.person_id, service_date, location_id

--grabs all enc during time period at specified location
--select pe.create_timestamp, pe.enc_id, pe.person_id
--INTO #enc
--FROM patient_encounter pe
--WHERE (pe.create_timestamp >= @Start_Date_1 AND pe.create_timestamp <= @End_Date_1)
--AND   pe.location_id = @location_1

--grabs most current enc for each patient
SELECT t.enc_id, t.person_id, t.service_date
INTO #date
FROM #temp1 t
INNER JOIN
	(SELECT person_id, MAX(service_date) AS MAXDATE
	 FROM #temp1
	 GROUP BY person_id) grouped
ON t.person_id = grouped.person_id AND t.service_date = grouped.MAXDATE

--***Main demographics table***
select  DISTINCT t.person_id
		,'age' = CAST((CONVERT(INT,CONVERT(CHAR(8),d.service_date,112))-CONVERT(CHAR(8),per.date_of_birth,112))/10000 AS varchar)
		,'sex' = per.sex
		,'white' = ''
		,'african-american' = ''
		,'asian' = ''
		,'pacific islander' = ''
		,'native-american' = ''
		,'race-other' = ''
		,'hispanic' = ''
INTO #demo
FROM #temp1 t
JOIN person per	ON t.person_id = per.person_id
JOIN #date d	ON t.person_id = d.person_id
--***End demo table***

select distinct person_id, payer_id, service_date 
from #temp1
group by person_id, payer_id, service_date
order by person_id

--***Start insurance table***
--Groups enc by payer and NULL finClass to be updated based upon payer
SELECT enc_id, payer_id, 'finClass' = NULL
INTO #pay
FROM #temp1
GROUP BY enc_id, payer_id

--Updates #pay with the encounters financial class
--Fpact
UPDATE #pay
SET [finClass] = '4110'
WHERE #pay.payer_id IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #pay p ON p.payer_id = pm.payer_id
WHERE financial_class = 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF'
)

--Medi-Cal Managed Care-4130
UPDATE #pay
SET [finClass] = '4130'
WHERE #pay.payer_id IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #pay p ON p.payer_id = pm.payer_id
WHERE financial_class = '484A05B3-D5C8-415B-A8EE-3D14A7AF11D6'
)

--Medi-cal
UPDATE #pay
SET [finClass] = '4120'
WHERE #pay.payer_id IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #pay p ON p.payer_id = pm.payer_id
WHERE financial_class = 'C5BDDA12-DDC9-4CFF-A0A3-9749C7DD353D'
)

--Commercial
UPDATE #pay
SET [finClass] = '4300'
WHERE #pay.payer_id IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #pay p ON p.payer_id = pm.payer_id
WHERE financial_class = '8E5D6C7E-A34E-4B3C-8C0A-B2F1D2E20285' OR financial_class = '332DF613-7C43-4287-9050-9949B4142B0C'
)

--Cash does not have a financial class so it will be represented as NULL in the payer_id column
UPDATE #pay
SET [finClass] = '0000'
WHERE #pay.payer_id IS NULL

----Uses max to select the payer with the highest designator
--SELECT DISTINCT p.enc_id, person_id, service_date,
--	CASE
--		WHEN MAX(finClass) = '4110' THEN 'Fpact'
--		WHEN MAX(finClass) = '4120' THEN 'Medi-Cal'
--		WHEN MAX(finClass) = '4130' THEN 'Medi-Cal Managed Care'
--		WHEN MAX(finClass) = '4300' THEN 'Commercial'
--		WHEN MAX(finClass) = '0'	THEN 'Cash'
--		ELSE 'Cash'
--	END AS 'finClass'
----INTO #finClass
--FROM #pay p
--join #date d on d.enc_id = p.enc_id
--where 
--GROUP BY p.enc_id, person_id, service_date
--order by person_id

--Uses max to select the payer with the highest designator
SELECT person_id, service_date,
	CASE
		WHEN MAX(finClass) = '4110' THEN 'Fpact'
		WHEN MAX(finClass) = '4120' THEN 'Medi-Cal'
		WHEN MAX(finClass) = '4130' THEN 'Medi-Cal Managed Care'
		WHEN MAX(finClass) = '4300' THEN 'Commercial'
		WHEN MAX(finClass) = '0'	THEN 'Cash'
		ELSE 'Cash'
	END AS 'finClass'
INTO #finClass
FROM #pay p
JOIN #date d ON d.enc_id = p.enc_id 
GROUP BY person_id, service_date
--order by person_id

--***End insurance table***
--**********END Table Create***********

--***Convert location ID to name***
SELECT location_name
,'a' AS [l]
INTO #loc
FROM location_mstr
WHERE location_id = @Location_1

--***Start Age***
UPDATE #demo
SET age =
	(
		CASE
			WHEN age BETWEEN 0  AND 17 THEN '>18'
			WHEN age BETWEEN 18 AND 24 THEN '18-24'
			WHEN age BETWEEN 25 AND 29 THEN '25-29'
			WHEN age BETWEEN 30 AND 34 THEN '30-34'
			WHEN age BETWEEN 35 AND 49 THEN '35-49'
			ELSE							'<50'
		END
	)
FROM #demo
--***End Age***

--***Start Race***
UPDATE #demo
SET white = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '1- white' AND ethnicity != 'Hispanic or Latino'
)

UPDATE #demo
SET [african-american] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '2- African American' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET asian = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '3- Asian' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [pacific islander] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '4- Pacific Islander' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [native-american] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE race = '5- Native American' AND ethnicity != 'Hispanic or Latino'
)
UPDATE #demo
SET [race-other] = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE (race LIKE '6-%' OR race LIKE '7%') AND ethnicity != 'Hispanic or Latino'
)
--***End Race***

--***Start ethnicity***
UPDATE #demo
SET hispanic = 'Y'
WHERE #demo.person_id IN
(
	SELECT p.person_id
	FROM person p
	JOIN #demo d ON d.person_id = p.person_id
	WHERE ethnicity = 'Hispanic or Latino'
)
--***End ethnicity***
--select * 
--from #demo
--where white = '' AND asian = '' AND [race-other] = '' and hispanic = '' and [native-american] = '' and [pacific islander] = '' and  [african-american] = ''

--select race from person
--where person_id in ('25776FC0-5085-4745-ACF1-CBC7CC796AE4'
--,'5CA98EEE-FA25-41E9-AF47-A8C3C384E414'
--,'C2D76384-C065-4712-9E80-14213262A4D3'
--,'574826BC-28ED-4F7C-B7D9-28F8115AA2AF'
--,'821E17F7-06EA-4675-BE6F-1DB38D560DEA'
--,'F70955B2-58DC-4FEA-BD6D-E462033EA1B2'
--,'3B1EA835-2845-48F0-901B-AD2C68A89A33'
--,'32203581-D11D-45BB-BB5F-00D33FC0DC32'
--,'B9A05579-841E-4C2C-802F-231316AACEE7'
--,'C47B7A80-5540-4976-BC34-AC3F69ECD304')

--***Creates counts for all demographics***
SELECT DISTINCT
 (SELECT COUNT (DISTINCT enc_id) FROM #temp1) AS [Total Patient Visits]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'F') AS Female
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex = 'M') AS Male
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE sex != 'M' AND sex != 'F') AS [Gender-Other]
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE age = '>18') AS 'Under 18'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE age = '18-24') AS '18-24'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE age = '25-29') AS '25-29'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE age = '30-34') AS '30-34'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE age = '35-49') AS '35-49'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE age = '<50') AS '50+'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE white = 'Y') AS 'White'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE hispanic = 'Y') AS 'Hispanic'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE [race-other] = 'Y') AS 'Race-Other'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE [african-american] = 'Y') AS 'African American'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE asian = 'Y' OR [pacific islander] = 'Y') AS 'Asian/Pacific Islander'
,(SELECT COUNT (DISTINCT person_id) FROM #demo WHERE [native-american] = 'Y') AS 'Native American'
,'a' AS [d]
INTO #demo_count
FROM #demo

----***Start fin class*** 
--UPDATE #ins
--SET [medi-cal] = 'Y'
--WHERE #ins.payer_id IN
--(
--	SELECT pm.payer_id
--	FROM payer_mstr pm
--	WHERE (pm.financial_class = '484A05B3-D5C8-415B-A8EE-3D14A7AF11D6' --Medi-Cal Managed Care-4130
--	OR	   pm.financial_class = 'C5BDDA12-DDC9-4CFF-A0A3-9749C7DD353D')--Medi-Cal-4120
--) 

--UPDATE #ins
--SET commercial = 'Y'
--WHERE #ins.payer_id IN
--(
--	SELECT pm.payer_id
--	FROM payer_mstr pm
--	WHERE (pm.financial_class = '8E5D6C7E-A34E-4B3C-8C0A-B2F1D2E20285' --Commercial Ins Exchange-4330
--	OR	   pm.financial_class = '332DF613-7C43-4287-9050-9949B4142B0C')--Commercial Ins Non-Exchange-4310
--) 

--UPDATE #ins
--SET fpact = 'Y'
--WHERE #ins.payer_id IN
--(
--	SELECT pm.payer_id
--	FROM payer_mstr pm
--	WHERE pm.financial_class = 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF' --Family PACT-4110
--) 

--UPDATE #ins
--SET cash = 'Y'
--WHERE #ins.payer_id IS NULL

SELECT DISTINCT
 (SELECT COUNT (*) FROM #finClass WHERE finClass LIKE 'medi%') AS 'Medi-Cal'
,(SELECT COUNT (*) FROM #finClass WHERE finClass = 'Commercial') AS 'Commercial'
,(SELECT COUNT (*) FROM #finClass WHERE finClass = 'Fpact') AS 'Fpact'
,(SELECT COUNT (*) FROM #finClass WHERE finClass = 'cash') AS 'Cash'
,'a' AS [p]
INTO #payer_count
FROM #finClass
--***end fin class*** 

--***Start service item***
--Wildcards used because Service_Item column is considered one long string so it will not find matches using equals or list
--***Start Cancer*** Combines both cancer screening procedures with Clinic breast exams
SELECT DISTINCT
 (SELECT COUNT (DISTINCT enc_id) FROM #temp1 WHERE 
	(
		   service_item_id IN ('L079','L079NC','L124','L034') --pap
	) 
 ) +
 (SELECT COUNT (DISTINCT t1.enc_id) --CBE
	FROM patient_encounter pe 
	JOIN PhysExamExtPop_ peep ON peep.enc_id = pe.enc_id
	JOIN #temp1 t1 ON t1.enc_id = pe.enc_id 
	WHERE peep.ExamFindings LIKE '%Palpation%')
 AS [Cancer Screening]
 --***End Cancer***

--***Start preg test***
,(SELECT COUNT (DISTINCT enc_id) FROM #temp1 WHERE 
	(   
		service_item_id IN ('81025K','81025KNC') --Preg test
	) 
) AS [Pregnancy Test]
--***End preg test***

--***Start Contraception***
,(SELECT COUNT (DISTINCT enc_id) FROM #temp1 WHERE 
	(
		service_item_id IN ('AUBRA','Brevicon','CHATEAL','Cyclessa','CyclessaNC','Desogen', 'DesogenNC'
		,'Gildess','Levora','LevoraNC','LYZA','Micronor','MicronorNC','Modicon', 'ModiconNC'
		,'OCEPT','ORCYCLEN','ORCYCLENNC','OTRICYCLEN','OTRINC','RECLIPSEN','Tarina'--Pill types
		,'J7303' --ring
		,'J7304' --patch
		,'XULANE' --patch
		,'J7300' --IUC
		,'J7301'--IUC
		,'J7302'--IUC
		,'J7307' --Implant
		,'J1050' --Depo
		,'C003' --diaphragm
		,'C005' --diaphragm
		,'C006' --foam
		,'C006NC' --foam
		,'dental' --dental dam
		,'film' --film
		,'film-NC' --film
		,'film10' --film
		,'sponge' --Sponge
		--OR Service_Item LIKE '%[1-4][0-8]con%' --condoms excluded
		)
	)
) AS [Contraception]
--***End Contraception***

--***Start STI Test*** --Convert to counting each test type seperately (use from annual report)
,(SELECT COUNT (DISTINCT enc_id) FROM #temp1 WHERE 
	(
		   service_item_id IN ('87491','87591','L103','L104','L105','L071')--GC/CT
	)
) +
(SELECT COUNT (DISTINCT enc_id) FROM #temp1 WHERE 
	(	
		   service_item_id IN ('L033','L095','L110') --herpes
	)
) +
(SELECT COUNT (DISTINCT enc_id) FROM #temp1 WHERE 
	(
		   service_item_id IN ('L023','L099','86703')--HIV
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
) AS [STI Testing]
--***End STI Test***

--***Start AB***
,(SELECT COUNT (DISTINCT enc_id) FROM #temp1 WHERE 
	(
		   service_item_id LIKE '%59840A%' --TAB
		OR service_item_id LIKE '%59841[C-N]%' --TAB
		OR service_item_id LIKE '%S0199%' --MAB
		)
) AS [AB Services]
,'a' AS [s]
--***End AB***
INTO #service_count
FROM #temp1
--***End service item***

--drop table #demo_count


--***Join all count tables together***

SELECT *
INTO #a
FROM #loc l
JOIN #demo_count dc ON dc.d = l.l
JOIN #service_count sc ON sc.s = l.l
JOIN #payer_count pc ON pc.p = l.l

ALTER TABLE #a
DROP COLUMN [l], [d], [s], [p]

select * from #a

--select * from #pay

--select * from appointments
--where appt_date >= '20160101' and appt_date <= '20161231'