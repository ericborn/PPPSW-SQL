select distinct SUBSTRING(p.med_rec_nbr, PATINDEX('%[^0]%', p.med_rec_nbr+'.'), LEN(p.med_rec_nbr)) AS "MRN",
enc_nbr, pe.create_timestamp AS 'DOS'
from patient_encounter pe
join patient_documents pd on pd.enc_id = pe.enc_id
join patient p ON p.person_id = pe.person_id
where pe.create_timestamp >= '20160101' AND pe.create_timestamp <= '20171231'
AND pd.document_desc LIKE '%text msg%'
order by enc_nbr