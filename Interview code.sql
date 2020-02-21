SELECT DISTINCT pp.person_id, service_date
INTO #a
FROM patient_procedure pp
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
WHERE (service_date BETWEEN '20170101' AND '20170331')
AND billable_ind = 'y' AND clinical_ind = 'y'
AND  service_item_id IN ('J7297', 'J7298' ,'J7300' ,'J7301' ,'J7302', 'J7307')
ORDER BY service_date DESC

CREATE TABLE #t
(
 person_nbr VARCHAR(50)
,name VARCHAR(50)
,date_of_birth DATE
,age INT
,service_date DATE
)

INSERT INTO #t
SELECT person_nbr, first_name + ' ' + last_name, date_of_birth, NULL, NULL
FROM person p
JOIN #a a ON a.person_id = p.person_id

UPDATE #t
SET #t.service_date = MAXDATE
FROM patient_procedure pp
JOIN person p ON p.person_id = pp.person_id
INNER JOIN
	(SELECT person_id, MAX(service_date) AS MAXDATE
	 FROM patient_procedure
	 GROUP BY person_id) grouped
ON pp.person_id = grouped.person_id AND pp.service_date = grouped.MAXDATE 
WHERE p.person_nbr = #T.person_nbr

UPDATE #t
SET age = CAST((CONVERT(INT,CONVERT(CHAR(8),GETDATE(),112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar)

DELETE FROM #t
WHERE age <= 9 OR age >= 51

select * 
from #t
ORDER BY age, service_date


SELECT COUNT(race) AS 'count', race FROM person GROUP BY race

select CASE_Column, COUNT(CASE_Column) as 'count'
FROM(
		select CASE
			WHEN CAST((CONVERT(INT,CONVERT(CHAR(8),GETDATE(),112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar) BETWEEN 0  AND 17 THEN '>18'
			WHEN CAST((CONVERT(INT,CONVERT(CHAR(8),GETDATE(),112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar) BETWEEN 18 AND 24 THEN '18-24'
			WHEN CAST((CONVERT(INT,CONVERT(CHAR(8),GETDATE(),112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar) BETWEEN 25 AND 29 THEN '25-29'
			WHEN CAST((CONVERT(INT,CONVERT(CHAR(8),GETDATE(),112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar) BETWEEN 30 AND 34 THEN '30-34'
			WHEN CAST((CONVERT(INT,CONVERT(CHAR(8),GETDATE(),112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar) BETWEEN 35 AND 49 THEN '35-49'
			ELSE '<50'
		END AS 'CASE_Column'
FROM person
) a
GROUP BY CASE_Column

select sex, COUNT(sex) 
from person
group by sex
