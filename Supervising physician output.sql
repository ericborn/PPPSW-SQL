Declare @FromDate as date,  @Todate as date
    
set @FromDate =  '2018-02-01' --DATEADD(month, DATEDIFF(month, -1, getdate()) - 2, 0) 
set @Todate  =  '2018-02-28'--DATEADD(ss, -1, DATEADD(month, DATEDIFF(month, 0, getdate()), 0)) 

--Drop table #SupervisingPhysician

Select  Distinct
p.person_id as Person_Number
,pe.enc_nbr as Encounter_Number
,PA.med_rec_nbr as med_rec_nbr
,pm.email_address
,cast(p.service_date as date)  as Date_Of_service
--,MI.chiefcomplaint1 as Reason_Of_visit
,(pm.last_name +', '+ pm.first_name)as Provider_Name
,(sp.first_name +' '+ sp.last_name)as Supervising_Physician

,pm.specialty_code_1
,txt_cc,
CASE WHEN txt_cc = 'Abdominal pain'  THEN 1 
WHEN txt_cc = 'Abnormal bleeding'  THEN 2 
WHEN txt_cc = 'Breast mass/pain'  THEN 3
WHEN txt_cc = 'Pain with intercourse'  THEN 4
WHEN txt_cc = 'Pelvic pain'  THEN 5
WHEN txt_cc = 'Vulvar pain first'  THEN 6
WHEN txt_cc = 'Vaginal discharge' Then 7
WHEN txt_cc = 'Hormonal contraception'Then 8
WHEN txt_cc = 'Colposcopy'Then 9 
WHEN txt_cc = 'abortion'Then 10
ELSE 11 END as SortOrder
,Sp.Provider_ID 
INTO #SupervisingPhysician
FROM NGProd.dbo.patient_encounter PE 
Inner join NGProd.dbo.patient PA ON Pa.person_id=pe.person_id --17096057
Inner join NGProd.dbo.patient_procedure p  on pe.enc_id=p.enc_id--17095919
INNER JOIN NGProd.dbo.master_im_ MI on MI.enc_id=pe.enc_id and mi.person_id=pe.person_id--6450552
inner Join NGProd.dbo.service_item_mstr Sm on Sm.service_item_id = p.service_item_id 
inner join  NGProd.dbo.Mstr_lists  ML oN SM.department = ML.mstr_list_item_id 
 --left join [ppreporting].[dbo].[PT_Supervising_Physician] sph on pe.enc_nbr=sph.IDMRN ---******** this pe.enc_nbr=sph.IDMRN  is handled in PS_Supervising_Physician 15 March 2018***********
Right join NGProd.dbo.provider_mstr pm on pm.provider_id=pe.rendering_provider_id AND pm.delete_ind = 'n'
Right join NGProd.dbo.provider_mstr SP on sp.provider_id=pe.supervisor_provider_id AND sp.delete_ind = 'n' --6654205
INNER join NGProd.dbo.hpi_female_urogenital_ fu on fu.enc_id=pe.enc_id and pe.person_id=fu.person_id
Where  mstr_list_item_desc like 'Visit%' and service_date between  @FromDate and @Todate and PM.specialty_code_1 = 'PA'
--and fu.txt_cc  in('Abdominal pain','Abnormal bleeding','Chronic pain','Lesion','Pain with intercourse','Pelvic pain','Breast mass/pain','Breast mass/pain',
--'Vulvar pain first','Hormonal contraception','Vaginal discharge','Colposcopy','abortion')

drop table #provider_counts
drop table #Output

CREATE TABLE #provider_counts
(
 [ID] INT IDENTITY(1,1)
,[provider_name] VARCHAR (100)
,[Charts] INT
)

INSERT INTO #provider_counts
SELECT Provider_Name, CAST(ROUND((COUNT(Provider_Name) * .05), 0) AS INT) AS 'Charts'
FROM #SupervisingPhysician
GROUP BY Provider_Name
ORDER BY provider_name

--select * from #provider_counts

CREATE TABLE #Output
(
 [Person_Number] UNIQUEIDENTIFIER
,[Encounter_Number] INT
,[med_rec_nbr] INT
,[email_address] VARCHAR(100)
,[Date_Of_service] DATE
,[Provider_Name] VARCHAR(100)
,[Supervising_Physician] VARCHAR(100)
,[specialty_code_1] VARCHAR(2)
,[txt_cc] VARCHAR(100)
,[SortOrder] INT
,[Provider_ID] UNIQUEIDENTIFIER
)

DECLARE
 @m INT
,@start INT

SELECT TOP 1 @m = MAX(id) from #provider_counts
SET @start = 1
--select @m

DECLARE 
 @Id INT
,@Chart INT
,@Provider VARCHAR(100)

WHILE (SELECT @start) <= @m
BEGIN

    SELECT Top 1 @Id = ID FROM #provider_counts ORDER BY ID
	SELECT TOP 1 @Chart = Charts FROM #provider_counts ORDER BY ID
	SELECT TOP 1 @Provider = provider_name FROM #provider_counts ORDER BY ID
	
	INSERT INTO #Output
	SELECT TOP (@chart) --*
	 [Person_Number]
	,[Encounter_Number]
	,[med_rec_nbr]
	,[email_address]
	,[Date_Of_service]
	,[Provider_Name]
	,[Supervising_Physician]
	,[specialty_code_1]
	,[txt_cc]
	,[SortOrder]
	,[Provider_ID]
	FROM #SupervisingPhysician sp
	WHERE @provider = Provider_Name
	AND txt_cc  in('Abdominal pain','Abnormal bleeding','Chronic pain','Lesion','Pain with intercourse','Pelvic pain','Breast mass/pain','Breast mass/pain',
	'Vulvar pain first','Hormonal contraception','Vaginal discharge','Colposcopy','abortion')

	SET @start = @start + 1

END

SELECT * 
FROM #output
ORDER BY Provider_Name