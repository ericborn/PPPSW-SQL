DECLARE @now datetime
DECLARE @later datetime
SET @now = CONVERT (date, GETUTCDATE());
SET @later = CONVERT (date, GETUTCDATE()+1);

SELECT login_id 
,MIN(st.event_timestamp)First_Logon
,MAX(st.event_timestamp)Last_Logon
FROM staff_tracking st
JOIN [NGProd].[dbo].[user_mstr] u ON u.user_id = st.user_id
WHERE event_timestamp >= @now AND event_timestamp <= @later
AND event_message LIKE '%logged on'
GROUP BY login_id
ORDER BY login_id

SELECT RIGHT([Clinic], LEN([Clinic]) - 3) AS [Clinc]
,[Name]
,[Title]
,MIN(st.event_timestamp)First_Logon
,MAX(st.event_timestamp)Last_Logon
FROM staff_tracking st
JOIN [NGProd].[dbo].[user_mstr] u ON u.user_id = st.user_id
JOIN PT_EmployeeTracking pt ON u.login_id = pt.userloginID 
WHERE event_timestamp >= @now AND event_timestamp <= @later
AND event_message LIKE '%logged on'
group by clinic, name, title

SELECT RIGHT([Clinic], LEN([Clinic]) - 3) AS [Clinc],
[Name],[Title],
CONVERT(VARCHAR(19),event_timestamp,110)Date_LogOn,
MIN(event_timestamp)First_Logon,
MAX(event_timestamp)Last_Logon,
LEFT(CAST(MAX(DATEADD(HOUR,-7,event_timestamp)) - MIN(DATEADD(HOUR,-7,event_timestamp))AS TIME),5)[Shift]
,CASE 
	WHEN DATEDIFF(minute,MIN(event_timestamp), MAx(event_timestamp)) > 510 THEN 'Y' 
	ELSE 'N' 
END    [Overtime]
FROM [ppreporting].[dbo].[PT_EmployeeTracking] E
INNER JOIN [NGProd].[dbo].[user_mstr] U ON U.login_id = E.userloginID  
INNER JOIN [ppreporting].[dbo].[staff_tracking] st ON st.user_id  =U.user_id 
WHERE E.userloginID is not null
GROUP BY [Clinic],[Name],[Title],CONVERT(VARCHAR(19),event_timestamp,110)
ORDER BY CONVERT(VARCHAR(19),event_timestamp,110) DESC,Clinic,name

select * from pt_employeetracking
select * from staff_tracking
select * from [NGProd].[dbo].[user_mstr]



DECLARE @now datetime
DECLARE @later datetime
SET @now = CONVERT (date, GETUTCDATE());
SET @later = CONVERT (date, GETUTCDATE()+1);

UPDATE pt_employeetracking
SET FirstLogin = i.First_Logon,
	LastLogin = i.Last_Logon
FROM (
SELECT login_id 
,MIN(st.event_timestamp)First_Logon
,MAX(st.event_timestamp)Last_Logon
FROM staff_tracking st
JOIN [NGProd].[dbo].[user_mstr] u ON u.user_id = st.user_id
WHERE event_timestamp >= @now AND event_timestamp <= @later
AND event_message LIKE '%logged on'
GROUP BY login_id) i
WHERE i.login_id = pt_employeetracking.userloginid


select login_id,  UserLoginID
from [NGProd].[dbo].[user_mstr] um
JOIN pt_employeetracking pt ON pt.UserLoginID = um.login_id