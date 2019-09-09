select distinct pp.person_id
into #ab
from patient_procedure pp
join location_mstr lm on pp.location_id = lm.location_id
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN person	p			 ON pp.person_id = p.person_id
where (pp.service_date >= '20160101' AND pp.service_date <= '20161231')
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.location_id IN ('E53D4FEC-7778-4093-9C45-DC526C9CC8D3', --rsss
					   'C1CAF54E-57B5-4A9F-84E7-554A8EF4EADB') --rshc
AND (PP.service_item_id LIKE '%59840A%' --TAB
OR  pp.service_item_id LIKE '%59841[C-N]%' --TAB
OR  pp.service_item_id LIKE '%S0199%' --MAB
OR  pp.service_item_id LIKE '%S0199A%') --MAB


select distinct pp.person_id
into #fp
from patient_procedure pp
join location_mstr lm on pp.location_id = lm.location_id
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN person	p			 ON pp.person_id = p.person_id
--JOIN #ab a ON a.enc_id = pp.enc_id
where (pp.service_date >= '20160101' AND pp.service_date <= '20161231')
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.location_id IN ('E53D4FEC-7778-4093-9C45-DC526C9CC8D3', --rsss
					   'C1CAF54E-57B5-4A9F-84E7-554A8EF4EADB') --rshc
AND pp.person_id NOT IN (select person_id from #ab)


select COUNT(distinct pp.person_id)
from patient_procedure pp
join location_mstr lm on pp.location_id = lm.location_id
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN person	p			 ON pp.person_id = p.person_id
where (pp.service_date >= '20160101' AND pp.service_date <= '20161231')
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.location_id IN ('E53D4FEC-7778-4093-9C45-DC526C9CC8D3', --rsss
					   'C1CAF54E-57B5-4A9F-84E7-554A8EF4EADB') --rshc
--encounters
--27635 total
--3257 ab
--24378 fp

--patients
--14565 total
--3114 ab
--11451 fp

select count(distinct person_id)
from #fp

select distinct
	CASE
		WHEN PP.service_item_id = 'S0199A' THEN 'MAB'
		WHEN PP.service_item_id = 'S0199' THEN 'MAB'
		WHEN PP.service_item_id = '59840A' THEN '1st Tri'
		WHEN PP.service_item_id LIKE '59841[C-N]%' THEN '2nd Tri'
	END AS [procedure]
	,COUNT(distinct pp.enc_id) AS [count], location_name
into #ab
from patient_procedure pp
join location_mstr lm on pp.location_id = lm.location_id
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN person	p			 ON pp.person_id = p.person_id
where (pp.service_date >= '20160101' AND pp.service_date <= '20161231')
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND (PP.service_item_id LIKE '%59840A%' --TAB
OR  pp.service_item_id LIKE '%59841[C-N]%' --TAB
OR  pp.service_item_id LIKE '%S0199%' --MAB
OR  pp.service_item_id LIKE '%S0199A%') --MAB
group by location_name, service_item_id--, 'procedure'
order by location_name

select * from #ab
group by [procedure], [count], location_name
order by location_name

select distinct location_name
from #ab
order by location_name
