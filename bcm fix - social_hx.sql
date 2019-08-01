--new location
--select txt_birth_control_visitend 
--from master_im_
--where

--drop table #Social_Hx_temp
--drop table #temp

select enc_id, person_id, CONVERT(DATE, create_timestamp) AS date, birth_control
INTO #Social_Hx_temp
from Social_Hx_

select 
--old location
		enc_id, person_id,
	   'BCM' = 
	CASE
		--male condom
		WHEN birth_control = 'condom'			    THEN 'Male Condom'
		WHEN birth_control = 'condoms' 
		  OR birth_control = ' condoms'		    THEN 'Male Condom' 
		WHEN birth_control LIKE '%Male Condom%' 
		 AND birth_control NOT LIKE '%female%' THEN 'Male Condom'
		WHEN birth_control LIKE 'condom%'		    THEN 'Male Condom'
		WHEN birth_control LIKE '%codom%'		    THEN 'Male Condom'
		WHEN birth_control LIKE '%condom'
			AND (birth_control NOT LIKE '%female%'
			AND   birth_control NOT LIKE '%OCP%'
			AND   birth_control NOT LIKE '%oral%'
			AND   birth_control NOT LIKE '%seeking%'
			AND   birth_control NOT LIKE '%same%')THEN 'Male Condom'
		WHEN birth_control LIKE 'male co%'
			AND birth_control NOT LIKE '%essu%'  THEN 'Male Condom'
		WHEN birth_control LIKE 'withdr%condom%' THEN 'Male Condom'
			
		--OC's
		WHEN birth_control LIKE '%chc%'			THEN 'Oral (CHC)'
		WHEN birth_control LIKE '%pop%'			THEN 'Oral (POP)'
		WHEN birth_control LIKE '%oral%'
			AND (birth_control NOT LIKE '%chc%'
			AND   birth_control NOT LIKE '%pop%'
			AND   birth_control NOT LIKE '%vase%'
			AND   birth_control NOT LIKE '%same%'
			AND   birth_control NOT LIKE '%consider%'
			AND   birth_control NOT LIKE '%not sexually%'
			AND   birth_control NOT LIKE '%partner%') THEN 'Oral (CHC)'
		WHEN birth_control = 'oral'					THEN 'Oral (CHC)'
		WHEN birth_control = 'oc'						THEN 'Oral (CHC)'
		WHEN birth_control = 'oc''s'					THEN 'Oral (CHC)'
		WHEN birth_control = 'ocs'					THEN 'Oral (CHC)'
		WHEN birth_control LIKE 'ocp%'				THEN 'Oral (CHC)'
		WHEN birth_control = 'pills'					THEN 'Oral (CHC)'
		WHEN birth_control LIKE 'birth%'				THEN 'Oral (CHC)'
		WHEN birth_control LIKE '%has oc%'			THEN 'Oral (CHC)'
		WHEN birth_control LIKE '%Abstinence%'
			AND birth_control LIKE '%oral%'			THEN 'Oral (CHC)'

		--patch
		WHEN birth_control LIKE '%PATCH%'
			AND (birth_control NOT LIKE '%consider%'
			OR birth_control NOT LIKE '%rtc%') THEN 'Patch'

		--ring
		WHEN birth_control LIKE 'ring%'  THEN 'Ring'
		WHEN birth_control LIKE '%nuva%' THEN 'Ring'
		WHEN birth_control LIKE '%ring'
		 AND birth_control NOT LIKE '%consider%' THEN 'Ring'

		--depo
		WHEN birth_control LIKE '%inject%'
			AND (birth_control NOT LIKE '%desire%'
			AND birth_control NOT LIKE '%rtc%') THEN 'Injection'
		WHEN birth_control LIKE '%depo%'
			AND (birth_control NOT LIKE '%f/u%'
			AND birth_control NOT LIKE '%none%'
			AND birth_control NOT LIKE '%oral%') THEN 'Injection'
		WHEN birth_control LIKE '%dmpa%'
			AND (birth_control NOT LIKE '%consider%'
			AND   birth_control NOT LIKE '%desire%'
			AND   birth_control NOT LIKE '%none%'
			AND   birth_control NOT LIKE '%plan%'
			AND   birth_control NOT LIKE '%will%'
			AND   birth_control NOT LIKE '%not%'
			AND   birth_control NOT LIKE '%none%'
			AND   birth_control NOT LIKE '%w/be%'
			AND   birth_control NOT LIKE '%iuc%') THEN 'Injection'

		--implant
		WHEN birth_control LIKE '%implan%'
			AND (birth_control NOT LIKE '%none%'
			AND birth_control NOT LIKE '%obtain%'
			AND birth_control NOT LIKE '%return%'
			AND birth_control NOT LIKE '%planned%'
			AND birth_control NOT LIKE '%wishes%'
			AND birth_control NOT LIKE '%pcp%'
			AND birth_control NOT LIKE '%rtc%'
			AND birth_control NOT LIKE '%schedule%'
			AND birth_control NOT LIKE '%appt%'
			AND birth_control NOT LIKE '%wants%'
			AND birth_control NOT LIKE '%pme%'
			AND birth_control NOT LIKE '%decline%'
			AND birth_control NOT LIKE '%IUD%') THEN 'Implant'
		WHEN birth_control = 'Nexplanon' THEN 'Implant'

		--IUC
		WHEN birth_control = 'IUC' THEN 'IUC'
		WHEN birth_control = 'IUD' THEN 'IUC (Levonorgestrel)'
		WHEN birth_control = 'IUS' THEN 'IUC (Levonorgestrel)'
		WHEN birth_control LIKE '%para%' 
			AND birth_control NOT LIKE '%will get para%' THEN 'IUC (Copper)'
		WHEN birth_control LIKE '%skyla%' THEN 'IUC (Levonorgestrel)'
		WHEN birth_control LIKE '%mirena%'
			AND (birth_control NOT LIKE '%appt%'
			AND   birth_control NOT LIKE '%considering%'
			AND   birth_control NOT LIKE '%desires%'
			AND   birth_control NOT LIKE '%call%') THEN 'IUC (Levonorgestrel)'
		WHEN birth_control LIKE '%levono%'
			AND (birth_control NOT LIKE '%plan%'
			AND   birth_control NOT LIKE '%pcp%'
			AND   birth_control NOT LIKE '%pending%') THEN 'IUC (Levonorgestrel)'
		WHEN birth_control LIKE '%IUC%'
			AND (birth_control NOT LIKE '%mirena%'
			AND   birth_control NOT LIKE '%oral%'
			AND   birth_control NOT LIKE '%pregnant%'
			AND   birth_control NOT LIKE '%consider%'
			AND   birth_control NOT LIKE '%partner%'
			AND   birth_control NOT LIKE '%no iuc%'
			AND   birth_control NOT LIKE '%complete%'
			AND   birth_control NOT LIKE '%pme%'
			AND   birth_control NOT LIKE '%none%'
			AND   birth_control NOT LIKE '%until%'
			AND   birth_control NOT LIKE '%inject%'
			AND   birth_control NOT LIKE '%desire%'
			AND   birth_control NOT LIKE '%hopeful%'
			AND   birth_control NOT LIKE '%interes%'
			AND   birth_control NOT LIKE '%plan%') THEN 'IUC (Copper)'

		--female sterilization
		WHEN birth_control LIKE '%female steriliz%'
			AND (birth_control NOT LIKE '%desire%' 
			AND  birth_control NOT LIKE '%consider%'
			AND  birth_control != 'male sterilization') THEN 'Female Sterilization'
		WHEN birth_control LIKE '%essu%'
			AND (birth_control NOT LIKE '%plan%'
			AND  birth_control NOT LIKE '%dmpa%'
			AND  birth_control NOT LIKE '%info%') THEN 'Female Sterilization'
		WHEN birth_control LIKE '%tubal%'
			AND  birth_control NOT LIKE '%plan%' THEN 'Female Sterilization'
		WHEN birth_control LIKE '%sterili%'
			AND (birth_control NOT LIKE '%plan%'
			AND  birth_control NOT LIKE '%partner%'
			AND  birth_control NOT LIKE '%desire%'
			AND  birth_control NOT LIKE '%seek%'
			AND  birth_control NOT LIKE '%wish%'
			AND  birth_control NOT LIKE '%hyst%'
			AND  birth_control NOT LIKE '%consider%'
			AND  birth_control != 'male sterilization') THEN 'Female Sterilization'
		WHEN birth_control = 'BTL' THEN 'Female Sterilization'
		
		--vasectomy
		WHEN birth_control LIKE '%vase%'
			AND birth_control NOT LIKE '%diap%' THEN 'Vasectomy'
		WHEN birth_control = 'Male Sterilization' 
			OR birth_control LIKE '%.male ster%' THEN 'Vasectomy'

		--partner method
		WHEN birth_control LIKE '%Partner Method%'
			AND birth_control NOT LIKE '%condom%' THEN 'Partner Method'
		WHEN birth_control LIKE '%partner ster%' THEN 'Partner Method'
		WHEN birth_control = 'relying on partner' THEN 'Partner Method'
		WHEN birth_control LIKE 'partner ha%' THEN 'Partner Method'
		WHEN birth_control LIKE '%partner%'
			AND (birth_control LIKE '%condom'
			AND  birth_control NOT LIKE '%SEX%') THEN 'Partner Method'
		WHEN birth_control LIKE '%partner%'
			AND  birth_control LIKE '%infer%' THEN 'Partner Method'
		WHEN birth_control LIKE '%rely%' THEN 'Partner Method'

		--abstinence
		WHEN birth_control = 'Not Sexually Active' THEN 'Abstinence'
		WHEN birth_control = 'Not Sexually Active/Abstinent' THEN 'Abstinence'
		WHEN birth_control LIKE 'abstin%'
			AND (birth_control NOT LIKE '%condom%'
			AND   birth_control NOT LIKE '%oral%') THEN 'Abstinence'
		WHEN birth_control LIKE '%Abstinence%'
			AND  birth_control NOT LIKE '%oral%' THEN 'Abstinence'
		WHEN birth_control LIKE 'not sex%' THEN 'Abstinence'
		WHEN birth_control LIKE '%Not Sexually Active / Abstinent%'
			AND (birth_control NOT LIKE '%cond%'
			AND   birth_control NOT LIKE '%oral%'
			AND   birth_control NOT LIKE '%ocs%'
			AND   birth_control NOT LIKE '%dmpa%') THEN 'Abstinence'
		WHEN birth_control LIKE 'abstain%' THEN 'Abstinence'

		--female condom
		WHEN birth_control LIKE '%Female Condom%' THEN 'Female Condom'
		WHEN birth_control LIKE '%film%'
			AND birth_control NOT LIKE '%condom%' THEN 'Female Condom'

		--Cervical Cap/diaphragm
		WHEN birth_control LIKE '%Diaphr%' THEN 'Cervical cap/Diaphragm' 
		WHEN birth_control = 'Cervical Cap' THEN 'Cervical cap/Diaphragm'

		--sponge
		WHEN birth_control = 'Sponge' THEN 'Sponge'

		--FAM/NFP
		WHEN birth_control = 'FAM/NFP' THEN 'FAM/NFP'
		WHEN birth_control LIKE '%Family%' THEN 'FAM/NFP'

		--LAM
		WHEN birth_control LIKE '%lacta%' THEN 'FAM/NFP'

		--Seeking pregnancy
		WHEN birth_control LIKE '%seeking%'
			AND (birth_control NOT LIKE '%none%' 
			AND   birth_control NOT LIKE '%steril%') THEN 'Seeking pregnancy' 
		WHEN birth_control LIKE '%trying%' THEN 'Seeking pregnancy' 
		WHEN birth_control LIKE '%pregnancy%'
			AND (birth_control NOT LIKE '%planned%'
			AND   birth_control NOT LIKE '%not%') THEN 'Seeking pregnancy' 
		WHEN  birth_control LIKE 'planning%' THEN 'Seeking pregnancy' 

		--Pregnant/Partner Pregnant
		WHEN birth_control LIKE '%pregnant%'
			AND (birth_control NOT LIKE '%not%' 
			AND   birth_control NOT LIKE '%trying%') THEN 'Pregnant/Partner Pregnant'
		WHEN birth_control LIKE '%unplanned%' THEN 'Pregnant/Partner Pregnant'
		WHEN birth_control LIKE '%planned preg%' THEN 'Pregnant/Partner Pregnant'
		WHEN birth_control LIKE 'pregan%' THEN 'Pregnant/Partner Pregnant'
		WHEN birth_control = 'preg' THEN 'Pregnant/Partner Pregnant'

		--infertile
		WHEN birth_control LIKE '%menop%' THEN 'Infertile'
		WHEN birth_control LIKE '%infert%'
			AND birth_control NOT LIKE '%part%' THEN 'Infertile'
		WHEN birth_control LIKE '%HYST%' THEN 'Infertile'

		--Same Sex Partner
		WHEN birth_control like '%same%' THEN 'Same sex partner'
		WHEN birth_control LIKE '%condom%'
			AND birth_control LIKE '%same%' THEN 'Same sex partner'
		WHEN birth_control LIKE 'female part%' THEN 'Same sex partner'

		--spermicide
		WHEN birth_control LIKE '%Spermicide%' THEN 'Spermicide'

		--No method
		WHEN birth_control = NULL THEN 'No Method'
		WHEN birth_control LIKE '%none%'
			AND (birth_control NOT LIKE '%preg%' 
			AND   birth_control NOT LIKE '%sex%') THEN 'No Method'
		WHEN birth_control LIKE 'none%'
			AND (birth_control NOT LIKE '%meno%'
			AND   birth_control NOT LIKE '%preg%'
			AND   birth_control NOT LIKE '%same%'
			AND   birth_control NOT LIKE '%depo%') THEN 'No Method'
		WHEN birth_control = 'unknown' THEN 'No Method'
		WHEN birth_control LIKE '%declin%'
			AND birth_control NOT LIKE '%condom%' THEN 'No Method'
		WHEN birth_control LIKE 'consider%' THEN 'No Method'
		WHEN birth_control LIKE 'desire%'
			AND birth_control NOT LIKE '%preg%' THEN 'No Method'
		WHEN birth_control LIKE 'refus%' THEN 'No Method'
		WHEN birth_control LIKE '%undec%' THEN 'No Method'
		WHEN birth_control = '' THEN 'No Method'
		WHEN birth_control = 'nothing' THEN 'No Method'

		--EC
		WHEN birth_control LIKE 'ec%'
			AND birth_control NOT LIKE '%condom%' THEN 'No Method'
		WHEN birth_control LIKE '%ella%'
			AND birth_control NOT LIKE '%condom%' THEN 'No Method'

		--other
		WHEN birth_control LIKE '%other%'
			AND (birth_control NOT LIKE '%IUC%'
			AND birth_control NOT LIKE '%hyster%'
			AND birth_control NOT LIKE '%preg%'
			AND birth_control NOT LIKE '%meno%'
			AND birth_control NOT LIKE '%oral%'
			AND birth_control NOT LIKE '%POP%'
			AND birth_control NOT LIKE '%condom%'
			AND birth_control NOT LIKE '%essu%'
			AND birth_control NOT LIKE '%plan%') THEN 'No Method'
		WHEN birth_control LIKE '%withdraw%'
			AND (birth_control NOT LIKE '%condom%'
			AND   birth_control NOT LIKE '%sperm%') THEN 'Other Methods'
		ELSE 'Male Condom'
	END
INTO #temp
from Social_Hx_
--WHERE (create_timestamp >= '20150701' AND create_timestamp <= '20160630')

update Social_Hx_ --2306649
set Social_Hx_.birth_control = #temp.BCM
from #Social_Hx_temp pp
JOIN #temp ON (pp.enc_id = #temp.enc_id and pp.person_id = #temp.person_id)

update top (5454) #Social_Hx_temp --update 60% of IUC to Levonorgestrel
set #Social_Hx_temp.birth_control = 'IUC (Levonorgestrel)'
from #Social_Hx_temp pp
JOIN #temp ON (pp.enc_id = #temp.enc_id and pp.person_id = #temp.person_id)
WHERE birth_control = 'IUC'

update #Social_Hx_temp --update rest of IUC to Copper
set #Social_Hx_temp.birth_control = 'IUC (Copper)'
from #Social_Hx_temp pp
JOIN #temp ON (pp.enc_id = #temp.enc_id and pp.person_id = #temp.person_id)
WHERE birth_control = 'IUC'

---------------------------------------------------------

select count(*) birth_control 
from Social_Hx_
where birth_control IS NULL
and (create_timestamp >= '20150701' AND create_timestamp <= '20160630')


select person_id, birth_control, MAX(date)
from #Social_Hx_temp
WHERE (date >= '20140701' AND date <= '20150630')
GROUP BY person_id, birth_control --create_timestamp
ORDER BY person_id, birth_control

select MAX(num) 
from #temp2
WHERE birth_control IS NOT NULL
GROUP BY person_id, birth_control, date, num
order by person_id

select birth_control
from #Social_Hx_temp pph
INNER JOIN
	(SELECT person_id, MAX(DATE) AS MAXDATE
	 FROM #Social_Hx_temp
	 GROUP BY person_id) groupedt
ON pph.person_id = groupedt.person_id AND pph.date = groupedt.MAXDATE
WHERE (pph.date >= '20140701' AND pph.date <= '20150630') AND pph.birth_control IS NOT NULL
order by pph.person_id

select birth_control, create_timestamp
from Social_Hx_
WHERE 

create_timestamp =(SELECT MAX(create_timestamp) FROM Social_Hx_)
--AND (create_timestamp >= '20140701' AND create_timestamp <= '20150630')
group by birth_control, create_timestamp

select COUNT (*)birth_control 
from Social_Hx_ pph
JOIN PP_Config_General_List_ep_ cg ON pph.birth_control = cg.list_value
WHERE (pph.create_timestamp >= '20140701' AND pph.create_timestamp <= '20150630')
and birth_control LIKE '%male condom%'

select birth_control 
from Social_Hx_ pph
--JOIN PP_Config_General_List_ep_ cg ON pph.birth_control = cg.list_value
WHERE (pph.create_timestamp >= '20140701' AND pph.create_timestamp <= '20150630')
and birth_control LIKE '%ORAL%'


select COUNT(*) AS 'count', birth_control
from Social_Hx_
group by birth_control