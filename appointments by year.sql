select year(appt_date) as 'year', count(appt_id) AS 'count'
from appointments
GROUP BY year(appt_date)
order by 'year'