--trans detail
SELECT SUM(allowed_amt) AS 'allowed', SUM(adj_amt) AS 'adjusted'
INTO #a
FROM patient_procedure pp
JOIN trans_detail td ON pp.enc_id = td.source_id
WHERE service_date >= '20170213' AND service_date <= '20170213'

SELECT SUM(allowed - adjusted) AS [total]
FROM #a

--charges
SELECT SUM(billed_amt) AS 'amount'--, SUM(adj_amt) AS 'adjusted'
--INTO #a
FROM patient_procedure pp
JOIN service_item_mstr sim ON  sim.service_item_id = pp.service_item_id
JOIN mstr_lists ml ON ml.mstr_list_item_id = sim.department
JOIN transactions t ON pp.enc_id = t.source_id
--JOIN charges c ON pp.enc_id = c.source_id
WHERE (service_date >= '20170213' AND service_date <= '20170213') 
AND department IN 
('7F2053E8-4A50-44D7-9800-29E1C9C96277'
,'C000C08F-6EB8-4EA2-9401-1654C57FDDD1'
,'96BE0A26-EF5C-4454-973B-5E61BDD302E8'
,'A3E26695-50D6-4ABD-934C-60BD4A8A129F'
,'67DA338D-B6ED-4DE4-A52B-DEAB0861A56A'
,'22A44407-C19E-4286-9D18-567C8651B8C8'
,'D96B57E5-B939-4DC4-BE52-656AC3285113'
,'8F999686-5A25-4464-8FAD-5A29EC49D64D'
,'249142A7-09E5-44D2-A4D4-783CC0C78649')

select * from trans_detail
select * from transactions

SELECT SUM(allowed - adjusted) AS [total]
FROM #a


select *--distinct mstr_list_item_desc
from mstr_lists ml
join service_item_mstr sim on ml.mstr_list_item_id=sim.department
where mstr_list_type='department'
--and mstr_list_item_desc like '%visit%'
and ml.delete_ind<>'Y'
Order by 1




select * 
from charges
where source_id = 'FC705FA6-8FE3-47AB-9AC0-0D19C5B59CBC'


SELECT * 
FROM transactions
WHERE (tran_date >= '20170213' AND tran_date <= '20170213')

select * from service_item_mstr


SELECT *
FROM charges c
JOIN trans_detail td ON c.charge_id = td.charge_id
where c.charge_id = 'A85B8A7E-48C2-4066-966A-D774B3862A90'

05F282DF-AEA8-4AEB-A427-C815D1AD67CE

service_item_id
Z6410

select * from mstr_lists 
where mstr_list_type = 'department'

SELECT * 
FROM transactions

SELECT * 
FROM trans_detail c
--JOIN trans_detail td ON c.charge_id = td.charge_id
where c.charge_id = 'A85B8A7E-48C2-4066-966A-D774B3862A90'

select * from patient_procedure

SELECT td.allowed_amt, td.paid_amt, td.adj_amt
FROM patient_procedure pp
JOIN trans_detail td ON pp.enc_id = td.source_id
WHERE service_date >= '20170213' AND service_date <= '20170213'

select *--distinct mstr_list_item_desc
from mstr_lists ml
join service_item_mstr sim on ml.mstr_list_item_id=sim.department
where mstr_list_type='department'
--and mstr_list_item_desc like '%visit%'
and ml.delete_ind<>'Y'
Order by 1

--6076
select DISTINCT pp.service_date, pe.enc_nbr, pp.service_item_id, t.tran_amt, t.billed_amt, t.approved_amt, td.allowed_amt, td.paid_amt, td.adj_amt, c.cob1_amt, c.amt
from patient_encounter pe
       --join location_mstr lm on pe.location_id=lm.location_id
       --join provider_mstr pm on pe.rendering_provider_id=pm.provider_id
       join patient_procedure pp on pe.enc_id=pp.enc_id
       join service_item_mstr sim on pp.cpt4_code_id=sim.cpt4_code_id
       join mstr_lists ml on sim.department=ml.mstr_list_item_id
	   JOIN transactions t ON pp.enc_id = t.source_id
	   JOIN trans_detail td ON pp.enc_id = td.source_id
	   --JOIN charges c ON pp.enc_id = c.source_id
where (service_date >= '20170213' AND service_date <= '20170213') 
AND department IN 
('7F2053E8-4A50-44D7-9800-29E1C9C96277'
,'C000C08F-6EB8-4EA2-9401-1654C57FDDD1'
,'96BE0A26-EF5C-4454-973B-5E61BDD302E8'
,'A3E26695-50D6-4ABD-934C-60BD4A8A129F'
,'67DA338D-B6ED-4DE4-A52B-DEAB0861A56A'
,'22A44407-C19E-4286-9D18-567C8651B8C8'
,'D96B57E5-B939-4DC4-BE52-656AC3285113'
,'8F999686-5A25-4464-8FAD-5A29EC49D64D'
,'249142A7-09E5-44D2-A4D4-783CC0C78649')
order by pe.enc_nbr
