SELECT c.name AS ColName, t.name AS TableName
FROM sys.columns c
    JOIN sys.tables t ON c.object_id = t.object_id
WHERE c.name LIKE '%rvu%'
order by tablename


select * 
from cpt4_rvu_mstr
where cpt4_code_id = '99211'

select * 
from cpt4_code_mstr
where cpt4_code_id = '99211'

select * --service_item_id, rvu1, rvu2, rvu3, rvu4, rvu5, rvu6, rvu7, rvu8 
from service_item_mstr
--where rvu6 = 
where delete_ind = 'n' and exp_date >= '20170101'
and service_item_id = '11982'


select distinct service_item_id, max(eff_date) [max eff date]
into #si
from service_item_mstr 
where rvu5 is not null
group by service_item_id

select distinct s.service_item_id, rvu5 
from #si s
join service_item_mstr sm on (s.service_item_id = sm.service_item_id and s.[max eff date] = sm.eff_date)