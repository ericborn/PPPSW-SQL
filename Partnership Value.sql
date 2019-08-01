--drop table #temp1

DECLARE @Start_Date_1 DATETIME
DECLARE @End_Date_1 DATETIME

--SET @Start_Date_1 = @Start_Date
--SET @End_Date_1 = @End_Date

SET @Start_Date_1 = '20160101'
SET @End_Date_1 = '20161231'

--**********Start data Table Creation***********
--Creates list of all encounters, dx and SIM codes during time period
SELECT pp.enc_id, pp.person_id, p.sex, pp.service_item_id, pp.service_date, pe.enc_nbr
,p.person_nbr, p.date_of_birth, location_name, cob1_payer_id, [age] = NULL
INTO #temp1
FROM ngprod.dbo.patient_procedure pp
JOIN ngprod.dbo.patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN ngprod.dbo.person	p			 ON pp.person_id = p.person_id
JOIN location_mstr lm ON pe.location_id = lm.location_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1) 
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND p.sex = 'f'
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
--AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --Clinical services and Lab locations are excluded
						 --'966B30EA-F24F-48D6-8346-948669FDCE6E' Online services included in totals
AND location_name IN (
'Chula Vista Planned Parenthood'
,'City Heights Planned Parenthood'
,'College Ave Planned Parenthood'
,'Escondido Planned Parenthood'
,'Euclid Ave Planned Parenthood'
,'FA Family Planning Planned Parent'
,'Moreno Valley Planned Parenthood'
,'Riverside Planned Parenthood'
,'RS Surgical Services Planned Parenthood'
)

--select * from #temp1
--***Calculate age at from DOS***
UPDATE #temp1
SET age = CAST((CONVERT(INT,CONVERT(CHAR(8),'20160615',112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar)
FROM #temp1 f
--JOIN person p ON p.person_id = f.person_id

SELECT distinct person_id, location_name, age-- COUNT(DISTINCT person_id) AS 'patient', location_name -- t.person_id, location_name, service_date, payer_name
FROM #temp1 t
--JOIN payer_mstr pm ON pm.payer_id = t.cob1_payer_id
--JOIN order_ o ON o.encounterID = t.enc_id
--WHERE --financial_class != 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF' 
--WHERE --(age BETWEEN 15 AND 44) 
	--(service_item_id LIKE '%L079%' --PAP
 --OR service_item_id LIKE '%L034%'
 --OR service_item_id LIKE '%L124%') 
--service_item_id = '81025K' AND actText LIKE '%preg%' AND obsValue = 'positive' 
GROUP BY location_name, person_id, age--, service_date, payer_name, t.person_id,
ORDER BY location_name


select * from #temp2
--***Start ENC Payer***
SELECT DISTINCT person_id, enc_id, cob1_payer_id, service_date, sex, [finClass] = NULL
INTO #temp2
FROM #temp1 t
JOIN location_mstr lm ON t.location_id = lm.location_id
WHERE 
location_name IN (
'Chula Vista Planned Parenthood'
,'City Heights Planned Parenthood'
,'College Ave Planned Parenthood'
,'Escondido Planned Parenthood'
,'Euclid Ave Planned Parenthood'
,'FA Family Planning Planned Parent'
,'Moreno Valley Planned Parenthood'
,'Riverside Planned Parenthood'
)
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
		WHEN MAX(cob1_payer_id) is not null THEN cob1_payer_id
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

select * from #pay2