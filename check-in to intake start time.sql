drop table #temp1

CREATE TABLE #temp1
(
 [appt_date] DATE
,[person_id] UNIQUEIDENTIFIER
,[location_id] UNIQUEIDENTIFIER
,[enc_id] UNIQUEIDENTIFIER
,[check-in] DATETIME
,[intake-start] DATETIME
)

SELECT * FROM #temp1

INSERT INTO #temp1
select appt_date, person_id, location_id, enc_id, NULL, NULL
from appointments

where appt_date = '20180213' AND delete_ind = 'n'
AND cancel_ind = 'n' AND resched_ind = 'n' AND person_id is not null
AND appt_kept_ind = 'y'

UPDATE #temp1
SET [intake-start] = pe.create_timestamp
FROM patient_encounter pe 
WHERE #temp1.enc_id = pe.enc_id


(SELECT pe.create_timestamp
FROM patient_encounter pe
JOIN #temp1 t ON t.enc_id = pe.enc_id
)


--***OUTPUT****
select appt_date, person_id, location_id, [check-in], [intake-start]
from #temp1