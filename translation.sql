--drop table #temp1

DECLARE @Start_Date_1 DATETIME
DECLARE @End_Date_1 DATETIME

--SET @Start_Date_1 = @Start_Date
--SET @End_Date_1 = @End_Date

SET @Start_Date_1 = '20170701'
SET @End_Date_1 = '20171031'

CREATE TABLE #temp1
(
	 person_id UNIQUEIDENTIFIER
	,service_date DATE
	,historianRelation VARCHAR(100)
	,location_name VARCHAR(100)
	,answer VARCHAR(100)
	,RFV VARCHAR(100)
)

INSERT INTO #temp1
SELECT DISTINCT pp.person_id, service_date, historianRelation, lm.location_name, c.answer, 'RFV' = NULL
FROM patient_procedure pp
JOIN patient_encounter pe ON pe.enc_id = pp.enc_id
JOIN person p ON p.person_id = pp.person_id
JOIN master_im_ m ON pe.enc_id = m.enc_id
JOIN configurable_consent_ext_ c ON c.enc_id = pp.enc_id
JOIN location_mstr lm ON pe.location_id = lm.location_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1) 
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND question = 'Language Interpreted'
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --Clinical services and Lab locations are excluded
						 --'966B30EA-F24F-48D6-8346-948669FDCE6E' Online services included in totals

UPDATE #temp1
SET RFV = event
FROM appointments a
JOIN #temp1 t ON t.person_id = a.person_id
JOIN events e ON e.event_id = a.event_id
WHERE a.appt_date = t.service_date AND a.person_id = t.person_id

ALTER TABLE #temp1
DROP COLUMN person_id

select * from #temp1