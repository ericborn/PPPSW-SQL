SELECT appt_date, 
CASE 
	WHEN begintime BETWEEN '0000' AND '1000' THEN '1-morning'
	WHEN begintime BETWEEN '1005' AND '1300' THEN '2-late-morning'
	WHEN begintime BETWEEN '1305' AND '1500' THEN '3-Afternoon'
	WHEN begintime BETWEEN '1505' AND '2000' THEN '4-Evening'
END AS [appt time], appt_kept_ind AS [kept]
INTO #temp1
FROM appointments a
WHERE appt_date >= '20160701' AND appt_date <= '20161120'
AND (cancel_ind = 'N' AND resched_ind = 'N' AND delete_ind = 'N')
AND event_id NOT IN('C27D53D4-5126-489B-950A-D9A69A4FE474', 'F9E0AD20-6791-486F-A807-35561547817F'
				   ,'B2D41BE7-B8F4-457C-B316-535457E74AB9', '8F4A4BCE-E144-44F4-958F-10158F140C09'
				   ,'F1659B36-53A0-4CCD-B274-42D11BED8B37') --block walk-ins
ORDER BY appt_date, [appt time], [kept]

drop table #temp1

SELECT DISTINCT
 (SELECT COUNT(kept) FROM #temp1 WHERE kept = 'y' AND [appt time] = '1-morning') AS [Show Morning]
,(SELECT COUNT(kept) FROM #temp1 WHERE kept = 'n' AND [appt time] = '1-morning') AS [No Show Morning]
,(SELECT COUNT(kept) FROM #temp1 WHERE [appt time] = '1-morning') AS [Total Morning]
,(SELECT COUNT(kept) FROM #temp1 WHERE kept = 'y' AND [appt time] = '2-late-morning') AS [Show Late-Morning]
,(SELECT COUNT(kept) FROM #temp1 WHERE kept = 'n' AND [appt time] = '2-late-morning') AS [No Show Late-Morning]
,(SELECT COUNT(kept) FROM #temp1 WHERE [appt time] = '2-late-morning') AS [Total Late-Morning]
,(SELECT COUNT(kept) FROM #temp1 WHERE kept = 'y' AND [appt time] = '3-Afternoon') AS [Show Afternoon]
,(SELECT COUNT(kept) FROM #temp1 WHERE kept = 'n' AND [appt time] = '3-Afternoon') AS [No Show Afternoon]
,(SELECT COUNT(kept) FROM #temp1 WHERE [appt time] = '3-Afternoon') AS [Total Afternoon]
,(SELECT COUNT(kept) FROM #temp1 WHERE kept = 'y' AND [appt time] = '4-Evening') AS [Show Evening]
,(SELECT COUNT(kept) FROM #temp1 WHERE kept = 'n' AND [appt time] = '4-Evening') AS [No Show Evening]
,(SELECT COUNT(kept) FROM #temp1 WHERE [appt time] = '4-Evening') AS [Total Evening]
FROM #temp1

select * from #temp1
select * from appointments
select * from appt_slots
select * from appointment_members
select * from events
WHERE [event] LIKE '%walk%'
select * from categories


select * from resources
WHERE [description] LIKE '%OVERFLOW%'