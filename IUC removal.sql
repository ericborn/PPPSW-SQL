USE [ppreporting]
GO
/****** Object:  StoredProcedure [dbo].[IUC_Removal]    Script Date: 3/28/2018 7:52:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----============================================= 
---- Author:    Eric Born 
---- Create date: 28 March 2018
---- Last Modified:
---- Description: Audit for IUC Removal

---- Change log:
---- 
---- =============================================

ALTER proc [dbo].[IUC_Removal]
(
	@Start_Date DATETIME, -- Start of date range 
	@End_Date DATETIME	-- End of date range 
)

AS

--drop table #out


--***Declare and set variables***
--DECLARE @Start_Date_1 datetime
--DECLARE @End_Date_1 Datetime

--SET @Start_Date_1 = '20180101'
--SET @End_Date_1 = '20180130'

CREATE TABLE #out
(
 [loc_name] VARCHAR(100)
,[provider] VARCHAR(100)
,[DOS] DATE
,[MRN] VARCHAR(100)
,[Removed/w] VARCHAR(50)
,[Strings_vis] VARCHAR(1)
)

--**********Start data Table Creation***********
INSERT INTO #out
SELECT DISTINCT lm.location_name, pm.description, pp.service_date
,SUBSTRING(pt.med_rec_nbr, PATINDEX('%[^0]%', pt.med_rec_nbr+'.'), LEN(pt.med_rec_nbr))
,CASE--Removed with
	WHEN txt_removed_with IS NOT NULL THEN txt_removed_with
	ELSE '0'
 END --Removed with
,CASE --Strings visible
	WHEN opt_strings = 1 THEN 'N'
	WHEN opt_strings = 2 THEN 'Y'
	ELSE '0'
END --Strings visible

--INTO #temp1
FROM NGProd.dbo.patient_procedure pp
JOIN NGProd.dbo.patient_encounter pe  ON pp.enc_id = pe.enc_id
JOIN NGProd.dbo.person	p			  ON pp.person_id = p.person_id
JOIN NGProd.dbo.patient pt			  ON pt.person_id = pp.person_id
JOIN Ngprod.dbo.Proc_IUD_ i			  ON i.enc_id = pp.enc_id
JOIN Ngprod.dbo.provider_mstr pm	  ON pm.provider_id = pp.provider_id
JOIN Ngprod.dbo.location_mstr lm	  ON lm.location_id = pp.location_id
WHERE (pp.service_date >= @Start_Date AND pp.service_date <= @End_Date)
AND pp.delete_ind = 'N'
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --Clinical services and Lab locations are excluded
AND service_item_id = '58301'

SELECT * FROM #out