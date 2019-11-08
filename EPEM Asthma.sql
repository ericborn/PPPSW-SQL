select * -- distinct txt_dxsx_name_tmp
from histories_master_
where disease LIKE '%ASTHMA%'

select * from person

select DISTINCT last_name, person_nbr,
'age' = CAST((CONVERT(INT,CONVERT(CHAR(8),'20170720',112))-CONVERT(CHAR(8),p.date_of_birth,112))/10000 AS varchar),
disease
from patient_procedure pp
JOIN person p ON p.person_id = pp.person_id
JOIN histories_master_ hm ON pp.person_id = hm.person_id
where
(diagnosis_code_id_1 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_2 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_3 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_4 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00'))
AND disease LIKE '%ASTHMA%'



select last_name, person_nbr,
'age' = CAST((CONVERT(INT,CONVERT(CHAR(8),'20170720',112))-CONVERT(CHAR(8),p.date_of_birth,112))/10000 AS varchar),
disease
from patient_procedure pp
JOIN person p ON p.person_id = pp.person_id
JOIN histories_master_ hm ON pp.person_id = hm.person_id
where
(diagnosis_code_id_1 IN ('O00.9', 'O00.90', 'O08.89', '631.8', '633.90', '633', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0'
,'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00', '640.03')
OR diagnosis_code_id_2 IN ('O00.9', 'O00.90', 'O08.89', '631.8', '633.90', '633', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0'
,'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00', '640.03')
OR diagnosis_code_id_3 IN ('O00.9', 'O00.90', 'O08.89', '631.8', '633.90', '633', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0'
,'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00', '640.03')
OR diagnosis_code_id_4 IN ('O00.9', 'O00.90', 'O08.89', '631.8', '633.90', '633', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0'
,'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00', '640.03'))
AND disease LIKE '%ASTHMA%'
order by last_name

--1709
--72