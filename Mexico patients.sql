--drop table #enc
--drop table #curenc
--drop table #e2
--drop table #demo

DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

SET @Start_Date_1 = '20150101'
SET @End_Date_1 = '20170801'

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
JOIN patient_procedure pp ON pp.enc_id = pe.enc_id
WHERE (pe.create_timestamp >= @Start_Date_1 AND pe.create_timestamp <= @End_Date_1)
AND (billable_ind = 'Y' AND clinical_ind = 'Y')
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND (service_item_id LIKE '%S0199%' OR service_item_id LIKE '%59840A%' OR service_item_id LIKE '%59841[C-N]%')
AND country IN ('Tijuanan', 'mx', '2-mexico', 'mexico')
--AND pe.location_id NOT IN ('966B30EA-F24F-48D6-8346-948669FDCE6E', '518024FD-A407-4409-9986-E6B3993F9D37', 
						   --'595BD5A1-B989-4401-9D73-BC63F26B1E7C', '3A067539-F112-4304-931D-613F7C4F26FD',
						   --'7E8F1E17-1FC5-4019-B510-B7D3EC453D82', '68C7DDB4-834A-4ABC-B3EB-87BF71D60F41',
						   --'096B6FF0-ED48-4A6C-95F6-8D37E1474394', '9D971E61-2B5A-4504-9016-7FD863790EE2')


--Grabs method from latest encounter date
SELECT e.enc_id, e.person_id, e.create_timestamp
INTO #curenc
FROM #enc e
INNER JOIN
	(SELECT person_id, MAX(create_timestamp) AS MAXDATE
	 FROM #enc
	 GROUP BY person_id) grouped
ON e.person_id = grouped.person_id AND e.create_timestamp = grouped.MAXDATE

select DISTINCT c.*, fi.family_annual_income AS [income], fi.family_size_nbr AS [size], 'fpl' = NULL
INTO #e2
FROM #curenc c
JOIN practice_person_family_info fi ON c.person_id = fi.person_id
WHERE fi.modify_timestamp = (SELECT MAX(modify_timestamp)
                   from practice_person_family_info fi2
                   where fi.person_id = fi2.person_id)

UPDATE #e2
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
FROM #e2

SELECT
		 'Person_Nbr' = per.person_nbr
		,'Country' = per.country
		,'City' = per.city
		,'Zip' =  per.zip
		,'Age' = CAST((CONVERT(INT,CONVERT(CHAR(8),e.create_timestamp,112))-CONVERT(CHAR(8),per.date_of_birth,112))/10000 AS varchar)
		,'Sex' = per.sex
		,'Race' = per.race
		,'Ethnicity' = per.ethnicity
		,'Annual Income' = e2.income
		--,'Financial Class' = ml.mstr_list_item_desc
		,'FPL' = fpl
		,'DOS' = CONVERT(VARCHAR(10),e.create_timestamp, 112)
		,'Clinic' = e.location_name
INTO #demo
FROM #enc e
JOIN #e2 e2				  ON e.person_id = e2.person_id
JOIN patient_encounter pe ON e.enc_id = pe.enc_id
JOIN person per			  ON e.person_id = per.person_id
--JOIN encounter_payer ep   ON pe.enc_id	    = ep.enc_id
--JOIN payer_mstr pm		  ON pe.cob1_payer_id = pm.payer_id
--JOIN mstr_lists ml		  ON pm.financial_class = ml.mstr_list_item_id

--drop table #demo
select * 
from #demo
where country IN ('Tijuanan', 'mx', '2-mexico', 'mexico')


--select distinct [financial class] from #demo
--ORDER BY DOS

select * from person
where country IN ('Tijuanan', 'mx', '2-mexico', 'mexico')




select distinct enc_id 
from patient_procedure pp
JOIN person p ON pp.person_id = p.person_id
WHERE service_date >= '20150101'
AND country IN ('Tijuanan', 'mx', '2-mexico', 'mexico')
AND (service_item_id LIKE '%S0199%' OR service_item_id LIKE '%59840A%' OR service_item_id LIKE '%59841[C-N]%')


SELECT * from #enc
