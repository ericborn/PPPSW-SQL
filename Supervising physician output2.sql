DECLARE @FromDate AS DATE,  @Todate AS DATE
    
SET @FromDate =  '2018-02-01' --DATEADD(month, DATEDIFF(month, -1, getdate()) - 2, 0) 
SET @Todate  =  '2018-02-28'--DATEADD(ss, -1, DATEADD(month, DATEDIFF(month, 0, getdate()), 0)) 

--Drop table #SupervisingPhysician

--***Builds table of all PA charts for time period***
SELECT DISTINCT
 p.person_id AS Person_Number
,pe.enc_nbr AS Encounter_Number
,PA.med_rec_nbr AS med_rec_nbr
,pm.email_address
,CAST(p.service_date AS DATE)  AS Date_Of_service
--,MI.chiefcomplaint1 as Reason_Of_visit
,(pm.last_name +', '+ pm.first_name)AS Provider_Name
,(sp.first_name +' '+ sp.last_name)AS Supervising_Physician
,pm.specialty_code_1
,txt_cc
,CASE 
	WHEN txt_cc = 'Abdominal pain'  THEN 1 
	WHEN txt_cc = 'Abnormal bleeding'  THEN 2 
	WHEN txt_cc = 'Breast mass/pain'  THEN 3
	WHEN txt_cc = 'Pain with intercourse'  THEN 4
	WHEN txt_cc = 'Pelvic pain'  THEN 5
	WHEN txt_cc = 'Vulvar pain first'  THEN 6
	WHEN txt_cc = 'Vaginal discharge' Then 7
	WHEN txt_cc = 'Hormonal contraception'Then 8
	WHEN txt_cc = 'Colposcopy'Then 9 
	WHEN txt_cc = 'abortion'Then 10
	ELSE 11 
END AS SortOrder
,Sp.Provider_ID 
INTO #SupervisingPhysician
FROM NGProd.dbo.patient_encounter PE 
Inner join NGProd.dbo.patient PA ON Pa.person_id=pe.person_id --17096057
Inner join NGProd.dbo.patient_procedure p  ON pe.enc_id=p.enc_id--17095919
INNER JOIN NGProd.dbo.master_im_ MI ON MI.enc_id=pe.enc_id and mi.person_id=pe.person_id--6450552
inner Join NGProd.dbo.service_item_mstr Sm ON Sm.service_item_id = p.service_item_id 
inner join  NGProd.dbo.Mstr_lists  ML ON SM.department = ML.mstr_list_item_id 
 --left join [ppreporting].[dbo].[PT_Supervising_Physician] sph on pe.enc_nbr=sph.IDMRN ---******** this pe.enc_nbr=sph.IDMRN  is handled in PS_Supervising_Physician 15 March 2018***********
Right join NGProd.dbo.provider_mstr pm ON pm.provider_id=pe.rendering_provider_id AND pm.delete_ind = 'n'
Right join NGProd.dbo.provider_mstr SP ON sp.provider_id=pe.supervisor_provider_id AND sp.delete_ind = 'n' --6654205
INNER join NGProd.dbo.hpi_female_urogenital_ fu ON fu.enc_id=pe.enc_id and pe.person_id=fu.person_id
WHERE  mstr_list_item_desc like 'Visit%' and service_date between  @FromDate and @Todate and PM.specialty_code_1 = 'PA'
--***Commented out as the total number of charts shouldn't be based on only high risk***
--and fu.txt_cc  in('Abdominal pain','Abnormal bleeding','Chronic pain','Lesion','Pain with intercourse','Pelvic pain','Breast mass/pain','Breast mass/pain',
--'Vulvar pain first','Hormonal contraception','Vaginal discharge','Colposcopy','abortion')

--drop table #provider_counts
--drop table #Output

CREATE TABLE #provider_counts
(
 [provider_name] VARCHAR (100)
,[Charts] INT
)

--***Finds %5 of charts per provider and rounds to nearest whole number***
INSERT INTO #provider_counts
SELECT Provider_Name, CAST(ROUND((COUNT(Provider_Name) * .05), 0) AS INT) AS 'Charts'
FROM #SupervisingPhysician
GROUP BY Provider_Name
ORDER BY provider_name

--select * from #provider_counts

CREATE TABLE #output
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

--***Creates variables used to dynamically pull charts for each provider***
--@Chart is used to track how many total charts to select per provider
--@Provider is used for providers name
DECLARE 
 @Chart INT
,@Provider VARCHAR(100)

--While loop to iterate through each provider and dynamically select the desired number of high risk charts
WHILE (Select Count(*) FROM #provider_counts) > 0
BEGIN

	--Selects a new provider and total chart number each time the previous provider was deleted during the iteration
	SELECT TOP 1 @Chart = Charts FROM #provider_counts
	SELECT TOP 1 @Provider = provider_name FROM #provider_counts

	--***Inserts high risk charts into #output table
	INSERT INTO #output
	Select TOP (@chart) *
	FROM #SupervisingPhysician sp
	WHERE @provider = Provider_Name
	AND txt_cc  in('Abdominal pain','Abnormal bleeding','Chronic pain','Lesion','Pain with intercourse','Pelvic pain','Breast mass/pain','Breast mass/pain',
	'Vulvar pain first','Hormonal contraception','Vaginal discharge','Colposcopy','abortion')

	--***Deletes provider from #provider_counts after charts have been pulled***
	DELETE #provider_counts WHERE provider_name = @Provider

END

--***Final output***
SELECT * 
FROM #output
ORDER BY Provider_Name