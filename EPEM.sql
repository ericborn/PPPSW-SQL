SELECT DISTINCT p.person_nbr, enc_id, location_name, service_date
,diagnosis_code_id_1, diagnosis_code_id_2, diagnosis_code_id_3, diagnosis_code_id_4
FROM #temp1 t
JOIN person p on p.person_id = t.person_id
JOIN location_mstr lm on lm.location_id = t.location_id
WHERE
  (diagnosis_code_id_1 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_2 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_3 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_4 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00'))
AND (service_item_id LIKE '%59840A%')

SELECT DISTINCT p.person_nbr, enc_id, location_name, service_date
,diagnosis_code_id_1
FROM #temp1 t
JOIN person p on p.person_id = t.person_id
JOIN location_mstr lm on lm.location_id = t.location_id
WHERE
  (diagnosis_code_id_1 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_2 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_3 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_4 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00'))
AND (service_item_id LIKE '%59841[C-N]%')

SELECT DISTINCT p.person_nbr, enc_id, location_name, service_date
,diagnosis_code_id_1, diagnosis_code_id_2, diagnosis_code_id_3, diagnosis_code_id_4
FROM #temp1 t
JOIN person p on p.person_id = t.person_id
JOIN location_mstr lm on lm.location_id = t.location_id
WHERE
  (diagnosis_code_id_1 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_2 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_3 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_4 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00'))
AND (service_item_id LIKE '%S0199%')

SELECT DISTINCT p.person_nbr, enc_id, location_name, service_date
,diagnosis_code_id_1, diagnosis_code_id_2, diagnosis_code_id_3, diagnosis_code_id_4
FROM #temp1 t
JOIN person p on p.person_id = t.person_id
JOIN location_mstr lm on lm.location_id = t.location_id
WHERE
  (diagnosis_code_id_1 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_2 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_3 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00')
OR diagnosis_code_id_4 IN ('O00.9', 'O02.0', 'O02.1', 'O03.9', 'O03.94', 'O20.0', 'O36.80X', 'Z32.01', 'Z32.00', 'Z3A.00'))
AND (service_item_id NOT LIKE '%59840A%' AND service_item_id NOT LIKE '%59841[C-N]%' AND service_item_id NOT LIKE '%S0199%')