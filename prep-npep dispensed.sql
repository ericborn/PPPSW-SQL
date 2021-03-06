USE [ppreporting]
GO
/****** Object:  StoredProcedure [dbo].[Prep_Npep_dispensed]    Script Date: 3/28/2018 8:33:27 AM ******/
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

ALTER proc [dbo].[Prep_Npep_dispensed]
(
	@Start_Date DATETIME, -- Start of date range 
	@End_Date DATETIME	-- End of date range 
)

AS

--drop table #out

--***Declare and set variables***
--DECLARE @Start_Date datetime
--DECLARE @End_Date Datetime

--SET @Start_Date = '20150101'
--SET @End_Date = '20180328'

CREATE TABLE #out
(
 [enc_id] UNIQUEIDENTIFIER
,[loc_name] VARCHAR(100)
,[insurance] VARCHAR(100)
,[DOS] DATE
,[MRN] VARCHAR(100)
,[truvada] VARCHAR(1)
,[tivicay] VARCHAR(1)
,[isentress] VARCHAR(1)
)

--**********Start data Table Creation***********
INSERT INTO #out
SELECT DISTINCT pe.enc_id, lm.location_name
,CASE 
	WHEN pay.payer_name IS NULL THEN 'Cash'
	ELSE pay.payer_name
 END
,pp.service_date
,SUBSTRING(pt.med_rec_nbr, PATINDEX('%[^0]%', pt.med_rec_nbr+'.'), LEN(pt.med_rec_nbr))
,NULL,NULL,NULL --Meds
FROM NGProd.dbo.patient_procedure pp
JOIN NGProd.dbo.patient_encounter pe   ON pp.enc_id = pe.enc_id
JOIN NGProd.dbo.person	p			   ON pp.person_id = p.person_id
JOIN NGProd.dbo.patient pt			   ON pt.person_id = pp.person_id
JOIN Ngprod.dbo.patient_medication pam ON pam.enc_id = pp.enc_id
JOIN Ngprod.dbo.provider_mstr pm	   ON pm.provider_id = pp.provider_id
JOIN Ngprod.dbo.location_mstr lm	   ON lm.location_id = pp.location_id
LEFT JOIN Ngprod.dbo.payer_mstr pay		   ON pay.payer_id = pe.cob1_payer_id
WHERE (pp.service_date >= @Start_Date AND pp.service_date <= @End_Date)
AND pp.delete_ind = 'N'
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --Clinical services and Lab locations are excluded
AND (medication_name LIKE '%truvada%' OR medication_name LIKE '%tivicay%' OR medication_name LIKE '%isentress%')

UPDATE #out
SET [truvada] = 'Y'
WHERE enc_id IN
(SELECT pm.enc_id
FROM Ngprod.dbo.patient_medication pm
JOIN #out o ON pm.enc_id = o.enc_id 
WHERE medication_name LIKE '%truvada%')

UPDATE #out
SET [tivicay] = 'Y'
WHERE enc_id IN
(SELECT pm.enc_id
FROM Ngprod.dbo.patient_medication pm
JOIN #out o ON pm.enc_id = o.enc_id 
WHERE medication_name LIKE '%tivicay%')

UPDATE #out
SET [isentress] = 'Y'
WHERE enc_id IN
(SELECT pm.enc_id
FROM Ngprod.dbo.patient_medication pm
JOIN #out o ON pm.enc_id = o.enc_id 
WHERE medication_name LIKE '%isentress%')

ALTER TABLE #out
DROP COLUMN enc_id

SELECT * FROM #out
ORDER BY [loc_name]