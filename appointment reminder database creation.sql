USE [master]
GO
/****** Object:  Database [Appointment_reminder]    Script Date: 5/8/2017 1:29:48 PM ******/
CREATE DATABASE [Appointment_reminder] ON  PRIMARY 
( NAME = N'Appointment_Reminder', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\Appointment_Reminder.mdf' , SIZE = 4599808KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'Appointment_Reminder_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\Appointment_Reminder.ldf' , SIZE = 4619584KB , MAXSIZE = 2048GB , FILEGROWTH = 10240KB )
GO
ALTER DATABASE [Appointment_reminder] SET COMPATIBILITY_LEVEL = 100
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Appointment_reminder].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [Appointment_reminder] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Appointment_reminder] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [Appointment_reminder] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [Appointment_reminder] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [Appointment_reminder] SET ARITHABORT OFF 
GO
ALTER DATABASE [Appointment_reminder] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [Appointment_reminder] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [Appointment_reminder] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Appointment_reminder] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Appointment_reminder] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Appointment_reminder] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Appointment_reminder] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [Appointment_reminder] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Appointment_reminder] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [Appointment_reminder] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Appointment_reminder] SET  DISABLE_BROKER 
GO
ALTER DATABASE [Appointment_reminder] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [Appointment_reminder] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Appointment_reminder] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [Appointment_reminder] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [Appointment_reminder] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Appointment_reminder] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Appointment_reminder] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [Appointment_reminder] SET RECOVERY FULL 
GO
ALTER DATABASE [Appointment_reminder] SET  MULTI_USER 
GO
ALTER DATABASE [Appointment_reminder] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Appointment_reminder] SET DB_CHAINING OFF 
GO
EXEC sys.sp_db_vardecimal_storage_format N'Appointment_reminder', N'ON'
GO
USE [Appointment_reminder]
GO
/****** Object:  User [PPSDRC\vbansal]    Script Date: 5/8/2017 1:29:48 PM ******/
CREATE USER [PPSDRC\vbansal] FOR LOGIN [PPSDRC\vbansal] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [PPSDRC\ssaran]    Script Date: 5/8/2017 1:29:48 PM ******/
CREATE USER [PPSDRC\ssaran] FOR LOGIN [PPSDRC\ssaran] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [PPSDRC\njain1]    Script Date: 5/8/2017 1:29:48 PM ******/
CREATE USER [PPSDRC\njain1] FOR LOGIN [PPSDRC\njain1] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [PPSDRC\mbhardia]    Script Date: 5/8/2017 1:29:48 PM ******/
CREATE USER [PPSDRC\mbhardia] FOR LOGIN [PPSDRC\mbhardia] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [PPSDRC\lrathore]    Script Date: 5/8/2017 1:29:48 PM ******/
CREATE USER [PPSDRC\lrathore] FOR LOGIN [PPSDRC\lrathore] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [PPSDRC\aveeramalla]    Script Date: 5/8/2017 1:29:48 PM ******/
CREATE USER [PPSDRC\aveeramalla] FOR LOGIN [PPSDRC\aveeramalla] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [PPSDRC\asrinivasan]    Script Date: 5/8/2017 1:29:48 PM ******/
CREATE USER [PPSDRC\asrinivasan] FOR LOGIN [PPSDRC\asrinivasan] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [PPSDRC\asankhala]    Script Date: 5/8/2017 1:29:48 PM ******/
CREATE USER [PPSDRC\asankhala] FOR LOGIN [PPSDRC\asankhala] WITH DEFAULT_SCHEMA=[dbo]
GO
sys.sp_addrolemember @rolename = N'db_owner', @membername = N'PPSDRC\vbansal'
GO
/****** Object:  StoredProcedure [dbo].[AppointmentTextCancellation]    Script Date: 5/8/2017 1:29:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Anthony Prendimano>
-- Create date: <10/28/2014>
-- Modified By: Vinay Bansal
-- Modified On : 11/12/2014
-- Modified Reson : Fetch all the cancel appointments
-- Description:	<Cancels appointment in EPM for any patient that sends a C or Cancel via text message.>
-- =============================================
CREATE PROCEDURE [dbo].[AppointmentTextCancellation] 
	-- Add the parameters for the stored procedure here
	--<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
AS
BEGIN

	--BEGIN TRANSACTION t1
	--BEGIN TRY
		SET NOCOUNT ON;
	
		Create table #Temp(Appt_ID Uniqueidentifier,Phone_Number nvarchar(100), Date_Created dateTime)
		Insert into #Temp (Phone_Number , Date_Created )
		Select [From], MH.Date_Created FROM [Message_History] MH where( Body ='C' or Body ='c' or Body like '%Cancel%' or Body like '%cancel%') and Direction = 'inbound' --and Date_Created BETWEEN @fromdate AND @todate
									
		Update #Temp SET Appt_ID = (Select Top 1 MS.Appointment_ID  From Message_Sent MS
										Where MS.[To] = #Temp.Phone_Number AND MS.Date_Created between DATEADD(D,-1, Cast(#Temp.Date_Created AS Date)) AND #Temp.Date_Created) --AND ms.Duration = 1440)
									
		--Select Distinct Appt_ID from #Temp		
		
		Update NGProd.dbo.Appointments  SET cancel_ind  = 'Y', modified_by ='1558', modify_timestamp = GETDATE()
		WHERE  appt_id in (Select Distinct Appt_ID from #Temp) 	and cancel_ind = 'N' AND appt_date >= CAST(Getdate() As date)		


--		Update NGProd.dbo.Appointments  SET cancel_ind  = '', modify_timestamp = GETDATE()
--		WHERE  appt_id ='F43D2EDA-07E7-4340-B47D-0C4B771D6A89' --in (Select Distinct Appt_ID from #Temp) 	and cancel_ind = 'N'		
		
--F43D2EDA-07E7-4340-B47D-0C4B771D6A89
--		Select * From NGProd.dbo.Appointments WHERE  appt_id in (Select Distinct Appt_ID from #Temp) and cancel_ind = 'N'  AND appt_date >= CAST(Getdate() As date)
	--	ROLLBACK TRANSACTION t1
	--	--COMMIT TRANSACTION
	--END TRY
	--BEGIN CATCH
	--	ROLLBACK TRANSACTION
	--END CATCH
END

GO
/****** Object:  StoredProcedure [dbo].[Disable_Notification]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Vinay Bansal
-- Create date: 25 August, 2014
-- Description:	Disable Notification
-- =============================================
CREATE PROCEDURE [dbo].[Disable_Notification] 
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Declare @UID uniqueidentifier

	SELECT @UID = mstr_list_item_id From NGProd.dbo.mstr_lists where mstr_list_item_desc = '1 - No'
	--PRINT @UID

--if exists (select 1 from NGProd.dbo.person_ud
--	WHERE  person_id in (SELECT Distinct P.person_id FROM [dbo].[Message_History] MH
--							INNER JOIN NGProd.dbo.person P ON P.day_phone = Right(MH.[From],10)
--							Where MH.Status = 'received' AND MH.Body = 'S' AND MH.Isactive = 0) )
--BEGIN							
		Update NGProd.dbo.person_ud  SET ud_demo5_id = @UID
		WHERE  person_id in (SELECT Distinct P.person_id FROM [dbo].[Message_History] MH
		INNER JOIN NGProd.dbo.person P ON P.day_phone = Right(MH.[From],10)
		Where MH.Status = 'received' AND MH.Body = 'S' AND MH.Isactive = 0) 
--END	


						
							
	UPDATE Message_History SET IsActive = 1 
	WHERE [Status] = 'received' AND [Body] = 'S' AND Isactive = 0	
	
END

GO
/****** Object:  StoredProcedure [dbo].[ELMAH_GetErrorsXml]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ELMAH_GetErrorsXml]
(
    @Application NVARCHAR(60),
    @PageIndex INT = 0,
    @PageSize INT = 15,
    @TotalCount INT OUTPUT
)
AS 

    SET NOCOUNT ON

    DECLARE @FirstTimeUTC DATETIME
    DECLARE @FirstSequence INT
    DECLARE @StartRow INT
    DECLARE @StartRowIndex INT

    SELECT 
        @TotalCount = COUNT(1) 
    FROM 
        [ELMAH_Error]
    WHERE 
        [Application] = @Application

    -- Get the ID of the first error for the requested page

    SET @StartRowIndex = @PageIndex * @PageSize + 1

    IF @StartRowIndex <= @TotalCount
    BEGIN

        SET ROWCOUNT @StartRowIndex

        SELECT  
            @FirstTimeUTC = [TimeUtc],
            @FirstSequence = [Sequence]
        FROM 
            [ELMAH_Error]
        WHERE   
            [Application] = @Application
        ORDER BY 
            [TimeUtc] DESC, 
            [Sequence] DESC

    END
    ELSE
    BEGIN

        SET @PageSize = 0

    END

    -- Now set the row count to the requested page size and get
    -- all records below it for the pertaining application.

    SET ROWCOUNT @PageSize

    SELECT 
        errorId     = [ErrorId], 
        application = [Application],
        host        = [Host], 
        type        = [Type],
        source      = [Source],
        message     = [Message],
        [user]      = [User],
        statusCode  = [StatusCode], 
        time        = CONVERT(VARCHAR(50), [TimeUtc], 126) + 'Z'
    FROM 
        [ELMAH_Error] error
    WHERE
        [Application] = @Application
    AND
        [TimeUtc] <= @FirstTimeUTC
    AND 
        [Sequence] <= @FirstSequence
    ORDER BY
        [TimeUtc] DESC, 
        [Sequence] DESC
    FOR
        XML AUTO


GO
/****** Object:  StoredProcedure [dbo].[ELMAH_GetErrorXml]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ELMAH_GetErrorXml]
(
    @Application NVARCHAR(60),
    @ErrorId UNIQUEIDENTIFIER
)
AS

    SET NOCOUNT ON

    SELECT 
        [AllXml]
    FROM 
        [ELMAH_Error]
    WHERE
        [ErrorId] = @ErrorId
    AND
        [Application] = @Application


GO
/****** Object:  StoredProcedure [dbo].[ELMAH_LogError]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ELMAH_LogError]
(
    @ErrorId UNIQUEIDENTIFIER,
    @Application NVARCHAR(60),
    @Host NVARCHAR(30),
    @Type NVARCHAR(100),
    @Source NVARCHAR(60),
    @Message NVARCHAR(500),
    @User NVARCHAR(50),
    @AllXml NTEXT,
    @StatusCode INT,
    @TimeUtc DATETIME
)
AS

    SET NOCOUNT ON

    INSERT
    INTO
        [ELMAH_Error]
        (
            [ErrorId],
            [Application],
            [Host],
            [Type],
            [Source],
            [Message],
            [User],
            [AllXml],
            [StatusCode],
            [TimeUtc]
        )
    VALUES
        (
            @ErrorId,
            @Application,
            @Host,
            @Type,
            @Source,
            @Message,
            @User,
            @AllXml,
            @StatusCode,
            @TimeUtc
        )


GO
/****** Object:  StoredProcedure [dbo].[getCallTrackingReport]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Vikas Joshi
-- Create date: 27/08/2014 12:58 AM
-- Description:	Gets call tracking report
-- =============================================
CREATE PROCEDURE [dbo].[getCallTrackingReport] 
	@fromdate datetime ,
	@todate datetime 
AS
BEGIN
	SET NOCOUNT ON;
	-- Exec [getCallTrackingReport] '2014-09-11', '2014-09-11'
	DECLARE @OptInEnglish bigint
	DECLARE @OptInSpanish bigint
	DECLARE @NonParticipant bigint
	DECLARE @OptedOut Bigint
	DECLARE @ReminderSet90Min bigint
	DECLARE @CancelledAppointments bigint
	DECLARE @ErrorCount Bigint
	DECLARE @PatientStop Bigint
	SET @todate = @todate + 1
	--Print @todate
	SET @CancelledAppointments=(SELECT COUNT(Account_Sid) FROM Message_History WHERE (BODY='c' OR BODY='C' or Body like '%cancel%' )and Direction = 'inbound' AND Date_Created Between @fromdate and @todate)
	SET @OptedOut =(SELECT COUNT(Account_Sid) FROM Message_History WHERE (BODY='S' OR BODY='s')AND Date_Created Between @fromdate and @todate)
	SET @ReminderSet90Min =(SELECT COUNT(MH.Account_Sid) FROM Message_History MH INNER JOIN Message_Sent MS ON MH.[Sid]=MS.[Sid] WHERE MS.Duration=90 AND MH.[Status]='delivered' AND MH.Date_Created Between @fromdate and @todate)
	--SET @OptInEnglish=(SELECT COUNT(MH.Account_Sid) FROM Message_History MH INNER JOIN Message_Sent MS ON MH.[Sid]=MS.[Sid] WHERE MS.[Language]='2 - English' AND MH.Date_Created Between @fromdate and @todate)
	--SET @OptInSpanish=(SELECT COUNT(MH.Account_Sid) FROM Message_History MH INNER JOIN Message_Sent MS ON MH.[Sid]=MS.[Sid] WHERE MS.[Language]='3 - Spanish' AND MH.Date_Created Between @fromdate and @todate)
	SET @ErrorCount =(SELECT COUNT(Account_Sid) FROM Message_History WHERE [Status] = 'undelivered'AND Date_Created Between @fromdate and @todate)
	
	Set @NonParticipant = (select COUNT(1) From NGProd.dbo.person ps
      join NGProd.dbo.patient pt on pt.person_id = ps.person_id
      join NGProd.dbo.person_ud ud on ud.person_id = ps.person_id
      join NGProd.dbo.mstr_lists ml on ml.mstr_list_item_id = ud.ud_demo5_id 
	 AND mstr_list_type = 'ud_demo5' AND ml.mstr_list_item_desc='1 - No')
	
	Set @OptInEnglish = (select COUNT(1) From NGProd.dbo.person ps
      join NGProd.dbo.patient pt on pt.person_id = ps.person_id
      join NGProd.dbo.person_ud ud on ud.person_id = ps.person_id
      join NGProd.dbo.mstr_lists ml on ml.mstr_list_item_id = ud.ud_demo5_id 
	 AND mstr_list_type = 'ud_demo5' AND ml.mstr_list_item_desc='2 - English')

	Set @OptInSpanish = (select COUNT(1) From NGProd.dbo.person ps
      join NGProd.dbo.patient pt on pt.person_id = ps.person_id
      join NGProd.dbo.person_ud ud on ud.person_id = ps.person_id
      join NGProd.dbo.mstr_lists ml on ml.mstr_list_item_id = ud.ud_demo5_id 
	 AND mstr_list_type = 'ud_demo5' AND ml.mstr_list_item_desc='3 - Spanish')	
	SELECT @OptInEnglish AS OptInEnglish,@OptInSpanish AS OptInSpanish,@NonParticipant AS NonParticipant,@ReminderSet90Min AS ReminderSet90Min,@CancelledAppointments AS CancelledAppointments, @ErrorCount As Undelivered, @OptedOut As OptedOut
END

GO
/****** Object:  StoredProcedure [dbo].[GetCancelReportData]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Amit Shrivastava>
-- Create date: <15-08-2014>
-- Description:	<Get Cancel Report Data>
-- Modified By : Vinay Bansal
-- Modified On : 04 Sept, 2014
-- =============================================
CREATE PROCEDURE [dbo].[GetCancelReportData]
	-- Add the parameters for the stored procedure here
	@Fromdate date,
	@todate date
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- Exec [GetCancelReportData] '2014-09-11', '2014-10-27'
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	/****** Script for SelectTopNRows command from SSMS  ******/
	
	/*Create table #CancelationTemp(Location nvarchar(200),location_id uniqueidentifier, mrn nvarchar(50), Patient_Name nvarchar(max),Phone_Number nvarchar(10),Appointment_Type	nvarchar(max), Appointment_Date datetime,Appointment_Time nvarchar(10), appointment_ID uniqueidentifier)
	INSERT INTO #CancelationTemp(appointment_ID)
	Select top 1 [Appointment_ID] From Message_Sent   
	Where [From] in (Select [From] FROM [Message_History] MH where Body ='C' or Body ='c' and Date_created BETWEEN @fromdate AND @todate)
	*/
	SET @todate = DateAdd(D,1,@todate)
	Create table #Temp([SID] nvarchar(34),Phone_Number nvarchar(100), Date_Created dateTime)
	Insert into #Temp (Phone_Number , Date_Created )
	Select [From], MH.Date_Created FROM [Message_History] MH where( Body ='C' or Body ='c' or Body like '%Cancel%' or Body like '%cancel%') and Direction = 'inbound' and Date_Created BETWEEN @fromdate AND @todate
	--Select * From #Temp
	/*Update #Temp SET [SID] = (Select Top 1 MH.[SID] From [Message_History] MH 
									Where MH.[To] = #Temp.Phone_Number AND MH.Date_Created between DATEADD(D,-1, #Temp.Date_Created) AND #Temp.Date_Created 
									order by  MH.Date_Created desc)  
									*/
									
		Update #Temp SET [SID] = (Select Top 1 MS.[SID] From Message_Sent MS
									--Inner Join Message_History MH ON MS.Sid = MH.SID
									Where MS.[To] = #Temp.Phone_Number AND MS.Date_Created between DATEADD(D,-1, Cast(#Temp.Date_Created AS Date)) AND #Temp.Date_Created) --AND ms.Duration = 1440)
	--Select * From #Temp
	Select  pa.med_rec_nbr,loc.location_name AS Location,P.first_name + ' ' + P.last_name As Name, T.Phone_Number, convert(varchar, Cast(App.appt_date As date),  101) As [Appointment Date]
    ,(LEFT(App.begintime,2)+':'+RIGHT(App.begintime,2)+':00') As BeginTime ,ev.event As [Event Type]
	 From NGProd.dbo.Appointments App
	 Join NGProd.dbo.patient pa on pa.person_id = App.person_id 
	 Join NGProd.dbo.person P On p.person_id = pa.person_id 
	 Left Join NGProd.dbo.LOCATION_MSTR loc on loc.location_id  = App.location_ID
	 Left JOIN NGProd.dbo.Events Ev On ev.event_id = app.event_id 
	 Inner Join Message_Sent MS on MS.Appointment_ID  = App.appt_id
	 Inner Join #Temp T ON T.[SID] = MS.[Sid]
	 --Order by Appt.begintime ASC
END



--Select * from Message_Sent where [To] ='+16197158208'

GO
/****** Object:  StoredProcedure [dbo].[GetNumbersforUndeleiveredMessage]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- =============================================
-- Author:		Amit Shrivastava
-- Create date: 18-08-2014
-- Description:	GetUndelivered Message Numbers
-- =============================================
CREATE PROCEDURE [dbo].[GetNumbersforUndeleiveredMessage] 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT * FROM [dbo].[Message_Sent] where Convert(date,date_created) = convert(date,GETDATE()) and [Status]='undelivered' 
	And [TO] not in  (Select Cell_number from UndeliveredNos where [COUNT] >2)
	--Code by vijay May 15 , 2015 :Message will not get in undeliverd If appointment gets in PT_MessageArchive table with sent status 
	And  (Select COUNT(1) from Message_History MH Where MH.[to]  = Message_Sent.[To] and Convert(date,date_created) = convert(date,GETDATE())) < 5   
	And [Appointment_ID] not in  (Select [Appt_ID] from dbo.PT_MessageArchive Where [Status] ='error' and [Duration] = [dbo].[Message_Sent].Duration)
	
 
END




GO
/****** Object:  StoredProcedure [dbo].[GetNumbersforUndeleiveredMessageTest]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- =============================================
-- Author:		Amit Shrivastava
-- Create date: 18-08-2014
-- Description:	GetUndelivered Message Numbers
-- =============================================
CREATE PROCEDURE [dbo].[GetNumbersforUndeleiveredMessageTest] 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT * FROM [dbo].[Message_Sent] where Convert(date,date_created) = convert(date,GETDATE()) and [Status]='undelivered' 
	And [TO] not in  (Select Cell_number from UndeliveredNos where [COUNT] >2)
	--Code by vijay May 15 , 2015 :Message will not get in undeliverd If appointment gets in PT_MessageArchive table with sent status 
	And [Appointment_ID] in  (Select [Appt_ID] from dbo.PT_MessageArchive Where [Status] ='error' and [Duration] = [dbo].[Message_Sent].Duration)
	--OR [dbo].[Message_Sent].[Status] ='undelivered' 
	
  
END

GO
/****** Object:  StoredProcedure [dbo].[GetPatientDetailsByPhoneNumber]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Amit Shrivastava
-- Create date: 15 August, 2014
-- Description:	Get Patient Details for Cancel Appointment
-- Modified by: Eric Born
-- Modified on: 01 December, 2015

-- Commented out selection of patient in any phone number field
-- except day_phone as the other fields are utilized for various contacts
-- and should not be considered
-- =============================================
CREATE PROCEDURE [dbo].[GetPatientDetailsByPhoneNumber]--'<NewDataSet>  <Numbers>    <Date_Created>2014-08-17T13:31:12-07:00</Date_Created>    <Date_Sent>2014-08-17T13:31:12-07:00</Date_Sent>    <From>+13233167354</From>  </Numbers></NewDataSet>'-- '6197784763,7025764278,6192044990,8587358419,8585788550,6196021324'
	-- Add the parameters for the stored procedure here
	@Numbers xml
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Reminder before One Day
	
	
	CREATE TABLE #Numbers(  
        [number] [nvarchar](max) NULL  
    );      
  
INSERT INTO #Numbers(  
  [number] 
        )  
 SELECT  
      T.C.value('(From)[1]', 'nvarchar(max)') AS BuyerID 
   FROM @Numbers.nodes('NewDataSet/Numbers') T(C)   
   
 --Select number from #numbers
	
	
	
	 --set @Numbers = SUBSTRING(@Numbers, 1, LEN(@Numbers)-1)
	Select  pa.med_rec_nbr ,pe.first_name, pe.last_name from 
	 NGPROD.dbo.patient pa inner join  NGPROD.dbo.person pe 
	on pa.person_id = pe.person_id 
	WHERE --pe.home_phone in (Select number from #numbers)
	 --or  pe.cell_phone in (Select number from #numbers) or
	  pe.day_phone in (Select number from #numbers)
	  --or pe.alt_PHONE in (Select number from #numbers)
	  --(Select Data from dbo.split(@numbers,','))
	
	

END



GO
/****** Object:  StoredProcedure [dbo].[GetTwiloNumber]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Amit Shrivastava>
-- Create date: <05-08-2014>
-- Description:	<Select phone number>
-- =============================================
CREATE PROCEDURE [dbo].[GetTwiloNumber]  
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	Declare @CurrentDate as datetime
	--Declare @NumberDate;
	--Set @CurrentDate = Convert(varchar, Getdate() ,110)
	Select @CurrentDate=convert(date,GETDATE());
	--Select @NumberDate = [Date] from Twilo_Numbers where [Count]=MaxCount
	Update Twilo_Numbers set [Date] = @CurrentDate,[Count]=0 where (Convert(date,[Date])!= Convert(date,@CurrentDate)) --and [Count]= MaxCount
	Select Numbers,[Count], MaxCount  from Twilo_Numbers where (Convert(date,[Date])= Convert(date,@CurrentDate))and [Count]< MaxCount
END


GO
/****** Object:  StoredProcedure [dbo].[InsertMessageHistory]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Amit Shrivastava>
-- Create date: <04-08-2014>
-- Description:	<Insert Messages received>
-- =============================================
CREATE PROCEDURE [dbo].[InsertMessageHistory] 
	-- Add the parameters for the stored procedure here
	 @AccountSid VARCHAR(34),
     @ApiVersion VARCHAR(10),
     @Body VARCHAR(Max),     
     @dateCreated DateTime,        
     @DateSent DateTime,        
     @DateUpdated DateTime,
     @Direction varchar(50),
     @ErrorCode Varchar(50),
     @ErrorMessage Varchar(Max),
     @From Varchar(15),
	 @NumImages int,
	 @NumSegments int,
	 @price float,
	 @sid varchar(34),
	 @Status varchar(50),
	 @To varchar(15)            
    
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	IF not exists(Select 1 From [Message_History] WHERE SID = @Sid)
	Begin
			INSERT INTO [dbo].[Message_History]
				   ([Account_Sid]
				   ,[Body]
				   ,[Date_Created]
				   ,[Date_Sent]
				   ,[Date_Updated]
				   ,[Direction]
				   ,[Error_Code]
				   ,[Error_Message]
				   ,[From]
				   ,[Num_Images]
				   ,[Num_Segments]
				   ,[Price]
				   ,[Sid]
				   ,[API_Version]
				   ,[Status]
				   ,[To])
			 VALUES
			 (
			  @AccountSid,
			  @Body ,     
			  @dateCreated,        
			  @DateSent, 
			  @DateUpdated ,
			  @Direction ,
			  @ErrorCode ,
			  @ErrorMessage,
			  @From,
			  @NumImages ,
			  @NumSegments,
			  @price ,
			  @sid,
			  @ApiVersion,
			  @Status,
			  @To
			 )
			 Update Message_Sent SET [Status] = @Status where [Sid] = @sid 
			 
			/* if(@Status = 'undelivered')
			 Begin
				Update Message_Sent SET [UndeliveredCount] = [UndeliveredCount] +1 Where [To] = @To AND Cast(Date_Created As date) = Cast(@dateCreated As date)
			 END */
     End
END


GO
/****** Object:  StoredProcedure [dbo].[InsertMessageSent]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Amit Shrivastava>
-- Create date: <13-08-2014>
-- Description:	<Insert Messages Sent>
-- =============================================
CREATE PROCEDURE [dbo].[InsertMessageSent] 
	-- Add the parameters for the stored procedure here
	 @AccountSid VARCHAR(34),
     @ApiVersion VARCHAR(10),
     @Body VARCHAR(Max),     
     @dateCreated DateTime,        
     @DateSent DateTime,        
     @DateUpdated DateTime,
     @Direction varchar(50),
     @ErrorCode Varchar(50),
     @ErrorMessage Varchar(Max),
     @From Varchar(15),
	 @NumImages int,
	 @NumSegments int,
	 @price float,
	 @sid varchar(34),
	 @Status varchar(50),
	 @To varchar(15),
	 @Duration bigint,
	 @Language nvarchar(200),
	 @Appt_ID uNIQUEIDENTIFIER           
    
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--Code by vijay July 24 , 2015 : Check if status is 'Undelivered' then set blank. To avoid sent multiple messages 
	--Create New table [PT_TestMessageSentArchive] and insert entry in it for archives
	IF EXISTS(Select 1 from [dbo].[Message_Sent] Where [To] =@To and LOWER(Status)='undelivered' and [Appointment_ID]=@Appt_ID and  Duration =@Duration)
	BEGIN 
		Update [dbo].[Message_Sent] SET Status='' Where [To] =@To and Status='Undelivered' and [Appointment_ID]=@Appt_ID and  Duration =@Duration
		INSERT INTO [dbo].[PT_TestMessageSentArchive]
           ([Body]
           ,[Date_Created]
           ,[Sid]
           ,[Status]
           ,[To]
           ,[Duration]
           ,[Appointment_ID])
     VALUES
           (@Body
           ,GETDATE()
           ,@sid
           ,@Status
           ,@To
           ,@Duration
           ,@Appt_ID)
	END
	else 
	BEGIN
	
		INSERT INTO [dbo].[Message_Sent]
           ([Account_Sid]
           ,[Body]
           ,[Date_Created]
           ,[Date_Sent]
           ,[Date_Updated]
           ,[Direction]
           ,[Error_Code]
           ,[Error_Message]
           ,[From]
           ,[Num_Images]
           ,[Num_Segments]
           ,[Price]
           ,[Sid]
           ,[API_Version]
           ,[Status]
           ,[To]
           ,[Duration]
           ,[Language]
           ,[Appointment_ID])
			 VALUES
			 (
			  @AccountSid,
			 @Body ,     
			 @dateCreated,        
			 @DateSent, 
			 @DateUpdated ,
			 @Direction ,
			 @ErrorCode ,
			 @ErrorMessage,
			 @From,
			 @NumImages ,
			 @NumSegments,
			 @price ,
			 @sid,
			 @ApiVersion,
			 @Status,
			 @To,
			 @Duration,
			 @Language,
			 @Appt_ID
			 )
	END
			--Code by vijay May 15 , 2015 : Status Update in PT_MessageArchive table
			 Update [dbo].[PT_MessageArchive] Set [Status]= 'Sent' ,[DateUpdated] = GETDATE(),[Body] =  @Body , [sid] = @sid
			 where [Appt_ID] = @Appt_ID and [Duration] = @Duration

END



GO
/****** Object:  StoredProcedure [dbo].[PS_AddCancelHistory]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Vijay Singh Chouhan>
-- Create date: <12/12/2014>
-- Description : Add cancel appointments 
-- =============================================
CREATE PROCEDURE [dbo].[PS_AddCancelHistory] 
	-- Add the parameters for the stored procedure here
	@Appointment_ID uniqueidentifier
	
AS
BEGIN
		Insert into CancelHistory (Appointment_ID , Date_Created ) values(@Appointment_ID ,getdate())
END

GO
/****** Object:  StoredProcedure [dbo].[PS_AppointmentInfo]    Script Date: 5/8/2017 1:29:49 PM ******/
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
create PROCEDURE [dbo].[PS_AppointmentInfo] (@phone nvarchar(12)) 



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
    JOIN   ngprod.dbo.person ps 
    ON     ps.day_phone = temp.phone_number; 

	--Find most recent appointment for patient
    WITH lastappt AS 
    ( 
             SELECT   a.appt_id, 
                      a.person_id,
					  a.appt_date,
                      Row_number() OVER ( partition BY a.person_id ORDER BY a.appt_date DESC ) AS mostrecent
             FROM     ngprod.dbo.appointments a
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
    JOIN   ngprod.dbo.appointments appt 
    ON     appt.appt_id = temp.appt_id 

    --Update location / address 
    UPDATE #temp_info 
    SET    loc_name = lm.location_name, 
           addy = lm.address_line_1,
		   city = lm.city,
		   [state] = lm.[state],
		   zip = lm.zip
    FROM   #temp_info temp 
    JOIN   ngprod.dbo.appointments appt 
    ON     appt.appt_id = temp.appt_id 
    JOIN   ngprod.dbo.location_mstr lm 
    ON     lm.location_id = appt.location_id
	
	--Update text language preference
	UPDATE #temp_info
	SET	   @lang = ml.mstr_list_item_desc
	FROM   #temp_info temp
	JOIN   ngprod.dbo.person_ud ud 
	ON ud.person_id = temp.person_id
	JOIN   ngprod.dbo.mstr_lists ml 
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

GO
/****** Object:  StoredProcedure [dbo].[PS_AppointmentReminder]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Vinay Bansal
-- Create date: 01 August, 2014
-- Description:	Get Appointments for Reminder
-- Modified by: Eric Born
-- Modified date: 01 December 2015

-- Commented out all instances of And A.create_timestamp = A.modify_timestamp as 
-- we believe this is causing patients who still have valid appointments to not receive texts
-- =============================================
CREATE PROCEDURE [dbo].[PS_AppointmentReminder]  
	-- Add the parameters for the stored procedure here
	@Type int = 3
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	-- Exec [PS_AppointmentReminder]  3
	SET NOCOUNT ON;
	-- Reminder before One Day
	DECLARE @Date datetime
	Create Table #TempAppt(person_id uniqueidentifier, Cell_phone nvarchar(10), Name nvarchar(200), Language_Type nvarchar(50)
							,appt_Id uniqueidentifier, Msg nvarchar(300), Duration bigint) 
	IF(@Type = 1)
	BEGIN
	Print CASt(Dateadd(d,1,GETDATE()) As date)
	Print CASt(Dateadd(d,2,GETDATE()) As date)
		Insert Into #TempAppt(person_id,Cell_phone,Name,Language_Type, Duration ) 
		SELECT DISTINCT P.person_Id, P.day_phone,p.first_name + ' ' + p.last_name As Name, ml.mstr_list_item_desc, 1440
		FROM NGProd.dbo.appointments A
		INNER JOIN NGProd.dbo.person P on a.person_id = p.person_id 
		JOIN NGProd.dbo.person_ud ud on ud.person_id = p.person_id
        JOIN NGProd.dbo.mstr_lists ml on ml.mstr_list_item_id = ud.ud_demo5_id 
		WHERE appt_date = CASt(Dateadd(d,1,GETDATE()) As date) --and CASt(Dateadd(d,2,GETDATE()) As date)
		AND P.day_phone is not null  And A.Cancel_ind = 'N' AND A.DElete_Ind = 'N' And A.resched_ind ='N'
		AND mstr_list_type = 'ud_demo5' AND mstr_list_item_desc <> '1 - No'
		--And A.create_timestamp = A.modify_timestamp
	
		Update #TempAppt SET appt_Id = (Select Top 1 A.appt_ID From NGProd.dbo.appointments A
										Where person_id = #TempAppt.person_id and A.appt_date = CASt(Dateadd(d,1,GETDATE()) As date) --and CASt(Dateadd(d,2,GETDATE()) As date) 
											And A.Cancel_ind = 'N' AND A.DElete_Ind = 'N'  And A.resched_ind ='N' --And A.create_timestamp = A.modify_timestamp
										order by appt_date, begintime asc) 
		
		Update #TempAppt SET Msg = Replace('This is your doctor’s office reminding you of your appointment tomorrow at xx:xx am/pm. To cancel reply ‘C’. This is an automated message, to reschedule please call 1-888-743-7526.','xx:xx am/pm',right(convert(varchar,DateAdd(ss, 3600*(A.beginTime/100) + 60*((A.beginTime % 100)) , '19000101'),0),7)) 
		From NGProd.dbo.appointments A 
		Where A.Appt_ID = #TempAppt.appt_Id AND Language_Type = '2 - English' 
		
		Update #TempAppt SET Msg = Replace('Este es un recordatorio de su cita mañana a las xx:xx am/pm. Para cancelar su cita responda ‘C’. Este es un mensaje automático; para hacer cambios llame al 1-888-743-7526.','xx:xx am/pm',right(convert(varchar,DateAdd(ss, 3600*(A.beginTime/100) + 60*((A.beginTime % 100)) , '19000101'),0),7)) 
		From NGProd.dbo.appointments A 
		Where A.Appt_ID = #TempAppt.appt_Id AND Language_Type = '3 - Spanish' 
		
		Select *, Language_Type as [Language] From #TempAppt Where appt_Id not in ( Select Appointment_ID from Message_Sent where Duration = '1440' )
			AND Cell_phone not in (Select Right(Cell_number,10) from UndeliveredNos where [COUNT] >5)
		--Code by vijay May 15 , 2015 :Message will not get in undeliverd If appointment gets in PT_MessageArchive table with sent status 
		--And appt_Id in  (Select [Appt_ID] from dbo.PT_MessageArchive Where [Status] ='error' and [Duration] = [dbo].[Message_Sent].Duration)
		--Select person_id , '9685758871' Cell_phone, 'ABC' As NAme, '2 - English' Language_Type,appt_Id, 'test' Msg, 1440 as Duration , '2 - English' as [Language]from NGProd.dbo.appointments A where appt_id ='2DCF33FD-20D7-411A-8C6D-8EF8FEE66490'
	END	
	ELSE IF @Type = 2
	BEGIN
		-- Appointment Reminder before 90 min
		SET @Date = DateAdd(MINUTE,90,GetDate())
		Print @Date
		Print Cast(REPLACE(SUBSTRING(convert(varchar, GETDATE(),108),1,5),':','') AS bigint)  
		Print Cast(REPLACE(SUBSTRING(convert(varchar, @Date,108),1,5),':','') as Bigint)
		--SELECT CONVERT(VARCHAR(10), GETDATE(), 112)
		--select REPLACE(SUBSTRING( convert(varchar, @Date,108),1,5),':','')
		Insert Into #TempAppt(person_id,Cell_phone,Name,Language_Type, Duration) 
		SELECT DISTINCT P.person_Id, P.day_phone,p.first_name + ' ' + p.last_name As Name, ml.mstr_list_item_desc, 90
		FROM NGProd.dbo.appointments A
		INNER JOIN NGProd.dbo.person P on a.person_id = p.person_id 
		--Inner join Patient PA on Pa.person_id = p.person_id 
		JOIN NGProd.dbo.person_ud ud on ud.person_id = p.person_id
        JOIN NGProd.dbo.mstr_lists ml on ml.mstr_list_item_id = ud.ud_demo5_id 
		--where appt_date = CONVERT(VARCHAR(10), @Date, 112) AND A.begintime Between REPLACE(SUBSTRING( convert(varchar, @Date,108),1,5),':','') AND REPLACE(SUBSTRING( convert(varchar, DateAdd(MINUTE,100,GetDate()),108),1,5),':','')
		where Cast(A.begintime as bigint) >= Cast(REPLACE(SUBSTRING(convert(varchar, GETDATE(),108),1,5),':','') AS bigint) 
				--AND Cast(A.begintime as bigint) < Cast(REPLACE(SUBSTRING( convert(varchar, DateAdd(MINUTE,100,GetDate()),108),1,5),':','') as Bigint)
				AND Cast(A.begintime as bigint) < Cast(REPLACE(SUBSTRING( convert(varchar, @Date,108),1,5),':','') as Bigint)
		AND P.day_phone is not null 
		AND appt_date = CONVERT(VARCHAR(10), @Date, 112)
		AND mstr_list_type = 'ud_demo5'
		AND mstr_list_item_desc <> '1 - No'
		And A.Cancel_ind = 'N' AND A.DElete_Ind = 'N' And A.resched_ind ='N' --And A.create_timestamp = A.modify_timestamp
		--order by begintime  
		
		Update #TempAppt SET appt_Id = (Select Top 1 A.appt_ID From NGProd.dbo.appointments A
				Where person_id = #TempAppt.person_id AND appt_date = CONVERT(VARCHAR(10), @Date, 112) AND Cast(A.begintime as bigint) >= Cast(REPLACE(SUBSTRING(convert(varchar, GETDATE(),108),1,5),':','') AS bigint) 
				--AND Cast(A.begintime as bigint) < Cast(REPLACE(SUBSTRING( convert(varchar, DateAdd(MINUTE,100,GetDate()),108),1,5),':','') as Bigint)
				AND Cast(A.begintime as bigint) < Cast(REPLACE(SUBSTRING( convert(varchar, @Date,108),1,5),':','') as Bigint)
				And A.Cancel_ind = 'N' AND A.DElete_Ind = 'N' And A.resched_ind ='N' --And A.create_timestamp = A.modify_timestamp
		   	    order by appt_date asc) 
		
			Update #TempAppt SET Msg = Replace('This is your doctor’s office reminding you of your appointment today at xx:xx am/pm. We look forward to seeing you! This is an automated message, to reschedule please call 1-888-743-7526.','xx:xx am/pm',right(convert(varchar,DateAdd(ss, 3600*(A.beginTime/100) + 60*((A.beginTime % 100)) , '19000101'),0),7)) 
			From NGProd.dbo.appointments A 
			Where A.Appt_ID = #TempAppt.appt_Id AND Language_Type = '2 - English' 
			
			Update #TempAppt SET Msg = Replace('Este es un mensaje de su clínica médica, para recordarle de su cita el día de hoy a las xx:xx am/pm. ¡Nos dará gusto atenderle! Este es un mensaje automático; para hacer cambios llame al 1-888-743-7526.','xx:xx am/pm',right(convert(varchar,DateAdd(ss, 3600*(A.beginTime/100) + 60*((A.beginTime % 100)) , '19000101'),0),7)) 
			From NGProd.dbo.appointments A 
			Where A.Appt_ID = #TempAppt.appt_Id AND Language_Type = '3 - Spanish' 
			
			Select *, Language_Type as [Language] From #TempAppt Where appt_Id not in ( Select Appointment_ID from Message_Sent where Duration = '90')
				AND Cell_phone not in (Select Right(Cell_number,10) from UndeliveredNos where [COUNT] >5)
			--Code by vijay May 15 , 2015 :Message will not get in undeliverd If appointment gets in PT_MessageArchive table with sent status 
			--And appt_Id in  (Select [Appt_ID] from dbo.PT_MessageArchive Where [Status] ='error' and [Duration] = [dbo].[Message_Sent].Duration)
		END
		
		ELSE IF @Type = 3
		BEGIN
			-- Appointment Reminder after 60 min
			--DECLA @Date datetime
			SET @Date = DateAdd(MINUTE,-60,GetDate())
			Print @Date
			Print CAST((CAST(GetDate() As date))  AS DateTime)
			Insert Into #TempAppt(person_id,Cell_phone,Name,Language_Type, Duration) 
			SELECT DISTINCT P.person_Id, P.day_phone,p.first_name + ' ' + p.last_name As Name, ml.mstr_list_item_desc, -60
			FROM NGProd.dbo.appointments A
			INNER JOIN NGProd.dbo.person P on a.person_id = p.person_id 
			--Inner join Patient PA on Pa.person_id = p.person_id 
			JOIN NGProd.dbo.person_ud ud on ud.person_id = p.person_id
			JOIN NGProd.dbo.mstr_lists ml on ml.mstr_list_item_id = ud.ud_demo5_id 
			where A.create_timestamp between CAST((CAST(GetDate() As date)) AS DateTime) AND @Date
			AND P.day_phone is not null 
			AND mstr_list_type = 'ud_demo5'
			AND mstr_list_item_desc <> '1 - No' And A.Cancel_ind = 'N' AND A.DElete_Ind = 'N' And A.resched_ind ='N' --And A.create_timestamp = A.modify_timestamp
			--order by begintime  
			-- Select CAST((CAST(GetDate() As date)) AS DateTime)
			--Print DateAdd(MINUTE,10,@Date)
			Update #TempAppt SET appt_Id = (Select Top 1 A.appt_ID From NGProd.dbo.appointments A
										Where person_id = #TempAppt.person_id and A.create_timestamp between CAST((CAST(GetDate() As date)) AS DateTime) AND @Date
										And A.Cancel_ind = 'N' AND A.DElete_Ind = 'N' And A.resched_ind ='N' --And A.create_timestamp = A.modify_timestamp
										order by appt_date asc) 
		
			Update #TempAppt SET Msg = Replace('Thank you for scheduling an appointment! You have opted-in for text reminders, charges from your carrier may apply. To opt-out reply ‘S’ to this message. This is an automated message, to contact us please call 1-888-743-7526.','xx:xx am/pm',right(convert(varchar,DateAdd(ss, 3600*(A.beginTime/100) + 60*((A.beginTime % 100)) , '19000101'),0),7)) 
			From NGProd.dbo.appointments A 
			Where A.Appt_ID = #TempAppt.appt_Id AND Language_Type = '2 - English' 
			
			Update #TempAppt SET Msg = Replace('Gracias por hacer una cita. Ha aceptado recibir mensajes de texto; puede haber cargos extra de su compañía de teléfono. Para cancelar los mensajes responda ‘S’. Este es un mensaje automático; para comunicarse con nosotros, llame al 1-888-743-7526.','xx:xx am/pm',right(convert(varchar,DateAdd(ss, 3600*(A.beginTime/100) + 60*((A.beginTime % 100)) , '19000101'),0),7)) 
			From NGProd.dbo.appointments A 
			Where A.Appt_ID = #TempAppt.appt_Id AND Language_Type = '3 - Spanish' 
			
			Select *, Language_Type as [Language] From #TempAppt Where appt_Id not in ( Select Appointment_ID from Message_Sent where Duration = '-60')
			AND Cell_phone not in (Select Right(Cell_number,10) from UndeliveredNos where [COUNT] >5)
			--Code by vijay May 15 , 2015 :Message will not get in undeliverd If appointment gets in PT_MessageArchive table with sent status 
			--And appt_Id in  (Select [Appt_ID] from dbo.PT_MessageArchive Where [Status] ='error' and [Duration] = #TempAppt.Duration)
			
			--Select person_id , '9685758871' Cell_phone, 'ABC1' As NAme, '2 - English' Language_Type,appt_Id, 'test MAY 16 1' Msg, '-60' as Duration , '2 - English' as [Language]from NGProd.dbo.appointments A where appt_id ='2DCF33FD-20D7-411A-8C6D-8EF8FEE66490'
			--Union all
			--Select person_id , '9094899376' Cell_phone, 'ABC2' As NAme, '2 - English' Language_Type,appt_Id, 'test MAY 16 2' Msg, '1440' as Duration , '2 - English' as [Language]from NGProd.dbo.appointments A where appt_id ='54F01D15-C499-4FCA-9A8F-83BF1FDBEF9B'
			--Union all
			--Select person_id , '9095738599' Cell_phone, 'ABC3' As NAme, '2 - English' Language_Type,appt_Id, 'test MAY 16 3' Msg, '1440' as Duration , '2 - English' as [Language]from NGProd.dbo.appointments A where appt_id ='35D663FD-2223-4C50-A4A4-38F0B7DF70FF'
			
		END
		
		Else IF @Type = 4
		BEGIN
			Select Distinct MH.[From], MS.Language,  MH.[SID],
			Case When MS.Language  = '2 - English' THEN 'You have opted out of receiving future appointment reminders. If you would like to opt back in please notify a staff member or call 1-888-743-7526. Thank you'
			WHEN MS.Language = '3 - Spanish' Then 'Optó por no recibir futuros recordatorios de citas . Si desea volver a tomar parte por favor notifique a un miembro del personal o llame al 1-888-743-7526 . Gracias'
			Else ' ' END as MSG 
			From Message_History MH 
			Inner Join Message_Sent MS ON MS.[To] = MH.[From]
			Where MH.IsActive = 1 and MH.IsReminderSent = 0	
			
			--Update Message_History  SET IsReminderSent = 1	Where IsActive = 1 and IsReminderSent = 0	
		END
	
END

--Select top 10 * from ngprod.dbo.appointments

GO
/****** Object:  StoredProcedure [dbo].[PS_AppointmentTextCancellation]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--=============================================
-- Author:		<Anthony Prendimano>
-- Create date: <10/28/2014>
-- Modified By: Vijay Singh Chouhan
-- Modified On : 09/12/2014
-- Modified Reson : Fetch all the cancel appointments 
-- Description:	<Cancels appointment in EPM for any patient that sends a C or Cancel via text message.>
-- =============================================
CREATE PROCEDURE [dbo].[PS_AppointmentTextCancellation] 
AS
BEGIN
		--SET NOCOUNT ON;
		Declare @todaydate varchar(8)
		Set @todaydate = convert(varchar(8),getdate(),112)
		--Select @todaydate 
		Create table #Temp(Appt_ID Uniqueidentifier,Phone_Number nvarchar(100), Date_Created dateTime)
		Insert into #Temp (Phone_Number , Date_Created )
		Select [From], MH.Date_Created FROM [Message_History] MH where( Body ='C' or Body ='c' or Body like '%Cancel%' or Body like '%cancel%') and Direction = 'inbound' --and Date_Created BETWEEN @fromdate AND @todate
									
		
		update T set Appt_ID =MS.Appointment_ID from #Temp T
		left join Message_Sent MS on MS.[To] = T.Phone_Number
		and MS.Date_Created between DATEADD(D,-1, Cast(T.Date_Created AS Date)) AND T.Date_Created
			
			
			
		--Update #Temp SET Appt_ID = (Select Top 1 MS.Appointment_ID  From Message_Sent MS
		--Where MS.[To] = #Temp.Phone_Number AND MS.Date_Created between DATEADD(D,-1, Cast(#Temp.Date_Created AS Date)) 
		--AND #Temp.Date_Created) --AND ms.Duration = 1440)	
					
							
		Select Distinct t.Appt_ID ,Phone_Number 
		from  #Temp t 
		inner join  NGProd.dbo.Appointments a on t.Appt_ID = a.appt_id 
		WHERE  a.appt_id Not in (Select [Appointment_ID] from CancelHistory) 	
		and cancel_ind = 'N' 
		AND appt_date  >= @todaydate 
		
		Update s SET cancel_ind  = 'Y', modified_by ='1558', modify_timestamp = GETDATE() 
		FROM NGProd.dbo.Appointments s 
		INNER Join #Temp t
		ON t.Appt_ID = s.appt_id			
		WHERE s.cancel_ind  = 'N' AND s.appt_date >=  @todaydate 
		
END

GO
/****** Object:  StoredProcedure [dbo].[PS_AppointmentTextCancellation_BCK_6_Feb_2017]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--=============================================
-- Author:		<Anthony Prendimano>
-- Create date: <10/28/2014>
-- Modified By: Vijay Singh Chouhan
-- Modified On : 09/12/2014
-- Modified Reson : Fetch all the cancel appointments 
-- Description:	<Cancels appointment in EPM for any patient that sends a C or Cancel via text message.>
-- =============================================
create PROCEDURE [dbo].[PS_AppointmentTextCancellation_BCK_6_Feb_2017] 
AS
BEGIN
		--SET NOCOUNT ON;
		Declare @todaydate varchar(8)
		Set @todaydate = convert(varchar(8),getdate(),112)
		--Select @todaydate 
		Create table #Temp(Appt_ID Uniqueidentifier,Phone_Number nvarchar(100), Date_Created dateTime)
		Insert into #Temp (Phone_Number , Date_Created )
		Select [From], MH.Date_Created FROM [Message_History] MH where( Body ='C' or Body ='c' or Body like '%Cancel%' or Body like '%cancel%') and Direction = 'inbound' --and Date_Created BETWEEN @fromdate AND @todate
									
		Update #Temp SET Appt_ID = (Select Top 1 MS.Appointment_ID  From Message_Sent MS
										Where MS.[To] = #Temp.Phone_Number AND MS.Date_Created between DATEADD(D,-1, Cast(#Temp.Date_Created AS Date)) AND #Temp.Date_Created) --AND ms.Duration = 1440)
									
		Select Distinct t.Appt_ID ,Phone_Number 
		from  #Temp t 
		inner join  NGProd.dbo.Appointments a on t.Appt_ID = a.appt_id 
		WHERE  a.appt_id Not in (Select [Appointment_ID] from CancelHistory) 	
		and cancel_ind = 'N' 
		AND appt_date  >= @todaydate 
		
		Update s SET cancel_ind  = 'Y', modified_by ='1558', modify_timestamp = GETDATE() 
		FROM NGProd.dbo.Appointments s 
		INNER Join #Temp t
		ON t.Appt_ID = s.appt_id			
		WHERE s.cancel_ind  = 'N' AND s.appt_date >=  @todaydate 
		
END

GO
/****** Object:  StoredProcedure [dbo].[PS_AppointmentTextCancellation_NEW]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--=============================================
-- Author:		<Anthony Prendimano>
-- Create date: <10/28/2014>
-- Modified By: Vijay Singh Chouhan
-- Modified On : 09/12/2014
-- Modified Reson : Fetch all the cancel appointments 
-- Description:	<Cancels appointment in EPM for any patient that sends a C or Cancel via text message.>
-- =============================================
CREATE PROCEDURE [dbo].[PS_AppointmentTextCancellation_NEW] 
AS
BEGIN
		--SET NOCOUNT ON;
		Declare @todaydate varchar(8)
		Set @todaydate = convert(varchar(8),getdate(),112)
		--Select @todaydate 
		Create table #Temp(Appt_ID Uniqueidentifier,Phone_Number nvarchar(100), Date_Created dateTime)
		Insert into #Temp (Phone_Number , Date_Created )
		Select [From], MH.Date_Created FROM [Message_History] MH where( Body ='C' or Body ='c' or Body like '%Cancel%' or Body like '%cancel%') and Direction = 'inbound' --and Date_Created BETWEEN @fromdate AND @todate
									
		
		update T set Appt_ID =MS.Appointment_ID from #Temp T
		left join Message_Sent MS on MS.[To] = T.Phone_Number
		and MS.Date_Created between DATEADD(D,-1, Cast(T.Date_Created AS Date)) AND T.Date_Created
			
			
			
		--Update #Temp SET Appt_ID = (Select Top 1 MS.Appointment_ID  From Message_Sent MS
		--Where MS.[To] = #Temp.Phone_Number AND MS.Date_Created between DATEADD(D,-1, Cast(#Temp.Date_Created AS Date)) 
		--AND #Temp.Date_Created) --AND ms.Duration = 1440)	
					
							
		Select Distinct t.Appt_ID ,Phone_Number 
		from  #Temp t 
		inner join  NGProd.dbo.Appointments a on t.Appt_ID = a.appt_id 
		WHERE  a.appt_id Not in (Select [Appointment_ID] from CancelHistory) 	
		and cancel_ind = 'N' 
		AND appt_date  >= @todaydate 
		
		Update s SET cancel_ind  = 'Y', modified_by ='1558', modify_timestamp = GETDATE() 
		FROM NGProd.dbo.Appointments s 
		INNER Join #Temp t
		ON t.Appt_ID = s.appt_id			
		WHERE s.cancel_ind  = 'N' AND s.appt_date >=  @todaydate 
		
END

GO
/****** Object:  StoredProcedure [dbo].[PS_InsertMessageArchive]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Vijay Singh>
-- Create date: <15-05-2015>
-- Description:	<Insert Messages Archive>
-- =============================================
CREATE PROCEDURE [dbo].[PS_InsertMessageArchive] 
	-- Add the parameters for the stored procedure here
	 
     @Appt_ID uNIQUEIDENTIFIER,    
	 @Duration bigint,       
	 @Status varchar(50),
     @Phone_Number varchar(15),     
     @DateCreated DateTime,        
     @DateUpdated DateTime,
	 @Body varchar(500) 
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    INSERT INTO [dbo].[PT_MessageArchive]
           ([Appt_ID],
			[Duration],
			[Status],
			[Phone_Number],
			[DateCreated],
			[DateUpdated],
			[Body])
			VALUES
			 (
			 @Appt_ID ,    
			 @Duration ,       
			 @Status ,
			 @Phone_Number,     
			 GETDATE(),        
			 @DateUpdated,
			 @Body 
			)
END


GO
/****** Object:  StoredProcedure [dbo].[PS_UpdateMessageArchive]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Vijay Singh>
-- Create date: <15-05-2015>
-- Description:	<IUpdate Messages Archive>
-- =============================================
CREATE PROCEDURE [dbo].[PS_UpdateMessageArchive] 
	-- Add the parameters for the stored procedure here
	 
     @Appt_ID uNIQUEIDENTIFIER,    
	 @Duration bigint,       
	 @Status varchar(50)
    
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	Update [dbo].[PT_MessageArchive] Set [Status] = @Status , DateUpdated= GETDATE() Where Appt_ID = @Appt_ID and Duration = @Duration
    
END


GO
/****** Object:  StoredProcedure [dbo].[test]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[test] (@date char(50))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT top 10 * from NGProd.dbo.appointments
	where appt_date > @date
END

GO
/****** Object:  StoredProcedure [dbo].[UpdateStopReminder]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Vinay Bansal
-- Create date: 8 Sept, 2014
-- Description:	Update Message History Reminder sent
-- =============================================
CREATE PROCEDURE [dbo].[UpdateStopReminder] 
	-- Add the parameters for the stored procedure here
	@SID nvarchar(200) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Update Message_History set IsReminderSent = 1 where [Sid] = @SID
END

GO
/****** Object:  StoredProcedure [dbo].[UpdateTwiloNumberCount]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Amit Shrivastava>
-- Create date: <05-08-2014>
-- Description:	<Update Count>
-- =============================================
CREATE PROCEDURE [dbo].[UpdateTwiloNumberCount] 
	@number varchar(15),
	@Count int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Update Twilo_Numbers set  [Count]=@Count where Numbers=@number
END


GO
/****** Object:  StoredProcedure [dbo].[UpdateUndelievered]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Vinay Bansal
-- Create date: 10 Sept, 2014
-- Description:	UpdateUndelievered
-- =============================================
CREATE PROCEDURE [dbo].[UpdateUndelievered] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	DECLARE @SID nvarchar(200) 
	DECLARE @Cell nVARCHAR(20) 
	DECLARE @Status nVARCHAR(256) 

	DECLARE db_cursor CURSOR FOR  
		SELECT sid,[TO],[status] FROM Message_History WHERE [ISUndelieveredTagged] = 0 
		And Date_Created > DATEADD(DAY,-3,GETDATE())
		order by Date_Created Asc

		OPEN db_cursor  
		FETCH NEXT FROM db_cursor INTO @SID,@Cell,@Status  
		
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			IF(@Status = 'undelivered')
			Begin
					Update UndeliveredNos SET [Count] = [COUNT] + 1
					Where Cell_number = @Cell
					
					IF not exists(Select 1 from UndeliveredNos where Cell_number = @Cell)
					Begin
					Insert Into UndeliveredNos(Cell_number, [Count])
					Values(@Cell, 1) 
					End
					
			END	   
			ELSE IF(@Status = 'delivered')
			BEGIN
				Delete From UndeliveredNos Where Cell_number = @Cell 
			END  
			
			Update Message_History SET [ISUndelieveredTagged] = 1 Where [Sid] = @SID
					
			FETCH NEXT FROM db_cursor INTO @SID,@Cell,@Status 
		END
		Deallocate db_cursor
	
END

GO
/****** Object:  UserDefinedFunction [dbo].[Split]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Split]  
(  
@RowData nvarchar(MAX),
@SplitOn nvarchar(5)
)    
RETURNS @ReturnValue TABLE  
(Data NVARCHAR(MAX))  
AS
BEGIN
Declare @Counter int
Set @Counter = 1
While (Charindex(@SplitOn,@RowData)>0)
Begin  
  Insert Into @ReturnValue (data)  
  Select Data =
      ltrim(rtrim(Substring(@RowData,1,Charindex(@SplitOn,@RowData)-1)))
  Set @RowData =
      Substring(@RowData,Charindex(@SplitOn,@RowData)+1,len(@RowData))
  Set @Counter = @Counter + 1  
End
Insert Into @ReturnValue (data)  
Select Data = ltrim(rtrim(@RowData))  
Return  
END

GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetNumeric]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetNumeric]
(@strAlphaNumeric VARCHAR(256))
RETURNS VARCHAR(256)
AS
BEGIN
DECLARE @intAlpha INT
SET @intAlpha = PATINDEX('%[^0-9]%', @strAlphaNumeric)
BEGIN
WHILE @intAlpha > 0
BEGIN
SET @strAlphaNumeric = STUFF(@strAlphaNumeric, @intAlpha, 1, '' )
SET @intAlpha = PATINDEX('%[^0-9]%', @strAlphaNumeric )
END
END
RETURN ISNULL(@strAlphaNumeric,0)
END

GO
/****** Object:  Table [dbo].[CancelHistory]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CancelHistory](
	[Cancel_ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Appointment_ID] [uniqueidentifier] NOT NULL,
	[Date_Created] [datetime] NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ELMAH_Error]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ELMAH_Error](
	[ErrorId] [uniqueidentifier] NOT NULL,
	[Application] [nvarchar](60) NOT NULL,
	[Host] [nvarchar](50) NOT NULL,
	[Type] [nvarchar](100) NOT NULL,
	[Source] [nvarchar](60) NOT NULL,
	[Message] [nvarchar](500) NOT NULL,
	[User] [nvarchar](50) NOT NULL,
	[StatusCode] [int] NOT NULL,
	[TimeUtc] [datetime] NOT NULL,
	[Sequence] [int] IDENTITY(1,1) NOT NULL,
	[AllXml] [ntext] NOT NULL,
 CONSTRAINT [PK_ELMAH_Error] PRIMARY KEY NONCLUSTERED 
(
	[ErrorId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Logs]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Logs](
	[Message] [nvarchar](2000) NOT NULL,
	[Created_Date] [datetime] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Message_History]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Message_History](
	[Account_Sid] [nvarchar](34) NOT NULL,
	[Body] [nvarchar](max) NULL,
	[Date_Created] [datetime] NULL,
	[Date_Sent] [datetime] NULL,
	[Date_Updated] [datetime] NULL,
	[Direction] [nvarchar](50) NULL,
	[Error_Code] [nvarchar](50) NULL,
	[Error_Message] [nvarchar](max) NULL,
	[From] [nvarchar](15) NULL,
	[Num_Images] [int] NULL,
	[Num_Segments] [int] NULL,
	[Price] [real] NULL,
	[Sid] [nvarchar](34) NULL,
	[API_Version] [nvarchar](10) NULL,
	[Status] [nvarchar](50) NULL,
	[To] [nvarchar](15) NULL,
	[IsActive] [bit] NULL,
	[IsReminderSent] [bit] NULL,
	[ISUndelieveredTagged] [bit] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Message_Sent]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Message_Sent](
	[Account_Sid] [nvarchar](34) NOT NULL,
	[Body] [nvarchar](max) NULL,
	[Date_Created] [datetime] NULL,
	[Date_Sent] [datetime] NULL,
	[Date_Updated] [datetime] NULL,
	[Direction] [nvarchar](50) NULL,
	[Error_Code] [nvarchar](50) NULL,
	[Error_Message] [nvarchar](max) NULL,
	[From] [nvarchar](15) NULL,
	[Num_Images] [int] NULL,
	[Num_Segments] [int] NULL,
	[Price] [real] NULL,
	[Sid] [nvarchar](34) NULL,
	[API_Version] [nvarchar](10) NULL,
	[Status] [nvarchar](50) NULL,
	[To] [nvarchar](15) NULL,
	[Duration] [bigint] NULL,
	[Language] [nvarchar](50) NULL,
	[Appointment_ID] [uniqueidentifier] NULL,
	[UndeliveredCount] [int] NULL,
	[CreatedDate] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PT_MessageArchive]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PT_MessageArchive](
	[Appt_ID] [uniqueidentifier] NOT NULL,
	[Duration] [int] NULL,
	[Status] [varchar](50) NULL,
	[Phone_Number] [varchar](15) NULL,
	[DateCreated] [datetime] NULL,
	[DateUpdated] [datetime] NULL,
	[Body] [varchar](500) NULL,
	[Sid] [varchar](34) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PT_TestMessageSentArchive]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PT_TestMessageSentArchive](
	[Body] [nvarchar](max) NULL,
	[Date_Created] [datetime] NULL,
	[Direction] [nvarchar](50) NULL,
	[From] [nvarchar](15) NULL,
	[Sid] [nvarchar](34) NULL,
	[Status] [nvarchar](50) NULL,
	[To] [nvarchar](15) NULL,
	[Duration] [bigint] NULL,
	[Appointment_ID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Twilo_Numbers]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Twilo_Numbers](
	[Numbers] [nvarchar](15) NULL,
	[Date] [datetime] NULL,
	[Count] [int] NULL,
	[MaxCount] [int] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[UndeliveredNos]    Script Date: 5/8/2017 1:29:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UndeliveredNos](
	[Cell_number] [nvarchar](50) NOT NULL,
	[Count] [int] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_ELMAH_Error_App_Time_Seq]    Script Date: 5/8/2017 1:29:49 PM ******/
CREATE NONCLUSTERED INDEX [IX_ELMAH_Error_App_Time_Seq] ON [dbo].[ELMAH_Error]
(
	[Application] ASC,
	[TimeUtc] DESC,
	[Sequence] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [_inx_Message_History_20150326_39B0252C]    Script Date: 5/8/2017 1:29:49 PM ******/
CREATE NONCLUSTERED INDEX [_inx_Message_History_20150326_39B0252C] ON [dbo].[Message_History]
(
	[IsActive] ASC,
	[IsReminderSent] ASC
)
INCLUDE ( 	[From],
	[Sid]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [_inx_Message_History_20150326_A706113D]    Script Date: 5/8/2017 1:29:49 PM ******/
CREATE NONCLUSTERED INDEX [_inx_Message_History_20150326_A706113D] ON [dbo].[Message_History]
(
	[Sid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [_inx_Message_History_20150409_A850E104]    Script Date: 5/8/2017 1:29:49 PM ******/
CREATE NONCLUSTERED INDEX [_inx_Message_History_20150409_A850E104] ON [dbo].[Message_History]
(
	[Status] ASC,
	[IsActive] ASC
)
INCLUDE ( 	[Body]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [_inx_Message_History_20150409_E0711FB0]    Script Date: 5/8/2017 1:29:49 PM ******/
CREATE NONCLUSTERED INDEX [_inx_Message_History_20150409_E0711FB0] ON [dbo].[Message_History]
(
	[ISUndelieveredTagged] ASC
)
INCLUDE ( 	[Date_Created],
	[Sid],
	[Status],
	[To]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [_inx_Message_History_20151210_0D81326C]    Script Date: 5/8/2017 1:29:49 PM ******/
CREATE NONCLUSTERED INDEX [_inx_Message_History_20151210_0D81326C] ON [dbo].[Message_History]
(
	[Direction] ASC
)
INCLUDE ( 	[Body],
	[Date_Created],
	[From]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [_inx_Message_History_20151210_BC3ADB4A]    Script Date: 5/8/2017 1:29:49 PM ******/
CREATE NONCLUSTERED INDEX [_inx_Message_History_20151210_BC3ADB4A] ON [dbo].[Message_History]
(
	[Date_Created] ASC
)
INCLUDE ( 	[To]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [_inx_Message_Sent_20150326_3DA46539]    Script Date: 5/8/2017 1:29:49 PM ******/
CREATE NONCLUSTERED INDEX [_inx_Message_Sent_20150326_3DA46539] ON [dbo].[Message_Sent]
(
	[To] ASC
)
INCLUDE ( 	[Language]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [_inx_Message_Sent_20150326_9DEECCD9]    Script Date: 5/8/2017 1:29:49 PM ******/
CREATE NONCLUSTERED INDEX [_inx_Message_Sent_20150326_9DEECCD9] ON [dbo].[Message_Sent]
(
	[Duration] ASC,
	[Appointment_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [_inx_Message_Sent_20150409_A7D244BF]    Script Date: 5/8/2017 1:29:49 PM ******/
CREATE NONCLUSTERED INDEX [_inx_Message_Sent_20150409_A7D244BF] ON [dbo].[Message_Sent]
(
	[Sid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_Message_Sent]    Script Date: 5/8/2017 1:29:49 PM ******/
CREATE NONCLUSTERED INDEX [IX_Message_Sent] ON [dbo].[Message_Sent]
(
	[Date_Created] ASC,
	[Status] ASC,
	[To] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_PT_MessageArchive_Status]    Script Date: 5/8/2017 1:29:49 PM ******/
CREATE NONCLUSTERED INDEX [IX_PT_MessageArchive_Status] ON [dbo].[PT_MessageArchive]
(
	[Status] ASC
)
INCLUDE ( 	[Appt_ID],
	[Duration]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ELMAH_Error] ADD  CONSTRAINT [DF_ELMAH_Error_ErrorId]  DEFAULT (newid()) FOR [ErrorId]
GO
ALTER TABLE [dbo].[Logs] ADD  CONSTRAINT [DF_Logs_Created_Date]  DEFAULT (getdate()) FOR [Created_Date]
GO
ALTER TABLE [dbo].[Message_History] ADD  CONSTRAINT [DF_Message_History_IsActive]  DEFAULT ((0)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Message_History] ADD  CONSTRAINT [DF_Message_History_IsReminderSent]  DEFAULT ((0)) FOR [IsReminderSent]
GO
ALTER TABLE [dbo].[Message_History] ADD  CONSTRAINT [DF_Message_History_ISUndelieveredTagged]  DEFAULT ((0)) FOR [ISUndelieveredTagged]
GO
ALTER TABLE [dbo].[Message_Sent] ADD  CONSTRAINT [DF_Message_Sent_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
USE [master]
GO
ALTER DATABASE [Appointment_reminder] SET  READ_WRITE 
GO
