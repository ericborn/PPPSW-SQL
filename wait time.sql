--USE [NGProd]
--GO
--/****** Object:  StoredProcedure [dbo].[pp_cycle_times]    Script Date: 3/15/2018 12:07:16 PM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

-- =============================================
-- Author:		Lopez Kimberlyn
-- Create date: 2/22/2018
-- Description:	Calculating wait time for patients
-- =============================================

--ALTER proc [dbo].[pp_cycle_times]
--(
--	@Start_Date DATETIME,
--	@End_Date DATETIME,
--	@Location VARCHAR(MAX)
--)

--AS
--DROP TABLE #temp

--SELECT * FROM location_mstr

USE [ppreporting]
GO
/****** Object:  StoredProcedure [dbo].[wait_time]    Script Date: 4/2/2018 3:16:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--============================================= 
-- Author: Kim Lopez
-- Create date: 2 April 2018
-- Last Modified: 
-- Description:	Calculating wait time for patients

-- Change log:
-- 
-- =============================================

ALTER proc [dbo].[wait_time]
(
	@Start_Date DATETIME,
	@End_Date DATETIME,
	@Location VARCHAR(MAX)
)

AS

--DECLARE @start_date DATETIME
--DECLARE @end_date DATETIME
--DECLARE @Location VARCHAR(MAX)

--SET @start_date = '20180301 00:00:00'
--SET @end_date = '20180331 23:59:59'
--SET @Location = '4BD8BD13-6076-4C78-AC9E-FEEC37F226D5'

--ACB96567-0B1F-4AF7-81FC-598B26C3E3DC
--2E863B41-F3B9-4768-AC31-AA300DAA9003
--A0D201B2-7AD9-40DD-8A0B-F270478B1736
--C1CAF54E-57B5-4A9F-84E7-554A8EF4EADB

CREATE TABLE #temp
(
	 [location_name] VARCHAR(50)
	,[date] DATE
	,[begintime] char(4) 
	,[enc_nbr] VARCHAR(10)
	,[event] VARCHAR(50)
	,[last_name] VARCHAR(50)
	,[first_name] VARCHAR(50)
	,[checkin_time] VARCHAR(50)
	,[MA_time] VARCHAR(50)
	,[wait_time] VARCHAR(10)
	,[checkout_time] VARCHAR(50)
	,[total_time] VARCHAR(10)
);

--Create table for AB appointments
INSERT INTO #temp 
SELECT DISTINCT
  lm.location_name
, CONVERT(DATE,checkin_datetime, 101) --date
, a.begintime --appt time
, pe.enc_nbr
, e.event
, a.last_name
, a.first_name
, RIGHT(CONVERT(varchar(MAX),pe.checkin_datetime, 100),7) --check-in time
, RIGHT(CONVERT(varchar(MAX),ab.create_timestamp, 100),7) --ma time
, CASE --wait time
       WHEN ab.create_timestamp IS NULL THEN DATEDIFF(mi, pe.checkin_datetime, getdate())	   
       ELSE DATEDIFF(mi, pe.checkin_datetime, ab.create_timestamp)
  END 
, RIGHT(CONVERT(varchar(MAX),pe.checkout_datetime, 100),7) --checkout time
, DATEDIFF(mi, pe.checkin_datetime, pe.checkout_datetime) --total time
FROM ngprod.dbo.patient_encounter AS pe 
JOIN ngprod.dbo.location_mstr AS lm ON lm.location_id = pe.location_id
JOIN ngprod.dbo.appointments AS a ON pe.enc_id = a.enc_id
LEFT JOIN ngprod.dbo.ab_Intake_ AS ab ON ab.enc_id = pe.enc_id	
JOIN ngprod.dbo.[events] AS e ON a.event_id = e.event_id
WHERE pe.create_timestamp between @start_date AND @end_date
AND lm.location_id = @Location
AND pe.billable_ind = 'Y'
AND pe.clinical_ind = 'Y'
AND a.appt_kept_ind = 'Y'
AND a.cancel_ind = 'N'
AND a.event_id IN --Only include AB related appointments
('607F47E7-9E2F-468B-ACA6-6AC1CF915246'
,'E57A24F1-E318-47C0-9AA4-A140131976DB'
,'14C226D0-C9D1-477E-8558-3B5D2C59E860'
,'CE3629B3-6C17-4D48-8D29-71592D340D0E'
,'886E4F27-ABAC-414C-AA20-2FF8E6A2C05E'
,'A9F8F70A-2625-4490-9253-88A1AEC07C75'
,'FEEA0C61-D204-4663-B10B-A46FD900E8D8'
,'8F39088E-6028-420B-94E6-8A312D9A3A16'
,'ED2A04B1-9C3F-44F2-B0A7-44B376BA3AAF')
ORDER BY begintime

--Create table for FP appointments
INSERT INTO #temp
SELECT DISTINCT
  lm.location_name
, CONVERT(DATE,checkin_datetime, 101) --check-in date
, a.begintime --appt time
, pe.enc_nbr
, e.event
, a.last_name
, a.first_name
, RIGHT(CONVERT(varchar(MAX),pe.checkin_datetime, 100),7) --check in-time
, RIGHT(CONVERT(varchar(MAX),fi.create_timestamp, 100),7) -- LEFT(CONVERT(VARCHAR(5), fi.create_timestamp, 8),5)
--, DATEDIFF(mi, pe.checkin_datetime, fi.create_timestamp)
, CASE
       WHEN fi.create_timestamp IS NULL AND pe.checkout_datetime IS NULL THEN DATEDIFF(mi, pe.checkin_datetime, getdate())
	   WHEN fi.create_timestamp IS NULL AND pe.checkout_datetime IS NOT NULL THEN DATEDIFF(mi, pe.checkin_datetime, pe.checkout_datetime)
	   WHEN fi.create_timestamp IS NOT NULL THEN DATEDIFF(mi, pe.checkin_datetime, fi.create_timestamp)
  END 
, RIGHT(CONVERT(varchar(MAX),pe.checkout_datetime, 100),7) -- LEFT(CONVERT(VARCHAR(5),pe.checkout_datetime, 8),5)
, DATEDIFF(mi, pe.checkin_datetime, pe.checkout_datetime)
FROM ngprod.dbo.patient_encounter AS pe 
JOIN ngprod.dbo.location_mstr AS lm ON lm.location_id = pe.location_id
JOIN ngprod.dbo.appointments AS a ON pe.enc_id = a.enc_id
JOIN ngprod.dbo.[events] AS e ON a.event_id = e.event_id
LEFT JOIN ngprod.dbo.fts_intake_ AS fi ON fi.enc_id = pe.enc_id
WHERE pe.create_timestamp between @start_date AND @end_date
AND lm.location_id = @Location
AND pe.billable_ind = 'Y'
AND pe.clinical_ind = 'Y'
AND a.appt_kept_ind = 'Y'
AND a.cancel_ind = 'N'
AND a.event_id NOT IN --Only include non-AB related appointments
('607F47E7-9E2F-468B-ACA6-6AC1CF915246'
,'E57A24F1-E318-47C0-9AA4-A140131976DB'
,'14C226D0-C9D1-477E-8558-3B5D2C59E860'
,'CE3629B3-6C17-4D48-8D29-71592D340D0E'
,'886E4F27-ABAC-414C-AA20-2FF8E6A2C05E'
,'A9F8F70A-2625-4490-9253-88A1AEC07C75'
,'FEEA0C61-D204-4663-B10B-A46FD900E8D8'
,'8F39088E-6028-420B-94E6-8A312D9A3A16'
,'ED2A04B1-9C3F-44F2-B0A7-44B376BA3AAF')
ORDER BY begintime

UPDATE #temp
SET [checkout_time] = 'N/A'
WHERE [checkout_time] IS NULL

UPDATE #temp
SET [total_time] = 'N/A'
WHERE [total_time] IS NULL

SELECT * FROM #temp