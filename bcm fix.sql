--new location
--select txt_birth_control_visitend 
--from master_im_
--where

--drop table #pp_home_temp
--drop table #temp

select enc_id, person_id, CONVERT(DATE, create_timestamp) AS date, bcm_at_end_of_visit
INTO #pp_home_temp
from PP_Home_

select 
--old location
		enc_id, person_id,
	   'BCM' = 
	CASE
		--male condom
		WHEN bcm_at_end_of_visit = 'condom'			    THEN 'Male Condom'
		WHEN bcm_at_end_of_visit = 'condoms' 
		  OR bcm_at_end_of_visit = ' condoms'		    THEN 'Male Condom' 
		WHEN bcm_at_end_of_visit LIKE '%Male Condom%' 
		 AND bcm_at_end_of_visit NOT LIKE '%female%' THEN 'Male Condom'
		WHEN bcm_at_end_of_visit LIKE 'condom%'		    THEN 'Male Condom'
		WHEN bcm_at_end_of_visit LIKE '%codom%'		    THEN 'Male Condom'
		WHEN bcm_at_end_of_visit LIKE '%condom'
			AND (bcm_at_end_of_visit NOT LIKE '%female%'
			AND   bcm_at_end_of_visit NOT LIKE '%OCP%'
			AND   bcm_at_end_of_visit NOT LIKE '%oral%'
			AND   bcm_at_end_of_visit NOT LIKE '%seeking%'
			AND   bcm_at_end_of_visit NOT LIKE '%same%')THEN 'Male Condom'
		WHEN bcm_at_end_of_visit LIKE 'male co%'
			AND bcm_at_end_of_visit NOT LIKE '%essu%'  THEN 'Male Condom'
		WHEN bcm_at_end_of_visit LIKE 'withdr%condom%' THEN 'Male Condom'
			
		--OC's
		WHEN bcm_at_end_of_visit LIKE '%chc%'			THEN 'Oral (CHC)'
		WHEN bcm_at_end_of_visit LIKE '%pop%'			THEN 'Oral (POP)'
		WHEN bcm_at_end_of_visit LIKE '%oral%'
			AND (bcm_at_end_of_visit NOT LIKE '%chc%'
			AND   bcm_at_end_of_visit NOT LIKE '%pop%'
			AND   bcm_at_end_of_visit NOT LIKE '%vase%'
			AND   bcm_at_end_of_visit NOT LIKE '%same%'
			AND   bcm_at_end_of_visit NOT LIKE '%consider%'
			AND   bcm_at_end_of_visit NOT LIKE '%not sexually%'
			AND   bcm_at_end_of_visit NOT LIKE '%partner%') THEN 'Oral (CHC)'
		WHEN bcm_at_end_of_visit = 'oral'					THEN 'Oral (CHC)'
		WHEN bcm_at_end_of_visit = 'oc'						THEN 'Oral (CHC)'
		WHEN bcm_at_end_of_visit = 'oc''s'					THEN 'Oral (CHC)'
		WHEN bcm_at_end_of_visit = 'ocs'					THEN 'Oral (CHC)'
		WHEN bcm_at_end_of_visit LIKE 'ocp%'				THEN 'Oral (CHC)'
		WHEN bcm_at_end_of_visit = 'pills'					THEN 'Oral (CHC)'
		WHEN bcm_at_end_of_visit LIKE 'birth%'				THEN 'Oral (CHC)'
		WHEN bcm_at_end_of_visit LIKE '%has oc%'			THEN 'Oral (CHC)'
		WHEN bcm_at_end_of_visit LIKE '%Abstinence%'
			AND bcm_at_end_of_visit LIKE '%oral%'			THEN 'Oral (CHC)'

		--patch
		WHEN bcm_at_end_of_visit LIKE '%PATCH%'
			AND (bcm_at_end_of_visit NOT LIKE '%consider%'
			OR bcm_at_end_of_visit NOT LIKE '%rtc%') THEN 'Patch'

		--ring
		WHEN bcm_at_end_of_visit LIKE 'ring%'  THEN 'Ring'
		WHEN bcm_at_end_of_visit LIKE '%nuva%' THEN 'Ring'
		WHEN bcm_at_end_of_visit LIKE '%ring'
		 AND bcm_at_end_of_visit NOT LIKE '%consider%' THEN 'Ring'

		--depo
		WHEN bcm_at_end_of_visit LIKE '%inject%'
			AND (bcm_at_end_of_visit NOT LIKE '%desire%'
			AND bcm_at_end_of_visit NOT LIKE '%rtc%') THEN 'Injection'
		WHEN bcm_at_end_of_visit LIKE '%depo%'
			AND (bcm_at_end_of_visit NOT LIKE '%f/u%'
			AND bcm_at_end_of_visit NOT LIKE '%none%'
			AND bcm_at_end_of_visit NOT LIKE '%oral%') THEN 'Injection'
		WHEN bcm_at_end_of_visit LIKE '%dmpa%'
			AND (bcm_at_end_of_visit NOT LIKE '%consider%'
			AND   bcm_at_end_of_visit NOT LIKE '%desire%'
			AND   bcm_at_end_of_visit NOT LIKE '%none%'
			AND   bcm_at_end_of_visit NOT LIKE '%plan%'
			AND   bcm_at_end_of_visit NOT LIKE '%will%'
			AND   bcm_at_end_of_visit NOT LIKE '%not%'
			AND   bcm_at_end_of_visit NOT LIKE '%none%'
			AND   bcm_at_end_of_visit NOT LIKE '%w/be%'
			AND   bcm_at_end_of_visit NOT LIKE '%iuc%') THEN 'Injection'

		--implant
		WHEN bcm_at_end_of_visit LIKE '%implan%'
			AND (bcm_at_end_of_visit NOT LIKE '%none%'
			AND bcm_at_end_of_visit NOT LIKE '%obtain%'
			AND bcm_at_end_of_visit NOT LIKE '%return%'
			AND bcm_at_end_of_visit NOT LIKE '%planned%'
			AND bcm_at_end_of_visit NOT LIKE '%wishes%'
			AND bcm_at_end_of_visit NOT LIKE '%pcp%'
			AND bcm_at_end_of_visit NOT LIKE '%rtc%'
			AND bcm_at_end_of_visit NOT LIKE '%schedule%'
			AND bcm_at_end_of_visit NOT LIKE '%appt%'
			AND bcm_at_end_of_visit NOT LIKE '%wants%'
			AND bcm_at_end_of_visit NOT LIKE '%pme%'
			AND bcm_at_end_of_visit NOT LIKE '%decline%'
			AND bcm_at_end_of_visit NOT LIKE '%IUD%') THEN 'Implant'
		WHEN bcm_at_end_of_visit = 'Nexplanon' THEN 'Implant'

		--IUC
		WHEN bcm_at_end_of_visit = 'IUC' THEN 'IUC'
		WHEN bcm_at_end_of_visit = 'IUD' THEN 'IUC (Levonorgestrel)'
		WHEN bcm_at_end_of_visit = 'IUS' THEN 'IUC (Levonorgestrel)'
		WHEN bcm_at_end_of_visit LIKE '%para%' 
			AND bcm_at_end_of_visit NOT LIKE '%will get para%' THEN 'IUC (Copper)'
		WHEN bcm_at_end_of_visit LIKE '%skyla%' THEN 'IUC (Levonorgestrel)'
		WHEN bcm_at_end_of_visit LIKE '%mirena%'
			AND (bcm_at_end_of_visit NOT LIKE '%appt%'
			AND   bcm_at_end_of_visit NOT LIKE '%considering%'
			AND   bcm_at_end_of_visit NOT LIKE '%desires%'
			AND   bcm_at_end_of_visit NOT LIKE '%call%') THEN 'IUC (Levonorgestrel)'
		WHEN bcm_at_end_of_visit LIKE '%levono%'
			AND (bcm_at_end_of_visit NOT LIKE '%plan%'
			AND   bcm_at_end_of_visit NOT LIKE '%pcp%'
			AND   bcm_at_end_of_visit NOT LIKE '%pending%') THEN 'IUC (Levonorgestrel)'
		WHEN bcm_at_end_of_visit LIKE '%IUC%'
			AND (bcm_at_end_of_visit NOT LIKE '%mirena%'
			AND   bcm_at_end_of_visit NOT LIKE '%oral%'
			AND   bcm_at_end_of_visit NOT LIKE '%pregnant%'
			AND   bcm_at_end_of_visit NOT LIKE '%consider%'
			AND   bcm_at_end_of_visit NOT LIKE '%partner%'
			AND   bcm_at_end_of_visit NOT LIKE '%no iuc%'
			AND   bcm_at_end_of_visit NOT LIKE '%complete%'
			AND   bcm_at_end_of_visit NOT LIKE '%pme%'
			AND   bcm_at_end_of_visit NOT LIKE '%none%'
			AND   bcm_at_end_of_visit NOT LIKE '%until%'
			AND   bcm_at_end_of_visit NOT LIKE '%inject%'
			AND   bcm_at_end_of_visit NOT LIKE '%desire%'
			AND   bcm_at_end_of_visit NOT LIKE '%hopeful%'
			AND   bcm_at_end_of_visit NOT LIKE '%interes%'
			AND   bcm_at_end_of_visit NOT LIKE '%plan%') THEN 'IUC (Copper)'

		--female sterilization
		WHEN bcm_at_end_of_visit LIKE '%female steriliz%'
			AND (bcm_at_end_of_visit NOT LIKE '%desire%' 
			AND  bcm_at_end_of_visit NOT LIKE '%consider%'
			AND  bcm_at_end_of_visit != 'male sterilization') THEN 'Female Sterilization'
		WHEN bcm_at_end_of_visit LIKE '%essu%'
			AND (bcm_at_end_of_visit NOT LIKE '%plan%'
			AND  bcm_at_end_of_visit NOT LIKE '%dmpa%'
			AND  bcm_at_end_of_visit NOT LIKE '%info%') THEN 'Female Sterilization'
		WHEN bcm_at_end_of_visit LIKE '%tubal%'
			AND  bcm_at_end_of_visit NOT LIKE '%plan%' THEN 'Female Sterilization'
		WHEN bcm_at_end_of_visit LIKE '%sterili%'
			AND (bcm_at_end_of_visit NOT LIKE '%plan%'
			AND  bcm_at_end_of_visit NOT LIKE '%partner%'
			AND  bcm_at_end_of_visit NOT LIKE '%desire%'
			AND  bcm_at_end_of_visit NOT LIKE '%seek%'
			AND  bcm_at_end_of_visit NOT LIKE '%wish%'
			AND  bcm_at_end_of_visit NOT LIKE '%hyst%'
			AND  bcm_at_end_of_visit NOT LIKE '%consider%'
			AND  bcm_at_end_of_visit != 'male sterilization') THEN 'Female Sterilization'
		WHEN bcm_at_end_of_visit = 'BTL' THEN 'Female Sterilization'
		
		--vasectomy
		WHEN bcm_at_end_of_visit LIKE '%vase%'
			AND bcm_at_end_of_visit NOT LIKE '%diap%' THEN 'Vasectomy'
		WHEN bcm_at_end_of_visit = 'Male Sterilization' 
			OR bcm_at_end_of_visit LIKE '%.male ster%' THEN 'Vasectomy'

		--partner method
		WHEN bcm_at_end_of_visit LIKE '%Partner Method%'
			AND bcm_at_end_of_visit NOT LIKE '%condom%' THEN 'Partner Method'
		WHEN bcm_at_end_of_visit LIKE '%partner ster%' THEN 'Partner Method'
		WHEN bcm_at_end_of_visit = 'relying on partner' THEN 'Partner Method'
		WHEN bcm_at_end_of_visit LIKE 'partner ha%' THEN 'Partner Method'
		WHEN bcm_at_end_of_visit LIKE '%partner%'
			AND (bcm_at_end_of_visit LIKE '%condom'
			AND  bcm_at_end_of_visit NOT LIKE '%SEX%') THEN 'Partner Method'
		WHEN bcm_at_end_of_visit LIKE '%partner%'
			AND  bcm_at_end_of_visit LIKE '%infer%' THEN 'Partner Method'
		WHEN bcm_at_end_of_visit LIKE '%rely%' THEN 'Partner Method'

		--abstinence
		WHEN bcm_at_end_of_visit = 'Not Sexually Active' THEN 'Abstinence'
		WHEN bcm_at_end_of_visit = 'Not Sexually Active/Abstinent' THEN 'Abstinence'
		WHEN bcm_at_end_of_visit LIKE 'abstin%'
			AND (bcm_at_end_of_visit NOT LIKE '%condom%'
			AND   bcm_at_end_of_visit NOT LIKE '%oral%') THEN 'Abstinence'
		WHEN bcm_at_end_of_visit LIKE '%Abstinence%'
			AND  bcm_at_end_of_visit NOT LIKE '%oral%' THEN 'Abstinence'
		WHEN bcm_at_end_of_visit LIKE 'not sex%' THEN 'Abstinence'
		WHEN bcm_at_end_of_visit LIKE '%Not Sexually Active / Abstinent%'
			AND (bcm_at_end_of_visit NOT LIKE '%cond%'
			AND   bcm_at_end_of_visit NOT LIKE '%oral%'
			AND   bcm_at_end_of_visit NOT LIKE '%ocs%'
			AND   bcm_at_end_of_visit NOT LIKE '%dmpa%') THEN 'Abstinence'
		WHEN bcm_at_end_of_visit LIKE 'abstain%' THEN 'Abstinence'

		--female condom
		WHEN bcm_at_end_of_visit LIKE '%Female Condom%' THEN 'Female Condom'
		WHEN bcm_at_end_of_visit LIKE '%film%'
			AND bcm_at_end_of_visit NOT LIKE '%condom%' THEN 'Female Condom'

		--Cervical Cap/diaphragm
		WHEN bcm_at_end_of_visit LIKE '%Diaphr%' THEN 'Cervical cap/Diaphragm' 
		WHEN bcm_at_end_of_visit = 'Cervical Cap' THEN 'Cervical cap/Diaphragm'

		--sponge
		WHEN bcm_at_end_of_visit = 'Sponge' THEN 'Sponge'

		--FAM/NFP
		WHEN bcm_at_end_of_visit = 'FAM/NFP' THEN 'FAM/NFP'
		WHEN bcm_at_end_of_visit LIKE '%Family%' THEN 'FAM/NFP'

		--LAM
		WHEN bcm_at_end_of_visit LIKE '%lacta%' THEN 'FAM/NFP'

		--Seeking pregnancy
		WHEN bcm_at_end_of_visit LIKE '%seeking%'
			AND (bcm_at_end_of_visit NOT LIKE '%none%' 
			AND   bcm_at_end_of_visit NOT LIKE '%steril%') THEN 'Seeking pregnancy' 
		WHEN bcm_at_end_of_visit LIKE '%trying%' THEN 'Seeking pregnancy' 
		WHEN bcm_at_end_of_visit LIKE '%pregnancy%'
			AND (bcm_at_end_of_visit NOT LIKE '%planned%'
			AND   bcm_at_end_of_visit NOT LIKE '%not%') THEN 'Seeking pregnancy' 
		WHEN  bcm_at_end_of_visit LIKE 'planning%' THEN 'Seeking pregnancy' 

		--Pregnant/Partner Pregnant
		WHEN bcm_at_end_of_visit LIKE '%pregnant%'
			AND (bcm_at_end_of_visit NOT LIKE '%not%' 
			AND   bcm_at_end_of_visit NOT LIKE '%trying%') THEN 'Pregnant/Partner Pregnant'
		WHEN bcm_at_end_of_visit LIKE '%unplanned%' THEN 'Pregnant/Partner Pregnant'
		WHEN bcm_at_end_of_visit LIKE '%planned preg%' THEN 'Pregnant/Partner Pregnant'
		WHEN bcm_at_end_of_visit LIKE 'pregan%' THEN 'Pregnant/Partner Pregnant'
		WHEN bcm_at_end_of_visit = 'preg' THEN 'Pregnant/Partner Pregnant'

		--infertile
		WHEN bcm_at_end_of_visit LIKE '%menop%' THEN 'Infertile'
		WHEN bcm_at_end_of_visit LIKE '%infert%'
			AND bcm_at_end_of_visit NOT LIKE '%part%' THEN 'Infertile'
		WHEN bcm_at_end_of_visit LIKE '%HYST%' THEN 'Infertile'

		--Same Sex Partner
		WHEN bcm_at_end_of_visit like '%same%' THEN 'Same sex partner'
		WHEN bcm_at_end_of_visit LIKE '%condom%'
			AND bcm_at_end_of_visit LIKE '%same%' THEN 'Same sex partner'
		WHEN bcm_at_end_of_visit LIKE 'female part%' THEN 'Same sex partner'

		--spermicide
		WHEN bcm_at_end_of_visit LIKE '%Spermicide%' THEN 'Spermicide'

		--No method
		WHEN bcm_at_end_of_visit = NULL THEN 'No Method'
		WHEN bcm_at_end_of_visit LIKE '%none%'
			AND (bcm_at_end_of_visit NOT LIKE '%preg%' 
			AND   bcm_at_end_of_visit NOT LIKE '%sex%') THEN 'No Method'
		WHEN bcm_at_end_of_visit LIKE 'none%'
			AND (bcm_at_end_of_visit NOT LIKE '%meno%'
			AND   bcm_at_end_of_visit NOT LIKE '%preg%'
			AND   bcm_at_end_of_visit NOT LIKE '%same%'
			AND   bcm_at_end_of_visit NOT LIKE '%depo%') THEN 'No Method'
		WHEN bcm_at_end_of_visit = 'unknown' THEN 'No Method'
		WHEN bcm_at_end_of_visit LIKE '%declin%'
			AND bcm_at_end_of_visit NOT LIKE '%condom%' THEN 'No Method'
		WHEN bcm_at_end_of_visit LIKE 'consider%' THEN 'No Method'
		WHEN bcm_at_end_of_visit LIKE 'desire%'
			AND bcm_at_end_of_visit NOT LIKE '%preg%' THEN 'No Method'
		WHEN bcm_at_end_of_visit LIKE 'refus%' THEN 'No Method'
		WHEN bcm_at_end_of_visit LIKE '%undec%' THEN 'No Method'
		WHEN bcm_at_end_of_visit = '' THEN 'No Method'
		WHEN bcm_at_end_of_visit = 'nothing' THEN 'No Method'

		--EC
		WHEN bcm_at_end_of_visit LIKE 'ec%'
			AND bcm_at_end_of_visit NOT LIKE '%condom%' THEN 'No Method'
		WHEN bcm_at_end_of_visit LIKE '%ella%'
			AND bcm_at_end_of_visit NOT LIKE '%condom%' THEN 'No Method'

		--other
		WHEN bcm_at_end_of_visit LIKE '%other%'
			AND (bcm_at_end_of_visit NOT LIKE '%IUC%'
			AND bcm_at_end_of_visit NOT LIKE '%hyster%'
			AND bcm_at_end_of_visit NOT LIKE '%preg%'
			AND bcm_at_end_of_visit NOT LIKE '%meno%'
			AND bcm_at_end_of_visit NOT LIKE '%oral%'
			AND bcm_at_end_of_visit NOT LIKE '%POP%'
			AND bcm_at_end_of_visit NOT LIKE '%condom%'
			AND bcm_at_end_of_visit NOT LIKE '%essu%'
			AND bcm_at_end_of_visit NOT LIKE '%plan%') THEN 'No Method'
		WHEN bcm_at_end_of_visit LIKE '%withdraw%'
			AND (bcm_at_end_of_visit NOT LIKE '%condom%'
			AND   bcm_at_end_of_visit NOT LIKE '%sperm%') THEN 'Other Methods'
		ELSE 'Male Condom'
	END
INTO #temp
from pp_home_
--WHERE (create_timestamp >= '20150701' AND create_timestamp <= '20160630')

update #pp_home_temp --2306649
set #pp_home_temp.bcm_at_end_of_visit = #temp.BCM
from #pp_home_temp pp
JOIN #temp ON (pp.enc_id = #temp.enc_id and pp.person_id = #temp.person_id)

update top (5454) #pp_home_temp --update 60% of IUC to Levonorgestrel
set #pp_home_temp.bcm_at_end_of_visit = 'IUC (Levonorgestrel)'
from #pp_home_temp pp
JOIN #temp ON (pp.enc_id = #temp.enc_id and pp.person_id = #temp.person_id)
WHERE bcm_at_end_of_visit = 'IUC'

update #pp_home_temp --update rest of IUC to Copper
set #pp_home_temp.bcm_at_end_of_visit = 'IUC (Copper)'
from #pp_home_temp pp
JOIN #temp ON (pp.enc_id = #temp.enc_id and pp.person_id = #temp.person_id)
WHERE bcm_at_end_of_visit = 'IUC'

---------------------------------------------------------

select distinct bcm_at_end_of_visit 
select count(*) bcm_at_end_of_visit 
from pp_home_
where bcm_at_end_of_visit IS NULL
and (create_timestamp >= '20150701' AND create_timestamp <= '20160630')


select person_id, bcm_at_end_of_visit, MAX(date)
from #pp_home_temp
WHERE (date >= '20140701' AND date <= '20150630')
GROUP BY person_id, bcm_at_end_of_visit --create_timestamp
ORDER BY person_id, bcm_at_end_of_visit

select MAX(num) 
from #temp2
WHERE bcm_at_end_of_visit IS NOT NULL
GROUP BY person_id, bcm_at_end_of_visit, date, num
order by person_id

select bcm_at_end_of_visit
from #pp_home_temp pph
INNER JOIN
	(SELECT person_id, MAX(DATE) AS MAXDATE
	 FROM #pp_home_temp
	 GROUP BY person_id) groupedt
ON pph.person_id = groupedt.person_id AND pph.date = groupedt.MAXDATE
WHERE (pph.date >= '20140701' AND pph.date <= '20150630') AND pph.bcm_at_end_of_visit IS NOT NULL
order by pph.person_id

select bcm_at_end_of_visit, create_timestamp
from pp_home_
WHERE 

create_timestamp =(SELECT MAX(create_timestamp) FROM pp_home_)
--AND (create_timestamp >= '20140701' AND create_timestamp <= '20150630')
group by bcm_at_end_of_visit, create_timestamp

select COUNT (*)bcm_at_end_of_visit 
from pp_home_ pph
JOIN PP_Config_General_List_ep_ cg ON pph.bcm_at_end_of_visit = cg.list_value
WHERE (pph.create_timestamp >= '20140701' AND pph.create_timestamp <= '20150630')
and bcm_at_end_of_visit LIKE '%male condom%'

select bcm_at_end_of_visit 
from pp_home_ pph
--JOIN PP_Config_General_List_ep_ cg ON pph.bcm_at_end_of_visit = cg.list_value
WHERE (pph.create_timestamp >= '20140701' AND pph.create_timestamp <= '20150630')
and bcm_at_end_of_visit LIKE '%ORAL%'


select COUNT(*) bcm_at_end_of_visit
from pp_home_
WHERE bcm_at_end_of_visit LIKE '%feMale Condom%'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'Oral (CHC)'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'Oral (POP)'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'Patch'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'Ring'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'Injection'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'Implant'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'IUC (Levonorgestrel)'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'IUC (Copper)'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'female sterilization'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'vasectomy'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'Partner Method'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'Abstinence'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'Female Condom'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'Cervical cap/Diaphragm'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'Sponge'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'FAM/NFP'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'Seeking Pregnancy'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'Pregnant/Partner Pregnant'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'Infertile'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'Same Sex Partner'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'Spermicide'

select COUNT(*) bcm_at_end_of_visit
from #pp_home_temp
WHERE bcm_at_end_of_visit = 'No Method'