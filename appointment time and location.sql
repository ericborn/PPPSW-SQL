USE [Appointment_reminder]
GO
/****** Object:  StoredProcedure [dbo].[PS_AppointmentInfo]    Script Date: 6/6/2016 8:22:08 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--============================================= 
-- Author:    Eric Born 
-- Create date: 01 December 2015> 
-- Description:  Sends patient appointment info when we receive a when or where via text message.>
-- =============================================

--@phone is patient phone number feeds into SQL from Node as an input
--@appt is the appointment info that travels out of SQL into node as an output
ALTER PROCEDURE [dbo].[PS_AppointmentInfo] (@phone nvarchar(12)) 



AS 
  BEGIN 
	--drop table #mr_appt_tank
	--drop table #temp_info
	--DECLARE @phone nvarchar(12) = '+11245879815' 
	--DECLARE @appt nvarchar(MAX)
    --DROP TABLE #temp_info 
    --DROP TABLE #mr_appt_tank 
	--select * from #temp_info
	--select * from #mr_appt_tank
	SET NOCOUNT ON;

	--Create variables for date check and no valid appointment message
	DECLARE @Date date = GetDate()
	DECLARE @lang nvarchar(MAX)
	DECLARE @message nvarchar(MAX)
	DECLARE @appt nvarchar(MAX)
	--Create temp table where all patient info will be stored
    CREATE TABLE #temp_info
                 ( 
					phone_number	VARCHAR(10) NULL, 
					person_id		UNIQUEIDENTIFIER NULL,
					appt_id			UNIQUEIDENTIFIER NULL, 
					begin_time		INT NULL, 
					loc_name		NVARCHAR(50) NULL, 
					addy			NVARCHAR(50) NULL,
					city			NVARCHAR(50) NULL,
					[state]			NVARCHAR(2) NULL,
					zip				INT NULL,
					appt_date		DATE NULL,
					appt_time		TIME NULL,
					lang			NVARCHAR(20) NULL 
                 ) 
--Insert patient phone number that was inputted into SQL from Node
INSERT INTO #temp_info
    SELECT RIGHT (@phone, 10)    AS phone_number,
		   NULL                  AS person_id, 
           NULL                  AS appt_id, 
           NULL                  AS begin_time, 
           NULL                  AS location_name, 
           NULL                  AS addy,
		   NULL					 AS city,
		   NULL					 AS [state],
		   NULL					 AS zip,
           NULL                  AS appt_date,
		   NULL					 AS appt_time,
		   NULL					 AS lang
   
    --Update person id
    UPDATE #temp_info 
    SET    person_id = ps.person_id 
    FROM   #temp_info temp 
    JOIN   ngsqldata.ngprod.dbo.person ps 
    ON     ps.day_phone = temp.phone_number; 

	--Find most recent appointment for patient
    WITH lastappt AS 
    ( 
             SELECT   a.appt_id, 
                      a.person_id,
					  a.appt_date,
                      Row_number() OVER ( partition BY a.person_id ORDER BY a.appt_date DESC ) AS mostrecent
             FROM     ngsqldata.ngprod.dbo.appointments a
             JOIN     #temp_info temp 
             ON       temp.person_id = a.person_id -- join to only consider people already in our tank
			 WHERE	  a.delete_ind = 'N' and a.cancel_ind = 'N' and a.resched_ind = 'N'
    ) 
    SELECT * 
    INTO   #mr_appt_tank 
    FROM   lastappt 
    WHERE  mostrecent = 1; 

    --Update apptment id
    UPDATE #temp_info 
    SET    appt_id = mr.appt_id 
    FROM   #temp_info temp 
    JOIN   #mr_appt_tank mr 
    ON     mr.person_id = temp.person_id 

    --Update the appt date / time 
    UPDATE #temp_info 
    SET    appt_date = appt.appt_date, 
           begin_time = appt.begintime 
    FROM   #temp_info temp
    JOIN   ngsqldata.ngprod.dbo.appointments appt 
    ON     appt.appt_id = temp.appt_id 

    --Update location / address 
    UPDATE #temp_info 
    SET    loc_name = lm.location_name, 
           addy = lm.address_line_1,
		   city = lm.city,
		   [state] = lm.[state],
		   zip = lm.zip
    FROM   #temp_info temp 
    JOIN   ngsqldata.ngprod.dbo.appointments appt 
    ON     appt.appt_id = temp.appt_id 
    JOIN   ngsqldata.ngprod.dbo.location_mstr lm 
    ON     lm.location_id = appt.location_id
	
	--Update text language preference
	UPDATE #temp_info
	SET	   @lang = ml.mstr_list_item_desc
	FROM   #temp_info temp
	JOIN   ngsqldata.ngprod.dbo.person_ud ud 
	ON ud.person_id = temp.person_id
	JOIN   ngsqldata.ngprod.dbo.mstr_lists ml 
	ON ml.mstr_list_item_id = ud.ud_demo5_id

	--Create 'no valid appointment' message based upon patients desired text reminder language
	IF (@lang = '2 - English')
	BEGIN
	SET @message = 'You have no appointments scheduled at this time. To schedule an appointment please call us at 1-888-743-7526 or visit our website at http://www.planned.org'
	END

	ELSE IF (@lang = '3 - Spanish')
	BEGIN
	SET @message = 'Usted no tiene citas en este momento. Si quisiera hacer una cita por favor llámenos al 1-888-743-7526 o visite nuestra página en http://www.planned.org.'
	END

	ELSE 
	BEGIN
	SET @message = 'You are currently not enrolled for text message reminders. To enroll please call us at 1-888-743-7526'
	END

	--Creating date var to ensure appt is in the future
	DECLARE @appt_date date  
	SELECT	@appt_date = appt_date
	FROM	#temp_info
	
	--Create English appointment info message that feeds back into Node.
	--First convert is needed to change date format to US standard, Month/date/year.
	--Second convert is needed to take database time, which is presented as an INT in 24 hour time, back to 12 hour time.
	IF (@Date < @appt_date and @lang = '2 - English')
	BEGIN
	SET @appt =
	(SELECT CONCAT  ('Your appointment is on ', CONVERT(varchar(12),appt_date,107), ' at ', 
	RIGHT(CONVERT(varchar(20), DATEADD(hour,begin_time/100, DATEADD(minute,begin_time%100,0)),100),7),
	' at our ', loc_name, ' clinic ', 'located at ', addy, ' ', city, ' ', [state], ' ', LEFT(zip, 5)) 
	from #temp_info)
	END

	--Create Spanish appointment info message that feeds back into Node.
	ELSE IF (@Date < @appt_date and @lang = '3 - Spanish')
	BEGIN
	SET @appt =
	(SELECT CONCAT  ('Su cita es el ', CONVERT(varchar(12),appt_date,107), ' a las ', 
	RIGHT(CONVERT(varchar(20), DATEADD(hour,begin_time/100, DATEADD(minute,begin_time%100,0)),100),7),
	' en nuestra ', loc_name, ' clínica en ', 'situada en ', addy, ' ', city, ' ', [state], ' ', LEFT(zip, 5)) 
	from #temp_info)
	END

	--Catch if no future appointment is found.
	ELSE

	BEGIN
	SET @appt =
	(SELECT @message)
	END	 

	BEGIN
	--select * from #temp_info
	SELECT @appt
	END
  END