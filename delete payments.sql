--select first_name + ' ' + last_name AS [Name], sig_msg, post_mod, se.create_timestamp
--from sig_events se
--JOIN user_mstr um ON se.created_by = um.user_id
--where se.create_timestamp >= '20170701' and se.create_timestamp <= '20170930'
--and sig_msg LIKE 'Unposted Transaction Deleted%'

--DROP TABLE #a
SELECT um.user_id, CONCAT(first_name, ' ', last_name) AS Name
,DATEPART(month,se.create_timestamp) AS 'Month'
INTO #a
FROM sig_events se
JOIN user_mstr um ON se.created_by = um.user_id
WHERE se.create_timestamp >= '20170101' AND se.create_timestamp <= '20171231'
AND sig_msg LIKE 'Unposted Transaction Deleted%'

SELECT [name], [Month], COUNT(user_id) AS 'count'
FROM #a
GROUP BY [name], [Month]
ORDER BY [name], [Month]