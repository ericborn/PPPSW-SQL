select DISTINCT enc_nbr, pp.provider_id, pp.service_date
from patient_procedure pp
JOIN patient_encounter pe on pp.enc_id = pe.enc_id
where pp.service_date >= 20170101 AND pp.service_date <= 20180201
and diagnosis_code_id_1 IN
(
'250','250.0','250.00','250.01','250.02','250.03','250.1','250.2','250.3','250.7','250.8','250.9'
,'253.5','357.2','362.0','362.01','366.41','588.1','648.0','648.00','648.01','648.02','648.03'
,'648.04','775.0','775.1','E10.65','E10.9','E11.65','E11.9','V18.0','V77.1'
)
OR diagnosis_code_id_2 IN
(
'250','250.0','250.00','250.01','250.02','250.03','250.1','250.2','250.3','250.7','250.8','250.9'
,'253.5','357.2','362.0','362.01','366.41','588.1','648.0','648.00','648.01','648.02','648.03'
,'648.04','775.0','775.1','E10.65','E10.9','E11.65','E11.9','V18.0','V77.1'
)
OR diagnosis_code_id_3 IN
(
'250','250.0','250.00','250.01','250.02','250.03','250.1','250.2','250.3','250.7','250.8','250.9'
,'253.5','357.2','362.0','362.01','366.41','588.1','648.0','648.00','648.01','648.02','648.03'
,'648.04','775.0','775.1','E10.65','E10.9','E11.65','E11.9','V18.0','V77.1'
)
OR diagnosis_code_id_4 IN
(
'250','250.0','250.00','250.01','250.02','250.03','250.1','250.2','250.3','250.7','250.8','250.9'
,'253.5','357.2','362.0','362.01','366.41','588.1','648.0','648.00','648.01','648.02','648.03'
,'648.04','775.0','775.1','E10.65','E10.9','E11.65','E11.9','V18.0','V77.1'
)
order by service_date


select DISTINCT diagnosis_code_id
from diagnosis_code_mstr
where description LIKE '%diabe%'


select * from provider_mstr
where provider_id IN
(
'40516DF0-B514-4A7A-B209-25CBDCA2A74D'
,'92A014B1-B393-4794-A0DA-34740521AE0E'
,'0C89FF71-0E33-4A4F-9E9F-3186A67EC1BF'
,'92A014B1-B393-4794-A0DA-34740521AE0E'
,'9679D0CD-3F21-4E8F-9437-2361E95A2DE5'
,'1AD79063-D1C8-4BAA-B45C-664C70AB3653'
,'0C89FF71-0E33-4A4F-9E9F-3186A67EC1BF'
,'92A014B1-B393-4794-A0DA-34740521AE0E'
,'BEFF73F3-AB03-44EC-BA16-BF78361A8DF7'
)

select * from provider_mstr
where provider_id IN
(
'92A014B1-B393-4794-A0DA-34740521AE0E'
,'69A27D9A-B6DD-45DD-83ED-2B4EA44F4B3B'
,'B1750643-B92D-436B-B1D2-73DDA536D3B5'
)




SELECT * --distinct request_type
FROM ngprod.dbo.erx_message_history H 
JOIN ngprod.dbo.patient_medication PM ON H.person_id = PM.person_id AND H.medication_id = PM.uniq_id AND h.provider_id = PM.provider_id --158274
WHERE h.create_timestamp >= '20170101'
AND medication_name LIKE 'Metfor%'

