--Gary wants to know the number of abortion appointment slots available for the last year (by month and appt type)... 

DECLARE @StartDate datetime
DECLARE @EndDate Datetime

SET @StartDate = '20170101'
SET @EndDate = '20170930'

SELECT location_name, category, DATEPART(mm, asa.start_date) AS 'month', COUNT(*) AS 'count'
FROM [appt_slots_archive] asa
JOIN [ngsqldata].NGProd.dbo.location_mstr l on l.location_id = asa.location_id
JOIN [ngsqldata].NGProd.dbo.categories c	on c.category_id = asa.category_id
WHERE asa.start_date between @StartDate and @EndDate
AND category IN ('LAM1','LAM2','MAB Procedure','TAB','TAB-APC','TAB-OR')
GROUP BY l.location_name, c.category,DATEPART( mm, asa.start_date)
ORDER BY  l.location_name, c.category,DATEPART( mm, asa.start_date)