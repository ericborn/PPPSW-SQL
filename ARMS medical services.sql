IF OBJECT_ID('tempdb..#ARMS') IS NOT NULL DROP TABLE #ARMS
IF OBJECT_ID('tempdb..#person') IS NOT NULL DROP TABLE #person
IF OBJECT_ID('tempdb..#enc') IS NOT NULL DROP TABLE #enc
IF OBJECT_ID('tempdb..#charges') IS NOT NULL DROP TABLE #charges
IF OBJECT_ID('tempdb..#proc') IS NOT NULL DROP TABLE #proc
IF OBJECT_ID('tempdb..#visit') IS NOT NULL DROP TABLE #visit
IF OBJECT_ID('tempdb..#labs') IS NOT NULL DROP TABLE #labs
IF OBJECT_ID('tempdb..#ContraClients') IS NOT NULL DROP TABLE #ContraClients
IF OBJECT_ID('tempdb..#ContrSIM') IS NOT NULL DROP TABLE #ContrSIM
IF OBJECT_ID('tempdb..#AB') IS NOT NULL DROP TABLE #AB
IF OBJECT_ID('tempdb..#IUC') IS NOT NULL DROP TABLE #IUC
IF OBJECT_ID('tempdb..#condoms') IS NOT NULL DROP TABLE #condoms

CREATE TABLE #ARMS (Report_Line VARCHAR(500), Count VARCHAR(12))

/* Temp table to capture visits one person per location per day */
SELECT person_id, sex, last_name, first_name
INTO #person -- drop table #person
FROM person
WHERE last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND expired_ind = 'N'

--temp table to capture only encounters during timeframe
SELECT pe.enc_id, pe.person_id, pe.enc_nbr, enc_timestamp, pe.location_id,p.sex, cob1_payer_id
INTO #enc -- drop table #enc
FROM patient_encounter pe
JOIN #person p
	ON pe.person_id = p.person_id
WHERE CONVERT(DATE,enc_timestamp) BETWEEN '2016-10-01' AND '2017-09-30'
AND billable_ind = 'Y'
AND clinical_ind = 'Y'

--temp table to pull all patient procedures during timeframe
SELECT pp.enc_id, pp.person_id, cpt4_code_id, modifier_id_1, diagnosis_code_id_1, diagnosis_code_id_2, diagnosis_code_id_3, diagnosis_code_id_4, e.sex, e.enc_timestamp, e.location_id, pp.service_item_id
INTO #proc -- drop table #proc
FROM patient_procedure pp
JOIN #enc e 
	ON pp.enc_id = e.enc_id

-- temp table to be used for single visit at single location within the timeframe of the report
;WITH visit AS (
SELECT pe.person_id, pe.enc_id, pe.location_id, CONVERT(date,pe.enc_timestamp) AS enc_timestamp, pe.sex, p.service_item_id, RN = ROW_NUMBER() OVER 
(PARTITION BY  pe.person_id, pe.location_id, CONVERT(date,pe.enc_timestamp) ORDER BY CONVERT(date,pe.enc_timestamp))
FROM #enc pe
JOIN #proc p
	ON pe.enc_id = p.enc_id
WHERE (     
		  service_item_id BETWEEN '99201' AND '99205'
       OR service_item_id BETWEEN '99211' AND '99215'
       OR service_item_id BETWEEN '99384' AND '99387'
       OR service_item_id BETWEEN '99394' AND '99397'
	 )
)
SELECT *
INTO #visit -- drop table #visit
FROM visit
WHERE RN = 1

-- temp table for IUC tracking 
SELECT pe.*,pia.rb10, pii.rb5, psw.iud_type, psw.chk_iud_inserted
INTO #IUC -- drop table #IUC
FROM #proc pe
LEFT JOIN PP_IUC_Assessment_ pia
	ON pe.enc_id = pia.enc_id
			LEFT JOIN PP_IUC_Insert_ pii
				ON pia.enc_id = pii.enc_id
LEFT JOIN Proc_IUD_ psw
	ON pe.enc_id = psw.enc_id
WHERE pe.sex = 'F'
AND pe.cpt4_code_id = '58300'

-- Lab Orders + Results
;WITH LabResultsRange
AS
(
	SELECT DISTINCT
		LN.person_id,
		LN.order_num AS Order_Num,
		LN.enc_id,
		LOT.test_code_id,
		LN.test_desc AS Test_Summary,
		ISNULL(OBP.test_desc, OBP.ng_test_desc) AS Test_Description,
		LN.completed_ind AS Completed_Ind,
		LN.ngn_status AS NG_Status,
		LN.test_status AS Test_Status,
		e.enc_timestamp,
		e.sex,
		OBP.order_result_stat AS Order_Result_Status,
		OBX.result_desc AS Result_Description,
		ISNULL(OBP.coll_date_time, LN.create_timestamp) AS Collection_Timestamp,
		CONVERT(VARCHAR(10),OBP.coll_date_time,101) AS Collection_Date,
		OBP.seq_num AS Seq_Num,
		CONVERT(VARCHAR(MAX),OBP.obr_comment) AS Panel_Comment,
		OBX.observ_result_stat AS Result_Status,
		OBX.observ_value AS Result_Value, 
		OBX.abnorm_flags AS Abnormal_Flag,
		OBX.units AS Units, 
		OBX.ref_range AS Result_Range, 
		OBX.obx_seq_num,
		OBX.obs_date_time AS Result_Timestamp,
		CONVERT(VARCHAR(10),OBX.obs_date_time,101) AS Result_Date,
		OBX.delete_ind AS Delete_Ind, 
		OBX.result_seq_num, 
		OBX.comment_ind AS Comment_Ind, 
		CONVERT(VARCHAR(MAX),OBX.result_comment) AS Result_Comment,     
		CONVERT(INT,ROW_NUMBER() OVER (PARTITION BY LN.enterprise_id, LN.practice_id, LN.person_id, LN.order_num, OBX.result_desc
			ORDER BY ISNULL(OBP.coll_date_time, LN.create_timestamp) DESC, LN.order_num, OBP.seq_num, OBX.obx_seq_num)) AS RowNum  
	FROM lab_nor LN
	JOIN #enc e
		ON LN.enc_id = e.enc_id
	JOIN lab_order_tests LOT 
		ON LN.order_num = LOT.order_num
		LEFT JOIN lab_results_obr_p OBP
			ON LN.order_num = OBP.ngn_order_num
	JOIN lab_results_obx OBX
		ON OBP.unique_obr_num = OBX.unique_obr_num
	WHERE ISNULL(LN.delete_ind,'') <> 'Y'
	AND ISNULL(OBP.delete_ind,'') <> 'Y'
	AND ISNULL(OBX.delete_ind,'') <> 'Y'
	AND ISNULL(LN.ngn_status,'') NOT IN ('Cancelled')
	AND ISNULL(OBX.observ_value,'') <> ''
	AND PATINDEX('%Cancelled%',OBX.observ_value) = 0
	AND PATINDEX('%TNP%',OBX.observ_value) = 0
	AND PATINDEX('%not%performed%',OBX.observ_value) = 0
	AND PATINDEX('%not%obtained%',OBX.observ_value) = 0
	AND PATINDEX('%not%done%',OBX.observ_value) = 0
	AND PATINDEX('%not%processed%',OBX.observ_value) = 0
	AND PATINDEX('%specimen%rejected%',OBX.observ_value) = 0
	AND PATINDEX('%unable%to%do%',OBX.observ_value) = 0
	AND PATINDEX('%unable%to%process%',OBX.observ_value) = 0
	AND PATINDEX('%unable%to%calculate%result%',OBX.observ_value) = 0
	AND PATINDEX('%not%sufficient%for%analysis',OBX.observ_value) = 0
)
SELECT person_id, sex, enc_id, enc_timestamp, Order_Num, test_code_id, Test_Description, Result_Description, Result_Value, Abnormal_Flag
INTO #Labs --drop table #labs
FROM LabResultsRange LR 
WHERE RowNum = 1 
ORDER BY CONVERT(DATETIME,Collection_Timestamp) DESC

--temp table for contraceptive clients
;with ContraClients AS (
SELECT im.txt_birth_control_visitend, pe.person_id, pe.enc_id, pe.enc_timestamp,pe.sex, RN = ROW_NUMBER() OVER
(PARTITION BY pe.person_id ORDER BY pe.enc_timestamp DESC)
FROM master_im_ im
JOIN #enc pe
	ON im.enc_id = pe.enc_id 
)
SELECT * 
INTO #ContraClients -- drop table #ContraClients
FROM ContraClients
WHERE RN = 1

--temp table for dispensed contraceptives
SELECT ml.mstr_list_item_desc, sim.service_item_id, sim.description
INTO #ContrSIM
FROM service_item_mstr sim
JOIN mstr_lists ml 
	 ON sim.department = ml.mstr_list_item_id
WHERE ml.mstr_list_item_desc LIKE 'supplies%'
AND ml.mstr_list_item_desc NOT IN  ('Supplies-Other','Supplies-Medication Abortion','Supplies-Prenatal','Supplies-Male Sterilization')
AND sim.description NOT LIKE '%removal%'
AND sim.description NOT LIKE '%tray%'
ORDER BY 1,2,3

--temp table for all AB specific visits
SELECT DISTINCT p.enc_id
INTO #AB  -- drop table #AB
FROM #proc p
WHERE cpt4_code_id IN ('59840A','59840AMD','59841C','59841CMD','59841D','59841DMD','59841E','59841EMD','59841F','59841FMD','59841G',
						'59841GMD','59841H','59841HMD','59841I','59841IMD','59841J','59841JMD','59841K','59841KMD','59841L','59841LMD',
						'59841M','59841MMD','59841N','59841NMD','S0199','S0199A','S0199NC')

/******************** DECLARE SOME VARIABLES ****************************************************************************************************************************************************************************************************************************************************/
DECLARE @1 VARCHAR(12) ,@2 VARCHAR(12) ,@3 VARCHAR(12) ,@4 VARCHAR(12) ,@5 VARCHAR(12) ,@6 VARCHAR(12) ,@7 VARCHAR(12) ,@8 VARCHAR(12) ,@9 VARCHAR(12) ,@10 VARCHAR(12) ,@11 VARCHAR(12) ,@12 VARCHAR(12) ,@13 VARCHAR(12) ,@14 VARCHAR(12) ,@15 VARCHAR(12) ,@16 VARCHAR(12) ,@17 VARCHAR(12) ,
@18 VARCHAR(12) ,@19 VARCHAR(12) ,@20 VARCHAR(12) ,@21 VARCHAR(12) ,@22 VARCHAR(12) ,@23 VARCHAR(12) ,@24 VARCHAR(12) ,@25 VARCHAR(12) ,@26 VARCHAR(12) ,@27 VARCHAR(12) ,@28 VARCHAR(12) ,@29 VARCHAR(12) ,@30 VARCHAR(12) ,@31 VARCHAR(12) ,@32 VARCHAR(12) ,@33 VARCHAR(12) ,
@34 VARCHAR(12) ,@35 VARCHAR(12) ,@36 VARCHAR(12) ,@37 VARCHAR(12) ,@38 VARCHAR(12) ,@39 VARCHAR(12) ,@40 VARCHAR(12) ,@41 VARCHAR(12) ,@42 VARCHAR(12) ,@43 VARCHAR(12) ,@44 VARCHAR(12) ,@45 VARCHAR(12) ,@46 VARCHAR(12) ,@47 VARCHAR(12) ,@48 VARCHAR(12) ,@49 VARCHAR(12) ,
@50 VARCHAR(12) ,@51 VARCHAR(12) ,@52 VARCHAR(12) ,@53 VARCHAR(12) ,@54 VARCHAR(12) ,@55 VARCHAR(12) ,@56 VARCHAR(12) ,@57 VARCHAR(12) ,@58 VARCHAR(12) ,@59 VARCHAR(12) ,@60 VARCHAR(12) ,@61 VARCHAR(12) ,@62 VARCHAR(12) ,@63 VARCHAR(12) ,@64 VARCHAR(12) ,@65 VARCHAR(12) ,
@66 VARCHAR(12) ,@67 VARCHAR(12) ,@68 VARCHAR(12) ,@69 VARCHAR(12) ,@70 VARCHAR(12) ,@71 VARCHAR(12) ,@72 VARCHAR(12) ,@73 VARCHAR(12) ,@74 VARCHAR(12) ,@75 VARCHAR(12) ,@76 VARCHAR(12) ,@77 VARCHAR(12) ,@78 VARCHAR(12) ,@79 VARCHAR(12) ,@80 VARCHAR(12) ,@81 VARCHAR(12) ,
@82 VARCHAR(12) ,@83 VARCHAR(12) ,@84 VARCHAR(12) ,@85 VARCHAR(12) ,@86 VARCHAR(12) ,@87 VARCHAR(12) ,@88 VARCHAR(12) ,@89 VARCHAR(12) ,@90 VARCHAR(12) ,@91 VARCHAR(12) ,@92 VARCHAR(12) ,@93 VARCHAR(12) ,@94 VARCHAR(12) ,@95 VARCHAR(12) ,@96 VARCHAR(12) ,@97 VARCHAR(12) ,
@98 VARCHAR(12) ,@99 VARCHAR(12) ,@100 VARCHAR(12) ,@101 VARCHAR(12) ,@102 VARCHAR(12) ,@103 VARCHAR(12) ,@104 VARCHAR(12) ,@105 VARCHAR(12) ,@106 VARCHAR(12) ,@107 VARCHAR(12) ,@108 VARCHAR(12) ,@109 VARCHAR(12) ,@110 VARCHAR(12) ,@111 VARCHAR(12) ,@112 VARCHAR(12) ,
@113 VARCHAR(12) ,@114 VARCHAR(12) ,@115 VARCHAR(12) ,@116 VARCHAR(12) ,@117 VARCHAR(12) ,@118 VARCHAR(12) ,@119 VARCHAR(12) ,@120 VARCHAR(12) ,@121 VARCHAR(12) ,@122 VARCHAR(12) ,@123 VARCHAR(12) ,@124 VARCHAR(12) ,@125 VARCHAR(12) ,@126 VARCHAR(12) ,@127 VARCHAR(12) ,
@128 VARCHAR(12) ,@129 VARCHAR(12) ,@130 VARCHAR(12) ,@131 VARCHAR(12) ,@132 VARCHAR(12) ,@133 VARCHAR(12) ,@134 VARCHAR(12) ,@135 VARCHAR(12) ,@136 VARCHAR(12) ,@137 VARCHAR(12) ,@138 VARCHAR(12) ,@139 VARCHAR(12) ,@140 VARCHAR(12) ,@141 VARCHAR(12) ,@142 VARCHAR(12) ,
@143 VARCHAR(12) ,@144 VARCHAR(12) ,@145 VARCHAR(12) ,@146 VARCHAR(12) ,@147 VARCHAR(12) ,@148 VARCHAR(12) ,@149 VARCHAR(12) ,@150 VARCHAR(12) ,@151 VARCHAR(12) ,@152 VARCHAR(12) ,@153 VARCHAR(12) ,@154 VARCHAR(12) ,@155 VARCHAR(12) ,@156 VARCHAR(12) ,@157 VARCHAR(12) ,
@158 VARCHAR(12) ,@159 VARCHAR(12) ,@160 VARCHAR(12) ,@161 VARCHAR(12) ,@162 VARCHAR(12) ,@163 VARCHAR(12) ,@164 VARCHAR(12) ,@165 VARCHAR(12) ,@166 VARCHAR(12) ,@167 VARCHAR(12) ,@168 VARCHAR(12) ,@169 VARCHAR(12) ,@170 VARCHAR(12) ,@171 VARCHAR(12) ,@172 VARCHAR(12) ,
@173 VARCHAR(12) ,@174 VARCHAR(12) ,@175 VARCHAR(12) ,@176 VARCHAR(12) ,@177 VARCHAR(12) ,@178 VARCHAR(12) ,@179 VARCHAR(12) ,@180 VARCHAR(12) ,@181 VARCHAR(12) ,@182 VARCHAR(12) ,@183 VARCHAR(12) ,@184 VARCHAR(12) ,@185 VARCHAR(12) ,@186 VARCHAR(12) ,@187 VARCHAR(12) ,
@188 VARCHAR(12) ,@189 VARCHAR(12) ,@190 VARCHAR(12) ,@191 VARCHAR(12) ,@192 VARCHAR(12) ,@193 VARCHAR(12) ,@194 VARCHAR(12) ,@195 VARCHAR(12) ,@196 VARCHAR(12) ,@197 VARCHAR(12) ,@198 VARCHAR(12) ,@199 VARCHAR(12) ,@200 VARCHAR(12) ,@201 VARCHAR(12) ,@202 VARCHAR(12) ,
@203 VARCHAR(12) ,@204 VARCHAR(12) ,@205 VARCHAR(12) ,@206 VARCHAR(12) ,@207 VARCHAR(12) ,@208 VARCHAR(12) ,@209 VARCHAR(12) ,@210 VARCHAR(12) ,@211 VARCHAR(12) ,@212 VARCHAR(12) ,@213 VARCHAR(12) ,@214 VARCHAR(12) ,@215 VARCHAR(12) ,@216 VARCHAR(12) ,@217 VARCHAR(12) ,
@218 VARCHAR(12) ,@219 VARCHAR(12) ,@220 VARCHAR(12) ,@221 VARCHAR(12) ,@222 VARCHAR(12) ,@223 VARCHAR(12) ,@224 VARCHAR(12) ,@225 VARCHAR(12) ,@226 VARCHAR(12) ,@227 VARCHAR(12) ,@228 VARCHAR(12) ,@229 VARCHAR(12) ,@230 VARCHAR(12) ,@231 VARCHAR(12) ,@232 VARCHAR(12) ,
@233 VARCHAR(12) ,@234 VARCHAR(12) ,@235 VARCHAR(12) ,@236 VARCHAR(12) ,@237 VARCHAR(12) ,@238 VARCHAR(12) ,@239 VARCHAR(12) ,@240 VARCHAR(12) ,@241 VARCHAR(12) ,@242 VARCHAR(12) ,@243 VARCHAR(12) ,@244 VARCHAR(12) ,@245 VARCHAR(12) ,@246 VARCHAR(12) ,@247 VARCHAR(12) ,
@248 VARCHAR(12) ,@249 VARCHAR(12) ,@250 VARCHAR(12) ,@251 VARCHAR(12) ,@252 VARCHAR(12) ,@253 VARCHAR(12) ,@254 VARCHAR(12) ,@255 VARCHAR(12) ,@256 VARCHAR(12) ,@257 VARCHAR(12) ,@258 VARCHAR(12) ,@259 VARCHAR(12) ,@260 VARCHAR(12) ,@261 VARCHAR(12) ,@262 VARCHAR(12) ,
@263 VARCHAR(12) ,@264 VARCHAR(12) ,@265 VARCHAR(12) ,@266 VARCHAR(12) ,@267 VARCHAR(12) ,@268 VARCHAR(12) ,@269 VARCHAR(12) ,@270 VARCHAR(12) ,@271 VARCHAR(12) ,@272 VARCHAR(12) ,@273 VARCHAR(12) ,@274 VARCHAR(12) ,@275 VARCHAR(12) ,@276 VARCHAR(12) ,@277 VARCHAR(12) ,
@278 VARCHAR(12) ,@279 VARCHAR(12) ,@280 VARCHAR(12) ,@281 VARCHAR(12) ,@282 VARCHAR(12) ,@283 VARCHAR(12) ,@284 VARCHAR(12) ,@285 VARCHAR(12) ,@286 VARCHAR(12) ,@287 VARCHAR(12) ,@288 VARCHAR(12) ,@289 VARCHAR(12) ,@290 VARCHAR(12) ,@291 VARCHAR(12) ,@292 VARCHAR(12) ,
@293 VARCHAR(12) ,@294 VARCHAR(12) ,@295 VARCHAR(12) ,@296 VARCHAR(12) ,@297 VARCHAR(12) ,@298 VARCHAR(12) ,@299 VARCHAR(12) ,@300 VARCHAR(12) ,@301 VARCHAR(12) ,@302 VARCHAR(12) ,@303 VARCHAR(12) ,@304 VARCHAR(12) ,@305 VARCHAR(12) ,@306 VARCHAR(12) ,@307 VARCHAR(12) ,
@308 VARCHAR(12) ,@309 VARCHAR(12) ,@310 VARCHAR(12) ,@311 VARCHAR(12) ,@312 VARCHAR(12) ,@313 VARCHAR(12) ,@314 VARCHAR(12) ,@315 VARCHAR(12) ,@316 VARCHAR(12) ,@317 VARCHAR(12) ,@318 VARCHAR(12) ,@319 VARCHAR(12) ,@320 VARCHAR(12) ,@321 VARCHAR(12) ,@322 VARCHAR(12) ,
@323 VARCHAR(12) ,@324 VARCHAR(12) ,@325 VARCHAR(12) ,@326 VARCHAR(12) ,@327 VARCHAR(12) ,@328 VARCHAR(12) ,@329 VARCHAR(12) ,@330 VARCHAR(12) ,@331 VARCHAR(12) ,@332 VARCHAR(12) ,@333 VARCHAR(12) ,@334 VARCHAR(12) ,@335 VARCHAR(12) ,@336 VARCHAR(12) ,@337 VARCHAR(12) ,
@338 VARCHAR(12) ,@339 VARCHAR(12) ,@340 VARCHAR(12) ,@341 VARCHAR(12) ,@342 VARCHAR(12) ,@343 VARCHAR(12) ,@344 VARCHAR(12) ,@345 VARCHAR(12) ,@346 VARCHAR(12) ,@347 VARCHAR(12) ,@348 VARCHAR(12) ,@349 VARCHAR(12) ,@350 VARCHAR(12)

/****************************************************************************************************************************************/

--Female Reproductive healthcare visits - Level 1 
SELECT @6 = COUNT(*) 
FROM #visit pe 
WHERE pe.sex = 'F'
AND (
	   service_item_id BETWEEN '99201' AND '99204'
	OR service_item_id BETWEEN '99211' AND '99214'
	OR service_item_id BETWEEN '99384' AND '99387'
	OR service_item_id BETWEEN '99394' AND '99397'
	)

INSERT INTO #ARMS VALUES ('Female Reproductive healthcare visits', @6)


--Male Reproductive healthcare visits - Level 1  
SELECT @7 = COUNT(*)
FROM #visit pe 
WHERE pe.sex = 'M'
AND (
	   service_item_id BETWEEN '99201' AND '99204'
	OR service_item_id BETWEEN '99211' AND '99214'
	OR service_item_id BETWEEN '99384' AND '99387'
	OR service_item_id BETWEEN '99394' AND '99397'
	)

INSERT INTO #ARMS VALUES ('Male Reproductive healthcare visits', @7)

--Transgender Reproductive healthcare visits - Level 1   
SELECT @8 = COUNT(*)
FROM #visit pe 
WHERE pe.sex NOT IN ('F', 'M')
AND (
	   service_item_id BETWEEN '99201' AND '99204'
	OR service_item_id BETWEEN '99211' AND '99214'
	OR service_item_id BETWEEN '99384' AND '99387'
	OR service_item_id BETWEEN '99394' AND '99397'
	)

INSERT INTO #ARMS VALUES ('Transgender Reproductive healthcare visits', @8)

--Hormonal injection (Depo-Provera) 
SELECT @9 = COUNT(*)
FROM #proc pe 
WHERE pe.sex = 'F'
AND (cpt4_code_id BETWEEN '96365' AND '96376' 
		OR cpt4_code_id = 'J1050')

INSERT INTO #ARMS VALUES ('Hormonal injection (Depo-Provera)', @9)

--Successful IUC insertions - Level 1 

	--Mirena
	SELECT @10 = COUNT(*)
	FROM #IUC
	WHERE (rb10 = 'mirena' OR iud_type = 'mirena iuc')
	AND ((modifier_id_1 <> '53' OR ISNULL(rb5,'N') = 'Y' OR ISNULL(chk_iud_inserted,0) = 1))

	INSERT INTO #ARMS VALUES ('Successful IUC insertions - Mirena', @10)

	--Skyla
	SELECT @11 = COUNT(*)
	FROM #IUC
	WHERE (rb10 = 'skyla' OR iud_type = 'skyla iuc')
	AND ((modifier_id_1 <> '53' OR ISNULL(rb5,'N') = 'Y' OR ISNULL(chk_iud_inserted,0) = 1))

	INSERT INTO #ARMS VALUES ('Successful IUC insertions - Skyla', @11)

	--ParaGard
	SELECT @12 = COUNT(*)
	FROM #IUC
	WHERE (rb10 = 'paragard' OR iud_type = 'paragard iuc')
	AND ((modifier_id_1 <> '53' OR ISNULL(rb5,'N') = 'Y' OR ISNULL(chk_iud_inserted,0) = 1))

	INSERT INTO #ARMS VALUES ('Successful IUC insertions - ParaGard', @12)

	--Liletta   **did not exist in the pre Family Planning templates**
	SELECT @13 = COUNT(*)
	FROM #IUC
	WHERE iud_type = 'liletta'
	AND ((modifier_id_1 <> '53' OR ISNULL(chk_iud_inserted,0) = 1))

	INSERT INTO #ARMS VALUES ('Successful IUC insertions - Liletta', @13)

--Successful IUC insertions - type unknown
SELECT @14 = 'DNA'
INSERT INTO #ARMS VALUES ('Successful IUC insertions - type unknown', @14)

--Failed IUC insertions - Level 1
SELECT @15 = COUNT(*)
FROM #IUC
WHERE (modifier_id_1 = '53' AND ISNULL(rb5,'N') <> 'Y' AND ISNULL(chk_iud_inserted,0) <> 1) 

INSERT INTO #ARMS VALUES ('Failed IUC insertions', @15)

--IUC removal - Level 1
SELECT @16 = COUNT(*)
FROM #proc pe
WHERE pe.sex = 'F' 
AND cpt4_code_id = '58301'

INSERT INTO #ARMS VALUES ('IUC removal', @16)

--Successful contraceptive implant insertion - Level 1
SELECT @17 = COUNT(*)
FROM #proc pe
LEFT JOIN proc_implant_contraception_ pic
	ON pe.enc_id = pic.enc_id
LEFT JOIN PP_Implanon_Insert_ pii
	ON pe.enc_id = pii.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('11975','11977','B006', 'M066','M076','J7307')
AND (pic.opt_implant_placement <> 3 OR pii.rb3 = 'T')

INSERT INTO #ARMS VALUES ('Successful contraceptive implant insertion', @17)

--Failed contraceptive implant insertion - Level 1 
SELECT @18 = COUNT(*)
FROM #proc pe
LEFT JOIN proc_implant_contraception_ pic
	ON pe.enc_id = pic.enc_id
LEFT JOIN PP_Implanon_Remove_ pir
	ON pe.enc_id = pir.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('11975','11977','B006', 'M066','M076','J7307')
AND modifier_id_1 = '53'--0

INSERT INTO #ARMS VALUES ('Failed contraceptive implant insertion', @18)

--Contraceptive implant removal - Level 1
SELECT @19 = COUNT(*)
FROM #proc pe
LEFT JOIN proc_implant_contraception_ pic
	ON pe.enc_id = pic.enc_id
LEFT JOIN PP_Implanon_Remove_ pir
	ON pe.enc_id = pir.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('11976','11977')--
AND (pic.opt_implant_removed = 1 OR (pir.rb10 IN ('Y','N')))

INSERT INTO #ARMS VALUES ('Contraceptive implant removal', @19)

--Destruction of vaginal, vulvar, penile lesion(s)
;with dest AS (
SELECT pe.cpt4_code_id, pe.person_id, pe.enc_id, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
WHERE (cpt4_code_id IN ('54050','54056','54057','54060','54065','56501','56515','57061','57065')
OR cpt4_code_id BETWEEN '17270' AND '17276')
)
SELECT @20 = COUNT(*)
FROM dest
WHERE RN = 1

INSERT INTO #ARMS VALUES ('Destruction of vaginal, vulvar, penile lesion(s)', @20)

--Aspiration of cyst(breast) - Level 1
SELECT @21 =  COUNT(*)
FROM #proc pe
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('19000','19001', '19000T')

INSERT INTO #ARMS VALUES ('Aspiration of cyst(breast)', @21)

--Other basic repordutive health care (includes diaphragm fittings) - Level 1
SELECT @22 = COUNT(*)
FROM #proc pe
WHERE pe.sex = 'F' 
AND (
		cpt4_code_id = '57170'
		OR cpt4_code_id = '57170D'
	)

INSERT INTO #ARMS VALUES ('Other basic repordutive health care (includes diaphragm fittings)', @22)

--Other basic reproductive health care (includes diaphragm fittings) - Joint Venture
SELECT @23 = 'DNA'
INSERT INTO #ARMS VALUES ('Other basic reproductive health care (includes diaphragm fittings) - Joint Venture', @23)

--Other basic reproductive health care (includes diaphragm fittings) - Pass Through
SELECT @24 = 'DNA'
INSERT INTO #ARMS VALUES ('Other basic reproductive health care (includes diaphragm fittings) - Pass Through', @24)

/* Intermediate Reproductive Health Care Level 3 */

--Office visit - high complexity (e.g. infertility services) 257
SELECT @25 = COUNT(*)
FROM #proc pe
WHERE pe.sex = 'F'
AND cpt4_code_id IN ('99205','99215')

INSERT INTO #ARMS VALUES ('Office visit - high complexity (e.g. infertility services)', @25)

--Hospital care - low complexity
SELECT @26 = COUNT(*)
FROM #proc pe
WHERE pe.sex = 'F'
AND cpt4_code_id IN ('99218','99221','99231')

INSERT INTO #ARMS VALUES ('Hospital care - low complexity', @26)

--Incision and drainage of vulvar or perineal abscess / Bartholin's gland abscess
SELECT @27 = COUNT(*)
FROM #proc pe
WHERE pe.sex = 'F'
AND cpt4_code_id IN ('56405','56420')

INSERT INTO #ARMS VALUES ('Incision and drainage of vulvar or perineal abscess / Bartholins gland abscess', @27)

--Insertion of pessary
SELECT @28 = COUNT(*)
FROM #proc pe
WHERE pe.sex = 'F'
AND cpt4_code_id = '57160' 

INSERT INTO #ARMS VALUES ('Insertion of pessary', @28)

--Intrauterine artificial insemination (therapeutic with partner semen)
SELECT @29 = COUNT(*)
FROM #proc pe
WHERE pe.sex = 'F'
AND cpt4_code_id = '58322' 

INSERT INTO #ARMS VALUES ('Intrauterine artificial insemination (therapeutic with partner semen)', @29)

/* Level 4 */

--Cryotherapy
SELECT @30 = COUNT(*)
FROM #proc pe
WHERE pe.sex = 'F'
AND cpt4_code_id = '57511' 

INSERT INTO #ARMS VALUES ('Cryotherapy', @30)

--Cryotherapy - clients
SELECT @31 = COUNT(DISTINCT pe.person_id)
FROM #proc pe
WHERE pe.sex = 'F'
AND cpt4_code_id = '57511' 

INSERT INTO #ARMS VALUES ('Cryotherapy - clients', @31)

--Hospital care - moderate complexity
SELECT @32 = COUNT(*)
FROM #proc pe
WHERE pe.sex = 'F'
AND cpt4_code_id IN ('99219','99222','99232') 

INSERT INTO #ARMS VALUES ('Hospital care - moderate complexity', @32)

/* Leve 5 */
 --Colposcopy
SELECT @33 = COUNT(*)
FROM #proc pe
WHERE pe.sex = 'F'
AND cpt4_code_id IN ('57452','57454','57455','57456','58110') 

INSERT INTO #ARMS VALUES ('Colposcopy', @33)

 --Colposcopy - clients
SELECT @34 = COUNT(DISTINCT pe.person_id)
FROM #proc pe
WHERE pe.sex = 'F'
AND cpt4_code_id IN ('57452','57454','57455','57456') 

INSERT INTO #ARMS VALUES ('Colposcopy - clients', @34)

--Vasectomy
SELECT @35 = COUNT(*)
FROM #proc pe
WHERE pe.sex = 'M'
AND cpt4_code_id IN ('55250','B013')

INSERT INTO #ARMS VALUES ('Vasectomy', @35)

--Vasectomy - Joint Venture - DNA
SELECT @36 = 'DNA'
INSERT INTO #ARMS VALUES ('Vasectomy - Joint Venture', @36)

--Vasectomy - Pass Through - DNA
SELECT @37 = 'DNA'
INSERT INTO #ARMS VALUES ('Vasectomy - Pass Through', @37)

--Prenatal including Smart Start - visits
SELECT @38 = COUNT(*)
FROM #proc pe
WHERE pe.sex = 'F'
AND cpt4_code_id IN ('59425','59426')

INSERT INTO #ARMS VALUES ('Prenatal including Smart Start - visits', @38)

--Prenatal including Smart Start - Clients
SELECT @39 = COUNT(DISTINCT pe.person_id)
FROM #proc pe
WHERE pe.sex = 'F'
AND cpt4_code_id IN ('59425','59426')

INSERT INTO #ARMS VALUES ('Prenatal including Smart Start - Clients', @39)

--Hospital care - high comoplexity
SELECT @40 = COUNT(*)
FROM #proc pe
WHERE pe.sex = 'F'
AND cpt4_code_id IN ('99220', '99223', '99233')

INSERT INTO #ARMS VALUES ('Hospital care - high comoplexity', @40)

--Fine needle aspiration (breast)
SELECT @41 = COUNT(*)
FROM #proc pe
WHERE pe.sex = 'F'
AND cpt4_code_id IN ('19000','10021')

INSERT INTO #ARMS VALUES ('Fine needle aspiration (breast)', @41)

--Biopsy of vulva, perineum, or cervix/vaginal mucosa DNA
SELECT @42 = 'DNA'
INSERT INTO #ARMS VALUES ('Biopsy of vulva, perineum, or cervix/vaginal mucosa DNA', @42)

--Endometrial biopsy or endocervical sampling
SELECT @43 = COUNT(*)
FROM #proc pe
WHERE pe.sex = 'F'
AND cpt4_code_id IN ('58100','58110')

INSERT INTO #ARMS VALUES ('Endometrial biopsy or endocervical sampling', @43)

--Endometrial biaopsy or endocervical sampling - positives DNA
SELECT @44 = 'DNA'
INSERT INTO #ARMS VALUES ('Endometrial biaopsy or endocervical sampling - positives', @44)

/* Level 6 */

/***************************************************************************************************************************** 
		For reporting puposes and consistancy we will define trimesters as below:
		 0 - 12 weeks 1st Trimester 59840A,59840AMD,59841C,59841CMD,59841D,59841DMD
		13 - 27 weeks 2nd Trimester 59841E,59841EMD,59841F,59841FMD,59841G,59841GMD,59841H,
									59841HMD,59841I,59841IMD,59841J,59841JMD,59841K,59841KMD,59841L,59841LMD,59841M,59841MMD,
									59841N,59841NMD
		28 + weeks    3rd Trimester
******************************************************************************************************************************/

--First trimester surgical abortion (local aneshesia and/or minimal and/or no sedation  
;with AB1 AS (
SELECT pe.cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
LEFT JOIN PP_Anesthesia_ ppa
	ON ppa.enc_id = pe.enc_id
LEFT JOIN AB_Procedure_ abp
	ON abp.enc_id = pe.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('59840','59851','59840A','59840AMD','59841C','59841CMD','59841D','59841DMD') --,'01966'
AND (ISNULL(ppa.anesthesia_type,'') NOT IN ('','Minimal sedation','IM sedation','IV sedation - moderate') 
		AND ISNULL(abp.txt_sed_procedure,'') NOT IN ('','_IV Sedation','Anesthesia With CRNA'))
)
SELECT @45 = COUNT(*)
FROM AB1
WHERE RN = 1 

INSERT INTO #ARMS VALUES ('First trimester surgical abortion (local aneshesia and/or minimal and/or no sedation', @45)

--First trimester surgical abortion (local aneshesia and/or minimal and/or no sedation - clients
;with AB1c AS (
SELECT pe.cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
LEFT JOIN PP_Anesthesia_ ppa
	ON ppa.enc_id = pe.enc_id
LEFT JOIN AB_Procedure_ abp
	ON abp.enc_id = pe.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('59840','59851','59840A','59840AMD','59841C','59841CMD','59841D','59841DMD') 
AND (ISNULL(ppa.anesthesia_type,'') NOT IN ('','Minimal sedation','IM sedation','IV sedation - moderate') AND ISNULL(abp.txt_sed_procedure,'') NOT IN ('','_IV Sedation','Anesthesia With CRNA'))
)
SELECT @46 = COUNT(DISTINCT person_id)
FROM AB1c
WHERE RN = 1 

INSERT INTO #ARMS VALUES ('First trimester surgical abortion (local aneshesia and/or minimal and/or no sedation - clients', @46)

--Surgical miscarriage management local anesthesia and/or minimal and/or no sedation
;with smm AS (
SELECT pe.cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
LEFT JOIN PP_Anesthesia_ ppa
	ON ppa.enc_id = pe.enc_id
LEFT JOIN AB_Procedure_ abp
	ON abp.enc_id = pe.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('59840A', '59841C', '59841D', '59841E', '59841F', '59841G', '59841H', '59841I', '59841J', '59841K', '59841L', '59841M', '59841N')
AND (ISNULL(ppa.anesthesia_type,'') IN ('Minimal sedation','') AND ISNULL(abp.txt_sed_procedure,'') NOT IN ('','_IV Sedation','Anesthesia With CRNA'))
AND (pe.diagnosis_code_id_1 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
	OR pe.diagnosis_code_id_2 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
	OR pe.diagnosis_code_id_3 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00'))
)
SELECT @47 = COUNT(*)
FROM smm
WHERE RN = 1 

INSERT INTO #ARMS VALUES ('Surgical miscarriage management (local anesthesia and/or minimal and/or no sedation', @47)

--Surgical miscarriage management (local anesthesia and/or minimal and/or no sedation - clients
;with smmc AS (
SELECT pe.cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
LEFT JOIN PP_Anesthesia_ ppa
	ON ppa.enc_id = pe.enc_id
LEFT JOIN AB_Procedure_ abp
	ON abp.enc_id = pe.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('59840A', '59841C', '59841D', '59841E', '59841F', '59841G', '59841H', '59841I', '59841J', '59841K', '59841L', '59841M', '59841N')
AND (ISNULL(ppa.anesthesia_type,'') IN ('Minimal sedation','') AND ISNULL(abp.txt_sed_procedure,'') NOT IN ('','_IV Sedation','Anesthesia With CRNA'))
AND (pe.diagnosis_code_id_1 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
	OR pe.diagnosis_code_id_2 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
	OR pe.diagnosis_code_id_3 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00'))
)
SELECT @48 = COUNT(DISTINCT person_id)
FROM smmc
WHERE RN = 1 

INSERT INTO #ARMS VALUES ('Surgical miscarriage management (local anesthesia and/or minimal and/or no sedation - clients', @48)

--Medication abortion
;with MAB AS (
SELECT pe.cpt4_code_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp desc)
FROM #proc pe
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('S0199','S0199A','S0199NC')
)
SELECT @49 = COUNT(*)
FROM MAB
WHERE RN = 1 

INSERT INTO #ARMS VALUES ('Medication abortion', @49)

--Medication abortion - clients
;with MABc AS (
SELECT cpt4_code_id, person_id, pe.enc_id,pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp desc)
FROM #proc pe
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('S0199','S0199A','S0199NC')
)
SELECT @50 = COUNT(DISTINCT person_id)
FROM MABc
WHERE RN = 1 

INSERT INTO #ARMS VALUES ('Medication abortion - clients', @50)

--Medical miscarriage management
;with MIS AS (
SELECT cpt4_code_id, person_id, pe.enc_id,pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp desc)
FROM #proc pe
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('S0199','S0199A','S0199NC')
AND (pe.diagnosis_code_id_1 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
	OR pe.diagnosis_code_id_2 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
	OR pe.diagnosis_code_id_3 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00'))	
)
SELECT @51 = COUNT(*)
FROM MIS		
WHERE RN = 1	

INSERT INTO #ARMS VALUES ('Medical miscarriage management', @51)

--Medical miscarriage management - clients	
;with MISc AS (
SELECT cpt4_code_id, person_id, pe.enc_id,pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp desc)
FROM #proc pe
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('S0199','S0199A','S0199NC')
AND (pe.diagnosis_code_id_1 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
	OR pe.diagnosis_code_id_2 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
	OR pe.diagnosis_code_id_3 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')))
SELECT @52 = COUNT(DISTINCT person_id)
FROM MISc		
WHERE RN = 1				

INSERT INTO #ARMS VALUES ('Medical miscarriage management - clients', @52)

--LEEP procedures			
;with LEEP AS (
SELECT cpt4_code_id, pe.enc_id,pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp desc)
FROM #proc pe
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('57460','57461','57522')
)
SELECT @53 = COUNT(*)
FROM LEEP
WHERE RN = 1 

INSERT INTO #ARMS VALUES ('LEEP procedures', @53)

--LEEP - clients		
;with LEEPc AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id,pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp desc)
FROM #proc pe
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('57460','57461','57522')
)
SELECT @54 = COUNT(DISTINCT person_id)
FROM LEEPc
WHERE RN = 1 

INSERT INTO #ARMS VALUES ('LEEP clients', @54)
		
--Marsupialization of Bartholin's Gland cyst		
;with BG AS (
SELECT cpt4_code_id, pe.enc_id,pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp desc)
FROM #proc pe
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('56440')
)
SELECT @55 = COUNT(*)
FROM BG
WHERE RN = 1

INSERT INTO #ARMS VALUES ('Marsupialization of Bartholins Gland cyst', @55)
		
--Mastotomy with exploration of drainage of abscess		
;with med AS (
SELECT cpt4_code_id, pe.enc_id,pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp desc)
FROM #proc pe
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('19020')
)
SELECT @56 = COUNT(*)
FROM med
WHERE RN = 1

INSERT INTO #ARMS VALUES ('Mastotomy with exploration of drainage of abscess', @56)

/* Level 6a */

--First trimester surgical abortion (moderate sedation)		
;with AB2 AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
LEFT JOIN PP_Anesthesia_ ppa
	ON ppa.enc_id = pe.enc_id
LEFT JOIN AB_Procedure_ abp
	ON abp.enc_id = pe.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('59840','59841','59840AMD','59840A','59841C','59841CMD','59841D','59841DMD')
AND (ISNULL(ppa.anesthesia_type,'') IN ('','Minimal sedation','IM sedation','IV sedation - moderate') OR ISNULL(abp.txt_sed_procedure,'') IN ('','_IV Sedation'))
)
SELECT @57 = COUNT(*)
FROM AB2
WHERE RN = 1

INSERT INTO #ARMS VALUES ('First trimester surgical abortion (moderate sedation)', @57)
		
--First trimester surgical abortion (moderate sedation) - clients
;with AB2 AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
LEFT JOIN PP_Anesthesia_ ppa
	ON ppa.enc_id = pe.enc_id
LEFT JOIN AB_Procedure_ abp
	ON abp.enc_id = pe.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('59840','59841','59840AMD','59840A','59841C','59841CMD','59841D','59841DMD')
AND (ISNULL(ppa.anesthesia_type,'') IN ('','Minimal sedation','IM sedation','IV sedation - moderate') OR ISNULL(abp.txt_sed_procedure,'') IN ('','_IV Sedation'))
)
SELECT @58 = COUNT(DISTINCT person_id)
FROM AB2
WHERE RN = 1

INSERT INTO #ARMS VALUES ('First trimester surgical abortion (moderate sedation) - clients', @58)
				
--Surgical miscarriage management (moderate sedation) 		
;with AB2 AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
LEFT JOIN PP_Anesthesia_ ppa
	ON ppa.enc_id = pe.enc_id
LEFT JOIN AB_Procedure_ abp
	ON abp.enc_id = pe.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('59840A', '59841C', '59841D', '59841E', '59841F', '59841G', '59841H', '59841I', '59841J', '59841K', '59841L', '59841M', '59841N')
AND (ISNULL(ppa.anesthesia_type,'') IN ('IM sedation','IV sedation - moderate') OR ISNULL(abp.txt_sed_procedure,'') IN ('_IV Sedation'))
AND (pe.diagnosis_code_id_1 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
	OR pe.diagnosis_code_id_2 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
	OR pe.diagnosis_code_id_3 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00'))
)
SELECT @59 = COUNT(*)
FROM AB2
WHERE RN = 1 

INSERT INTO #ARMS VALUES ('Surgical miscarriage management (moderate sedation)', @59)

--Surgical miscarriage management (moderate sedation) - clients				
;with AB2 AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
LEFT JOIN PP_Anesthesia_ ppa
	ON ppa.enc_id = pe.enc_id
LEFT JOIN AB_Procedure_ abp
	ON abp.enc_id = pe.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('59840A', '59841C', '59841D', '59841E', '59841F', '59841G', '59841H', '59841I', '59841J', '59841K', '59841L', '59841M', '59841N')
AND (ISNULL(ppa.anesthesia_type,'') IN ('IM sedation','IV sedation - moderate') OR ISNULL(abp.txt_sed_procedure,'') IN ('_IV Sedation'))
AND (pe.diagnosis_code_id_1 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
	OR pe.diagnosis_code_id_2 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
	OR pe.diagnosis_code_id_3 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00'))
)
SELECT @60 = COUNT(DISTINCT person_id)
FROM AB2
WHERE RN = 1

INSERT INTO #ARMS VALUES ('Surgical miscarriage management (moderate sedation) - clients', @60)

/* Level 7 */
--First trimester surgical abortion (deep sedation)
;with AB2 AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
LEFT JOIN PP_Anesthesia_ ppa
	ON ppa.enc_id = pe.enc_id
LEFT JOIN AB_Procedure_ abp
	ON abp.enc_id = pe.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('59840','59841','59840AMD','59840A','59841C','59841CMD','59841D','59841DMD')
AND (ISNULL(ppa.anesthesia_type,'') IN ('IV sedation - deep', 'General Anesthesia') OR ISNULL(abp.txt_sed_procedure,'') IN ('General Anesthesia','Anesthesia With CRNA'))
)
SELECT @61 = COUNT(*)
FROM AB2
WHERE RN = 1

INSERT INTO #ARMS VALUES ('First trimester surgical abortion (deep sedation)', @61)
		
--First trimester surgical abortion (deep sedation) - clients	
;with AB2 AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
LEFT JOIN PP_Anesthesia_ ppa
	ON ppa.enc_id = pe.enc_id
LEFT JOIN AB_Procedure_ abp
	ON abp.enc_id = pe.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('59840','59841','59840AMD','59840A','59841C','59841CMD','59841D','59841DMD')
AND (ISNULL(ppa.anesthesia_type,'') IN ('IV sedation - deep', 'General Anesthesia') OR ISNULL(abp.txt_sed_procedure,'') IN ('Anesthesia With CRNA'))
)
SELECT @62 = COUNT(DISTINCT person_id)
FROM AB2
WHERE RN = 1

INSERT INTO #ARMS VALUES ('First trimester surgical abortion (deep sedation) - clients', @62)

--First trimester surgical abortion (unknown anesthesia) INTERNAL USE ONLY	
SELECT @63 = 0
INSERT INTO #ARMS VALUES ('First trimester surgical abortion (unknown anesthesia) INTERNAL USE ONLY', @63)	

--First trimester surgical abortion (unknown anesthesia) - clients INTERNAL USE ONLY		
SELECT @64 = 0
INSERT INTO #ARMS VALUES ('First trimester surgical abortion (unknown anesthesia) - clients INTERNAL USE ONLY', @64)

--Surgical miscarriage management (deep sedation)	
;with AB2 AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
LEFT JOIN PP_Anesthesia_ ppa
	ON ppa.enc_id = pe.enc_id
LEFT JOIN AB_Procedure_ abp
	ON abp.enc_id = pe.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('59840A', '59841C', '59841D', '59841E', '59841F', '59841G', '59841H', '59841I', '59841J', '59841K', '59841L', '59841M', '59841N')
AND (ISNULL(ppa.anesthesia_type,'') IN ('IV sedation - deep', 'General Anesthesia') OR ISNULL(abp.txt_sed_procedure,'') IN ('Anesthesia With CRNA'))
AND (pe.diagnosis_code_id_1 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
	OR pe.diagnosis_code_id_2 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
	OR pe.diagnosis_code_id_3 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00'))
)
SELECT @65 = COUNT(*)
FROM AB2
WHERE RN = 1

INSERT INTO #ARMS VALUES ('Surgical miscarriage management (deep sedation)', @65)	

--Surgical miscarriage management (deep sedation) - clients	
;with AB2 AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
LEFT JOIN PP_Anesthesia_ ppa
	ON ppa.enc_id = pe.enc_id
LEFT JOIN AB_Procedure_ abp
	ON abp.enc_id = pe.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('59840A', '59841C', '59841D', '59841E', '59841F', '59841G', '59841H', '59841I', '59841J', '59841K', '59841L', '59841M', '59841N')
AND (ISNULL(ppa.anesthesia_type,'') IN ('IV sedation - deep', 'General Anesthesia') OR ISNULL(abp.txt_sed_procedure,'') IN ('Anesthesia With CRNA'))
AND (pe.diagnosis_code_id_1 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
	OR pe.diagnosis_code_id_2 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
	OR pe.diagnosis_code_id_3 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00'))
)
SELECT @66 = COUNT(DISTINCT person_id)
FROM AB2
WHERE RN = 1

INSERT INTO #ARMS VALUES ('Surgical miscarriage management (deep sedation) - clients', @66)

--Surgical miscarriage management (unknown anesthesia) INTERNAL USE ONLY		
SELECT @67 = 0
INSERT INTO #ARMS VALUES ('Surgical miscarriage management (unknown anesthesia) INTERNAL USE ONLY', @67)
		
--Second trimester surgical abortion (local anesthesia and / or minimal and / or no sedation)
;with smm AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
LEFT JOIN PP_Anesthesia_ ppa
	ON ppa.enc_id = pe.enc_id
LEFT JOIN AB_Procedure_ abp
	ON abp.enc_id = pe.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('59841','59850','59851','59855', '59856', '59857','59841E','59841EMD',
					 '59841F','59841FMD','59841G','59841GMD','59841H','59841HMD','59841I','59841IMD','59841J','59841JMD','59841K','59841KMD',
					 '59841L','59841LMD','59841M','59841MMD','59841N','59841NMD') 
AND (ISNULL(ppa.anesthesia_type,'') NOT IN ('','Minimal sedation','IM sedation','IV sedation - moderate') AND ISNULL(abp.txt_sed_procedure,'') NOT IN ('','_IV Sedation','Anesthesia With CRNA'))
)
SELECT @68 = COUNT(*)
FROM smm
WHERE RN = 1

INSERT INTO #ARMS VALUES ('Second trimester surgical abortion (local anesthesia and / or minimal and / or no sedation)', @68)	
			
--Second trimester surgical abortion (local anesthesia and / or minimal and /or no sedation) - clients				
;with smmc AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
LEFT JOIN PP_Anesthesia_ ppa
	ON ppa.enc_id = pe.enc_id
LEFT JOIN AB_Procedure_ abp
	ON abp.enc_id = pe.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('59841','59850','59851','59855', '59856', '59857','59841E','59841EMD',
					 '59841F','59841FMD','59841G','59841GMD','59841H','59841HMD','59841I','59841IMD','59841J','59841JMD','59841K','59841KMD',
					 '59841L','59841LMD','59841M','59841MMD','59841N','59841NMD') --, '01966'
AND (ISNULL(ppa.anesthesia_type,'') NOT IN ('','Minimal sedation','IM sedation','IV sedation - moderate') AND ISNULL(abp.txt_sed_procedure,'') NOT IN ('','_IV Sedation','Anesthesia With CRNA'))
)
SELECT @69 = COUNT(DISTINCT person_id)
FROM smmc
WHERE RN = 1 

INSERT INTO #ARMS VALUES ('Second trimester surgical abortion (local anesthesia and / or minimal and / or no sedation) - clients', @69)

/* Level 7a */
--Second trimester surgical abortion (moderate sedation)		
;with ssam AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
LEFT JOIN PP_Anesthesia_ ppa
	ON ppa.enc_id = pe.enc_id
LEFT JOIN AB_Procedure_ abp
	ON abp.enc_id = pe.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('59841','59850','59851','59855', '59856', '59857','59841E','59841EMD',
					 '59841F','59841FMD','59841G','59841GMD','59841H','59841HMD','59841I','59841IMD','59841J','59841JMD','59841K','59841KMD',
					 '59841L','59841LMD','59841M','59841MMD','59841N','59841NMD') --, '01966'
AND (ISNULL(ppa.anesthesia_type,'') IN ('','Minimal sedation','IM sedation','IV sedation - moderate') OR ISNULL(abp.txt_sed_procedure,'') IN ('','_IV Sedation'))
)
SELECT @70 = COUNT(*)
FROM ssam
WHERE RN = 1

INSERT INTO #ARMS VALUES ('Second trimester surgical abortion (moderate sedation)', @70)

--Second trimester surgical abortion (moderate sedation) - clients	
;with ssamc AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
LEFT JOIN PP_Anesthesia_ ppa
	ON ppa.enc_id = pe.enc_id
LEFT JOIN AB_Procedure_ abp
	ON abp.enc_id = pe.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('59841','59850','59851','59855', '59856', '59857','59841E','59841EMD',
					 '59841F','59841FMD','59841G','59841GMD','59841H','59841HMD','59841I','59841IMD','59841J','59841JMD','59841K','59841KMD',
					 '59841L','59841LMD','59841M','59841MMD','59841N','59841NMD')
AND (ISNULL(ppa.anesthesia_type,'') IN ('','Minimal sedation','IM sedation','IV sedation - moderate') OR ISNULL(abp.txt_sed_procedure,'') IN ('','_IV Sedation'))
)
SELECT @71 = COUNT(DISTINCT person_id)
FROM ssamc
WHERE RN = 1 

INSERT INTO #ARMS VALUES ('Second trimester surgical abortion (moderate sedation) - clients', @71)

/* Level 8 */
--Second trimester surgical abortion (deep sedation)
;with ssad AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
LEFT JOIN PP_Anesthesia_ ppa
	ON ppa.enc_id = pe.enc_id
LEFT JOIN AB_Procedure_ abp
	ON abp.enc_id = pe.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('59841','59850','59851','59855', '59856', '59857','59841E','59841EMD',
					 '59841F','59841FMD','59841G','59841GMD','59841H','59841HMD','59841I','59841IMD','59841J','59841JMD','59841K','59841KMD',
					 '59841L','59841LMD','59841M','59841MMD','59841N','59841NMD')
AND (ISNULL(ppa.anesthesia_type,'') IN ('IV sedation - deep', 'General Anesthesia') OR ISNULL(abp.txt_sed_procedure,'') IN ('Anesthesia With CRNA', 'General Anesthesia'))
)
SELECT @72 = COUNT(*)
FROM ssad
WHERE RN = 1

INSERT INTO #ARMS VALUES ('Second trimester surgical abortion (deep sedation)', @72)	
				
--Second trimester surgical abortion (deep sedation) - clients	
;with ssadc AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
LEFT JOIN PP_Anesthesia_ ppa
	ON ppa.enc_id = pe.enc_id
LEFT JOIN AB_Procedure_ abp
	ON abp.enc_id = pe.enc_id
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('59841','59850','59851','59855', '59856', '59857','59841E','59841EMD',
					 '59841F','59841FMD','59841G','59841GMD','59841H','59841HMD','59841I','59841IMD','59841J','59841JMD','59841K','59841KMD',
					 '59841L','59841LMD','59841M','59841MMD','59841N','59841NMD')
AND (ISNULL(ppa.anesthesia_type,'') IN ('IV sedation - deep', 'General Anesthesia') OR ISNULL(abp.txt_sed_procedure,'') IN ('Anesthesia With CRNA', 'General Anesthesia'))
)
SELECT @73 = COUNT(DISTINCT person_id)
FROM ssadc
WHERE RN = 1

INSERT INTO #ARMS VALUES ('Second trimester surgical abortion (deep sedation) - clients', @73)
			
--Second trimester surgical abortion (unknown anesthesia) INTERNAL USE ONLY
SELECT @74 = 0
INSERT INTO #ARMS VALUES ('Second trimester surgical abortion (unknown anesthesia) INTERNAL USE ONLY', @74)
		
--Second trimester surgical abortion (unknown anesthesia) - clients INTERNAL USE ONLY		
SELECT @75 = 0
INSERT INTO #ARMS VALUES ('Second trimester surgical abortion (unknown anesthesia) - clients INTERNAL USE ONLY', @75)

--Total unduplicated abortion clients		
SELECT @76 = (CAST(@46 AS INT) + CAST(@49 AS INT) + CAST(@58 AS INT) + CAST(@62 AS INT) + CAST(@69 AS INT) + CAST(@71 AS INT) + CAST(@73 AS INT))
INSERT INTO #ARMS VALUES ('Total unduplicated abortion clients', @76)		
		
--Transabdominal tubal sterilization
;with tts AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('58600','58605','58611','58615')
)
SELECT @77 = COUNT(*)
FROM tts
WHERE RN = 1

INSERT INTO #ARMS VALUES ('Transabdominal tubal sterilization', @77)		
	
--Transabdominal tubal sterilization - Joint Venture  DNA	
SELECT @78 = 'DNA'
INSERT INTO #ARMS VALUES ('Transabdominal tubal sterilization - Joint Venture', @78)
			
--Transabdominal tubal sterilization - Pass Through  DNA	
SELECT @79 = 'DNA'
INSERT INTO #ARMS VALUES ('Transabdominal tubal sterilization - Pass Through', @79)
			
--Hysteroscopic tubal sterilization - Essure	
;with hts AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
WHERE pe.sex = 'F' 
AND cpt4_code_id LIKE '58565%'
)
SELECT @80 = COUNT(*)
FROM hts
WHERE RN = 1

INSERT INTO #ARMS VALUES ('Hysteroscopic tubal sterilization - Essure', @80)
			
--Hysteroscopic tubal sterilization - Essure - Joint Venture  DNA		
SELECT @81 = 'DNA'
INSERT INTO #ARMS VALUES ('Hysteroscopic tubal sterilization - Essure - Joint Venture', @81)
		
--Hysteroscopic tubal sterilization - Essure - Pass Through DNA	
SELECT @82 = 'DNA'
INSERT INTO #ARMS VALUES ('Hysteroscopic tubal sterilization - Essure - Pass Through', @82)
			
--Excision of Skene's or Bartholin's Gland
;with ebg AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('53270','56740')
)
SELECT @83 = COUNT(*)
FROM ebg
WHERE RN = 1

INSERT INTO #ARMS VALUES ('Excision of Skenes or Bartholins Gland', @83)
			
--Diagnostic laparoscopy	
;with dl AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
WHERE pe.sex = 'F'
AND cpt4_code_id IN ('49320')
)
SELECT @84 = COUNT(*)
FROM dl
WHERE RN = 1 

INSERT INTO #ARMS VALUES ('Diagnostic laparoscopy', @84)
		
--Hysteroscopy (non-sterilization)		
;with hyst AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
WHERE pe.sex = 'F' 
AND cpt4_code_id BETWEEN '58555' AND '58563'
)
SELECT @85 = COUNT(*)
FROM hyst
WHERE RN = 1

INSERT INTO #ARMS VALUES ('Hysteroscopy (non-sterilization)', @85)
		
--Ablation of extensive CIN (cervical dysplasia) or condylomata				
;with abl AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
WHERE pe.sex = 'F' 
AND cpt4_code_id IN ('56515')
)
SELECT @86 = COUNT(*)
FROM abl
WHERE RN = 1

INSERT INTO #ARMS VALUES ('Ablation of extensive CIN (cervical dysplasia) or condylomata', @86)

--Hymenotomy	
;with hym AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
WHERE pe.sex = 'F' 
AND cpt4_code_id = '56442'
)
SELECT @87 = COUNT(*)
FROM hym
WHERE RN = 1

INSERT INTO #ARMS VALUES ('Hymenotomy', @87)
			
--Perineoplasty	
;with peri AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
WHERE pe.sex = 'F' 
AND cpt4_code_id = '56810'
)
SELECT @88 = COUNT(*)
FROM peri
WHERE RN = 1 

INSERT INTO #ARMS VALUES ('Perineoplasty', @88)
			
--Cone biopsy
;with cone AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
WHERE pe.sex = 'F'
AND cpt4_code_id = '57520'
)
SELECT @89 = COUNT(*)
FROM cone
WHERE RN = 1 

INSERT INTO #ARMS VALUES ('Cone biopsy', @89)
			
--Diagnostic D&C under deep sedation	
;with DNC AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
WHERE pe.sex = 'F'
AND cpt4_code_id IN ('58120','00940')
)
SELECT @90 = COUNT(*)
FROM DNC
WHERE RN = 1

INSERT INTO #ARMS VALUES ('Diagnostic D&C under deep sedation', @90)
		
--Uterine evacuation and curettage for hydatiform mole
;with utev AS (
SELECT cpt4_code_id, pe.person_id, pe.enc_id, pe.enc_timestamp, RN = ROW_NUMBER() OVER
(PARTITION BY pe.enc_id ORDER BY pe.enc_timestamp DESC)
FROM #proc pe
WHERE pe.sex = 'F'
AND cpt4_code_id = '59870'
)
SELECT @91 = COUNT(*)
FROM utev
WHERE RN = 1

INSERT INTO #ARMS VALUES ('Uterine evacuation and curettage for hydatiform mole', @91)			

/* Non-Reproductive Health Care */

--Basic Non-Reproductive Health Care 
/* Level 2 */
--Non-reproductive health care visits
SELECT @92 = 0				
INSERT INTO #ARMS VALUES ('Non-reproductive health care visits', @92)
--Counseling			
SELECT @93 = 0				
INSERT INTO #ARMS VALUES ('Counseling', @93)

--Intermediate Non-Reproductive Health Care
/* Level 3 */
--Office visit - high complexity	
SELECT @94 = 0				
INSERT INTO #ARMS VALUES ('Office visit - high complexity', @94)			

--Initial preventive medicine (adults 18 - 39)
SELECT @95 = 0				
INSERT INTO #ARMS VALUES ('Initial preventive medicine (adults 18 - 39)', @95)
			
/********************************************************************************************************/
/* Tests, Positives and Diagnoses */
--FEMALE
--Pregnancy tests	
SELECT @117 = COUNT(*)
FROM #enc pe
JOIN order_ o
	ON o.encounterID = pe.enc_id
WHERE pe.sex = 'F'
AND actCode IN ('81025','81025K')
AND actStatus = 'completed'	

INSERT INTO #ARMS VALUES ('Pregnancy tests', @117)

--Pregnancy tests / positives	
SELECT @118 = COUNT(*)
FROM #enc pe
JOIN order_ o
	ON o.encounterID = pe.enc_id
WHERE pe.sex = 'F'
AND actCode IN ('81025','81025K')
AND actStatus = 'completed'
AND obsValue = 'positive'

INSERT INTO #ARMS VALUES ('Pregnancy tests positives', @118)
	
--Gonorrhea tests		
SELECT @119 = COUNT(*)
FROM #Labs l
WHERE sex = 'F'
AND l.test_code_id IN ('10256','11363','16504','16506','1759','196250','199123','2649','3636','3640','375','395','4558','498','501','6399','70049',
'70051','70222','8396','8472','8475','CT4','GC6','NG001404','NG001545','NG002014','Voxent1000')
AND l.Result_Description IN ('GC','NEISSERIA GONORRHOEAE RNA, TMA','NEISSERIA GONORRHOEAE (GC) CULTURE','NEISSERIA GONORRHOEAE RNA, TMA, RECTAL',
							'NEISSERIA GONORRHOEAE RNA, TMA, THROAT','Neisseria gonorrhoeae, NAA')

INSERT INTO #ARMS VALUES ('Gonorrhea tests', @119)

--Gonorrhea tests / positives		
SELECT @120 = COUNT(*)
FROM #Labs l
WHERE sex = 'F'
AND l.test_code_id IN ('10256','11363','16504','16506','1759','196250','199123','2649','3636','3640','375','395','4558','498','501','6399','70049',
'70051','70222','8396','8472','8475','CT4','GC6','NG001404','NG001545','NG002014','Voxent1000')
AND l.Result_Description IN ('GC','NEISSERIA GONORRHOEAE RNA, TMA','NEISSERIA GONORRHOEAE (GC) CULTURE','NEISSERIA GONORRHOEAE RNA, TMA, RECTAL',
							'NEISSERIA GONORRHOEAE RNA, TMA, THROAT','Neisseria gonorrhoeae, NAA')
AND l.Result_Value IN ('POSITIVE','DETECTED')

INSERT INTO #ARMS VALUES ('Gonorrhea tests positives', @120)
		
--Syphilis tests
SELECT @121 = COUNT(*)
FROM #Labs l
WHERE sex = 'F'
AND l.test_code_id IN ('70222','L026','5233','6399','2649','93170','3640','1759','10256','498','8472','11363','16506','3636')
AND l.Result_Description IN ('RPR (DX) W/REFL TITER AND CONFIRMATORY TESTING','RPR')

INSERT INTO #ARMS VALUES ('Syphilis tests', @121)

--Syphilis tests / positives		
SELECT @122 = COUNT(*)
FROM #Labs l
WHERE sex = 'F'
AND l.test_code_id IN ('70222','L026','5233','6399','2649','93170','3640','1759','10256','498','8472','11363','16506','3636')
AND l.Result_Description IN ('RPR (DX) W/REFL TITER AND CONFIRMATORY TESTING','RPR')
AND l.Abnormal_Flag = 'A'

INSERT INTO #ARMS VALUES ('Syphilis tests positives', @122)

--Chlamydia tests		
SELECT @123 = COUNT(*)
FROM #Labs l
WHERE sex = 'F'
AND l.test_code_id IN ('10256','11363','16506','1759','196250','199123','2649','3636','3640','375','395','4558','498',
'501','6399','70051','70222','8396','8472','8475','CT4','GC6','NG001404','NG001545','NG002014','Voxent1000')
AND l.Result_Description IN ('','CT','CHLAMYDIA TRACHOMATIS RNA, TMA','CHLAMYDIA TRACHOMATIS RNA, TMA, RECTAL','Chlamydia trachomatis, NAA',
							'CHLAMYDIA TRACHOMATIS RNA, TMA, THROAT')

INSERT INTO #ARMS VALUES ('Chlamydia tests', @123)

--Chlamydia tests / positives		
SELECT @124 = COUNT(*)
FROM #Labs l
WHERE sex = 'F'
AND l.test_code_id IN ('10256','11363','16506','1759','196250','199123','2649','3636','3640','375','395','4558','498',
'501','6399','70051','70222','8396','8472','8475','CT4','GC6','NG001404','NG001545','NG002014','Voxent1000')
AND l.Result_Description IN ('','CT','CHLAMYDIA TRACHOMATIS RNA, TMA','CHLAMYDIA TRACHOMATIS RNA, TMA, RECTAL','Chlamydia trachomatis, NAA',
							'CHLAMYDIA TRACHOMATIS RNA, TMA, THROAT')
AND l.Result_Value IN ('POSITIVE','DETECTED')

INSERT INTO #ARMS VALUES ('Chlamydia tests positives', @124)

--Genital herpes blood tests
SELECT @125 = COUNT(*) --(DISTINCT enc_id)
FROM #Labs l
WHERE sex = 'F'
AND l.test_code_id IN ('11363','16506','19550','196250','2649','3636','3640','395','498','501','5233','6399','70222','792',
'8472','8475','93170')
AND l.Result_Description IN ('HSV 1 IGG TYPE SPECIFIC AB','HSV 2 IGG TYPE SPECIFIC AB')

INSERT INTO #ARMS VALUES ('Genital herpes blood tests', @125)

--Genital herpes blood tests / positives	
SELECT  @126 = COUNT(*)
FROM #Labs l
WHERE l.sex = 'F'
AND l.test_code_id IN ('11363','16506','19550','196250','2649','3636','3640','395','498','501','5233','6399','70222','792',
'8472','8475','93170')
AND l.Result_Description IN ('HSV 1 IGG TYPE SPECIFIC AB','HSV 2 IGG TYPE SPECIFIC AB')
AND l.Abnormal_Flag <> 'N'

INSERT INTO #ARMS VALUES ('Genital herpes blood tests positives', @126)
			
--Genital herpes culture tests	
SELECT @127 = COUNT(DISTINCT pe.enc_id)
FROM #enc pe
JOIN #Labs l
	ON l.enc_id = pe.enc_id
WHERE pe.sex = 'F'
AND l.test_code_id IN ('2649', '17495', '2692')
AND l.Result_Description ='HERPES SIMPLEX VIRUS CULTURE W/RFL TO TYPING'	

INSERT INTO #ARMS VALUES ('Genital herpes culture tests', @127)

--Genital herpes culture tests / positives		
SELECT @128 = COUNT(DISTINCT pe.enc_id)
FROM #enc pe
JOIN #Labs l
	ON l.enc_id = pe.enc_id
WHERE pe.sex = 'F'
AND l.test_code_id IN ('2649', '17495', '2692')
AND l.Result_Description ='HERPES SIMPLEX VIRUS CULTURE W/RFL TO TYPING'
AND ISNULL(l.Abnormal_Flag,'N') <> 'N'		

INSERT INTO #ARMS VALUES ('Genital herpes culture tests positives', @128)

--Genital herpes unspecified (DNA / protein with unspecified specimen) tests
SELECT @129 = 0
INSERT INTO #ARMS VALUES ('Genital herpes unspecified (DNA / protein with unspecified specimen) tests', @129)
--Genital herpes unspecified (DNA / protein with unspecified specimen) tests / positives
SELECT @130 = 0	
INSERT INTO #ARMS VALUES ('Genital herpes unspecified (DNA / protein with unspecified specimen) tests positives', @130)
			
--Hepatitis B tests
SELECT @131 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex = 'F'
AND l.test_code_id IN ('498', '501', '498', '8475', '498', '499', '501')
AND l.Result_Description like '%hepatitis b%'
AND ISNULL(l.Abnormal_Flag,'N') = 'A'

INSERT INTO #ARMS VALUES ('Hepatitis B tests', @131)

--Hepatitis B tests / positives
SELECT @132 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex = 'F'
AND l.test_code_id IN ('498', '501', '498', '8475', '498', '499', '501')
AND l.Result_Description like '%hepatitis b%'
AND ISNULL(l.Abnormal_Flag,'N') = 'A'

INSERT INTO #ARMS VALUES ('Hepatitis B tests positives', @132)

--Hepatitis C tests	
SELECT @133 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex = 'F'
AND l.test_code_id IN ('8472')
AND l.Result_Description like '%hepatitis c%'

INSERT INTO #ARMS VALUES ('Hepatitis C tests', @133)

--Hepatitis C tests / positives			
SELECT @134 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex = 'F'
AND l.test_code_id IN ('8472')
AND l.Result_Description like '%hepatitis c%'
AND ISNULL(l.Abnormal_Flag,'N') = 'A'

INSERT INTO #ARMS VALUES ('Hepatitis C tests positives', @134)
	
--Trichomoniasis diagnoses		
SELECT @135 = COUNT(DISTINCT pd.person_id)
FROM patient_diagnosis pd
JOIN #enc pe 
	ON pd.person_id = pe.person_id
WHERE pe.sex = 'F'
AND pd.icd9cm_code_id IN ('A59.03','A59.01')

INSERT INTO #ARMS VALUES ('Trichomoniasis diagnoses', @135)
		
--Genital wart diagnoses	
SELECT @136 = COUNT(DISTINCT pd.person_id)
FROM patient_diagnosis pd
JOIN #enc pe 
	ON pd.person_id = pe.person_id
WHERE pe.sex = 'F'
AND pd.icd9cm_code_id IN ('A63.0')

INSERT INTO #ARMS VALUES ('Genital wart diagnoses', @136)
			
--HPV tests	
SELECT @137 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE l.sex = 'F'
AND l.test_code_id IN ('191940', '196250', '507301', '90649', '192047', '196250', '197146', '199123', '507301', '87210', 
						'194074', '196250', '199123', '81002', '87210', '90649')
AND l.Result_Description IN ('HPV, high-risk', 'DIAGNOSIS:')

INSERT INTO #ARMS VALUES ('HPV tests', @137)

--HPV tests / positives		
SELECT @138 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex = 'F'
AND l.test_code_id IN ('191940', '196250', '507301', '90649', '192047', '196250', '197146', '199123', '507301', '87210', 
						'194074', '196250', '199123', '81002', '87210', '90649')
AND l.Result_Description IN ('HPV, high-risk', 'DIAGNOSIS:')
AND ISNULL(l.Abnormal_Flag,'N') = 'A'	

INSERT INTO #ARMS VALUES ('HPV tests positives', @138)
	
--HIV rapid tests	
SELECT @139 = COUNT(DISTINCT pe.enc_id)
FROM #enc pe
JOIN order_ o
	ON o.encounterID = pe.enc_id
WHERE pe.sex = 'F'
AND actCode IN ('87806','86701','86703')
AND actStatus = 'completed'

INSERT INTO #ARMS VALUES ('HIV rapid tests', @139)
			
--HIV send-out tests	
SELECT @140 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex = 'F'
AND l.test_code_id IN ('93170', '5233', '19728', '40085')
AND l.Result_Description LIKE '%hiv%'

INSERT INTO #ARMS VALUES ('HIV send-out tests', @140)
			
--Confirmed HIV positives		
SELECT @141 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex = 'F'
AND l.test_code_id IN ('93170', '5233', '19728', '40085')
AND l.Result_Description LIKE '%hiv%'
AND ISNULL(l.Abnormal_Flag,'N') = 'A'

INSERT INTO #ARMS VALUES ('Confirmed HIV positives', @141)
		
--Other STI tests		
SELECT @142 = 'DNA'
INSERT INTO #ARMS VALUES ('Other STI tests', @142)

--Other STI tests positives		
SELECT @143 = 'DNA'
INSERT INTO #ARMS VALUES ('Other STI tests positives', @143)
				
--Liquid-based Pap tests	
SELECT @144 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex = 'F'
AND l.test_code_id IN ('196250', '199123','193000')

INSERT INTO #ARMS VALUES ('Liquid-based Pap tests', @144)
				
--Conventional Pap tests 
SELECT @145 = 0
INSERT INTO #ARMS VALUES ('Conventional Pap tests', @145)
				
--Pap tests - type unknown 
SELECT @146 = 0	
INSERT INTO #ARMS VALUES ('Pap tests - type unknown', @146)
		
--Pap tests resulting in ASCUS, low-grade, high-grade, cancerous, or AGUS diagnoses	
SELECT @147 = 0		
INSERT INTO #ARMS VALUES ('Pap tests resulting in ASCUS, low-grade, high-grade, cancerous, or AGUS diagnoses', @147)
			
--Breast examinations
SELECT  @148 = COUNT(distinct pe.enc_id) 
FROM #enc pe
JOIN pe_breast_ pb 
	ON pb.enc_id = pe.enc_id
WHERE (pb.palpr_nl = '1' 
		OR pb.palpL_nL = '1' 
		OR pb.palpb_nl = '1' 
		OR ISNULL(pb.palponly1,'') <>'' 
		OR ISNULL(pb.palponly2,'') <>'' 
		OR ISNULL(pb.palponly3,'') <>'' 
		OR ISNULL(pb.palponly4,'') <>'' 
		OR ISNULL(pb.palpb1,'') <>'' 
		OR ISNULL(pb.palpb2,'') <>''
		) 
AND sex = 'F'

INSERT INTO #ARMS VALUES ('Breast examinations', @148)

--Breast examinations positives
SELECT @149 = COUNT(distinct pe.enc_id) 
FROM #enc pe
JOIN pe_breast_ pb 
	ON pb.enc_id = pe.enc_id
JOIN pe_breast_palp_ bp
	ON pb.enc_id = bp.enc_id
WHERE (    
		   (pb.palpr_nl <> '1' AND (ISNULL(pb.palponly1,'') <>'' OR ISNULL(pb.palponly2,'') <>'' ) AND bp.size5a IS NOT NULL)
		OR (pb.palpL_nL <> '1' AND (ISNULL(pb.palponly3,'') <>'' OR ISNULL(pb.palponly4,'') <>'' ) AND bp.size7a IS NOT NULL)
	  )
AND sex = 'F'

INSERT INTO #ARMS VALUES ('Breast examinations positives', @149)

			
--BRSQs (Breast Risk Screening Questionnaire) conducted 
SELECT @150 = COUNT(*)
FROM #enc e
JOIN obgyn_histories_mrp_ ohm
	ON e.enc_id = ohm.enc_id
JOIN PP_Breast_CA_Risk_Screen_ ppba
	ON ohm.enc_id = ppba.enc_id
LEFT JOIN PPPS_BRSQ_ brsq
	ON e.enc_id = brsq.enc_id
WHERE e.sex = 'F' 
AND ((ohm.medicalHx31 <>'' AND ohm.medicalhx46 <>'')
AND (ppba.familyHx_01 <>'' AND ppba.familyHx_02 <>''))
OR brsq.docgen = 1

INSERT INTO #ARMS VALUES ('Breast Risk Screening Questionnaire) conducted', @150)

--MALE-------------------------------------------------------------------------------------
--Gonorrhea tests		
SELECT @151 = COUNT(*)
FROM #Labs l
WHERE sex = 'M'
AND l.test_code_id IN ('10256','11363','16504','16506','1759','196250','199123','2649','3636','3640','375','395','4558','498','501','6399','70049',
'70051','70222','8396','8472','8475','CT4','GC6','NG001404','NG001545','NG002014','Voxent1000')
AND l.Result_Description IN ('GC','NEISSERIA GONORRHOEAE RNA, TMA','NEISSERIA GONORRHOEAE (GC) CULTURE','NEISSERIA GONORRHOEAE RNA, TMA, RECTAL',
							'NEISSERIA GONORRHOEAE RNA, TMA, THROAT','Neisseria gonorrhoeae, NAA')

INSERT INTO #ARMS VALUES ('Gonorrhea tests', @151)

--Gonorrhea tests / positives		
SELECT @152 = COUNT(*)
FROM #Labs l
WHERE sex = 'M'
AND l.test_code_id IN ('10256','11363','16504','16506','1759','196250','199123','2649','3636','3640','375','395','4558','498','501','6399','70049',
'70051','70222','8396','8472','8475','CT4','GC6','NG001404','NG001545','NG002014','Voxent1000')
AND l.Result_Description IN ('GC','NEISSERIA GONORRHOEAE RNA, TMA','NEISSERIA GONORRHOEAE (GC) CULTURE','NEISSERIA GONORRHOEAE RNA, TMA, RECTAL',
							'NEISSERIA GONORRHOEAE RNA, TMA, THROAT','Neisseria gonorrhoeae, NAA')
AND l.Result_Value IN ('POSITIVE','DETECTED')

INSERT INTO #ARMS VALUES ('Gonorrhea tests positives', @152)
		
--Syphilis tests
SELECT @153 = COUNT(*)
FROM #Labs l
WHERE sex = 'M'
AND l.test_code_id IN ('70222','L026','5233','6399','2649','93170','3640','1759','10256','498','8472','11363','16506','3636')
AND l.Result_Description IN ('RPR (DX) W/REFL TITER AND CONFIRMATORY TESTING','RPR')

INSERT INTO #ARMS VALUES ('Syphilis tests', @153)

--Syphilis tests / positives		
SELECT @154 = COUNT(*)
FROM #Labs l
WHERE sex = 'M'
AND l.test_code_id IN ('70222','L026','5233','6399','2649','93170','3640','1759','10256','498','8472','11363','16506','3636')
AND l.Result_Description IN ('RPR (DX) W/REFL TITER AND CONFIRMATORY TESTING','RPR')
AND l.Abnormal_Flag = 'A'

INSERT INTO #ARMS VALUES ('Syphilis tests positives', @154)

--Chlamydia tests		
SELECT @155 = COUNT(*)
FROM #Labs l
WHERE sex = 'M'
AND l.test_code_id IN ('10256','11363','16506','1759','196250','199123','2649','3636','3640','375','395','4558','498',
'501','6399','70051','70222','8396','8472','8475','CT4','GC6','NG001404','NG001545','NG002014','Voxent1000')
AND l.Result_Description IN ('','CT','CHLAMYDIA TRACHOMATIS RNA, TMA','CHLAMYDIA TRACHOMATIS RNA, TMA, RECTAL','Chlamydia trachomatis, NAA',
							'CHLAMYDIA TRACHOMATIS RNA, TMA, THROAT')

INSERT INTO #ARMS VALUES ('Chlamydia tests', @155)

--Chlamydia tests / positives		
SELECT @156 = COUNT(*)
FROM #Labs l
WHERE sex = 'M'
AND l.test_code_id IN ('10256','11363','16506','1759','196250','199123','2649','3636','3640','375','395','4558','498',
'501','6399','70051','70222','8396','8472','8475','CT4','GC6','NG001404','NG001545','NG002014','Voxent1000')
AND l.Result_Description IN ('','CT','CHLAMYDIA TRACHOMATIS RNA, TMA','CHLAMYDIA TRACHOMATIS RNA, TMA, RECTAL','Chlamydia trachomatis, NAA',
							'CHLAMYDIA TRACHOMATIS RNA, TMA, THROAT')
AND l.Result_Value IN ('POSITIVE','DETECTED')

INSERT INTO #ARMS VALUES ('Chlamydia tests positives', @156)

--Genital herpes blood tests
SELECT @157 = COUNT(*)
FROM #Labs l
WHERE sex = 'M'
AND l.test_code_id IN ('11363','16506','19550','196250','2649','3636','3640','395','498','501','5233','6399','70222','792',
'8472','8475','93170')
AND l.Result_Description IN ('HSV 1 IGG TYPE SPECIFIC AB','HSV 2 IGG TYPE SPECIFIC AB')

INSERT INTO #ARMS VALUES ('Genital herpes blood tests', @157)

--Genital herpes blood tests / positives	
SELECT @158 = COUNT(*)
FROM #Labs l
WHERE sex = 'M'
AND l.test_code_id IN ('11363','16506','19550','196250','2649','3636','3640','395','498','501','5233','6399','70222','792',
'8472','8475','93170')
AND l.Result_Description IN ('HSV 1 IGG TYPE SPECIFIC AB','HSV 2 IGG TYPE SPECIFIC AB')
AND l.Abnormal_Flag <> 'N'

INSERT INTO #ARMS VALUES ('Genital herpes blood tests positives', @158)
			
--Genital herpes culture tests	
SELECT @159 = COUNT(DISTINCT pe.enc_id)
FROM #enc pe
JOIN #Labs l
	ON l.enc_id = pe.enc_id
WHERE pe.sex = 'M'
AND l.test_code_id IN ('2649', '17495', '2692')
AND l.Result_Description ='HERPES SIMPLEX VIRUS CULTURE W/RFL TO TYPING'	

INSERT INTO #ARMS VALUES ('Genital herpes culture tests', @159)

--Genital herpes culture tests / positives		
SELECT @160 = COUNT(DISTINCT pe.enc_id)
FROM #enc pe
JOIN #Labs l
	ON l.enc_id = pe.enc_id
WHERE pe.sex = 'M'
AND l.test_code_id IN ('2649', '17495', '2692')
AND l.Result_Description ='HERPES SIMPLEX VIRUS CULTURE W/RFL TO TYPING'
AND ISNULL(l.Abnormal_Flag,'N') <> 'N'		

INSERT INTO #ARMS VALUES ('Genital herpes culture tests positives', @160)

--Genital herpes unspecified (DNA / protein with unspecified specimen) tests
SELECT @161 = 0
INSERT INTO #ARMS VALUES ('Genital herpes unspecified (DNA / protein with unspecified specimen) tests', @161)

--Genital herpes unspecified (DNA / protein with unspecified specimen) tests / positives
SELECT @162 = 0	
INSERT INTO #ARMS VALUES ('Genital herpes unspecified (DNA / protein with unspecified specimen) tests positives', @162)
			
--Hepatitis B tests
SELECT @163 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex = 'M'
AND l.test_code_id IN ('498', '501', '498', '8475', '498', '499', '501')
AND l.Result_Description like '%hepatitis b%'
AND ISNULL(l.Abnormal_Flag,'N') = 'A'

INSERT INTO #ARMS VALUES ('Hepatitis B tests', @163)

--Hepatitis B tests / positives
SELECT @164 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex = 'M'
AND l.test_code_id IN ('498', '501', '498', '8475', '498', '499', '501')
AND l.Result_Description like '%hepatitis b%'
AND ISNULL(l.Abnormal_Flag,'N') = 'A'

INSERT INTO #ARMS VALUES ('Hepatitis B tests positives', @164)

--Hepatitis C tests	
SELECT @165 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex = 'M'
AND l.test_code_id IN ('8472')
AND l.Result_Description like '%hepatitis c%'

INSERT INTO #ARMS VALUES ('Hepatitis C tests', @165)

--Hepatitis C tests / positives			
SELECT @166 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex = 'M'
AND l.test_code_id IN ('8472')
AND l.Result_Description like '%hepatitis c%'
AND ISNULL(l.Abnormal_Flag,'N') = 'A'

INSERT INTO #ARMS VALUES ('Hepatitis C tests positives', @166)
	
--Trichomoniasis diagnoses		
SELECT @167 = COUNT(DISTINCT pd.person_id)
FROM patient_diagnosis pd
JOIN #enc pe 
	ON pd.person_id = pe.person_id
WHERE pe.sex = 'M'
AND pd.icd9cm_code_id IN ('A59.03','A59.01')

INSERT INTO #ARMS VALUES ('Trichomoniasis diagnoses', @167)
		
--Genital wart diagnoses	
SELECT @168 = COUNT(DISTINCT pd.person_id)
FROM patient_diagnosis pd
JOIN #enc pe 
	ON pd.person_id = pe.person_id
WHERE pe.sex = 'M'
AND pd.icd9cm_code_id IN ('A63.0')

INSERT INTO #ARMS VALUES ('Genital wart diagnoses', @168)
		
--HIV rapid tests	
SELECT @169 = COUNT(DISTINCT pe.enc_id)
FROM #enc pe
JOIN order_ o
	ON o.encounterID = pe.enc_id
WHERE pe.sex = 'M'
AND actCode IN ('87806','86701','86703')
AND actStatus = 'completed'

INSERT INTO #ARMS VALUES ('HIV rapid tests', @169)
			
--HIV send-out tests	
SELECT @170 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex = 'M'
AND l.test_code_id IN ('93170', '5233', '19728', '40085')
AND l.Result_Description LIKE '%hiv%'

INSERT INTO #ARMS VALUES ('HIV send-out tests', @170)
			
--Confirmed HIV positives		
SELECT @171 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex = 'M'
AND l.test_code_id IN ('93170', '5233', '19728', '40085')
AND l.Result_Description LIKE '%hiv%'
AND ISNULL(l.Abnormal_Flag,'N') = 'A'

INSERT INTO #ARMS VALUES ('Confirmed HIV positives', @171)
		
--Other STI tests		
SELECT @172 = 'DNA'
INSERT INTO #ARMS VALUES ('Other STI tests', @172)

--Other STI tests positives		
SELECT @173 = 'DNA'
INSERT INTO #ARMS VALUES ('Other STI tests positives', @173)		

--GENDER UNKNOWN------------------------------------------------------------------------------------
--Gonorrhea tests		
SELECT @174 = COUNT(*)
FROM #Labs l
WHERE sex NOT IN ('F','M')
AND l.test_code_id IN ('10256','11363','16504','16506','1759','196250','199123','2649','3636','3640','375','395','4558','498','501','6399','70049',
'70051','70222','8396','8472','8475','CT4','GC6','NG001404','NG001545','NG002014','Voxent1000')
AND l.Result_Description IN ('GC','NEISSERIA GONORRHOEAE RNA, TMA','NEISSERIA GONORRHOEAE (GC) CULTURE','NEISSERIA GONORRHOEAE RNA, TMA, RECTAL',
							'NEISSERIA GONORRHOEAE RNA, TMA, THROAT','Neisseria gonorrhoeae, NAA')

INSERT INTO #ARMS VALUES ('Gonorrhea tests', @174)

--Gonorrhea tests / positives		
SELECT @175 = COUNT(*)
FROM #Labs l
WHERE sex NOT IN ('F','M')
AND l.test_code_id IN ('10256','11363','16504','16506','1759','196250','199123','2649','3636','3640','375','395','4558','498','501','6399','70049',
'70051','70222','8396','8472','8475','CT4','GC6','NG001404','NG001545','NG002014','Voxent1000')
AND l.Result_Description IN ('GC','NEISSERIA GONORRHOEAE RNA, TMA','NEISSERIA GONORRHOEAE (GC) CULTURE','NEISSERIA GONORRHOEAE RNA, TMA, RECTAL',
							'NEISSERIA GONORRHOEAE RNA, TMA, THROAT','Neisseria gonorrhoeae, NAA')
AND l.Result_Value IN ('POSITIVE','DETECTED')

INSERT INTO #ARMS VALUES ('Gonorrhea tests positives', @175)
		
--Syphilis tests
SELECT @176 = COUNT(*)
FROM #Labs l
WHERE sex NOT IN ('F','M')
AND l.test_code_id IN ('70222','L026','5233','6399','2649','93170','3640','1759','10256','498','8472','11363','16506','3636')
AND l.Result_Description IN ('RPR (DX) W/REFL TITER AND CONFIRMATORY TESTING','RPR')

INSERT INTO #ARMS VALUES ('Syphilis tests', @176)

--Syphilis tests / positives		
SELECT @177 = COUNT(*)
FROM #Labs l
WHERE sex NOT IN ('F','M')
AND l.test_code_id IN ('70222','L026','5233','6399','2649','93170','3640','1759','10256','498','8472','11363','16506','3636')
AND l.Result_Description IN ('RPR (DX) W/REFL TITER AND CONFIRMATORY TESTING','RPR')
AND l.Abnormal_Flag = 'A'

INSERT INTO #ARMS VALUES ('Syphilis tests positives', @177)

--Chlamydia tests		
SELECT @178 = COUNT(*)
FROM #Labs l
WHERE sex NOT IN ('F','M')
AND l.test_code_id IN ('10256','11363','16506','1759','196250','199123','2649','3636','3640','375','395','4558','498',
'501','6399','70051','70222','8396','8472','8475','CT4','GC6','NG001404','NG001545','NG002014','Voxent1000')
AND l.Result_Description IN ('','CT','CHLAMYDIA TRACHOMATIS RNA, TMA','CHLAMYDIA TRACHOMATIS RNA, TMA, RECTAL','Chlamydia trachomatis, NAA',
							'CHLAMYDIA TRACHOMATIS RNA, TMA, THROAT')

INSERT INTO #ARMS VALUES ('Chlamydia tests', @178)

--Chlamydia tests / positives		
SELECT @179 = COUNT(*)
FROM #Labs l
WHERE sex NOT IN ('F','M')
AND l.test_code_id IN ('10256','11363','16506','1759','196250','199123','2649','3636','3640','375','395','4558','498',
'501','6399','70051','70222','8396','8472','8475','CT4','GC6','NG001404','NG001545','NG002014','Voxent1000')
AND l.Result_Description IN ('','CT','CHLAMYDIA TRACHOMATIS RNA, TMA','CHLAMYDIA TRACHOMATIS RNA, TMA, RECTAL','Chlamydia trachomatis, NAA',
							'CHLAMYDIA TRACHOMATIS RNA, TMA, THROAT')
AND l.Result_Value IN ('POSITIVE','DETECTED')

INSERT INTO #ARMS VALUES ('Chlamydia tests positives', @179)

--Genital herpes blood tests
SELECT @180 = COUNT(*)
FROM #Labs l
WHERE sex NOT IN ('F','M')
AND l.test_code_id IN ('11363','16506','19550','196250','2649','3636','3640','395','498','501','5233','6399','70222','792',
'8472','8475','93170')
AND l.Result_Description IN ('HSV 1 IGG TYPE SPECIFIC AB','HSV 2 IGG TYPE SPECIFIC AB')

INSERT INTO #ARMS VALUES ('Genital herpes blood tests', @180)

--Genital herpes blood tests / positives	
SELECT @181 = COUNT(*)
FROM #Labs l
WHERE sex NOT IN ('F','M')
AND l.test_code_id IN ('11363','16506','19550','196250','2649','3636','3640','395','498','501','5233','6399','70222','792',
'8472','8475','93170')
AND l.Result_Description IN ('HSV 1 IGG TYPE SPECIFIC AB','HSV 2 IGG TYPE SPECIFIC AB')
AND l.Abnormal_Flag <> 'N'

INSERT INTO #ARMS VALUES ('Genital herpes blood tests positives', @181)
			
--Genital herpes culture tests	
SELECT @182 = COUNT(DISTINCT pe.enc_id)
FROM #enc pe
JOIN #Labs l
	ON l.enc_id = pe.enc_id
WHERE pe.sex NOT IN ('F','M')
AND l.test_code_id IN ('2649', '17495', '2692')
AND l.Result_Description ='HERPES SIMPLEX VIRUS CULTURE W/RFL TO TYPING'	

INSERT INTO #ARMS VALUES ('Genital herpes culture tests', @182)

--Genital herpes culture tests / positives		
SELECT @183 = COUNT(DISTINCT pe.enc_id)
FROM #enc pe
JOIN #Labs l
	ON l.enc_id = pe.enc_id
WHERE pe.sex NOT IN ('F','M')
AND l.test_code_id IN ('2649', '17495', '2692')
AND l.Result_Description ='HERPES SIMPLEX VIRUS CULTURE W/RFL TO TYPING'
AND ISNULL(l.Abnormal_Flag,'N') <> 'N'		

INSERT INTO #ARMS VALUES ('Genital herpes culture tests positives', @183)

--Genital herpes unspecified (DNA / protein with unspecified specimen) tests
SELECT @184 = 0
INSERT INTO #ARMS VALUES ('Genital herpes unspecified (DNA / protein with unspecified specimen) tests', @184)

--Genital herpes unspecified (DNA / protein with unspecified specimen) tests / positives
SELECT @185 = 0	
INSERT INTO #ARMS VALUES ('Genital herpes unspecified (DNA / protein with unspecified specimen) tests positivies', @185)
			
--Hepatitis B tests
SELECT @186 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex NOT IN ('F','M')
AND l.test_code_id IN ('498', '501', '498', '8475', '498', '499', '501')
AND l.Result_Description like '%hepatitis b%'
AND ISNULL(l.Abnormal_Flag,'N') = 'A'

INSERT INTO #ARMS VALUES ('Hepatitis B tests', @186)

--Hepatitis B tests / positives
SELECT @187 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex NOT IN ('F','M')
AND l.test_code_id IN ('498', '501', '498', '8475', '498', '499', '501')
AND l.Result_Description like '%hepatitis b%'
AND ISNULL(l.Abnormal_Flag,'N') = 'A'

INSERT INTO #ARMS VALUES ('Hepatitis B tests positives', @187)

--Hepatitis C tests	
SELECT @188 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex NOT IN ('F','M')
AND l.test_code_id IN ('8472')
AND l.Result_Description like '%hepatitis c%'

INSERT INTO #ARMS VALUES ('Hepatitis C tests', @188)

--Hepatitis C tests / positives			
SELECT @189 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex NOT IN ('F','M')
AND l.test_code_id IN ('8472')
AND l.Result_Description like '%hepatitis c%'
AND ISNULL(l.Abnormal_Flag,'N') = 'A'

INSERT INTO #ARMS VALUES ('Hepatitis C tests positives', @189)
	
--Trichomoniasis diagnoses		
SELECT @190 = COUNT(DISTINCT pd.person_id)
FROM patient_diagnosis pd
JOIN #enc pe 
	ON pd.person_id = pe.person_id
WHERE pe.sex NOT IN ('F','M')
AND pd.icd9cm_code_id IN ('A59.03','A59.01')

INSERT INTO #ARMS VALUES ('Trichomoniasis diagnoses', @190)
		
--Genital wart diagnoses	
SELECT @191 = COUNT(DISTINCT pd.person_id)
FROM patient_diagnosis pd
JOIN #enc pe 
	ON pd.person_id = pe.person_id
WHERE pe.sex NOT IN ('F','M')
AND pd.icd9cm_code_id IN ('A63.0')

INSERT INTO #ARMS VALUES ('Genital wart diagnoses', @191)
			
--HIV rapid tests	
SELECT @192 = COUNT(DISTINCT pe.enc_id)
FROM #enc pe
JOIN order_ o
	ON o.encounterID = pe.enc_id
WHERE pe.sex NOT IN ('F','M')
AND actCode IN ('87806','86701','86703')
AND actStatus = 'completed'

INSERT INTO #ARMS VALUES ('HIV rapid tests', @192)
			
--HIV send-out tests	
SELECT @193 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex NOT IN ('F','M')
AND l.test_code_id IN ('93170', '5233', '19728', '40085')
AND l.Result_Description LIKE '%hiv%'

INSERT INTO #ARMS VALUES ('HIV send-out tests', @193)
			
--Confirmed HIV positives		
SELECT @194 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex NOT IN ('F','M')
AND l.test_code_id IN ('93170', '5233', '19728', '40085')
AND l.Result_Description LIKE '%hiv%'
AND ISNULL(l.Abnormal_Flag,'N') = 'A'

INSERT INTO #ARMS VALUES ('Confirmed HIV positives', @194)
		
--Other STI tests		
SELECT @195 = 'DNA'
INSERT INTO #ARMS VALUES ('Other STI tests', @195)

--Other STI tests positives		
SELECT @196 = 'DNA'
INSERT INTO #ARMS VALUES ('Other STI tests positives', @196)	
	
/**************************************************************************************************************************/
INSERT INTO #ARMS VALUES ('Does your affiliate have an in-house laboratory service for Pap test evaluation?','DNA')		
INSERT INTO #ARMS VALUES ('Does your affiliate have an in-house laboratory service for Chlamydia testing?','DNA')			
INSERT INTO #ARMS VALUES ('Does your affiliate have an in-house laboratory service for Gonorrhea testing?','DNA')			
INSERT INTO #ARMS VALUES ('Does your affiliate offer flu vaccines?','DNA')			
INSERT INTO #ARMS VALUES ('Does your affiliate offer weight management services?','DNA')			
INSERT INTO #ARMS VALUES ('Does your affiliate offer smoking cessation services?','DNA')			
INSERT INTO #ARMS VALUES ('Does your affiliate offer services related to diabetes treatment?','DNA')			
INSERT INTO #ARMS VALUES ('Does your affiliate offer services related to the treatment of lipid disorders?','DNA')			
INSERT INTO #ARMS VALUES ('Does your affiliate offer services related to the treatment of hypertension?','DNA')			
INSERT INTO #ARMS VALUES ('Does your affiliate offer services related to asthma treatment?','DNA')			
INSERT INTO #ARMS VALUES ('Does your affiliate offer services related to the treatment of hypothyroidism?','DNA')			

/*************************************************************************************************
select distinct txt_birth_control_visitend
from master_im_

NULL					Abstinence					Cervical cap/Diaphragm
FAM/NFP					Female Condom				Female Sterilization
Implant					Infertile					Injection
IUC (Copper)			IUC (Levonorgestrel)		Male Condom
No Method				Oral (CHC)					Oral (POP)
Other method			Other Methods				Partner Method
Patch					Pregnant/Partner Pregnant	Ring
Same sex partner		Seeking pregnancy			Spermicide
Sponge					Vasectomy
**************************************************************************************************/

/* Female Contraception Clients by Primary Method */
--Oral contraception Female Contraception Clients		

SELECT @208 = COUNT(*)
FROM #ContraClients
WHERE txt_birth_control_visitend IN ('Oral (CHC)','Oral (POP)')	
AND sex = 'F'

INSERT INTO #ARMS VALUES ('Oral contraception Female Contraception Clients', @208)

--Oral contraception Cycles of Contraception Dispensed  
SELECT @209 = REPLACE(SUM(quantity),'.00','')
FROM charges c
JOIN #enc e
	ON c.source_id = e.enc_id
WHERE c.cpt4_code_id IN (SELECT service_item_id
					   FROM #ContrSIM 
					   WHERE mstr_list_item_desc = 'Supplies-Oral Contraceptive'
					   AND service_item_id NOT IN ('C003-PT','C007-INS') --female condoms and gel listed under incorrect category
					   )
AND c.quantity >= 1

INSERT INTO #ARMS VALUES ('Oral contraception Cycles of Contraception Dispensed	', @209)

--Contraceptive vaginal ring (Nuvaring)	
SELECT @210 = COUNT(*)
FROM #ContraClients
WHERE txt_birth_control_visitend = 'ring'
AND sex = 'F'

INSERT INTO #ARMS VALUES ('Contraceptive vaginal ring (Nuvaring) Female Contraception Clients', @210)

--Contraceptive vaginal ring (Nuvaring) Cycles of Contraception Dispensed		
SELECT @211 = REPLACE(SUM(quantity),'.00','')
FROM charges c
JOIN #enc e
	ON c.source_id = e.enc_id
WHERE c.cpt4_code_id IN (SELECT service_item_id 
					   FROM #ContrSIM 
					   WHERE service_item_id IN ('X7730','X7730-INS','X7730-PT','J7303','X7728','B002')
					   )
AND c.quantity >= 1

INSERT INTO #ARMS VALUES ('Contraceptive vaginal ring (Nuvaring) Cycles of Contraception Dispensed', @211)

--Transdermal contraceptive patch (Ortho-Evra)	
SELECT @212 = COUNT(*)
FROM #ContraClients
WHERE txt_birth_control_visitend = 'patch'
AND sex = 'F'

INSERT INTO #ARMS VALUES ('Transdermal contraceptive patch (Ortho-Evra) Female Contraception Clients', @212)

--Transdermal contraceptive patch (Ortho-Evra) Cycles of Contraception Dispensed
SELECT @213 = CAST(SUM(
              CASE
                     WHEN quantity >=12 THEN quantity / 3
                     ELSE quantity
              END)AS DECIMAL(25,0))
FROM charges c
JOIN #enc e
	ON c.source_id = e.enc_id
WHERE c.cpt4_code_id IN (SELECT service_item_id 
					   FROM #ContrSIM 
					   WHERE service_item_id IN ('X7728','XULANE','J7304')
					   )
AND c.quantity >= 1

INSERT INTO #ARMS VALUES ('Transdermal contraceptive patch (Ortho-Evra) Cycles of Contraception Dispensed', @213)

--IUC
SELECT @214 = COUNT(*)
FROM #ContraClients
WHERE txt_birth_control_visitend IN ('IUC (Copper)','IUC (Levonorgestrel)')
AND sex = 'F'

INSERT INTO #ARMS VALUES ('IUC Female Contraception Clients', @214)	

--IUC Cycles of Contraception Dispensed	
SELECT @215 = REPLACE(SUM(quantity),'.00','')
FROM charges c
JOIN #enc e
	ON c.source_id = e.enc_id
WHERE c.cpt4_code_id IN (SELECT service_item_id 
					   FROM #ContrSIM 
					   WHERE service_item_id IN ('J7297','J7298','J7300','J7301','J7302','Liletta','X1522','X1532')
					   )
AND c.quantity >= 1

INSERT INTO #ARMS VALUES ('IUC Cycles of Contraception Dispensed', @215)

--Contraceptive implant 	
SELECT @216 = COUNT(*)
FROM #ContraClients
WHERE txt_birth_control_visitend IN ('implant')
AND sex = 'F'

INSERT INTO #ARMS VALUES ('Contraceptive implant Female Contraception Clients', @216)	

--Contraceptive Implant Cycles of Contraception Dispensed
SELECT @217 = REPLACE(SUM(quantity),'.00','')
FROM charges c
JOIN #enc e
	ON c.source_id = e.enc_id
WHERE c.cpt4_code_id IN (SELECT service_item_id 
					   FROM #ContrSIM 
					   WHERE service_item_id IN ('11975','11977','B006', 'M066','M076','J7307')
					   )
AND c.quantity >= 1

INSERT INTO #ARMS VALUES ('Contraceptive Implant Cycles of Contraception Dispensed', @217)

--Hormonal injection (Depo-Provera)	
SELECT @218 = COUNT(*)
FROM #ContraClients
WHERE txt_birth_control_visitend IN ('injection')
AND sex = 'F'

INSERT INTO #ARMS VALUES ('Hormonal injection (Depo-Provera) Female Contraception Clients', @218)	

--Hormonal injection (Depo-provera) Cycles of Contraception Dispensed
SELECT @219 = COUNT(*)
FROM charges c
JOIN #enc e
	ON c.source_id = e.enc_id
WHERE c.cpt4_code_id = 'J1050'

INSERT INTO #ARMS VALUES ('Hormonal injection (Depo-provera) Cycles of Contraception Dispensed', @219)

--Condoms / Non-Prescription Barrier	
SELECT @220 = COUNT(*)
FROM #ContraClients
WHERE txt_birth_control_visitend IN ('female condom','male condom')
AND sex = 'F'

INSERT INTO #ARMS VALUES ('Condoms / Non-Prescription Barrier Female Contraception Clients', @220)

--Condoms/Non-Prescription Barrier Cycles of Contraception Dispensed
SELECT c.*
INTO #condoms  -- drop table #condoms
FROM charges c
JOIN #enc e
	ON c.source_id = e.enc_id
WHERE c.cpt4_code_id IN (SELECT service_item_id 
					   FROM #ContrSIM 
					   WHERE service_item_id IN ('C003-PT','10CON','10CON-NC','12CON','12CON-NC','24CON','24CON-NC',
												 '30CON','30CON-NC','48CON','C002','C002NC','C003','C003-INS','C033',
												 'RCONB','RCONO')
					   )
AND c.quantity >= 1

UPDATE #condoms
SET quantity = CASE WHEN service_item_id IN ('10CON','10CON-NC') THEN 10
					WHEN service_item_id IN ('12CON','12CON-NC') THEN 12
					WHEN service_item_id IN ('24CON','24CON-NC') THEN 24
					WHEN service_item_id IN ('30CON','30CON-NC') THEN 30
					WHEN service_item_id = '48CON' THEN 48 ELSE quantity END

SELECT @221 = REPLACE(SUM(quantity),'.00','')
FROM #condoms

INSERT INTO #ARMS VALUES ('Condoms/Non-Prescription Barrier Cycles of Contraception Dispensed', @221)

--Other / unknown method	
SELECT @222 = COUNT(*)
FROM #ContraClients
WHERE txt_birth_control_visitend IN ('female sterilization','other method','other methods','spermicide','sponge','vasectomy',
									 'partner method','cervical cap/diaphragm','abstinence',NULL,'FAM/NFP','No Method','Same sex partner',
									 'Infertile','Pregnant/Partner Pregnant','Seeking pregnancy','')
AND sex = 'F'

INSERT INTO #ARMS VALUES ('Other / unknown method Female Contraception Clients', @222)

--Other / unknown method Cycles of Contraception Dispensed		
SELECT @223 = 0
INSERT INTO #ARMS VALUES ('Other / unknown method Cycles of Contraception Dispensed', @223)

--Total Female Contraception Clients - internal use only
SELECT @224 = COUNT(*)
FROM #ContraClients
WHERE sex = 'F'

INSERT INTO #ARMS VALUES ('Total Female Contraception Clients - internal use only', @224)

--Total Cycles of Contraception Dispensed
SELECT @225 = (CAST(@209 AS INT)+ CAST(@211 AS INT) + CAST(@213 AS INT) + CAST(@215 AS INT) + CAST(@217 AS INT) + CAST(@219 AS INT) + CAST(@221 AS INT) + CAST(@223 AS INT))
INSERT INTO #ARMS VALUES ('Total Cycles of Contraception Dispensed', @225)

/*****************************************************************************************************************************/
/* Female Contraception Clients */
--New female contraception clients	
--Continuing female contraception clients	
	
/* Female Services */
--Emergency contraception kits provided ON site	
SELECT @229 = COUNT(DISTINCT enc_id) 
FROM charges c
JOIN #enc e
	ON c.source_id = e.enc_id
WHERE (c.service_item_id LIKE '%ella%' 
       OR c.service_item_id LIKE '%econtra%' 
       OR c.service_item_id LIKE '%next%'
       OR c.service_item_id LIKE '%X7722%' --Plan B
         ) 
AND c.quantity >= 1

INSERT INTO #ARMS VALUES ('Emergency contraception kits provided ON site', @229)
			
--Emergency contraception - clients		
SELECT @230 = COUNT(DISTINCT e.person_id) 
FROM charges c
JOIN #enc e
	ON c.source_id = e.enc_id
WHERE (c.service_item_id LIKE '%ella%' 
       OR c.service_item_id LIKE '%econtra%' 
       OR c.service_item_id LIKE '%next%'
       OR c.service_item_id LIKE '%X7722%' --Plan B
         ) 		

INSERT INTO #ARMS VALUES ('Emergency contraception - clients', @230)

--Urinary tract infection treatments	
SELECT @231 = COUNT(DISTINCT e.enc_id)
FROM patient_diagnosis pd
JOIN patient_medication pm
	ON pd.enc_id = pm.enc_id
JOIN #enc e
	ON pd.enc_id = e.enc_id
where icd9cm_code_id IN ('N30.00','N30.01','R30.0','R35.0')
AND (
	PATINDEX('%Ciprofloxacin HCL 250mg%',pm.medication_name) = 1
	OR PATINDEX('%Macrodantin%',pm.medication_name) = 1
	OR PATINDEX('%Monurol%',pm.medication_name) = 1
	OR PATINDEX('%Nitrofurantoin monohydrate%',pm.medication_name) = 1
	OR PATINDEX('%Sulfamethoxazole-trimethoprim%',pm.medication_name) = 1
	)	
AND e.sex = 'F'		

INSERT INTO #ARMS VALUES ('Urinary tract infection treatments - female', @231)	
		
--Scabies treatments	
SELECT @232 = COUNT(DISTINCT e.enc_id)
FROM patient_diagnosis pd
JOIN patient_medication pm
	ON pd.enc_id = pm.enc_id
JOIN #enc e
	ON pd.enc_id = e.enc_id
where icd9cm_code_id IN ('B86')
AND PATINDEX('%Permethrin 5% %',pm.medication_name) = 1	
AND e.sex = 'F'	

INSERT INTO #ARMS VALUES ('Scabies treatments - female', @232)	
		
--Pediculosis Pubis treatments	
SELECT @233 = COUNT(DISTINCT e.enc_id)
FROM patient_diagnosis pd
JOIN patient_medication pm
	ON pd.enc_id = pm.enc_id
JOIN #enc e
	ON pd.enc_id = e.enc_id
where icd9cm_code_id IN ('B85.3')
AND PATINDEX('%Permethrin 1% %',pm.medication_name) = 1	
AND e.sex = 'F'			

INSERT INTO #ARMS VALUES ('Pediculosis Pubis treatments - female', @233)	

--Genital wart treatments
SELECT @234 = COUNT(DISTINCT e.enc_id)
FROM #enc e
JOIN proc_external_genitalia_ peg
	ON e.enc_id = peg.enc_id
WHERE (peg.chk_wart_tx = 1 AND ISNULL(peg.txt_treatment_method,'') <> '')
AND e.sex = 'F'			

INSERT INTO #ARMS VALUES ('Genital wart treatments - female', @234)	
		
--Genital wart treatment - clients				
SELECT @235 = COUNT(DISTINCT e.person_id)
FROM #enc e
JOIN proc_external_genitalia_ peg
	ON e.enc_id = peg.enc_id
WHERE (peg.chk_wart_tx = 1 AND ISNULL(peg.txt_treatment_method,'') <> '')
AND e.sex = 'F'

INSERT INTO #ARMS VALUES ('Genital Wart Treatment - female - clients', @235)

--Hepatitis vaccinations	
SELECT @236 = COUNT(DISTINCT enc_id)
from #proc
WHERE cpt4_code_id = '90746'
AND sex = 'F'

INSERT INTO #ARMS VALUES ('Hepatitis vaccinations - female', @236)	
			
--HPV vaccinations	
SELECT @237 = COUNT(DISTINCT enc_id) -- multi series injection given Once per patient
from #proc
WHERE cpt4_code_id = '90649'
AND sex = 'F'

INSERT INTO #ARMS VALUES ('HPV vaccinations', @237)				

--Primary care visits	0	
SELECT @238 = 0
INSERT INTO #ARMS VALUES ('Primary care visits', @238)				
		
--Primary care clients	0	
SELECT @239 = 0
INSERT INTO #ARMS VALUES ('Primary care clients', @239)				
		
INSERT INTO #ARMS VALUES ('Well-woman visits (if not counted under primary care)',0)
INSERT INTO #ARMS VALUES ('Well-woman clients (if not counted under primary care)',0)				
INSERT INTO #ARMS VALUES ('Expectant management visits',0)				
INSERT INTO #ARMS VALUES ('Expectant management clients',0)			
INSERT INTO #ARMS VALUES ('Other female services',0)				
INSERT INTO #ARMS VALUES ('Other - description',0)				

/* Client and Visit Count - Female */
--Total female visits, any service
SELECT @246 = COUNT(DISTINCT enc_id)
FROM #enc
WHERE sex = 'F'

INSERT INTO #ARMS VALUES ('Total female visits, any service', @246)				
	
--Total female clients, any service	
SELECT @247 = COUNT(DISTINCT person_id)
FROM #enc
WHERE sex = 'F'

INSERT INTO #ARMS VALUES ('Total female clients, any service', @247)				

/* Male Services */
--Urinary tract infection treatments - Male
SELECT @248 = COUNT(DISTINCT e.enc_id)
FROM patient_diagnosis pd
JOIN patient_medication pm
	ON pd.enc_id = pm.enc_id
JOIN #enc e
	ON pd.enc_id = e.enc_id
where icd9cm_code_id IN ('N30.00','N30.01','R30.0','R35.0')
AND (
	PATINDEX('%Ciprofloxacin HCL 250mg%',pm.medication_name) = 1
	OR PATINDEX('%Macrodantin%',pm.medication_name) = 1
	OR PATINDEX('%Monurol%',pm.medication_name) = 1
	OR PATINDEX('%Nitrofurantoin monohydrate%',pm.medication_name) = 1
	OR PATINDEX('%Sulfamethoxazole-trimethoprim%',pm.medication_name) = 1
	)	
AND e.sex = 'M'		

INSERT INTO #ARMS VALUES ('Urinary tract infection treatments - male', @248)	
		
--Scabies treatments - male
SELECT @249 = COUNT(DISTINCT e.enc_id)
FROM patient_diagnosis pd
JOIN patient_medication pm
	ON pd.enc_id = pm.enc_id
JOIN #enc e
	ON pd.enc_id = e.enc_id
where icd9cm_code_id IN ('B86')
AND PATINDEX('%Permethrin 5% %',pm.medication_name) = 1	
AND e.sex = 'M'	

INSERT INTO #ARMS VALUES ('Scabies treatments - male', @249)	
		
--Pediculosis Pubis treatments	- male
SELECT @250 = COUNT(DISTINCT e.enc_id)
FROM patient_diagnosis pd
JOIN patient_medication pm
	ON pd.enc_id = pm.enc_id
JOIN #enc e
	ON pd.enc_id = e.enc_id
where icd9cm_code_id IN ('B85.3')
AND PATINDEX('%Permethrin 1% %',pm.medication_name) = 1	
AND e.sex = 'M'			

INSERT INTO #ARMS VALUES ('Pediculosis Pubis treatments - male', @250)	

--Genital wart treatments - male
SELECT @251 = COUNT(DISTINCT e.enc_id)
FROM #enc e
JOIN proc_external_genitalia_ peg
	ON e.enc_id = peg.enc_id
WHERE (peg.chk_wart_tx = 1 AND ISNULL(peg.txt_treatment_method,'') <> '')
AND e.sex = 'M'			

INSERT INTO #ARMS VALUES ('Genital wart treatments - male', @251)	
		
--Genital wart treatment - clients
SELECT @252 = COUNT(DISTINCT e.person_id)
FROM #enc e
JOIN proc_external_genitalia_ peg
	ON e.enc_id = peg.enc_id
WHERE (peg.chk_wart_tx = 1 AND ISNULL(peg.txt_treatment_method,'') <> '')
AND e.sex = 'M'

INSERT INTO #ARMS VALUES ('Genital wart treatment - male - clients', @252)				

--Hepatitis vaccinations - male
SELECT @253 = COUNT(DISTINCT enc_id)
from #proc
WHERE cpt4_code_id = '90746'
AND sex = 'M'

INSERT INTO #ARMS VALUES ('Hepatitis vaccinations - male', @253)	
			
--HPV vaccinations - male	
SELECT @254 = COUNT(DISTINCT enc_id) -- multi series injection given Once per patient
from #proc
WHERE cpt4_code_id = '90649'
AND sex = 'M'

INSERT INTO #ARMS VALUES ('HPV vaccinations - male', @254)				

--Primary care visits - male	0	
SELECT @255 = 0
INSERT INTO #ARMS VALUES ('Primary care visits - male', @255)				
		
--Primary care clients	0	
SELECT @256 = 0
INSERT INTO #ARMS VALUES ('Primary care clients - male', @256)	
				
--Other male services				
SELECT @257 = 'DNA'
INSERT INTO #ARMS VALUES ('Other male services', @257)

--Other - description	
SELECT @258 = 'DNA'
INSERT INTO #ARMS VALUES ('Other - description - male', @258)

/* Client and Visit Count - Male */
--Total male visits, any service	
SELECT @259 = COUNT(DISTINCT enc_id)
FROM #enc
WHERE sex = 'M'

INSERT INTO #ARMS VALUES ('Total male visits, any service', @259)	

--Total male clients, any service	
SELECT @260 = COUNT(DISTINCT person_id)
FROM #enc
WHERE sex = 'M'

INSERT INTO #ARMS VALUES ('Total male clients, any service', @260)	

--Do you provide any services via telemedicine?
SELECT @261 = 'DNA'
INSERT INTO #ARMS VALUES ('Do you provide any services via telemedicine?', @261)

-- Title X center visits
SELECT @262 = COUNT(DISTINCT enc_id)
FROM #proc p
WHERE p.location_id NOT IN ('68C7DDB4-834A-4ABC-B3EB-87BF71D60F41', '966B30EA-F24F-48D6-8346-948669FDCE6E'
                            ,'518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --FASS, Online, Clinical services and Lab are excluded as they are non Title X centers
AND (
		diagnosis_code_id_1 != 'Z64.0'
		AND  diagnosis_code_id_2 != 'Z64.0'
		AND  diagnosis_code_id_3 != 'Z64.0'
		AND  diagnosis_code_id_4 != 'Z64.0'
		AND  cpt4_code_id NOT LIKE '%59840A%'
		AND  cpt4_code_id NOT LIKE '%59841[C-N]%'
		AND  cpt4_code_id NOT LIKE '%S0199%'
		AND  cpt4_code_id NOT LIKE '%S0199A%'
       )

INSERT INTO #ARMS VALUES ('Title X center visits', @262)	

-- Title X center clients
SELECT @263 = COUNT(DISTINCT person_id)
FROM #proc p
WHERE p.location_id NOT IN ('68C7DDB4-834A-4ABC-B3EB-87BF71D60F41', '966B30EA-F24F-48D6-8346-948669FDCE6E'
                            ,'518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --FASS, Online, Clinical services and Lab are excluded as they are non Title X centers
AND (
		diagnosis_code_id_1 != 'Z64.0'
		AND  diagnosis_code_id_2 != 'Z64.0'
		AND  diagnosis_code_id_3 != 'Z64.0'
		AND  diagnosis_code_id_4 != 'Z64.0'
		AND  cpt4_code_id NOT LIKE '%59840A%'
		AND  cpt4_code_id NOT LIKE '%59841[C-N]%'
		AND  cpt4_code_id NOT LIKE '%S0199%'
		AND  cpt4_code_id NOT LIKE '%S0199A%'
       )

INSERT INTO #ARMS VALUES ('Title X center clients', @263)

--Referrals to an adoption agency for pregnant women
SELECT @264 = 'DNA'
INSERT INTO #ARMS VALUES ('Referrals to an adoption agency for pregnant women', @264)

-- Abnormal breast exams resulting int a client referral

--Abnormal Pap tests resulting in a client referral
SELECT @266 = 'DNA'
INSERT INTO #ARMS VALUES ('Abnormal Pap tests resulting in a client referral', @266)

/* Visits by Payer Class */
/*******************************************************************************************************************
Commercial Ins Exchange-4330           (CoveredCA)	66
Commercial Ins Non-Exchange-4310       (Private)	65
Family PACT-4110                       (Self-pay/sliding fee – there is no category for F-PACT)	70
Medi-Cal Managed Care-4130             (Medi-Cal Managed Care)	63
Medi-Cal-4120                          (Medi-Cal)	62
Self-Pay                               (Self-pay/sliding fee)	70
*********************************************************************************************************************/

--***Start ENC Payer***
SELECT DISTINCT person_id, enc_id, cob1_payer_id, service_date, sex, [finClass] = NULL
INTO #temp2
FROM #temp1 t
WHERE t.enc_id NOT IN (SELECT r.enc_id FROM #refill r)
ORDER BY person_id

UPDATE #temp2
SET [finClass] = '4110'
WHERE #temp2.cob1_payer_id IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #temp2 t ON t.cob1_payer_id = pm.payer_id
WHERE financial_class = 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF'
)

--Medi-Cal Managed Care-4130
UPDATE #temp2
SET [finClass] = '4130'
WHERE #temp2.cob1_payer_id IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #temp2 t ON t.cob1_payer_id = pm.payer_id
WHERE financial_class = '484A05B3-D5C8-415B-A8EE-3D14A7AF11D6'
)

--Medi-cal
UPDATE #temp2
SET [finClass] = '4120'
WHERE #temp2.cob1_payer_id IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #temp2 t ON t.cob1_payer_id = pm.payer_id
WHERE financial_class = 'C5BDDA12-DDC9-4CFF-A0A3-9749C7DD353D'
)

--Commercial
UPDATE #temp2
SET [finClass] = '4300'
WHERE #temp2.cob1_payer_id IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #temp2 t ON t.cob1_payer_id = pm.payer_id
WHERE financial_class = '8E5D6C7E-A34E-4B3C-8C0A-B2F1D2E20285' OR financial_class = '332DF613-7C43-4287-9050-9949B4142B0C'
)

--Cash does not have a financial class so it will be represented as NULL in the payer_id column
UPDATE #temp2
SET [finClass] = '0000'
WHERE #temp2.cob1_payer_id IS NULL

SELECT person_id
	  ,MAX(finClass) AS [finClass]
	  ,service_date
	  ,sex
INTO #enc_pay
FROM #temp2
GROUP BY person_id, service_date, sex
ORDER BY person_id, service_date

--***Start insurance table by patient***
--Groups enc by payer and NULL finClass to be updated based upon payer
SELECT DISTINCT person_id, enc_id, service_date, 'finClass' = NULL
INTO #pay
FROM #temp1
GROUP BY person_id, enc_id, service_date
ORDER BY person_id

SELECT DISTINCT p.person_id,
	CASE
		WHEN MAX(cob1_payer_id) is not null THEN cob1_payer_id
		ELSE NULL
	END AS 'payer'
INTO #lucky
FROM #pay p
JOIN patient_encounter pe ON p.enc_id = pe.enc_id
GROUP BY p.person_id, finClass, cob1_payer_id
ORDER BY person_id

SELECT *, 'finClass' = NULL
INTO #pay2
FROM #lucky

--Updates #pay with the encounters financial class
--Fpact
UPDATE #pay2
SET [finClass] = '4110'
WHERE #pay2.payer IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #pay2 p ON p.payer = pm.payer_id
WHERE financial_class = 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF'
)

--Medi-Cal Managed Care-4130
UPDATE #pay2
SET [finClass] = '4130'
WHERE #pay2.payer IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #pay2 p ON p.payer = pm.payer_id
WHERE financial_class = '484A05B3-D5C8-415B-A8EE-3D14A7AF11D6'
)

--Medi-cal
UPDATE #pay2
SET [finClass] = '4120'
WHERE #pay2.payer IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #pay2 p ON p.payer = pm.payer_id
WHERE financial_class = 'C5BDDA12-DDC9-4CFF-A0A3-9749C7DD353D'
)

--Commercial
UPDATE #pay2
SET [finClass] = '4300'
WHERE #pay2.payer IN
(
SELECT pm.payer_id --AS [fin_class]
FROM payer_mstr pm
JOIN #pay2 p ON p.payer = pm.payer_id
WHERE financial_class = '8E5D6C7E-A34E-4B3C-8C0A-B2F1D2E20285' OR financial_class = '332DF613-7C43-4287-9050-9949B4142B0C'
)

--Cash does not have a financial class so it will be represented as NULL in the payer_id column
UPDATE #pay2
SET [finClass] = '0000'
WHERE #pay2.payer IS NULL

--Uses max to select the payer with the highest designator
SELECT DISTINCT p.person_id,
	CASE
		WHEN MAX(finClass) = '4300' THEN 'Commercial'
		WHEN MAX(finClass) = '4130' THEN 'Medi-Cal Managed Care'
		WHEN MAX(finClass) = '4120' THEN 'Medi-Cal'
		WHEN MAX(finClass) = '4110' THEN 'Fpact'
		WHEN MAX(finClass) = '0'	THEN 'Cash'
		ELSE 'Cash'
	END AS 'finClass'
INTO #finClass
FROM #pay2 p
GROUP BY p.person_id
order by finClass

--All AB/MAB who pay cash
SELECT DISTINCT enc_id
INTO #ab_cash
FROM #temp1 t
WHERE (service_item_id LIKE '%59840A%' 
    OR service_item_id LIKE '%59841[C-N]%' 
    OR service_item_id LIKE '%S0199%'
	OR location_id = '68C7DDB4-834A-4ABC-B3EB-87BF71D60F41') 
	AND cob1_payer_id IS NULL

 --Paid Cash. exclude FASS, MAB, TAB
SELECT DISTINCT x.enc_id
INTO #x_cash
FROM #x x
JOIN #temp1 t ON t.enc_id = x.enc_id
WHERE cob1_payer_id IS NULL



--/* Non-Abortion Vistis by Payer Class */ could pull from Title X because excludes any AB codes
--Commercial insurance visits
SELECT @290 = COUNT(DISTINCT enc_id)
FROM #enc pe
INNER JOIN payer_mstr PM 
	ON pe.cob1_payer_id = pm.payer_id
LEFT JOIN mstr_lists ML 
	ON PM.financial_class = ML.mstr_list_item_id AND ML.mstr_list_type = 'fin_class'
WHERE mstr_list_item_desc IN ('Commercial Ins Exchange-4330', 'Commercial Ins Non-Exchange-4310')
--AND cob1_payer_id IS NOT NULL
AND enc_id NOT IN (SELECT enc_id FROM #AB)

INSERT INTO #ARMS VALUES ('Commercial insurance visits - Non-AB', @290)
select cob1_payer_id from patient_encounter
--Medicaid visits (full-fee / "traditional" only)	
SELECT @291 = COUNT(DISTINCT enc_id)
FROM #enc pe
LEFT JOIN payer_mstr PM 
	ON pe.cob1_payer_id = pm.payer_id
LEFT JOIN mstr_lists ML 
	ON PM.financial_class = ML.mstr_list_item_id AND ML.mstr_list_type = 'fin_class'
WHERE mstr_list_item_desc = 'Medi-Cal-4120'
AND cob1_payer_id IS NOT NULL
AND enc_id NOT IN (SELECT enc_id FROM #AB)

INSERT INTO #ARMS VALUES ('Medicaid visits (full-fee / "traditional" only) - Non-AB', @291)

--Medicaid Family Planning Waiver visits	
SELECT @292 = COUNT(DISTINCT enc_id)
FROM #enc pe
LEFT JOIN payer_mstr PM 
	ON pe.cob1_payer_id = pm.payer_id
LEFT JOIN mstr_lists ML 
	ON PM.financial_class = ML.mstr_list_item_id AND ML.mstr_list_type = 'fin_class'
WHERE mstr_list_item_desc = 'Family PACT-4110'
AND cob1_payer_id IS NOT NULL
AND enc_id NOT IN (SELECT enc_id FROM #AB)

INSERT INTO #ARMS VALUES ('Medicaid Family Planning Waiver visits - Non-AB', @292)

--Medicaid Managed Care visits	
SELECT @293 = COUNT(DISTINCT enc_id)
FROM #enc pe
LEFT JOIN payer_mstr PM 
	ON pe.cob1_payer_id = pm.payer_id
LEFT JOIN mstr_lists ML 
	ON PM.financial_class = ML.mstr_list_item_id AND ML.mstr_list_type = 'fin_class'
WHERE mstr_list_item_desc = 'Medi-Cal Managed Care-4130'
AND cob1_payer_id IS NOT NULL
AND enc_id NOT IN (SELECT enc_id FROM #AB)

INSERT INTO #ARMS VALUES ('Medicaid Managed Care visits - Non-AB', @293)

--Medicare	
SELECT @294 = COUNT(DISTINCT enc_id)
FROM #enc pe
LEFT JOIN payer_mstr PM 
	ON pe.cob1_payer_id = pm.payer_id
LEFT JOIN mstr_lists ML 
	ON PM.financial_class = ML.mstr_list_item_id AND ML.mstr_list_type = 'fin_class'
WHERE mstr_list_item_desc = 'Medicare'
AND cob1_payer_id IS NOT NULL
AND enc_id NOT IN (SELECT enc_id FROM #AB)

INSERT INTO #ARMS VALUES ('Medicare - Non-AB', @294)

--Full self-pay visits
SELECT @295 = COUNT(DISTINCT enc_id)
FROM #enc pe
LEFT JOIN payer_mstr PM 
	ON pe.cob1_payer_id = pm.payer_id
LEFT JOIN mstr_lists ML 
	ON PM.financial_class = ML.mstr_list_item_id AND ML.mstr_list_type = 'fin_class'
WHERE (ml.mstr_list_item_desc LIKE '%cash%' OR pe.cob1_payer_id IS NULL)
AND enc_id NOT IN (SELECT enc_id FROM #AB)

INSERT INTO #ARMS VALUES ('Full self-pay visits - Non-AB', @295)

--Title X-funded self pay visits
SELECT @296 = COUNT(DISTINCT pe.enc_id)
FROM #enc pe
JOIN #proc p
	ON pe.enc_id = p.enc_id
LEFT JOIN payer_mstr PM 
	ON pe.cob1_payer_id = pm.payer_id
LEFT JOIN mstr_lists ML 
	ON PM.financial_class = ML.mstr_list_item_id AND ML.mstr_list_type = 'fin_class'
WHERE (ml.mstr_list_item_desc LIKE '%cash%' OR pe.cob1_payer_id IS NULL)
AND pe.enc_id NOT IN (SELECT enc_id FROM #AB)
AND p.location_id NOT IN ('68C7DDB4-834A-4ABC-B3EB-87BF71D60F41', '966B30EA-F24F-48D6-8346-948669FDCE6E'
                            ,'518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --FASS, Online, Clinical services and Lab are excluded as they are non Title X centers
AND (
		diagnosis_code_id_1 != 'Z64.0'
		AND  diagnosis_code_id_2 != 'Z64.0'
		AND  diagnosis_code_id_3 != 'Z64.0'
		AND  diagnosis_code_id_4 != 'Z64.0'
		AND  cpt4_code_id NOT LIKE '%59840A%'
		AND  cpt4_code_id NOT LIKE '%59841[C-N]%'
		AND  cpt4_code_id NOT LIKE '%S0199%'
		AND  cpt4_code_id NOT LIKE '%S0199A%'
       )	

INSERT INTO #ARMS VALUES ('Title X-funded self pay visits - Non-AB', @296)

--Other self-pay visits (subsidized by other grants)	
INSERT INTO #ARMS VALUES ('Other self-pay visits (subsidized by other grants)- Non-AB', 0)
--Unknown primary payor visits	
INSERT INTO #ARMS VALUES ('Unknown primary payor visits - Non-AB', 0)

/* Abortion Visits by Payer Class */
--Commercial insurance visits	
SELECT @299 = COUNT(DISTINCT enc_id)
FROM #enc pe
LEFT JOIN payer_mstr PM 
	ON pe.cob1_payer_id = pm.payer_id
LEFT JOIN mstr_lists ML 
	ON PM.financial_class = ML.mstr_list_item_id AND ML.mstr_list_type = 'fin_class'
WHERE mstr_list_item_desc IN ('Commercial Ins Exchange-4330', 'Commercial Ins Non-Exchange-4310')
AND cob1_payer_id IS NOT NULL
AND enc_id IN (SELECT enc_id FROM #AB)

INSERT INTO #ARMS VALUES ('Commercial insurance visits - AB', @299)

--Medicaid visits (full-fee / "traditional" only)
SELECT @300 = COUNT(DISTINCT enc_id)
FROM #enc pe
LEFT JOIN payer_mstr PM 
	ON pe.cob1_payer_id = pm.payer_id
LEFT JOIN mstr_lists ML 
	ON PM.financial_class = ML.mstr_list_item_id AND ML.mstr_list_type = 'fin_class'
WHERE mstr_list_item_desc = 'Medi-Cal-4120'
AND cob1_payer_id IS NOT NULL
AND enc_id IN (SELECT enc_id FROM #AB)

INSERT INTO #ARMS VALUES ('Medicaid visits (full-fee / "traditional" only) - AB', @300)
	
--Medicaid Family Planning Waiver visits
SELECT @301 = COUNT(DISTINCT enc_id)
FROM #enc pe
LEFT JOIN payer_mstr PM 
	ON pe.cob1_payer_id = pm.payer_id
LEFT JOIN mstr_lists ML 
	ON PM.financial_class = ML.mstr_list_item_id AND ML.mstr_list_type = 'fin_class'
WHERE mstr_list_item_desc = 'Family PACT-4110'
AND cob1_payer_id IS NOT NULL
AND enc_id IN (SELECT enc_id FROM #AB)

INSERT INTO #ARMS VALUES ('Medicaid Family Planning Waiver visits - AB', @301)
	
--Medicaid Managed Care visits	
SELECT @302 = COUNT(DISTINCT enc_id)
FROM #enc pe
LEFT JOIN payer_mstr PM 
	ON pe.cob1_payer_id = pm.payer_id
LEFT JOIN mstr_lists ML 
	ON PM.financial_class = ML.mstr_list_item_id AND ML.mstr_list_type = 'fin_class'
WHERE mstr_list_item_desc = 'Medi-Cal Managed Care-4130'
AND cob1_payer_id IS NOT NULL
AND enc_id IN (SELECT enc_id FROM #AB)

INSERT INTO #ARMS VALUES ('Medicaid Managed Care visits - AB', @302)

--Medicare	
SELECT @303 = COUNT(DISTINCT enc_id)
FROM #enc pe
LEFT JOIN payer_mstr PM 
	ON pe.cob1_payer_id = pm.payer_id
LEFT JOIN mstr_lists ML 
	ON PM.financial_class = ML.mstr_list_item_id AND ML.mstr_list_type = 'fin_class'
WHERE mstr_list_item_desc = 'Medicare'
AND cob1_payer_id IS NOT NULL
AND enc_id IN (SELECT enc_id FROM #AB)

INSERT INTO #ARMS VALUES ('Medicare - AB', @303)

--Full self-pay visits	
SELECT @304 = COUNT(DISTINCT enc_id)
FROM #enc pe
LEFT JOIN payer_mstr PM 
	ON pe.cob1_payer_id = pm.payer_id
LEFT JOIN mstr_lists ML 
	ON PM.financial_class = ML.mstr_list_item_id AND ML.mstr_list_type = 'fin_class'
WHERE (ml.mstr_list_item_desc LIKE '%cash%' OR pe.cob1_payer_id IS NULL)
AND enc_id IN (SELECT enc_id FROM #AB)

INSERT INTO #ARMS VALUES ('Full self-pay visits - AB', @304)

--Title X-funded self pay visits	
SELECT @305 = COUNT(DISTINCT pe.enc_id)
FROM #enc pe
JOIN #proc p
	ON pe.enc_id = p.enc_id
LEFT JOIN payer_mstr PM 
	ON pe.cob1_payer_id = pm.payer_id
LEFT JOIN mstr_lists ML 
	ON PM.financial_class = ML.mstr_list_item_id AND ML.mstr_list_type = 'fin_class'
WHERE (ml.mstr_list_item_desc LIKE '%cash%' OR pe.cob1_payer_id IS NULL)
AND pe.enc_id IN (SELECT enc_id FROM #AB)
AND p.location_id NOT IN ('68C7DDB4-834A-4ABC-B3EB-87BF71D60F41', '966B30EA-F24F-48D6-8346-948669FDCE6E'
                            ,'518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --FASS, Online, Clinical services and Lab are excluded as they are non Title X centers
AND (
		diagnosis_code_id_1 != 'Z64.0'
		AND  diagnosis_code_id_2 != 'Z64.0'
		AND  diagnosis_code_id_3 != 'Z64.0'
		AND  diagnosis_code_id_4 != 'Z64.0'
		AND  cpt4_code_id NOT LIKE '%59840A%'
		AND  cpt4_code_id NOT LIKE '%59841[C-N]%'
		AND  cpt4_code_id NOT LIKE '%S0199%'
		AND  cpt4_code_id NOT LIKE '%S0199A%'
       )

INSERT INTO #ARMS VALUES ('Title X-funded self pay visits - AB', @305)

--Other self-pay visits (subsidized by other grants)	
INSERT INTO #ARMS VALUES ('Other self-pay visits (subsidized by other grants)- AB', 0)
--Unknown primary payor visits	
INSERT INTO #ARMS VALUES ('Unknown primary payor visits - AB', 0)

/* Medical Data by State */
--Total female visits, any service	
SELECT @308 = COUNT(*)
FROM #enc
WHERE sex = 'F'

INSERT INTO #ARMS VALUES ('Total female visits, any service', @308)
			
--Total female clients, any service	
SELECT @309 = COUNT(DISTINCT person_id)
FROM #enc
WHERE sex = 'F'			

INSERT INTO #ARMS VALUES ('Total female clients, any service', @309)

--Total male visits, any service
SELECT @310 = COUNT(*)
FROM #enc
WHERE sex = 'M'

INSERT INTO #ARMS VALUES ('Total male visits, any service', @310)
				
--Total male clients, any service
SELECT @311 = COUNT(DISTINCT person_id)
FROM #enc
WHERE sex = 'M'	

INSERT INTO #ARMS VALUES ('Total male clients, any service', @311)
				
--Title X center visits	
SELECT @312 = COUNT(*)
FROM #enc pe
WHERE pe.location_id NOT IN ('68C7DDB4-834A-4ABC-B3EB-87BF71D60F41', '966B30EA-F24F-48D6-8346-948669FDCE6E'
                            ,'518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD') --FASS, Online, Clinical services and Lab are excluded as they are non Title X centers

INSERT INTO #ARMS VALUES ('Title X center visits', @312)
			
--Title X center clients
SELECT @313 = COUNT(DISTINCT person_id)
FROM #enc pe
WHERE pe.location_id NOT IN ('68C7DDB4-834A-4ABC-B3EB-87BF71D60F41', '966B30EA-F24F-48D6-8346-948669FDCE6E'
                            ,'518024FD-A407-4409-9986-E6B3993F9D37', '3A067539-F112-4304-931D-613F7C4F26FD')

INSERT INTO #ARMS VALUES ('Title X center clients', @313)
											
--Total female contraception client (anyone that has recieved contraception services AND they didn't get an AB on same day )
SELECT @314 = COUNT(DISTINCT person_id)
FROM #ContraClients
WHERE sex = 'F'
AND enc_id NOT IN (
					SELECT enc_id FROM #proc p
					WHERE p.cpt4_code_id IN (
					'59840A','59840AMD','59841C','59841CMD','59841D','59841DMD','59841E','59841EMD','59841F','59841FMD','59841G',
					'59841GMD','59841H','59841HMD','59841I','59841IMD','59841J','59841JMD','59841K','59841KMD','59841L','59841LMD',
					'59841M','9841MMD','59841N','59841NMD')
					)
INSERT INTO #ARMS VALUES ('Total female contraception client',@314)
			
--Medication abortion procedures
SELECT @315 = @50	
INSERT INTO #ARMS VALUES ('Medication abortion procedures', @315)
			
--First trimester abortion procedures	
SELECT @316 = COUNT(DISTINCT enc_id)
FROM #proc
WHERE cpt4_code_id IN ('59840','59851','59840A','59840AMD','59841C','59841CMD','59841D','59841DMD')	

INSERT INTO #ARMS VALUES ('First trimester abortion procedures', @316)
		
--Second trimester abortion procedures		
SELECT @317 = COUNT(DISTINCT enc_id)
FROM #proc
WHERE cpt4_code_id IN ('59841','59850','59851','59855', '59856', '59857','59841E','59841EMD',
					 '59841F','59841FMD','59841G','59841GMD','59841H','59841HMD','59841I','59841IMD','59841J','59841JMD','59841K','59841KMD',
					 '59841L','59841LMD','59841M','59841MMD','59841N','59841NMD') 	

INSERT INTO #ARMS VALUES ('Second trimester abortion procedures', @317)
		
INSERT INTO #ARMS VALUES ('Prenatal including Smart Start - visits',0)				
INSERT INTO #ARMS VALUES ('Prenatal including Smart Start - clients',0)				
INSERT INTO #ARMS VALUES ('Primary care visits',0)				
INSERT INTO #ARMS VALUES ('Primary care clients',0)				
INSERT INTO #ARMS VALUES ('Well-woman visits (if not counted under primary care)',0)				
INSERT INTO #ARMS VALUES ('Well-woman clients (if not counted under primary care)',0)	

/* Tests, Positives, and Diagnoses by State */
--Chlamydia tests / positives (female)
SELECT @325 = COUNT(*)
FROM #Labs l
WHERE sex = 'F'
AND l.test_code_id IN ('10256','11363','16506','1759','196250','199123','2649','3636','3640','375','395','4558','498',
'501','6399','70051','70222','8396','8472','8475','CT4','GC6','NG001404','NG001545','NG002014','Voxent1000')
AND l.Result_Description IN ('','CT','CHLAMYDIA TRACHOMATIS RNA, TMA','CHLAMYDIA TRACHOMATIS RNA, TMA, RECTAL','Chlamydia trachomatis, NAA',
							'CHLAMYDIA TRACHOMATIS RNA, TMA, THROAT')
AND l.Result_Value IN ('POSITIVE','DETECTED')

INSERT INTO #ARMS VALUES ('Chlamydia tests / positives (female)', @325)
 				
--Chlamydia tests / positives (male)
SELECT @327 = COUNT(*)
FROM #Labs l
WHERE sex = 'M'
AND l.test_code_id IN ('10256','11363','16506','1759','196250','199123','2649','3636','3640','375','395','4558','498',
'501','6399','70051','70222','8396','8472','8475','CT4','GC6','NG001404','NG001545','NG002014','Voxent1000')
AND l.Result_Description IN ('','CT','CHLAMYDIA TRACHOMATIS RNA, TMA','CHLAMYDIA TRACHOMATIS RNA, TMA, RECTAL','Chlamydia trachomatis, NAA',
							'CHLAMYDIA TRACHOMATIS RNA, TMA, THROAT')
AND l.Result_Value IN ('POSITIVE','DETECTED')

INSERT INTO #ARMS VALUES ('Chlamydia tests / positives (male)', @327)
				
--Chlamydia tests / positives (gender unknown)	
SELECT @329 = COUNT(*)
FROM #Labs l
WHERE sex NOT IN ('F','M')
AND l.test_code_id IN ('10256','11363','16506','1759','196250','199123','2649','3636','3640','375','395','4558','498',
'501','6399','70051','70222','8396','8472','8475','CT4','GC6','NG001404','NG001545','NG002014','Voxent1000')
AND l.Result_Description IN ('','CT','CHLAMYDIA TRACHOMATIS RNA, TMA','CHLAMYDIA TRACHOMATIS RNA, TMA, RECTAL','Chlamydia trachomatis, NAA',
							'CHLAMYDIA TRACHOMATIS RNA, TMA, THROAT')
AND l.Result_Value IN ('POSITIVE','DETECTED')

INSERT INTO #ARMS VALUES ('Chlamydia tests / positives (gender unknown)', @329)
			
--HPV tests/positives (female)	
SELECT @331 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex = 'F'
AND l.test_code_id IN ('191940', '196250', '507301', '90649', '192047', '196250', '197146', '199123', '507301', '87210', 
						'194074', '196250', '199123', '81002', '87210', '90649')
AND l.Result_Description IN ('HPV, high-risk', 'DIAGNOSIS:')
AND ISNULL(l.Abnormal_Flag,'N') = 'A'	

INSERT INTO #ARMS VALUES ('HPV tests/positives (female)', @331)
			
--Pap tests			
SELECT @332 = COUNT(DISTINCT enc_id)
FROM #Labs l
WHERE sex = 'F'
AND l.test_code_id IN ('196250', '199123','193000')

INSERT INTO #ARMS VALUES ('Pap Tests', @332)

INSERT INTO #ARMS VALUES ('Pap tests resulting in ASCUS, low-grade, high-grade, cancerous, or AGUS diagnoses',0)

--Breast examinations / positives	
SELECT @334 = COUNT(distinct pe.enc_id) 
FROM #enc pe
JOIN pe_breast_ pb 
	ON pb.enc_id = pe.enc_id
JOIN pe_breast_palp_ bp
	ON pb.enc_id = bp.enc_id
WHERE (    
		   (pb.palpr_nl <> '1' AND (ISNULL(pb.palponly1,'') <>'' OR ISNULL(pb.palponly2,'') <>'' ) AND bp.size5a IS NOT NULL)
		OR (pb.palpL_nL <> '1' AND (ISNULL(pb.palponly3,'') <>'' OR ISNULL(pb.palponly4,'') <>'' ) AND bp.size7a IS NOT NULL)
	  )
AND sex = 'F'

INSERT INTO #ARMS VALUES ('Breast examinations / positives', @334)
			
/*************************************************************************************************************/	
SELECT * FROM #ARMS