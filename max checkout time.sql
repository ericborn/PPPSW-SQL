select * from appointments


declare @date date
set @date = getdate()
select @date

select MAX(checkout_datetime) AS 'last_checkout', lm.location_name
from patient_encounter pe
JOIN location_mstr lm ON lm.location_id = pe.location_id
GROUP BY location_name

drop table #a

CREATE TABLE #a
(
[date] date,
[checkout] datetime,
[location_name] VARCHAR(MAX)
)


INSERT INTO #a
SELECT DISTINCT 
CAST(CONVERT(DATETIME,pe.create_timestamp, 101) AS DATE), MAX(checkout_datetime), lm.location_name
from patient_encounter pe
JOIN location_mstr lm ON lm.location_id = pe.location_id
where pe.create_timestamp >= '20170601' AND pe.create_timestamp <= '20170630'
GROUP BY location_name, pe.create_timestamp


select * from #a
order by [date], location_name