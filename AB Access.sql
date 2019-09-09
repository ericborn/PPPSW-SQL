--============================================= 
-- Author: Eric Born
-- Create Date: 08/01/2017
-- Numerator: Number of AB appointments scheduled within the indicated timeframe
--			  % of MAB appointments scheduled within 5 days
--			  % of TAB 1-day appointments scheduled within 5 days
--			  % of TAB 2-day appointments scheduled within 7 days
-- Denominator: Total AB appointments scheduled
-- Modified by:
-- Modifications:
-- =============================================

--***Drop temp tables***
--DROP TABLE #appt
--DROP TABLE #total
--DROP TABLE #percent

--***Declare and set our variables***
DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 datetime

SET @Start_Date_1 = '20171001'
SET @End_Date_1 = '20171231'

--Gather appointment date, appointment create date and the difference between the two based on AB event types
SELECT a.create_timestamp, appt_date, DATEDIFF(DAY,a.create_timestamp, appt_date) AS 'Diff', [event]
INTO #appt
FROM ngprod.dbo.appointments a
JOIN ngprod.dbo.events e on e.event_id = a.event_id
WHERE a.create_timestamp >= @Start_Date_1 AND a.create_timestamp <= @End_Date_1
AND [event] IN 
(
 'Specialty-MAB'
,'Specialty-APC'
,'Specialty-EPEM'
,'Specialty-TAB'
,'Specialty-CYTO'
,'Specialty-LAM1'
,'Specialty-LAM2'
)

--Calculates the total number of AB appointments and total scheduled within the desired amount of time (mab/1st tri 5 days, 2nd tri 7 days) 
SELECT DISTINCT
 (SELECT COUNT(*) FROM #appt WHERE [event] = 'Specialty-MAB' AND [diff] <= 5) AS [MAB_5]
,(SELECT COUNT(*) FROM #appt WHERE [event] = 'Specialty-MAB') AS [MAB_T]
,(SELECT COUNT(*) FROM #appt WHERE [event] 
IN ('Specialty-APC','Specialty-EPEM','Specialty-TAB','Specialty-CYTO') AND [diff] <= 5) AS [TAB1_5]
,(SELECT COUNT(*) FROM #appt WHERE [event] 
IN ('Specialty-APC','Specialty-EPEM','Specialty-TAB','Specialty-CYTO')) AS [TAB1_T]
,(SELECT COUNT(*) FROM #appt WHERE [event] IN('Specialty-LAM1','Specialty-LAM2') AND [diff] <= 7) AS [TAB2_7]
,(SELECT COUNT(*) FROM #appt WHERE [event] IN('Specialty-LAM1','Specialty-LAM2')) AS [TAB2_T]
INTO #total

--Outputs calculated percentages of appointments scheduled within thresholds
SELECT DISTINCT
LEFT((SELECT COUNT(*) FROM #appt WHERE [event] = 'Specialty-MAB' AND [diff] <= 5) * 100.0 /
     (SELECT COUNT(*) FROM #appt WHERE [event] = 'Specialty-MAB') * 100.0, 2) AS [MAB_T]

,LEFT((SELECT COUNT(*) FROM #appt WHERE [event] 
IN ('Specialty-APC','Specialty-EPEM','Specialty-TAB','Specialty-CYTO') AND [diff] <= 5) * 100.0 /
      (SELECT COUNT(*) FROM #appt WHERE [event] 
IN ('Specialty-APC','Specialty-EPEM','Specialty-TAB','Specialty-CYTO'))  * 100.0, 2) AS [TAB1_T]

,LEFT((SELECT COUNT(*) FROM #appt WHERE [event] IN('Specialty-LAM1','Specialty-LAM2') AND [diff] <= 7) * 100.0 /
	  (SELECT COUNT(*) FROM #appt WHERE [event] IN('Specialty-LAM1','Specialty-LAM2'))  * 100.0, 2) AS [TAB2_T]
INTO #percent

select * from #total
select * from #percent