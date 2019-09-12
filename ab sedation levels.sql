/* Level 6a */
DECLARE @57 INT
--First trimester surgical abortion (moderate sedation)  
;with AB2 AS (
SELECT service_item_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
--INTO #ab2
FROM patient_encounter pe
LEFT JOIN PP_Anesthesia_ ppa
 ON ppa.enc_id = pe.enc_id
LEFT JOIN AB_Procedure_ abp
 ON abp.enc_id = pe.enc_id
JOIN person p ON pe.person_id = p.person_id
JOIN patient_procedure pp ON pe.enc_id = pp.enc_id
WHERE (pe.enc_timestamp >= '20151001' AND pe.enc_timestamp <= '20160930')
AND p.sex = 'F' 
AND service_item_id IN ('59840','59841','59840AMD','59840A','59841C','59841CMD','59841D','59841DMD')
AND (ISNULL(ppa.anesthesia_type,'') IN ('','Minimal sedation','IM sedation','IV sedation - moderate') OR ISNULL(abp.txt_sed_procedure,'') IN ('','_IV Sedation'))
)
SELECT @57 = COUNT(*)
FROM AB2
WHERE RN = 1

SELECT @57

select * from #ab2 where rn = 1

/* Level 6a */
DECLARE @57 INT
--First trimester surgical abortion (moderate sedation)  
;with AB2 AS (
SELECT service_item_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM patient_encounter pe
LEFT JOIN PP_Anesthesia_ ppa
 ON ppa.enc_id = pe.enc_id
LEFT JOIN AB_Procedure_ abp
 ON abp.enc_id = pe.enc_id
JOIN person p ON pe.person_id = p.person_id
JOIN patient_procedure pp ON pe.enc_id = pp.enc_id
WHERE (pe.enc_timestamp >= '20151001' AND pe.enc_timestamp <= '20160930')
AND p.sex = 'F' 
AND service_item_id IN ('99144','99145')
AND service_item_id NOT IN ('59840','59841','59840AMD','59840A','59841C','59841CMD','59841D','59841DMD')
AND (ISNULL(ppa.anesthesia_type,'') IN ('','Minimal sedation','IM sedation','IV sedation - moderate') OR ISNULL(abp.txt_sed_procedure,'') IN ('','_IV Sedation'))
)
SELECT @57 = COUNT(*)
FROM AB2
WHERE RN = 1

SELECT @57



select enc_nbr, create_timestamp
from patient_encounter
where enc_id IN (
'020E5CEE-01D6-41C1-9BD3-0314BE5AE80B'
,'1D7EE42B-4580-4749-84B3-0398BD13B53C'
,'132885E3-8DE4-42DC-8DF5-040240A119D9'
,'F83F3060-A0C9-4049-B409-040759455EC2'
,'7E7AD469-4749-4D1B-9AE5-04151FBEBD0D'
,'BD8A6F19-5C6B-4AC8-9042-05E504A84AFE'
,'AF78B564-EA84-42E2-A0B7-062CFDBB3FD2'
,'8BD33347-3FF4-4D1C-8B41-0782ED5B875D'
,'19D627A4-CA17-4400-AF27-083830DFA94D'
,'7A15DCAD-60AA-49CC-B4FF-093326552784'
,'6784538E-18CD-4B20-91F7-0981F7807C68'
,'25D70E8F-BFE8-428E-8B45-0D053BF0941B'
,'4B18AE72-2BF1-4104-A07C-0E64A6D87EAB'
,'8E0677D7-BFEF-46C5-8C6F-0E8FD987C86E'
,'4FD71843-4ABC-4899-9A99-0E95FEAE77CA'
,'8E06D7E9-3354-4AAC-8192-0FEAC6D2D887'
,'F3DE1F05-044A-4EF6-AD38-111AA8C17858'
,'463AF8AB-95B9-4B5E-B7DC-112816D757EA'
,'25A051F0-219F-49AD-826B-1196FD90306F'
,'F700D522-1B0E-4D17-AADB-136EF8230181'
,'C42922A1-9AA3-417A-A697-1444B28D0733'
,'EA58844B-D6A9-4EDA-BA22-14DA5C729B3B'
)

SELECT --enc_nbr, anesthesia_type, rb_contra_sedation, rb_contra_sedation_txt
DISTINCT anesthesia_type, COUNT(DISTINCT p.ENC_ID) AS 'count'
FROM PP_Anesthesia_ p
join patient_encounter pe ON pe.enc_id = p.enc_id
where (p.create_timestamp >= '20170101' AND p.create_timestamp <= '20170630')
--AND anesthesia_type = 'iv sedation - moderate'
group by anesthesia_type

order by rb_contra_sedation desc



select * from AB_Procedure_
where txt_sed_procedure is null

select distinct txt_sed_procedure, COUNT(DISTINCT ENC_ID) AS 'count'
from AB_Procedure_
WHERE txt_est_blood_loss IS NOT NULL and create_timestamp >= '20170101' AND create_timestamp <= '20170530'
group by txt_sed_procedure
order by txt_sed_procedure

DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 datetime

SET @Start_Date_1 = '20170101'
SET @End_Date_1 = '20170630'

--**********Start data Table Creation***********
--Creates list of all encounters, dx and SIM codes during time period
SELECT DISTINCT pp.enc_id, pp.person_id, p.sex, pp.service_date, pe.enc_nbr, p.person_nbr, p.date_of_birth, pp.service_item_id
INTO #temp1
FROM ngprod.dbo.patient_procedure pp
JOIN ngprod.dbo.patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN ngprod.dbo.person	p			 ON pp.person_id = p.person_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1) 
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND p.sex = 'f'
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.location_id NOT IN ('518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD'
						  ,'966B30EA-F24F-48D6-8346-948669FDCE6E') --Clinical, Online services and Lab locations are excluded
AND (service_Item_id = '59840A' OR Service_Item_id LIKE '59841[C-N]')

select DATEPART(MONTH, SERVICE_DATE) AS [month], COUNT(service_date) AS 'count'
from #temp1
group by SERVICE_DATE
order by service_date

select distinct txt_sed_procedure, COUNT(DISTINCT a.ENC_ID) AS 'count'
from AB_Procedure_ a
JOIN #temp1 t ON t.enc_id = a.enc_id
--WHERE txt_est_blood_loss IS NOT NULL
--where chk_consent_obtained is not NULL and create_timestamp >= '20170101' AND create_timestamp <= '20170530'
group by txt_sed_procedure
order by txt_sed_procedure

select *
from AB_Procedure_ a
JOIN #temp1 t ON t.enc_id = a.enc_id
WHERE txt_est_blood_loss IS NOT NULL