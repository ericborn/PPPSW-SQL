select appt_date --count(a.event_id) as 'count', event--, count(*) as 'total'
from appointments a
JOIN events e ON e.event_id = a.event_id
where appt_date = '20170718' AND cancel_ind = 'y' AND a.delete_ind = 'n' AND resched_ind = 'n'
--AND enc_id is not null
group by event
order by event

drop table #t

select CONVERT(VARCHAR, CONVERT(CHAR(8), appt_date, 112) 
  + ' ' + CONVERT(CHAR(8), begintime, 108)) AS 'appt_time',
--datediff(hour, combined = appt_date + begintime, a.modify_timestamp) AS 'diff,'
a.modify_timestamp, a.modified_by--, appt_nbr --count(*) as 'count'--, event--, count(*) as 'total'
INTO #t
from appointments a
JOIN events e ON e.event_id = a.event_id
where appt_date = '20170718' AND a.delete_ind = 'n' AND resched_ind = 'n'
AND a.event_id != '6257266B-ECD8-40FC-9BBB-0BEFFBE64840'


select datediff(hour, appt_time, modify_timestamp) AS 'diff,'
from #t


--drop table #a
--select * from #a

SELECT location_name, e.event, a.appt_date, scheduled = appt_date + begintime
,REPLACE(REPLACE(REPLACE(CONVERT(varchar(16), a.modify_timestamp, 120), '-', ''),':',''),' ','') AS 'modified'
,a.cancel_ind,
CASE 
			WHEN DATEPART(dw, appt_date) = (2) THEN 'Monday'
			WHEN DATEPART(dw, appt_date) = (3) THEN 'Tuesday'
			WHEN DATEPART(dw, appt_date) = (4) THEN 'Wednesday'
			WHEN DATEPART(dw, appt_date) = (5) THEN 'Thursday'
			WHEN DATEPART(dw, appt_date) = (6) THEN 'Friday'
			WHEN DATEPART(dw, appt_date) = (7) THEN 'Saturday'
		 END AS 'Day number'
,CASE
WHEN enc_id is not null THEN 1
ELSE 0
END AS 'show'
INTO #a
FROM appointments a
JOIN events e ON e.event_id = a.event_id
JOIN location_mstr lm ON lm.location_id = a.location_id
where (a.appt_date >= '20170529' AND a.appt_date <= '20170701') AND a.delete_ind = 'n' AND resched_ind = 'n'
AND a.event_id != '6257266B-ECD8-40FC-9BBB-0BEFFBE64840'

--drop table #c
select location_name, event, appt_date, scheduled, modified
,CONVERT(FLOAT, REPLACE(scheduled, CHAR(0), '')) - CONVERT(FLOAT, REPLACE(modified, CHAR(0), '')) as 'diff'
,cancel_ind, [Day number], [show]
INTO #c
from #a

drop table #c
select * from #c


select *-- count(diff)
from #c
where diff > 100

select * from events
WHERE delete_ind = 'n'



--select CONVERT(VARCHAR, CONVERT(CHAR(8), appt_date, 112) 
--  + ' ' + CONVERT(CHAR(8), begintime, 108)) AS 'appt_time',
--datediff(hour, combined = appt_date + begintime, a.modify_timestamp) AS 'diff,'
a.modify_timestamp, a.modified_by--, appt_nbr --count(*) as 'count'--, event--, count(*) as 'total'
select COUNT(*)
--INTO #t
from appointments a
JOIN events e ON e.event_id = a.event_id
where (a.appt_date >= '20170529' AND a.appt_date <= '20170701') and resched_ind = 'Y'
AND a.event_id != '6257266B-ECD8-40FC-9BBB-0BEFFBE64840'