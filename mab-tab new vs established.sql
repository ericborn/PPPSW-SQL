--Mab patients by zipcode for 2016
--tab patients by zipcode for 2016
/*
Zip 
City        
County                 
State     
Country (in case we have people from Mexico)
Service (MAB/TAB)         
Service Date (so I can group by quarters)
Location
*/
select * from location_mstr
select * from cou
SELECT DISTINCT   
		 p.zip
		,p.city
		,[county]
		,p.[state]
		,p.country
		,pp.service_date
		,lm.location_name
		,p.person_id AS 'patients'
		,'TAB' AS 'Service'
--INTO #tab
from master_im_ m
join patient_procedure pp on pp.enc_id = m.enc_id
join person p on p.person_id = pp.person_id
join location_mstr lm ON pp.location_id = lm.location_id
where (service_date >= '20160101' and service_date <= '20161231')
and (pp.service_item_id = '59840A' OR pp.service_item_id LIKE '59841[C-N]%')
order by zip

select DISTINCT   
		 p.zip
		,p.city
		,[county]
		,p.[state]
		,p.country
		,pp.service_date
		,lm.location_name
		,p.person_id AS 'patients'
		,'MAB' AS 'Service'
into #mab
from master_im_ m
join patient_procedure pp on pp.enc_id = m.enc_id
join person p on p.person_id = pp.person_id
join location_mstr lm ON pp.location_id = lm.location_id
where (service_date >= '20160101' and service_date <= '20161231')
and pp.service_item_id LIKE 's0199%'

select * from #mab
union all
select * from #tab

--************Use MAB/TAB query to find patients during report period. Look back -30 days to see if they had another encounter, 
--if so use new vs established from that visit instead***************

select count(*) AS 'total mab', datepart(month, service_date) AS 'serviceDate'
from patient_procedure pp
join person p on pp.person_id = p.person_id
where service_item_id = 's0199'
group by service_date


SELECT count(*) AS 'total mab', CAST(MONTH(service_date) AS VARCHAR(2)) + '-' + CAST(YEAR(service_date) AS VARCHAR(4)) AS 'serviceDate'
from patient_procedure pp
join person p on pp.person_id = p.person_id
where service_item_id = 's0199'
group by service_date
order by service_date

select * from patient_encounter

--1 new
--2 established
select newEstablished, COUNT (distinct pp.enc_id) AS 'total'
from master_im_ m
join patient_procedure pp on pp.enc_id = m.enc_id
where (service_date >= '20160701' and service_date <= '20160931')
and pp.service_item_id = '59840A' OR pp.service_item_id LIKE '59841[C-N]%'
group by newEstablished


----------
drop table #tab
drop table #mab
drop table #m
drop table #t
drop table #new
drop table #n

--***TAB Start***
select distinct pp.enc_id, p.person_id, pp.service_date, 'service' = 'TAB',
				case
				when newEstablished = 1 then 'N'
				when newEstablished = 2 then 'E'
				end AS [n/e]
into #tab
from master_im_ m
join patient_procedure pp on pp.enc_id = m.enc_id
join patient_encounter pe on pe.enc_id = pp.enc_id
join person p on p.person_id = pp.person_id
where (service_date >= '20160101' and service_date <= '20161231')
and (pp.service_item_id = '59840A' OR pp.service_item_id LIKE '59841[C-N]%')
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')

select distinct pp.enc_id, pp.person_id, pp.service_date AS 'pp_date', t.service_date AS 't_date'
into #t
from #tab t
join patient_procedure pp on t.person_id = pp.person_id
where pp.service_date between dateadd(day, -30, t.service_date) and dateadd(day, -1, t.service_date)

select m.enc_id, newEstablished
INTO #n
from master_im_ m
join #t t on t.enc_id = m.enc_id

update #tab
set [n/e] = 'N'
where #tab.enc_id in
(
select enc_id 
from #n
where newEstablished = 1
)

update #tab
set [n/e] = 'E'
where #tab.enc_id in
(
select enc_id 
from #n
where newEstablished = 2
)

update #tab
set [n/e] = 'E'
where #tab.[n/e] is null
--***TAB End***
----------
--***MAB Start***
select distinct pp.enc_id, p.person_id, pp.service_date, 'service' = 'MAB',
				case
				when newEstablished = 1 then 'N'
				when newEstablished = 2 then 'E'
				end AS [n/e]
into #mab
from master_im_ m
join patient_procedure pp on pp.enc_id = m.enc_id
join patient_encounter pe on pe.enc_id = pp.enc_id
join person p on p.person_id = pp.person_id
where (service_date >= '20160101' and service_date <= '20161231')
and pp.service_item_id LIKE 's0199%'
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')

select distinct pp.enc_id, pp.person_id, pp.service_date AS 'pp_date', m.service_date AS 't_date'
into #m
from #mab m
join patient_procedure pp on m.person_id = pp.person_id
where pp.service_date between dateadd(day, -30, m.service_date) and dateadd(day, -1, m.service_date)

--select *, datediff(day,pp_date, t_date) AS 'diff'
--from #p
--order by [diff]

select mas.enc_id, newEstablished
INTO #new
from master_im_ mas
join #m m on m.enc_id = mas.enc_id

update #mab
set [n/e] = 'N'
where #mab.enc_id in
(
select enc_id 
from #new
where newEstablished = 1
)

update #mab
set [n/e] = 'E'
where #mab.enc_id in
(
select enc_id 
from #new
where newEstablished = 2
)

update #mab
set [n/e] = 'E'
where #mab.[n/e] is null
--***MAB End***

select [n/e], [service], service_date from #tab
UNION ALL
select [n/e], [service], service_date from #mab


--select * from patient_encounter
--where enc_id = '4D869D13-590A-447A-9F15-33415D585BB6'

--select newEstablished, create_timestamp from master_im_
--where person_id = '8B8288B8-162C-4EBE-9AE4-54F8CD402E32'

--enc_id = '4D869D13-590A-447A-9F15-33415D585BB6'