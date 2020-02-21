getdate

select event_timestamp, um.user_id, um.first_name + ' ' + um.last_name AS 'Name'
from staff_tracking st
JOIN ngprod.dbo.user_mstr um ON  um.user_id = st.user_id
where last_name LIKE '%MA'
and delete_ind = 'n'
order by name, event_timestamp

select * from staff_tracking
select * from PT_EmployeeTracking


select * from user_mstr
where last_name LIKE '%MA'
and delete_ind = 'n'