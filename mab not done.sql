--DROP TABLE #t

--select * from appointments

SELECT DISTINCT appt_date, location_name, person_id
INTO #t
FROM appointments a
JOIN location_mstr lm ON lm.location_id = a.location_id
WHERE appt_date >= '20170101' AND appt_date <= '20171231'
AND event_id IN ('866B1B4D-CE4D-473A-8128-6486B8BFBD6B', '607F47E7-9E2F-468B-ACA6-6AC1CF915246')
AND appt_kept_ind = 'Y'

SELECT DISTINCT pp.person_id, service_date
INTO #ab
FROM patient_procedure pp
JOIN #t t ON t.person_id = pp.person_id AND t.appt_date = pp.service_date
WHERE service_item_id = 'S0199'

DELETE t FROM #t t
JOIN #ab a ON t.person_id = a.person_id AND t.appt_date = a.service_date
--WHERE person_id 

SELECT DISTINCT t.appt_date, location_name, person_nbr
FROM #t t
JOIN person p ON p.person_id = t.person_id
JOIN order_ o ON o.person_id = t.person_id AND o.completedDate = t.appt_date
WHERE actCode = '81025K'
AND actStatus = 'completed'
AND obsValue = 'negative'