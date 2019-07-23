--******ADD CODE TO CHECK THAT CONSENT IS PRESENT*******

/* CHANGE HISTORY

-- Date			Author			Version				Description
-- 3/23/2018	Tim Newman		1.0					Created

*/


-------------------------------------------------------------------------------------------------------------------------
--Output file configuration
-------------------------------------------------------------------------------------------------------------------------
--DECLARE @SQL_STRING nvarchar(max)

--BEGIN
		
--		--Output Folder for ODS Extraction 
--		DECLARE @Output_Folder varchar(100)	
--		SET @Output_Folder	= 'E:\Press Ganey'					--Put in path to Files Directory here.
		
		
--END 

--DROP TABLE #t
--DROP TABLE PRESSGANEY

CREATE TABLE #t
(
 [person_id] UNIQUEIDENTIFIER
,[Designator] VARCHAR(6)
,[Client_ID] VARCHAR(5)
,[Last_Name] VARCHAR(50)
,[Middle_Name] VARCHAR(1)
,[First_Name] VARCHAR(50)
,[address1] VARCHAR(50)
,[address2] VARCHAR(50)
,[city] VARCHAR(50)
,[state] VARCHAR(50)
,[zip] VARCHAR(9)
,[Telephone] VARCHAR(10)
,[Mobile] VARCHAR(10)
,[Gender] VARCHAR(1)
,[DOB] VARCHAR(8)
,[Language] VARCHAR(1)
,[Med_Rec_Nbr] VARCHAR(20)
,[Unique_ID] INT --person number
,[Location_Code] VARCHAR(10)
,[Location_Name] VARCHAR(50)
,[NPI] VARCHAR(10)
,[Physician] VARCHAR(50)
,[VisitDate] DATE
,[DischargeDate] DATE
,[email] VARCHAR(50)
,[EOR] VARCHAR(1)
)
--select * from #t
--***Declare and set variables***
DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

SET @Start_Date_1 = '20180409'
SET @End_Date_1 = '20180409'

--***Addresses hard coded to NULL for patient confidentiality***
--***Phone coded to NULL until text invites are enabled***
INSERT INTO #t
SELECT DISTINCT 
 pp.person_id
,CASE --Designator
	WHEN service_item_id IN ('59840A', '59841C', '59841D', '59841E', '59841F', '59841G', '59841H'
						    ,'59841I', '59841J', '59841K', '59841L', '59841M', '59841N') 
	THEN 'MD0101' --TAB
	ELSE 'MD0102' --All other
END 
,'30191' --Client ID
,p.last_name
,LEFT(p.middle_name, 1)
,p.first_name
,NULL --p.address_line_1
,NULL --p.address_line_2
,NULL --p.city
,NULL --p.state
,LEFT(p.zip, 5)
,NULL --day_phone --home phone
,NULL --day_phone --cell phone
,CASE --gender
	WHEN p.sex = 'm' THEN '1'
	WHEN p.sex = 'f' THEN '2'
	ELSE 'M'
END
,p.date_of_birth
,CASE --Language
	WHEN language LIKE '%english%' THEN 0
	WHEN language LIKE '%spanish%' THEN 1
	WHEN language = 'Albanian' THEN 57  
	WHEN language = 'Arabic' THEN 22  
	WHEN language = 'French' THEN 20  
	WHEN language = 'Portuguese' THEN 47 
	WHEN language = 'Armenian' THEN 31  
	WHEN language = 'German' THEN 4  
	WHEN language = 'Punjabi' THEN 54 
	WHEN language = 'Bengali' THEN 60  
	WHEN language = 'Greek' THEN 7  
	WHEN language = 'Romanian' THEN 55 
	WHEN language = 'Bosnian' THEN 50  
	WHEN language = 'Haitian-Creole' THEN 36  
	WHEN language = 'Russian' THEN 3 
	WHEN language = 'Bosnian-Croatian' THEN 49  
	WHEN language = 'Hebrew' THEN 37  
	WHEN language = 'Samoan' THEN 25 
	WHEN language = 'Bosnian-Muslim' THEN 48  
	WHEN language = 'Hindi' THEN 38  
	WHEN language = 'Serbian' THEN 51 
	WHEN language = 'Bosnian-Serbian'  THEN 32  
	WHEN language = 'Hmong' THEN 26  
	WHEN language = 'Somali' THEN 27 
	WHEN language = 'Cambodian' THEN 34  
	WHEN language = 'Ilocano' THEN 56  
	WHEN language = 'Chao-Chou' THEN 41  
	WHEN language = 'Indonesian' THEN 42  
	WHEN language = 'Swahili' THEN 45 
	WHEN language = 'Chinese' THEN 12  
	WHEN language = 'Italian' THEN 5  
	WHEN language = 'Tagalog' THEN 30  
	WHEN language = 'Japanese' THEN 28  
	WHEN language = 'Thai' THEN 46 
	WHEN language = 'Chuukese' THEN 23  
	WHEN language = 'Korean' THEN 29  
	WHEN language = 'Turkish' THEN 53 
	WHEN language = 'Creole' THEN 21  
	WHEN language = 'Laotian' THEN 43  
	WHEN language = 'Urdu' THEN 39 
	WHEN language = 'Croatian' THEN 52  
	WHEN language = 'Malayan' THEN 44  
	WHEN language = 'Vietnamese' THEN 13 
	WHEN language = 'Malayalam' THEN 58  
	WHEN language = 'Yiddish' THEN 40 
	WHEN language = 'Marshallese' THEN 24  
	WHEN language = 'Farsi' THEN 59  
	WHEN language = 'Polish' THEN 6 
	ELSE 0
END
,SUBSTRING(pt.med_rec_nbr, PATINDEX('%[^0]%', pt.med_rec_nbr+'.'), LEN(pt.med_rec_nbr)) --MRN
,person_nbr
,lm.national_provider_id --location code
,lm.location_name
,pm.national_provider_id --NPI
,pm.last_name + ' ' + pm.first_name --Provider name
,pp.service_date --visit date
--,convert(VARCHAR(5), pe.checkin_datetime, 108) --visit time
,pp.service_date --discharge date
,p.email_address
,'$' --End of Record
FROM NGProd.dbo.patient_procedure pp
JOIN NGProd.dbo.patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN NGProd.dbo.person p			 ON pp.person_id = p.person_id
JOIN NGProd.dbo.patient pt			 ON pt.person_id = p.person_id
JOIN NGProd.dbo.location_mstr lm	 ON lm.location_id = pe.location_id
JOIN NGProd.dbo.provider_mstr pm	 ON pm.provider_id = pp.provider_id
JOIN NGProd.dbo.patient_documents pd ON pd.enc_id = pe.enc_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1)
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --Clinical services and Lab locations are excluded
AND p.email_address IS NOT NULL --Can be commented out once we move to text instead of email
AND pd.document_desc LIKE '%text msg%' --Consent name needs to be changed to new consent or a check 
									   --Needs to be created that looks for new consent after x date

UPDATE #T
SET [Location_Name] = REPLACE([Location_Name], 'Planned Parenthood','')

UPDATE #T
SET [Location_Name] = REPLACE([Location_Name], 'Planned Parent','')

UPDATE #T
SET [Location_Name] = REPLACE([Location_Name], 'Planned Pare','')

UPDATE #T
SET [Location_Name] = REPLACE([Location_Name], 'services','');

--drop table cte

WITH cte AS (
     SELECT DISTINCT t.[person_id], t.[Designator]
,t.[Client_ID],t.[Last_Name],t.[Middle_Name],t.[First_Name],t.[address1],t.[address2]
,t.[city],t.[state],t.[zip],t.[Telephone],t.[Mobile],t.[Gender],t.[DOB],t.[Language],t.[Med_Rec_Nbr] ,t.[Unique_ID]
,t.[Location_Code],t.[Location_Name],t.[NPI],t.[Physician],t.[VisitDate],t.[DischargeDate],t.[email],t.[EOR],
             ROW_NUMBER() OVER (PARTITION BY last_name, first_name, dob, visitDate ORDER BY last_name, first_name, dob, visitDate DESC) AS seqnum  
     FROM #t t
     
    )
SELECT t.[Designator]
,t.[Client_ID],t.[Last_Name],t.[Middle_Name],t.[First_Name],t.[address1],t.[address2]
,t.[city],t.[state],t.[zip],t.[Telephone],t.[Mobile],t.[Gender],t.[DOB],t.[Language],t.[Med_Rec_Nbr] ,t.[Unique_ID]
,t.[Location_Code],t.[Location_Name],t.[NPI],t.[Physician],t.[VisitDate],t.[DischargeDate],t.[email],t.[EOR]
INTO PressGaney
FROM cte t
WHERE seqnum = 1

SELECT * FROM PressGaney

--Used to build provider mapping table for Press Ganey file
--SELECT DISTINCT pm.national_provider_id, SUBSTRING(pm.last_name, 1, LEN(pm.last_name)-3) + ', ' + pm.first_name AS [name]
--,NULL,
--CASE
--	WHEN specialty_code_1 = 'RN' THEN 'Registered Nurse'
--	WHEN specialty_code_1 = 'NP' THEN 'Nurse Practitioner'
--	WHEN specialty_code_1 = 'MD' THEN 'Physician'
--	WHEN specialty_code_1 = 'CNM' THEN 'Midwife'
--	WHEN specialty_code_1 = 'PA' THEN 'Physician Assistant'
--	ELSE specialty_code_1
--END
--	,NULL,pm.first_name + ' ' + SUBSTRING(pm.last_name, 1, LEN(pm.last_name)-3)
--FROM provider_mstr pm
--JOIN #out o ON o.NPI = pm.national_provider_id
--ORDER BY [name]