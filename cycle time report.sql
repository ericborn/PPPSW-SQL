--USE [NGProd]
--GO
--/****** Object:  StoredProcedure [dbo].[pp_cycle_times]    Script Date: 3/1/2018 2:39:46 PM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

---- =============================================
---- Author:		Lopez Kimberlyn
---- Create date: 2/22/2018
---- Description:	Calculating wait time for patients
---- =============================================

--ALTER proc [dbo].[pp_cycle_times]
--(
--	@Start_Date DATETIME,
--	@End_Date DATETIME,
--	@Location VARCHAR(MAX)
--)

--AS
--DROP TABLE #temp

----SELECT 
----RIGHT(CONVERT(varchar(MAX),checkin_datetime, 100),7)
----,create_timestamp 
----,enc_id
----FROM patient_encounter

DECLARE @start_date DATETIME
DECLARE @end_date DATETIME
DECLARE @location UNIQUEIDENTIFIER

SET @start_date = '20180301 00:00:00'
SET @end_date = '20180301 23:59:59'
set @location = '4BD8BD13-6076-4C78-AC9E-FEEC37F226D5'


CREATE TABLE #temp
(
	 [location_name] VARCHAR(50)
	,[date] DATE
	,[enc_nbr] VARCHAR(10)
	,[event] VARCHAR(50)
	,[last_name] VARCHAR(50)
	,[first_name] VARCHAR(50)
	,[checkin_time] varchar(10)
	--[waiting_room_time] varchar(10) --Duration between check-in and being called back
	,[MA_time] varchar(10) --Time called back (checked between intake temp, vitals, ma interview)
	,[wait_time] INT --Duration between intake and soap
	--Soap open timestamp
	,[checkout_time] varchar(10) --checkout timestamp
	,[total_time] varchar(10) --total time from check-in to check-out
);

--Create table for AB appointments
INSERT INTO #temp 
SELECT DISTINCT
 lm.location_name
,CONVERT(DATE,checkin_datetime, 101)
, pe.enc_nbr
, e.event
, a.last_name
, a.first_name
,RIGHT(CONVERT(varchar(MAX),pe.checkin_datetime, 100),7) -- LEFT(CONVERT(VARCHAR(5), pe.checkin_datetime, 8),5)
,RIGHT(CONVERT(varchar(MAX),ab.create_timestamp, 100),7) -- LEFT(CONVERT(VARCHAR(5), ab.create_timestamp, 8),5)
,DATEDIFF(mi, pe.checkin_datetime, ab.create_timestamp)
,RIGHT(CONVERT(varchar(MAX),pe.checkout_datetime, 100),7) -- LEFT(CONVERT(VARCHAR(5),pe.checkout_datetime, 8),5)
,DATEDIFF(mi, pe.checkin_datetime, pe.checkout_datetime)
FROM ngprod.dbo.patient_encounter AS pe 
JOIN ngprod.dbo.location_mstr AS lm ON lm.location_id = pe.location_id
JOIN ngprod.dbo.appointments AS a ON pe.enc_id = a.enc_id
JOIN ngprod.dbo.ab_Intake_ AS ab ON ab.enc_id = pe.enc_id	
JOIN ngprod.dbo.[events] AS e ON a.event_id = e.event_id
WHERE pe.create_timestamp between @start_date AND @end_date
AND lm.location_id = @Location
AND pe.billable_ind = 'Y'
AND pe.clinical_ind = 'Y'
AND a.appt_kept_ind = 'Y'
AND a.cancel_ind = 'N'

--Create table for FP appointments
INSERT INTO #temp
SELECT DISTINCT
 lm.location_name
,CONVERT(DATE,checkin_datetime, 101)
, pe.enc_nbr
, e.event
, a.last_name
, a.first_name
--TALK TO BRADFORD FOR ACCURATE INTAKE WORKFLOW
--Example on how to look at multiple templates and find the first with a timestamp
--, CASE
--	WHEN vitals_ create_timestamp IS NOT NULL THEN DATEDIFF(MINUTE,create_timestamp,GETDATE()) --Vitals template
--	WHEN ma_interview create_timestamp IS NOT NULL THEN DATEDIFF(MINUTE,create_timestamp,GETDATE()) --Ma interview template
--	WHEN fi.create_timestamp IS NOT NULL THEN DATEDIFF(MINUTE,create_timestamp,GETDATE()) --FTS intake template
--END
,RIGHT(CONVERT(varchar(MAX),pe.checkin_datetime, 100),7) -- LEFT(CONVERT(VARCHAR(5), pe.checkin_datetime, 8),5)
,RIGHT(CONVERT(varchar(MAX),fi.create_timestamp, 100),7) -- LEFT(CONVERT(VARCHAR(5), fi.create_timestamp, 8),5)
, DATEDIFF(mi, pe.checkin_datetime, fi.create_timestamp)
,RIGHT(CONVERT(varchar(MAX),pe.checkout_datetime, 100),7) -- LEFT(CONVERT(VARCHAR(5),pe.checkout_datetime, 8),5)
, DATEDIFF(mi, pe.checkin_datetime, pe.checkout_datetime)
FROM ngprod.dbo.patient_encounter AS pe 
JOIN ngprod.dbo.location_mstr AS lm ON lm.location_id = pe.location_id
JOIN ngprod.dbo.appointments AS a ON pe.enc_id = a.enc_id
JOIN ngprod.dbo.[events] AS e ON a.event_id = e.event_id
JOIN ngprod.dbo.fts_intake_ AS fi ON fi.enc_id = pe.enc_id
WHERE pe.create_timestamp between @start_date AND @end_date
AND lm.location_id = @Location
AND pe.billable_ind = 'Y'
AND pe.clinical_ind = 'Y'
AND a.appt_kept_ind = 'Y'
AND a.cancel_ind = 'N'
ORDER BY pe.enc_nbr

--alter table #temp
--alter column [checkin_time]  VARCHAR(5)

--alter table #temp
--alter column [MA_time]  VARCHAR(5)

--alter table #temp
--alter column [wait_time]  VARCHAR(5)

--alter table #temp
--alter column [checkout_time]VARCHAR(5)

UPDATE #temp
SET [checkout_time] = 'N/A'
WHERE [checkout_time] IS NULL

UPDATE #temp
SET [total_time] = 'N/A'
WHERE [total_time] IS NULL

SELECT * FROM #temp
ORDER BY checkin_time ASC




select DateAdd(day,-DateDiff(day,0,checkin_time),getdate()) As NewTime 

from #temp

select GETDATE()
select DATEDIFF(MINUTE,checkin_datetime,GETDATE())
from patient_encounter

SELECT * FROM #temp