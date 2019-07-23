select enrollment_status,enrolled_when,ngweb_enrollments.create_timestamp,
create_user.first_name,create_user.last_name 
from ngweb_enrollments
join user_mstr create_user on create_user.user_id = ngweb_enrollments.created_by
order by enrollment_status, last_name

SELECT COUNT(DISTINCT pe.person_id) --pe.person_id
FROM patient_encounter pe
--JOIN ngweb_enrollments n ON n.person_id = pe.person_id
WHERE (pe.create_timestamp >= '20160101' AND pe.create_timestamp <= '20161231')
--AND enrollment_status = 3

select * from ngweb_enrollments

SELECT COUNT(DISTINCT pe.person_id) --pe.person_id
FROM patient_encounter pe
--JOIN ngweb_enrollments n ON n.person_id = pe.person_id
WHERE (pe.create_timestamp >= '20161101' AND pe.create_timestamp <= '20170131')
AND enrollment_status = 1

8-01-2016 - 10-30-2016
--8897 tokens issued
--3230 enrolled
--5667 pending

--51530 Total unique patients seen
--19292 patients with a pending token
--15523 enrolled patients

10-31-2016 - 01-31-2017
--10792 tokens issued
--4325 enrolled
--6467 pending

--53081 Total unique patients seen
--19326 patients with a pending token
--16931 enrolled patients

1 = pending
3 = enrolled