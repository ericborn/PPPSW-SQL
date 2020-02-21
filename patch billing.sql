DROP TABLE pat_amt_break

CREATE TABLE pat_amt_break
(
 [time] DATETIME
,person_nbr VARCHAR(50)
,[service_date] DATE
,pp_service_item_id VARCHAR(50)
,c_service_item_id VARCHAR(50)
,cob1_amt VARCHAR(50)
,pat_amt VARCHAR(50)
)

INSERT INTO pat_amt_break
select distinct GETDATE(), p.person_nbr, pp.service_date, pp.service_item_id, c.service_item_id, c.cob1_amt, pat_amt
from patient_procedure pp
left join payer_mstr pm on pm.payer_id = pp.payer_id
join person p on p.person_id = pp.person_id
join charges c on pp.enc_id = c.source_id
where PP.service_date >= '20180102' AND PP.service_date <= '20180106' 
AND pp.service_item_id = 'J7304'
AND c.service_item_id = 'J7304'
--order by service_date

select *  
from pat_amt_break
--where time >= '20171225 10:05:00' AND time < '20171225 10:30:00'
order by person_nbr, time



INSERT INTO pat_amt_break

Select GETDATE(), person_nbr, pp.service_item_id, c.cob1_amt, pat_amt

from charges c

join patient_procedure pp on pp.enc_id = c.source_id

join payer_mstr pm on pm.payer_id = pp.payer_id

JOIN person p ON p.person_id = pp.person_id

where PP.service_date = '20171221'

AND pp.service_item_id = 'J7304' 
AND pp.payer_id IS NOT NULL

AND c.service_item_id = 'J7304'