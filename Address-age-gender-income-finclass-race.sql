drop table #enc
drop table #curenc
drop table #e2
drop table #demo

DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

SET @Start_Date_1 = '20161001'
SET @End_Date_1 = '20161231'

--SET @Start_Date_1 = '20160401'
--SET @End_Date_1 = '20160630'

--SET @Start_Date_1 = '20160701'
--SET @End_Date_1 = '20160930'

--SET @Start_Date_1 = '20161001'
--SET @End_Date_1 = '20161231'

--Creates BCM at end of visit table and groups by desired categories
select pe.create_timestamp, pe.enc_id, pe.person_id, lm.location_name
INTO #enc
FROM patient_encounter pe
JOIN person	p			  ON pe.person_id = p.person_id
JOIN location_mstr lm	  ON pe.location_id = lm.location_id
WHERE (pe.create_timestamp >= @Start_Date_1 AND pe.create_timestamp <= @End_Date_1)
AND (billable_ind = 'Y' AND clinical_ind = 'Y')
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pe.location_id NOT IN ('966B30EA-F24F-48D6-8346-948669FDCE6E', '518024FD-A407-4409-9986-E6B3993F9D37', 
						   '595BD5A1-B989-4401-9D73-BC63F26B1E7C', '3A067539-F112-4304-931D-613F7C4F26FD',
						   '7E8F1E17-1FC5-4019-B510-B7D3EC453D82', '68C7DDB4-834A-4ABC-B3EB-87BF71D60F41',
						   '096B6FF0-ED48-4A6C-95F6-8D37E1474394', '9D971E61-2B5A-4504-9016-7FD863790EE2')

--Grabs method from latest encounter date
SELECT e.enc_id, e.person_id, e.create_timestamp
INTO #curenc
FROM #enc e
INNER JOIN
	(SELECT person_id, MAX(create_timestamp) AS MAXDATE
	 FROM #enc
	 GROUP BY person_id) grouped
ON e.person_id = grouped.person_id AND e.create_timestamp = grouped.MAXDATE

select DISTINCT c.*, fi.family_annual_income, fi.family_size_nbr
INTO #e2
FROM #curenc c
JOIN practice_person_family_info fi ON c.person_id = fi.person_id
WHERE fi.modify_timestamp = (SELECT MAX(modify_timestamp)
                   from practice_person_family_info fi2
                   where fi.person_id = fi2.person_id)

SELECT DISTINCT
		 'Address' = per.address_line_1
		,'City' = per.city
		,'Zip' =  per.zip
		,'Age' = CAST((CONVERT(INT,CONVERT(CHAR(8),e.create_timestamp,112))-CONVERT(CHAR(8),per.date_of_birth,112))/10000 AS varchar)
		,'Sex' = per.sex
		,'Race' = per.race
		,'Ethnicity' = per.ethnicity
		,'Annual Income' = e2.family_annual_income
		,'Financial Class' = ml.mstr_list_item_desc
		,'DOS' = CONVERT(VARCHAR(10),e.create_timestamp, 112)
		,'Clinic' = e.location_name
INTO #demo
FROM #enc e
JOIN #e2 e2				  ON e.person_id = e2.person_id
JOIN patient_encounter pe ON e.enc_id = pe.enc_id
JOIN person per			  ON e.person_id = per.person_id
JOIN encounter_payer ep   ON pe.enc_id	    = ep.enc_id
JOIN payer_mstr pm		  ON pe.cob1_payer_id = pm.payer_id
JOIN mstr_lists ml		  ON pm.financial_class = ml.mstr_list_item_id

select distinct [financial class] from #demo
ORDER BY DOS