--DROP TABLE #enc
--DROP TABLE #c

select service_item_desc, service_item_id
from patient_procedure where
service_item_id in ('C003-pt', 'c002', 'c033','rconb', 'rcono')

--***Declare and set variables***
DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

SET @Start_Date_1 = '20160701'
SET @End_Date_1 = '20170630'

select distinct sig_msg 
from sig_events s
WHERE (s.create_timestamp >= @Start_Date_1 AND s.create_timestamp <= @End_Date_1)
AND sig_msg LIKE 'encounter %' AND sig_msg NOT LIKE 'encounter accessed%'
AND sig_msg NOT LIKE 'encounter charge%' AND sig_msg NOT LIKE 'encounter insurance%'

--**********Start data Table Creation***********
CREATE TABLE #enc
(
 enc_nbr INT
,DOS DATE
,Enc_status VARCHAR(10)
,Clinical VARCHAR(1)
,Billable VARCHAR(1)
,Charges VARCHAR(10)
)


--Insert supressed, merged and deleted encounters
INSERT INTO #enc
SELECT DISTINCT
 RIGHT(sig_msg, 7) AS enc_nbr
,s.create_timestamp
,CASE
	WHEN s.sig_msg LIKE 'encounter suppress%' THEN 'Suppressed'
	WHEN s.sig_msg LIKE 'encounter merg%' THEN 'Merge'
	WHEN s.sig_msg LIKE 'encounter delete%' THEN 'Delete'
 END
,NULL
,NULL
,NULL
FROM sig_events s
WHERE (s.create_timestamp >= @Start_Date_1 AND s.create_timestamp <= @End_Date_1)
AND (s.sig_msg LIKE 'encounter suppress%'
OR   s.sig_msg LIKE 'encounter merg%'
OR   s.sig_msg LIKE 'encounter delete%')

--Insert active encounters
INSERT INTO	#enc
SELECT DISTINCT enc_nbr, pe.enc_timestamp, 'Active', clinical_ind, billable_ind, NULL
FROM patient_encounter pe
LEFT JOIN patient_procedure pp ON pe.enc_id = pp.enc_id
WHERE enc_timestamp >= @Start_Date_1 AND enc_timestamp <= @End_Date_1

--Calculate total charges for active encounters
SELECT e.enc_nbr, SUM(amt) AS 'sum'
INTO #c
FROM charges c
JOIN patient_encounter pe ON pe.enc_id = c.source_id
JOIN #enc e ON e.enc_nbr = pe.enc_nbr
WHERE e.enc_nbr = pe.enc_nbr
GROUP BY e.enc_nbr

--Add total charges to main table
UPDATE #enc
SET Charges = #c.sum
FROM #c
WHERE #c.enc_nbr = #enc.enc_nbr

--Display results 297293
select * from #enc
ORDER BY dos, enc_nbr

--select * from #enc
--where billable = 'Y' and charges is null
--ORDER BY dos, enc_nbr

--select * from patient_encounter
--where enc_nbr = '3937342'

--select * 
--from patient_encounter--charges
--where enc_nbr = '4388380'

--select * 
--from charges
--where source_id = '67C442E8-82AF-4BEB-A87E-0F81E5C2630F'

--select * from patient_procedure
--where enc_id = '67C442E8-82AF-4BEB-A87E-0F81E5C2630F'

--select * from sig_events --10179
--WHERE sig_msg LIKE 'encounter delete%'
--AND create_timestamp >= '20160701' AND create_timestamp <= '20170630'


--SELECT * FROM sig_events --3357
--WHERE sig_msg LIKE 'encounter merg%'
--AND create_timestamp >= '20160701' AND create_timestamp <= '20170630'

--select * from sig_events --7404
--WHERE sig_msg LIKE 'encounter suppress%'
--AND create_timestamp >= '20160701' AND create_timestamp <= '20170630'