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

SELECT distinct pe.person_id, pe.cob1_payer_id
INTO #temp1
FROM patient_procedure pp
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN person	p			  ON pp.person_id = p.person_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1)
AND pe.location_id = @location_1
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')

--grabs most current enc for each patient
--SELECT t.enc_id, t.person_id, t.service_date
--INTO #date
--FROM #temp1 t
--INNER JOIN
--	(SELECT person_id, MAX(service_date) AS MAXDATE
--	 FROM #temp1
--	 GROUP BY person_id) grouped
--ON t.person_id = grouped.person_id AND t.service_date = grouped.MAXDATE

----***Main demographics table***
--select  DISTINCT t.person_id
--		,'age' = CAST((CONVERT(INT,CONVERT(CHAR(8),d.service_date,112))-CONVERT(CHAR(8),per.date_of_birth,112))/10000 AS varchar)
--		,'sex' = per.sex
--		,'white' = ''
--		,'african-american' = ''
--		,'asian' = ''
--		,'pacific islander' = ''
--		,'native-american' = ''
--		,'race-other' = ''
--		,'hispanic' = ''
--INTO #demo
--FROM #temp1 t
--JOIN person per	ON t.person_id = per.person_id
--JOIN #date d	ON t.person_id = d.person_id
----***End demo table***

--***Start insurance table***
--Groups enc by payer and NULL finClass to be updated based upon payer
SELECT person_id, cob1_payer_id, 'finClass' = NULL
INTO #pay
FROM #temp1
GROUP BY person_id, cob1_payer_id

--Updates #pay with the encounters financial class
--Fpact
UPDATE #pay
SET [finClass] = '4110'
WHERE #pay.cob1_payer_id IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #pay p ON p.cob1_payer_id = pm.payer_id
WHERE financial_class = 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF'
)

--Medi-Cal Managed Care-4130
UPDATE #pay
SET [finClass] = '4130'
WHERE #pay.cob1_payer_id IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #pay p ON p.cob1_payer_id = pm.payer_id
WHERE financial_class = '484A05B3-D5C8-415B-A8EE-3D14A7AF11D6'
)

--Medi-cal
UPDATE #pay
SET [finClass] = '4120'
WHERE #pay.cob1_payer_id IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #pay p ON p.cob1_payer_id = pm.payer_id
WHERE financial_class = 'C5BDDA12-DDC9-4CFF-A0A3-9749C7DD353D'
)

--Commercial
UPDATE #pay
SET [finClass] = '4300'
WHERE #pay.cob1_payer_id IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #pay p ON p.cob1_payer_id = pm.payer_id
WHERE financial_class = '8E5D6C7E-A34E-4B3C-8C0A-B2F1D2E20285' OR financial_class = '332DF613-7C43-4287-9050-9949B4142B0C'
)

--Cash does not have a financial class so it will be represented as NULL in the payer_id column
UPDATE #pay
SET [finClass] = '0000'
WHERE #pay.cob1_payer_id IS NULL

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
FROM #pay p
GROUP BY p.person_id

select finClass, count(finClass) AS 'class' --25166
 from #finClass
group by finClass

--select distinct finClass
--from #pay

select finClass, count(finClass) AS 'class' --25166
from #pay
group by finClass

--select * from #pay
--where finClass is null