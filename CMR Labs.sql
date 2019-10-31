USE [NGProd]
GO
/****** Object:  StoredProcedure [dbo].[Public_Health_Labs]    Script Date: 12/2/2016 1:35:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Eric Born
-- Create date: June 2016
-- Description:	Gathers info for CMR template
-- =============================================
ALTER PROCEDURE [dbo].[Public_Health_Labs]
	-- Person_id and enc_number feeds into SP from template. enc_number is manually entered on template
	-- Patient info for template
     @Person_id			UNIQUEIDENTIFIER
	,@EncNbr			VARCHAR(50)
	,@ptGender			VARCHAR(10)
	,@EncDate			VARCHAR(50) OUTPUT
	--Lab Results
	,@CTChkBox			INT			OUTPUT
	,@CTSpecimen		VARCHAR(50) OUTPUT
	,@CTCollectDate		VARCHAR(15) OUTPUT
	,@GCChkBox			INT			OUTPUT
	,@GCSpecimen		VARCHAR(50) OUTPUT
	,@GCCollectDate		VARCHAR(15) OUTPUT 
	,@RPRChkBox			INT			OUTPUT
	,@RPRCollectDate	VARCHAR(15) OUTPUT
	--,@RPRTiter			VARCHAR(10) OUTPUT
	,@SYP_RPR			VARCHAR(2)  OUTPUT
	,@SYP_FTA			VARCHAR(2)  OUTPUT
	,@SYP_TP_AP			VARCHAR(2)  OUTPUT
	,@SYP_VDRL			VARCHAR(2)  OUTPUT
	,@SYP_EIA			VARCHAR(2)  OUTPUT
	,@SYP_CSF			VARCHAR(2)  OUTPUT
	--,@ptPreg			VARCHAR(15)	OUTPUT
	--,@ptDueDate			VARCHAR(15) OUTPUT
	,@HepChk			INT			OUTPUT
	,@HepA				INT			OUTPUT
	,@HepB				INT			OUTPUT
	,@HepC				INT			OUTPUT
	,@HepD				INT			OUTPUT
	,@HepE				INT			OUTPUT
	 
AS
	SET NOCOUNT ON;

BEGIN
	DECLARE @encID			UNIQUEIDENTIFIER
	SET @encID				= (select pe.enc_id from patient_encounter pe where enc_nbr = @EncNbr)
	--Creation of temp tables was necessary to provide additional filters down to the specific lab associated with the encounter
	--Creating variables for test results temp tables
	--CT
	DECLARE @Chlamydia			VARCHAR(50)
	DECLARE @ChlamydiaValue     INT
	DECLARE @Spec_CT			VARCHAR(50)
	DECLARE @CollectionDate_CT  VARCHAR(15)
	--GC
	DECLARE @gonorrhea			VARCHAR(50)
	DECLARE @gonorrheaValue     INT
	DECLARE @Spec_GC			VARCHAR(50)
	DECLARE @CollectionDate_GC  VARCHAR(15)
	--Syph
	DECLARE @RPR				VARCHAR(2)
	DECLARE @FTA				VARCHAR(2)
	DECLARE @TP_AP				VARCHAR(2)
	DECLARE @VDRL				VARCHAR(2)
	DECLARE @EIA				VARCHAR(2)
	DECLARE @CSF				VARCHAR(2)
	DECLARE @titer				VARCHAR(10)
	DECLARE @RPRValue			INT
	DECLARE @CollectionDate_RPR VARCHAR(15)
	--Hep
	DECLARE @HepValue			INT
	DECLARE @hep_a				VARCHAR(2)
	DECLARE @hep_b				VARCHAR(2)
	DECLARE @hep_c				VARCHAR(2)
	DECLARE @hep_d				VARCHAR(2)
	DECLARE @hep_e				VARCHAR(2)

--Start of CT temp table creation
	SELECT 
		 obx.observ_value
		,obr.date_time_reported
		,obx.result_desc
		,'enc_timestamp' = CONVERT(CHAR(8), nor.enc_timestamp, 112)
		,'Specimen' = 
		 CASE 
			   WHEN lot.test_code_text LIKE ('%vaginal%') THEN 'Vaginal'
			   WHEN lot.test_code_text LIKE ('%urine%')	  THEN 'Urine'
			   WHEN lot.test_code_text LIKE ('%rectal%')  THEN 'Rectal'
			   WHEN lot.test_code_text LIKE ('%anal%')    THEN 'Rectal'
			   WHEN lot.test_code_text LIKE ('%endo%')    THEN 'Cervical'
			   WHEN lot.test_code_text LIKE ('%phary%')   THEN 'Pharyngeal'
			   WHEN lot.test_code_text LIKE ('%ureth%')   THEN 'Uretheral'
		 END	       	       
	INTO #CT
	FROM 
		lab_results_obx obx
		JOIN lab_results_obr_p obr  ON obx.unique_obr_num	= obr.unique_obr_num
		JOIN lab_nor nor			ON obr.ngn_order_num	= nor.order_num
		JOIN lab_order_tests lot	ON nor.order_num		= lot.order_num  
		JOIN patient_encounter pe	ON nor.enc_id			= pe.enc_id 
	WHERE 
	   obx.abnorm_flags IN ('H','HH', '>', 'L', 'LL', '<', 'A', 'AA', 'U', 'D', 'B', 'W', 'R', 'I')
	AND
	   obx.person_id = @Person_id  
	AND
	   nor.enc_id = @EncID      
	AND
	   obx.result_desc LIKE '%CT%'
	AND   
	   obr.date_time_reported = (SELECT  MAX(t0.date_time_reported) 
								 FROM lab_results_obr_p (nolock) t0 
								 WHERE obr.person_id=t0.person_id AND t0.test_desc=obr.test_desc 
								 AND obr.ngn_order_num=t0.ngn_order_num)  
	AND
	   (obx.observ_value LIKE '%positive%' or obx.observ_value LIKE '%detected%')                                         

	Set @Chlamydia			= (SELECT TOP 1 result_desc   FROM #CT)
	Set @ChlamydiaValue		= (SELECT Count(*)			  FROM #CT)
	Set @Spec_CT			= (SELECT TOP 1 Specimen	  FROM #CT)
	Set @CollectionDate_CT  = (SELECT TOP 1 enc_timestamp FROM #CT)
	IF (@ChlamydiaValue = 0)
		BEGIN
		  Set @ChlamydiaValue = 0
		END
	IF (@ChlamydiaValue > 0)
		BEGIN
		  Set @ChlamydiaValue = 1
		END
	--End of CT

	--Start of GC temp table creation
	SELECT
		 obx.observ_value
		,obr.date_time_reported
		,obx.result_desc
		,'enc_timestamp' = CONVERT(CHAR(8), nor.enc_timestamp, 112)
		,'Specimen' =
		 CASE 
			   WHEN lot.test_code_text LIKE ('%vaginal%') THEN 'Vaginal'
			   WHEN lot.test_code_text LIKE ('%urine%')	  THEN 'Urine'
			   WHEN lot.test_code_text LIKE ('%rectal%')  THEN 'Rectal'
			   WHEN lot.test_code_text LIKE ('%anal%')    THEN 'Rectal'
			   WHEN lot.test_code_text LIKE ('%endo%')    THEN 'Cervical'
			   WHEN lot.test_code_text LIKE ('%phary%')   THEN 'Pharyngeal'
			   WHEN lot.test_code_text LIKE ('%ureth%')   THEN 'Uretheral'
		 END
	INTO #GC
	FROM 
		lab_results_obx obx
		JOIN lab_results_obr_p obr  ON obx.unique_obr_num	= obr.unique_obr_num
		JOIN lab_nor nor			ON obr.ngn_order_num	= nor.order_num
		JOIN lab_order_tests lot	ON nor.order_num		= lot.order_num  
		JOIN patient_encounter pe	ON nor.enc_id			= pe.enc_id 
	WHERE 
	   obx.abnorm_flags IN ('H','HH', '>', 'L', 'LL', '<', 'A', 'AA', 'U', 'D', 'B', 'W', 'R', 'I')
	AND
	   obx.person_id = @Person_id  
	AND
	   nor.enc_id = @EncID      
	AND
	   obx.result_desc LIKE '%GC%'
	AND   
	   obr.date_time_reported = (SELECT  MAX(t0.date_time_reported) 
								 FROM lab_results_obr_p (nolock) t0 
								 WHERE obr.person_id=t0.person_id AND t0.test_desc=obr.test_desc 
								 AND obr.ngn_order_num=t0.ngn_order_num)  
	AND
	   (obx.observ_value LIKE '%positive%' or obx.observ_value LIKE '%detected%')

	SET @gonorrhea		   = (SELECT TOP 1 result_desc FROM #GC)
	SET @gonorrheaValue	   = (SELECT COUNT(*) FROM #GC)
	SET @Spec_GC		   = (SELECT TOP 1 Specimen FROM #GC)
	SET @CollectionDate_GC = (SELECT TOP 1 enc_timestamp FROM #GC)
	IF (@gonorrheaValue = 0)
		BEGIN
		  SET @gonorrheaValue = 0
		END
	IF (@gonorrheaValue > 0)
		BEGIN
		  SET @gonorrheaValue = 1
		END
	--End of GC query


	--Start of Syphilis temp table creation
	----------------Create check that this only fires if syph test was done---------------------------
	SELECT
		 obx.observ_value
		,obr.date_time_reported
		,obx.result_desc
		,'enc_timestamp' = CONVERT(CHAR(8), nor.enc_timestamp, 112)
		,obx.unique_obr_num
		,RPR	= NULL
		,FTA	= NULL
		,TP_PA  = NULL
		,VDRL	= NULL
		,EIA	= NULL
		,CSF	= NULL
	INTO #RPR
	FROM 
		lab_results_obx obx
		JOIN lab_results_obr_p obr  ON obx.unique_obr_num	= obr.unique_obr_num
		JOIN lab_nor nor			ON obr.ngn_order_num	= nor.order_num
		JOIN lab_order_tests lot	ON nor.order_num		= lot.order_num  
		JOIN patient_encounter pe	ON nor.enc_id			= pe.enc_id 
	WHERE 
	   obx.abnorm_flags IN ('H','HH', '>', 'L', 'LL', '<', 'A', 'AA', 'U', 'D', 'B', 'W', 'R', 'I')
	AND
	   obx.person_id = @Person_id  
	And
	   nor.enc_id = @encID       
	AND --Include all test result types
   		(result_desc LIKE '%RPR%' OR result_desc LIKE '%vdrl%' OR result_desc LIKE '%fta%'
		OR result_desc LIKE '%trepo%' OR result_desc LIKE '%eia%' OR result_desc LIKE '%csf%')
			--Exclude HIV 1/2 EIA being picked up by %eia%
			--Exclude INTERPRETATION and /RESULT being picked up by the letters RPR in the word
	AND 
		result_desc NOT LIKE 'HIV%' AND result_desc != 'INTERPRETATION' AND result_desc != 'INTERPRETATION/RESULT:'
	AND   
	   obr.date_time_reported = (SELECT  MAX(t0.date_time_reported) 
								 FROM lab_results_obr_p (nolock) t0 
								 WHERE obr.person_id=t0.person_id AND t0.test_desc=obr.test_desc 
								 AND obr.ngn_order_num=t0.ngn_order_num) 	
	--Updates table to positive(1) for the correct strain(s)
	UPDATE #RPR
	SET RPR = 1
	where result_desc like '%RPR%' AND observ_value like 'REACTIVE%' 

	UPDATE #RPR
	SET FTA = 1
	where result_desc like '%FTA%' AND observ_value like 'REACTIVE%'

	UPDATE #RPR
	SET TP_PA = 1
	where result_desc like '%trepo%' AND observ_value like 'REACTIVE%'

	UPDATE #RPR
	SET VDRL = 1
	where result_desc like '%vdrl%' AND observ_value like 'REACTIVE%'

	UPDATE #RPR
	SET EIA = 1
	where result_desc like '%eia%' AND observ_value like 'REACTIVE%'

	UPDATE #RPR
	SET CSF = 1
	where result_desc like '%csf%' AND observ_value like 'REACTIVE%'
							 													 
	SET @RPR				= (select COUNT(*) from #RPR where RPR	 = 1)
	SET @VDRL				= (select COUNT(*) from #RPR where VDRL  = 1)
	SET @FTA				= (select COUNT(*) from #RPR where FTA	 = 1)
	SET @TP_AP				= (select COUNT(*) from #RPR where TP_PA = 1)
	SET @EIA				= (select COUNT(*) from #RPR where EIA   = 1)
	SET @CSF				= (select COUNT(*) from #RPR where CSF	 = 1)

	IF (@RPR = 0)
		BEGIN
		  SET @RPR = 0
		END
	IF (@RPR > 0)
		BEGIN
		  SET @RPR = 1
		END

	IF (@VDRL = 0)
		BEGIN
		  SET @VDRL = 0
		END
	IF (@VDRL > 0)
		BEGIN
		  SET @VDRL = 1
		END

	IF (@FTA = 0)
		BEGIN
		  SET @FTA = 0
		END
	IF (@FTA > 0)
		BEGIN
		  SET @FTA = 1
		END

	IF (@TP_AP = 0)
		BEGIN
		  SET @TP_AP = 0
		END
	IF (@TP_AP > 0)
		BEGIN
		  SET @TP_AP = 1
		END

	IF (@EIA = 0)
		BEGIN
		  SET @EIA = 0
		END
	IF (@EIA > 0)
		BEGIN
		  SET @EIA = 1
		END
	
	IF (@CSF = 0)
		BEGIN
		  SET @CSF = 0
		END
	IF (@CSF > 0)
		BEGIN
		  SET @CSF = 1
		END

	--Grabs just the numeric values from observ_value column then inserts a colon(:) after the first digit as titer						 
	--SET @titer				= (SELECT TOP 1 STUFF([dbo].[udf_GetNumeric](observ_value), 2, 0, ':') FROM #RPR
	--							Where observ_value not like '%[^0-9]%')

	SET @RPRValue			= (SELECT COUNT(*) FROM #RPR)
	SET @CollectionDate_RPR = (SELECT TOP 1 enc_timestamp FROM #RPR)

	IF (@RPRValue = 0)
		BEGIN
		  SET @RPRValue = 0
		END
	IF (@RPRValue > 0)
		BEGIN
		  SET @RPRValue = 1
		END
	--End of Syphilis query

	--Start hep query
	SELECT
		 obx.observ_value
		,obr.date_time_reported
		,obx.result_desc
		,'enc_timestamp' = CONVERT(CHAR(8), nor.enc_timestamp, 112)
		,obx.unique_obr_num
		,hepA = NULL
		,hepB = NULL
		,hepC = NULL
		,HepD = NULL
		,HepE = NULL
	
	INTO #hep
	FROM 
		lab_results_obx obx
		JOIN lab_results_obr_p obr  ON obx.unique_obr_num	= obr.unique_obr_num
		JOIN lab_nor nor			ON obr.ngn_order_num	= nor.order_num
		JOIN lab_order_tests lot	ON nor.order_num		= lot.order_num  
		JOIN patient_encounter pe	ON nor.enc_id			= pe.enc_id 
	WHERE 
	   obx.abnorm_flags = 'A'
	AND
	   obx.person_id = @Person_id  
	And
	   nor.enc_id = @encID       
	AND
   		result_desc LIKE '%hep%'
	AND   
	   obr.date_time_reported = (SELECT  MAX(t0.date_time_reported) 
								 FROM lab_results_obr_p (nolock) t0 
								 WHERE obr.person_id=t0.person_id AND t0.test_desc=obr.test_desc 
								 AND obr.ngn_order_num=t0.ngn_order_num) 

	UPDATE #hep
	SET hepA = 1
	where result_desc LIKE 'HEPATITIS A%' AND observ_value like 'REACTIVE%' 

	UPDATE #hep
	SET hepB = 1
	where result_desc LIKE 'HEPATITIS B%' AND observ_value like 'REACTIVE%'

	UPDATE #hep
	SET hepC = 1
	where result_desc LIKE 'HEPATITIS C%' AND observ_value like 'REACTIVE%'

	UPDATE #hep
	SET hepD = 1
	where result_desc LIKE 'HEPATITIS D%' AND observ_value like 'REACTIVE%'

	UPDATE #hep
	SET hepE = 1
	where result_desc LIKE 'HEPATITIS E%' AND observ_value like 'REACTIVE%'

	SET @hep_a				= (select COUNT(*) from #hep where hepA	 = 1)
	SET @hep_b				= (select COUNT(*) from #hep where hepB	 = 1)
	SET @hep_c				= (select COUNT(*) from #hep where hepC	 = 1)
	SET @hep_d				= (select COUNT(*) from #hep where hepD	 = 1)
	SET @hep_e				= (select COUNT(*) from #hep where hepE	 = 1)

	IF (@hep_a = 0)
		BEGIN
		  SET @hep_a = 0
	END
	IF (@hep_a > 0)
		BEGIN
		  SET @hep_a = 1
	END

	IF (@hep_b = 0)
		BEGIN
		  SET @hep_b = 0
	END
	IF (@hep_b > 0)
		BEGIN
		  SET @hep_b = 1
	END

	IF (@hep_c = 0)
		BEGIN
		  SET @hep_c = 0
	END
	IF (@hep_c > 0)
		BEGIN
		  SET @hep_c = 1
	END

	IF (@hep_d = 0)
		BEGIN
		  SET @hep_d = 0
	END
	IF (@hep_d > 0)
		BEGIN
		  SET @hep_d = 1
	END

	IF (@hep_e = 0)
		BEGIN
		  SET @hep_e = 0
	END
	IF (@hep_e > 0)
		BEGIN
		  SET @hep_e = 1
	END

	SET @HepValue			= (SELECT COUNT(*) FROM #hep) 
	IF (@HepValue = 0)
		BEGIN
		  SET @HepValue = 0
	END
	IF (@HepValue > 0)
		BEGIN
		  SET @HepValue = 1
	END
	--END hep query

	--Start main info select
	SELECT 
		--Patient info for template
		 @EncDate			= CONVERT(Char(8), pe.enc_timestamp, 112)
		--Lab Results
		,@CTChkBox			= @ChlamydiaValue 
		,@CTSpecimen		= @Spec_CT
		,@CTCollectDate		= @CollectionDate_CT
		,@GCChkBox			= @gonorrheaValue 
		,@GCSpecimen		= @Spec_GC
		,@GCCollectDate		= @CollectionDate_GC
		,@RPRChkBox			= @RPRValue 
		,@RPRCollectDate	= @CollectionDate_RPR
		--,@RPRTiter			= @titer
		,@SYP_RPR			= @RPR
		,@SYP_FTA			= @FTA
		,@SYP_TP_AP			= @TP_AP
		,@SYP_VDRL			= @VDRL
		,@SYP_EIA			= @EIA
		,@SYP_CSF			= @CSF
		--,@ptPreg			= @Preg		
		--,@ptDueDate			= CONVERT(Char(8), @DelDate, 112)
		,@HepChk			= @HepValue
		,@HepA				= @hep_a
		,@HepB				= @hep_b
		,@HepC				= @hep_c
		,@HepD				= @hep_d
		,@HepE				= @hep_e

	FROM 
		patient_encounter pe
		JOIN person per				ON pe.person_id = per.person_id
		JOIN patient pat			ON pe.person_id = pat.person_id
		--Voxent
		--JOIN PP_History_Comp_ phc	ON pe.enc_id = phc.enc_id
		--8.3.11
		JOIN hpi_sti_screening_ hss	ON pe.enc_id = hss.enc_id
		JOIN location_mstr loc		ON pe.location_id = loc.location_id 
		--JOIN provider_mstr pro		ON pe.rendering_provider_id = pro.provider_id
		JOIN lab_nor nor			ON pe.enc_id = nor.enc_id
		JOIN lab_results_obx obx	ON pe.person_id = obx.person_id
		JOIN lab_results_obr_p obr  ON obx.unique_obr_num = obr.unique_obr_num
		JOIN lab_order_tests lot	ON nor.order_num = lot.order_num

	WHERE 
		pe.person_id = @Person_id
		AND
		pe.enc_nbr = @EncNbr

END
--END main info select