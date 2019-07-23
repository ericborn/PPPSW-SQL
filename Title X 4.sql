/*******
--============================================= 
-- Author:    Eric Born 
-- Create date: 1 February 2016 
-- Last Modified: 10 January 2018
-- Description: CDS File generation for website upload to CFHC
--		Agency number hardcoded to 2524
--		Site ID | CV - 9034 | CH - 9085 | CO - 8068 | CA - 9030 | EC - 9028 | ES - 9027 | EA - 9014 | FA - 9026 |
--		| IV - 9999 | KM - 9029 | MM - 9033 | MB - 9031 | MO - 8036 | RM - 9020 | RS - 9021 | VS - 9032 |
--		Real site ID for IV is 252401 but NG only allows four digits in the field so we need to convert it within the report before submission
--		Filter out all encounters with an AB related DX or SIM code
--		Max patient ages collected f=55 m=60. Age calculated automatically based on DOB compared to service date
--		Homeless, substance abuse, migrant worker and disabled status are not collected by the organization so they are hard coded to 3 - unknown
--		Patients under 18 have family size set to 1 and income set to 0 per Title X report specs
-- Change log:
-- 01 June 2017    - Changed IV location within database to 9999 from previous Mission Bay value of 9031
				   - Database field only holds 4 characters so I created code to map 9999 to 252401 which is the value CFHC uses to recognize IV location
-- 10 January 2018 - Reverted to using XML multi-column combine that was removed several months prior.
				   - Removing this caused the comma seperated [med svces] list to break and only report 1 test instead of the actual number of test performed
-- 11 January 2018 - Added HIV test code 87806
-- 25 January 2018 - Updated race update to count multi-racial when race LIKE '%multi%' and unknown LIKE '%unkno%'
-- =============================================
********/

--drop table #temp1
--drop table #temp2
--drop table #demo
--drop table #dx
--drop table #e3
--drop table #test
--drop table #test2
--drop table #ct
--drop table #per

USE [ngprod]

--***Declare and set variables***
DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

SET @Start_Date_1 = '20180201'
SET @End_Date_1 = '20180228'

--select * from person
--where DATEDIFF(YY, date_of_birth, @Start_Date_1) > 60 

--**********Start data Table Creation***********
--***pp.delete_ind = 'n' added
--Creates list of all encounters, dx and SIM codes during time period
SELECT pp.enc_id, pe.enc_nbr, pp.person_id, CAST(p.person_nbr AS INT) AS [p_nbr], pm.specialty_code_1 AS [provider type], pm.[description] AS [provider],
       pp.diagnosis_code_id_1, pp.diagnosis_code_id_2, pp.diagnosis_code_id_3, pp.diagnosis_code_id_4, 
       pp.service_item_id, pp.service_date, pp.location_id, ml.mstr_list_item_desc AS 'LEP'
INTO #temp1
FROM patient_procedure pp
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN person	p			  ON pp.person_id = p.person_id
JOIN person_ud pu		  ON pu.person_id = p.person_id
JOIN mstr_lists ml		  ON ml.mstr_list_item_id = pu.ud_demo3_id
JOIN provider_mstr pm	  ON pe.rendering_provider_id = pm.provider_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1)
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.delete_ind = 'N'
AND ((DATEDIFF(YY, p.date_of_birth, @Start_Date_1) <= 60 AND p.sex = 'm') OR (DATEDIFF(YY, p.date_of_birth, @Start_Date_1) <= 55 AND p.sex = 'f'))
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND pp.location_id NOT IN ('966B30EA-F24F-48D6-8346-948669FDCE6E', '518024FD-A407-4409-9986-E6B3993F9D37', --Exclude Sterilization FASS, PPPSW, Lab
						   '595BD5A1-B989-4401-9D73-BC63F26B1E7C', '3A067539-F112-4304-931D-613F7C4F26FD', --Las Colinas Detention Facility, Clinical Services
						   '7E8F1E17-1FC5-4019-B510-B7D3EC453D82', '68C7DDB4-834A-4ABC-B3EB-87BF71D60F41', --Online Health Services, default location
						   '096B6FF0-ED48-4A6C-95F6-8D37E1474394', '9D971E61-2B5A-4504-9016-7FD863790EE2')

--Creates temp 2 and concatenates same encounters on multiple rows into a single with all service items 
SELECT enc_id, enc_nbr, person_id, [p_nbr], [provider type], [provider], location_id, t1.LEP, service_date,
	(SELECT ' ' + t2.service_item_id
	FROM #temp1 t2
	WHERE t2.enc_id = t1.enc_id
	FOR XML PATH('')) [Service_Item],
	(SELECT ' ' + t2.diagnosis_code_id_1 + ' ' + t2.diagnosis_code_id_2 + ' ' + t2.diagnosis_code_id_3 + ' ' + t2.diagnosis_code_id_4
	FROM #temp1 t2
	WHERE t2.enc_id = t1.enc_id
	FOR XML PATH('')) [dx]
INTO #temp2
FROM #temp1 t1
GROUP BY t1.enc_id, t1.enc_nbr, t1.person_id, t1.[p_nbr], [provider type], [provider], location_id, service_date, t1.LEP

--Remove all encounters that have any AB related SIM and DX codes
SELECT * 
INTO #dx
FROM #temp2
where service_item NOT LIKE '%s0199%' AND Service_Item NOT LIKE '%S0199A%' AND Service_Item NOT LIKE '%59840A%' AND Service_Item NOT LIKE '%59841[C-N]%' 
AND Service_Item NOT LIKE '%99214PME%' AND dx NOT LIKE '%Z64.0%' --AB SIM's and DX codes

--Grabs family size and income from latest encounter date
SELECT DISTINCT dx.person_id, fi.family_annual_income AS [income], fi.family_size_nbr AS [Family Size]
INTO #e3
FROM #dx dx
JOIN practice_person_family_info fi ON dx.person_id = fi.person_id
WHERE fi.modify_timestamp = (SELECT MAX(modify_timestamp)
							 FROM practice_person_family_info fi2
							 WHERE fi.person_id = fi2.person_id)

--Create table for converting tests into numeric values
CREATE TABLE #test
(
 [enc_id] UNIQUEIDENTIFIER
,[ct]	  VARCHAR(2)
,[gc]     VARCHAR(2)
,[hiv]    VARCHAR(2)
,[pap]    VARCHAR(2)
,[ec]     VARCHAR(2)
,[rpr]    VARCHAR(2)
,[test]   VARCHAR(20)
)

--insert all desired encounters from dx table into test table
--***Distinct added***
INSERT INTO #test(enc_id)
SELECT DISTINCT t2.enc_id
FROM #temp2 t2

--***obx.delete_ind = 'N' added***
SELECT DISTINCT
		 obx.person_id
		,nor.enc_id
		,obx.observ_value AS result	       	       
	INTO #ct
	FROM     lab_results_obx obx
		JOIN lab_results_obr_p obr  ON obx.unique_obr_num	= obr.unique_obr_num
		JOIN lab_nor nor			ON obr.ngn_order_num	= nor.order_num
		JOIN lab_order_tests lot	ON nor.order_num		= lot.order_num  
		JOIN #temp2 t2				ON nor.enc_id			= t2.enc_id 
	WHERE 
		obx.person_id = t2.person_id 
	AND nor.enc_id = t2.enc_id      
	AND obx.result_desc = 'CT'
	AND obx.delete_ind = 'N'

--Main demographics table
--DATEADD used to converted all dob to the 1st of the month, CONVERT used to change date/time to just date in YYYYMMDD format
--***Patient number replicate 0's added
SELECT DISTINCT 
		 t2.enc_id
		,t2.enc_nbr
		,[agency nbr] = 2524
		,CASE 
			WHEN lm.site_id = '9999' THEN '252401' --Added to fix location ID for Imperial Valley since DB field only holds 4 characters
			ELSE lm.site_id
		 END AS [site nbr]
		--,'patient nbr' = '' --left blank to be converted with padded 0's
		,[patient nbr] = REPLICATE('0',9-LEN([p_nbr])) + CAST([p_nbr] AS VARCHAR)
		,[date of birth] = CONVERT(VARCHAR(8), DATEADD(MONTH, DATEDIFF(MONTH, 0, per.date_of_birth), 0), 112) --converted to 1st of birth month
		,[TX Gender] = per.sex
		,[TX Race] = per.race
		,[TX Ethnicity] = per.ethnicity
		,[TX Fam Size] = e.[family size]
		,[end BCM] = im.txt_birth_control_visitend
		,[TX Income] = e.[income] --********Divide by 12***********
		,[date of visit] = t2.service_date
		,[med svces] = NULL --left null to be updated by comma seperated list of values
		,[prov of svces] = '' --converted from provider type to numerical value by an update
		,[limited english proficiency] = t2.LEP
		,[insurance status] = '' --converted from type of insurance to numberical value
		,[TX Homeless Status] = 3 --3 is unknown as it is uncollected for the following 4 items
		,[TX Substance Abuse Status] = 3
		,[TX Migrant Worker Status] = 3
		,[TX Disabled Status] = 3
		,[TX Zip] = per.zip
		,[CT result] = '' --updated from #ct table
INTO #demo
FROM #temp2 t2
JOIN person per		  ON per.person_id	= t2.person_id
JOIN master_im_ im	  ON im.enc_id		= t2.enc_id
JOIN location_mstr lm ON lm.location_id = t2.location_id
JOIN #e3 e			  ON e.person_id	= t2.person_id

--Med services column altered to accommodate data from comma seperated list created below
ALTER TABLE #demo 
ALTER COLUMN [med svces] VARCHAR(20) --altered to allow for comma seperated service list to be inserted

--race
UPDATE #demo 
SET [TX Race] =
CASE
	WHEN [TX Race] LIKE '1-%' THEN 1 --white
	WHEN [TX Race] LIKE '2-%' THEN 2 --african
	WHEN [TX Race] LIKE '3-%' THEN 3 --asian
	WHEN [TX Race] LIKE '4-%' THEN 4 --pacific islander
	WHEN [TX Race] LIKE '5-%' THEN 5 --native american
	WHEN [TX Race] LIKE '%multi%' THEN 6 --More than one race
	WHEN [TX Race] LIKE '7-%' THEN 7 --other
	WHEN [TX Race] LIKE '%unkno%' THEN 8 --unknown
	ELSE 8 --convert all others to unknown
END
from #demo

--Ethnicity
UPDATE #demo
SET [TX Ethnicity] =
CASE 
	WHEN [TX Ethnicity] = 'Hispanic or Latino' THEN 1 --hispanic
	WHEN [TX Ethnicity] = 'Not Hispanic or Latino' THEN 2 --non-hispanic
	ELSE 3 --unknown
END
FROM #demo

--Update family size 1 and income 0 if patient less than 18 per Title X document 
--***Age calculated from DOB compared to visit date added***
UPDATE #demo
SET [TX Fam Size] =
CASE
	WHEN DATEDIFF(YY, [date of birth], [date of visit]) < 18 THEN 1
	ELSE [TX Fam Size]
END
FROM #demo

UPDATE #demo
SET [TX income] =
CASE
	WHEN DATEDIFF(YY, [date of birth], [date of visit]) < 18 THEN 0
	ELSE [TX income]
END
FROM #demo

--BCM at end of visit
--Female only methods as defined by CDS are signifed by a check against gender
--Any male found with one of those methods is converted to "other" to avoid file rejection
UPDATE #demo
SET [end BCM] =
CASE
	WHEN [end BCM] = 'Abstinence'									THEN 1
	WHEN [TX gender] = 'F' AND [end BCM] = 'Sponge'					THEN 2
	WHEN [TX gender] = 'F' AND [end BCM] = 'Cervical cap/Diaphragm'	THEN 3
	WHEN [TX gender] = 'F' AND [end BCM] = 'Female Condom'			THEN 4
	WHEN [TX gender] = 'F' AND [end BCM] = 'Female Sterilization'	THEN 5
	WHEN [end BCM] = 'FAM/NFP'										THEN 6
	WHEN [TX gender] = 'F' AND [end BCM] = 'Implant'				THEN 7
	WHEN [TX gender] = 'F' AND [end BCM] = 'Injection'				THEN 9
	WHEN [TX gender] = 'F' AND [end BCM] = 'Patch'					THEN 10
	WHEN [TX gender] = 'F' AND [end BCM] = 'IUC (Copper)'			THEN 11
	WHEN [TX gender] = 'F' AND [end BCM] = 'IUC (Levonorgestrel)'	THEN 11
	WHEN [end BCM] = 'Male Condom'									THEN 12
	WHEN [TX gender] = 'F' AND [end BCM] = 'Oral (CHC)'				THEN 13
	WHEN [TX gender] = 'F' AND [end BCM] = 'Oral (POP)'				THEN 13
	WHEN [TX gender] = 'F' AND [end BCM] = 'Spermicide'				THEN 14
	WHEN [TX gender] = 'F' AND [end BCM] = 'Ring'					THEN 15
	WHEN [end BCM] = 'Vasectomy'									THEN 16
	WHEN [end BCM] = 'Other Method'									THEN 17
	WHEN [end BCM] = 'Pregnant/Partner Pregnant'					THEN 18
	WHEN [end BCM] = 'Partner Method'								THEN 19 --Relying on partner/female method
	WHEN [end BCM] = 'No Method'									THEN 20
	WHEN [end BCM] = 'Infertile'									THEN 20 --None - Other reason/same sex partner
	WHEN [end BCM] = 'Same sex partner'								THEN 20 --None - Other reason/same sex partner
	WHEN [end BCM] IS NULL											THEN 20 --No method (unknown is no longer an option per CDS)
	WHEN [end BCM] = 'Seeking pregnancy'							THEN 22
	WHEN [TX gender] = 'M' AND [end BCM] IN ('Sponge','Cervical cap/Diaphragm','Female Condom','Female Sterilization','Implant','Injection'
											,'Patch','IUC (Copper)','IUC (Levonorgestrel)','Oral (CHC)','Oral (POP)','Spermicide','Ring') THEN 19
											--Relying on partner/female method
	ELSE 20
END
from #demo

--Limited english proficiency
UPDATE #demo
SET [limited english proficiency] = 
CASE
	WHEN [limited english proficiency] = '1-Yes' THEN 2 --1-Yes proficent in english in our system, 2 in CDS
	WHEN [limited english proficiency] = '2-No'  THEN 1 --2-not proficent in english in our system, 1 in CDS
	ELSE 2
END
FROM #demo

--***L031 Added***
UPDATE #test
SET ct =  
CASE
	WHEN Service_Item LIKE '%87491%'  THEN '3'  --CT 
	WHEN Service_Item LIKE '%L031%' THEN '3'
	WHEN Service_Item LIKE '%L069%' THEN '3'
	WHEN Service_Item LIKE '%L071%' THEN '3'
	WHEN Service_Item LIKE '%L073%' THEN '3' 
	WHEN Service_Item LIKE '%L103%' THEN '3'
	WHEN Service_Item LIKE '%L104%' THEN '3'
	WHEN Service_Item LIKE '%L105%' THEN '3'
	ELSE ''
END
FROM #temp2 t2
JOIN #test t ON t.enc_id = t2.enc_id

--***Added L071, L073, L103, L104, L105***
UPDATE #test
SET gc =
CASE
	WHEN Service_Item LIKE '%87591%'  THEN '5' --gc
	WHEN Service_Item LIKE '%L029%'   THEN '5'
	WHEN Service_Item LIKE '%L070%'   THEN '5'
	WHEN Service_Item LIKE '%L071%'   THEN '5'
	WHEN Service_Item LIKE '%L073%'   THEN '5'
	WHEN Service_Item LIKE '%L103%'   THEN '5'
	WHEN Service_Item LIKE '%L104%'   THEN '5'
	WHEN Service_Item LIKE '%L105%'   THEN '5'
	ELSE ''
END
FROM #temp2 t2
JOIN #test t ON t.enc_id = t2.enc_id

--Added code 87806 for Rapid HIV test
UPDATE #test
SET hiv =  
CASE
	WHEN Service_Item LIKE '%86703%' THEN '6' --HIV
	WHEN Service_Item LIKE '%87806%' THEN '6'
	WHEN Service_Item LIKE '%L023%'  THEN '6'
	WHEN Service_Item LIKE '%L099%'  THEN '6'
	ELSE ''
END
FROM #temp2 t2
JOIN #test t ON t.enc_id = t2.enc_id

UPDATE #test
SET pap =  
CASE
	WHEN Service_Item LIKE '%L079%'   THEN '8'--PAP
	WHEN Service_Item LIKE '%L034%'   THEN '8'--Thin prep
	WHEN Service_Item LIKE '%L124%'   THEN '8'--Thin prep
	ELSE ''
END
FROM #temp2 t2
JOIN #test t ON t.enc_id = t2.enc_id

UPDATE #test
SET ec =  
CASE
	WHEN Service_Item LIKE '%ELLA%'		THEN '11' --EC
	WHEN Service_Item LIKE '%NEXT%'		THEN '11'
	WHEN Service_Item LIKE '%X7722%'	THEN '11'
	WHEN Service_Item LIKE '%X722-INS%' THEN '11'
	WHEN Service_Item LIKE '%X722-PT%'  THEN '11'
	WHEN Service_Item LIKE '%ECONTRA%'  THEN '11'
	WHEN Service_Item LIKE '%plan b%'   THEN '11'
	ELSE ''
END
FROM #temp2 t2
JOIN #test t ON t.enc_id = t2.enc_id

--***Changed incorrect code from L099 to L026***
UPDATE #test
SET rpr =  
CASE
	WHEN Service_Item LIKE '%L026%' THEN '12' --RPR
	ELSE ''
END
FROM #temp2 t2
JOIN #test t ON t.enc_id = t2.enc_id

--Table created to combine all patient tests into a comma seperated list
select t.enc_id,
stuff(
   (
	coalesce(', ' + NULLIF(t.ct, ''), '') +
	coalesce(', ' + NULLIF(t.gc, ''), '') +
	coalesce(', ' + NULLIF(t.hiv, ''), '')+
	coalesce(', ' + NULLIF(t.pap, ''), '')+
	coalesce(', ' + NULLIF(t.ec, ''), '') +
	coalesce(', ' + NULLIF(t.rpr, ''), '')
   ), 1, 1, '') AS test
INTO #test2
from #test t

--drop table #test2
--select * from #test2
--Insert comma seperated list back into main temp table
update #demo 
SET [med svces] = test
FROM #test2 t
WHERE #demo.enc_id = t.enc_id

--insurance 1 public, 2 private, 3 cash/uninsured
--***Start fin class*** 
UPDATE #demo
SET [insurance status] = 1
WHERE #demo.enc_id IN
(
	select pe.enc_id
	FROM patient_encounter pe
	JOIN #demo d ON d.enc_id = pe.enc_id
	JOIN payer_mstr pm		ON pe.cob1_payer_id = pm.payer_id
	WHERE (pm.financial_class = '484A05B3-D5C8-415B-A8EE-3D14A7AF11D6'  --Medi-Cal Managed Care-4130
	OR	   pm.financial_class = 'C5BDDA12-DDC9-4CFF-A0A3-9749C7DD353D')  --Medi-Cal-4120
	--OR	   pm.financial_class = 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF') --Family PACT-4110
	AND pe.enc_id = d.enc_id
) 

UPDATE #demo
SET [insurance status] = 2
WHERE #demo.enc_id IN
(
	select pe.enc_id
	FROM patient_encounter pe
	JOIN #demo d ON pe.enc_id = d.enc_id
	JOIN payer_mstr pm		ON pe.cob1_payer_id = pm.payer_id
	WHERE (pm.financial_class = '8E5D6C7E-A34E-4B3C-8C0A-B2F1D2E20285' --Commercial Ins Exchange-4330
	OR	   pm.financial_class = '332DF613-7C43-4287-9050-9949B4142B0C')--Commercial Ins Non-Exchange-4310
	AND pe.enc_id = d.enc_id
) 

UPDATE #demo
SET [insurance status] = 3
WHERE #demo.enc_id IN
(
	select pe.enc_id
	FROM patient_encounter pe
	JOIN #demo d ON d.enc_id = pe.enc_id
	JOIN payer_mstr pm		ON pe.cob1_payer_id = pm.payer_id
	WHERE (pm.financial_class = 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF') --Family PACT-411030   
	AND pe.enc_id = d.enc_id
) 

UPDATE #demo
SET [insurance status] = 3
WHERE #demo.enc_id IN
(
	SELECT d.enc_id 
	FROM #demo d
	WHERE d.[insurance status] != 1 
	AND d.[insurance status] != 2 
)
--***End fin class*** 

--***Start CT reults***
--Sets ct result to 1 for positive and 0 for negative test results in the #ct table
UPDATE #demo
SET [CT result] = 
CASE
	WHEN ct.result = 'POSITIVE' THEN 1
	WHEN ct.result = 'negative' THEN 0
	ELSE ''
END
FROM #ct ct
JOIN #demo d ON ct.enc_id = d.enc_id
--***End CT reults***

UPDATE #demo
SET [prov of svces] =
CASE 
	WHEN t2.[provider type] = 'MD' THEN 1
	ELSE 2 
END
FROM #temp2 t2
JOIN #demo d ON t2.enc_id = d.enc_id 

DELETE FROM #demo
WHERE [site nbr] = ''

--ALTER TABLE #demo
--DROP COLUMN enc_id, enc_nbr, [ct result]

DELETE FROM #demo
WHERE enc_id IN
(
SELECT d.enc_id 
FROM #demo d
JOIN patient_procedure pp on pp.enc_id = d.enc_id
where service_item_ID LIKE '%s0199%' OR service_item_ID  LIKE '%S0199A%' OR service_item_ID LIKE '%59840A%' OR service_item_ID LIKE '%59841[C-N]%' 
AND service_item_ID  LIKE '%99214PME%'
)

--***Output desired report columns only***
SELECT [agency nbr], [site nbr], [patient nbr], [date of birth], [TX Gender], [TX Race], [TX Ethnicity], [TX Fam Size], [end BCM], [TX Income]
,[date of visit], [med svces], [prov of svces], [limited english proficiency], [insurance status], [TX Homeless Status], [TX Substance Abuse Status], [TX Migrant Worker Status]
,[TX Disabled Status], [TX Zip]
FROM #demo

--***Create for questions that are required for semi and annual reporting but not submitted through the file upload
--MA/RN visit count by location
--SELECT COUNT(DISTINCT t.enc_id) as 'Count', location_name
--FROM #temp1 t
--JOIN #demo d ON d.enc_id = t.enc_id
--JOIN patient_encounter pe ON pe.enc_id = t.enc_id
--JOIN location_mstr lm ON lm.location_id = pe.location_id
--WHERE service_item_id != '99211' --Office/outpatient visit,est, min
--AND service_item_id != '99211PSV' --Post Surgical AB Visit-NO EXAM
--AND (service_item_id LIKE '99211%' --MA/RN
--OR   service_item_id LIKE '99499%') --refill
--AND pe.location_id NOT IN ('966B30EA-F24F-48D6-8346-948669FDCE6E', '518024FD-A407-4409-9986-E6B3993F9D37', --Exclude Sterilization FASS, PPPSW, Lab
--						   '595BD5A1-B989-4401-9D73-BC63F26B1E7C', '3A067539-F112-4304-931D-613F7C4F26FD', --Las Colinas Detention Facility, Clinical Services
--						   '7E8F1E17-1FC5-4019-B510-B7D3EC453D82', '68C7DDB4-834A-4ABC-B3EB-87BF71D60F41', --Online Health Services, default location
--						   '096B6FF0-ED48-4A6C-95F6-8D37E1474394', '9D971E61-2B5A-4504-9016-7FD863790EE2')
--GROUP BY location_name
--ORDER BY location_name

--Licensed visit count by location
--Doesnt work correctly, use all encounters by location and minus MA/RN to get licensed encounters
--SELECT COUNT(DISTINCT t.enc_id) as 'Count', location_name
--FROM #temp1 t
--JOIN #demo d ON d.enc_id = t.enc_id
--JOIN patient_encounter pe ON pe.enc_id = t.enc_id
--JOIN location_mstr lm ON lm.location_id = pe.location_id
--WHERE service_item_id NOT LIKE '99211%' --MA/RN
--AND service_item_id NOT LIKE  '99499%' --refill
--GROUP BY location_name
--ORDER BY location_name

--All encounters
--SELECT COUNT(DISTINCT t.enc_id) as 'Count', location_name
--FROM #temp1 t
--JOIN #demo d ON d.enc_id = t.enc_id
--JOIN patient_encounter pe ON pe.enc_id = t.enc_id
--JOIN location_mstr lm ON lm.location_id = pe.location_id
--WHERE pe.location_id NOT IN ('966B30EA-F24F-48D6-8346-948669FDCE6E', '518024FD-A407-4409-9986-E6B3993F9D37', --Exclude Sterilization FASS, PPPSW, Lab
--						   '595BD5A1-B989-4401-9D73-BC63F26B1E7C', '3A067539-F112-4304-931D-613F7C4F26FD', --Las Colinas Detention Facility, Clinical Services
--						   '7E8F1E17-1FC5-4019-B510-B7D3EC453D82', '68C7DDB4-834A-4ABC-B3EB-87BF71D60F41', --Online Health Services, default location
--						   '096B6FF0-ED48-4A6C-95F6-8D37E1474394', '9D971E61-2B5A-4504-9016-7FD863790EE2')
--GROUP BY location_name
--ORDER BY location_name

--Total encounter count
--SELECT count (DISTINCT enc_id)
--from #demo