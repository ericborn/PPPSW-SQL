DECLARE @Start_Date datetime
DECLARE @End_Date datetime

--SET @Start_Date = '20170901'
--SET @End_Date = '20171130'

--First day of previous month
SET @Start_Date = DATEADD(mm, DATEDIFF(mm, 0, GETDATE()) - 1, 0) 

--Last day of previous month, time calculate based on current time
SET @End_Date = DATEADD(DAY, -(DAY(GETDATE())), GETDATE()) 

INSERT INTO event_audit_search
SELECT 
 adt.event_timestamp
,adt.created_by
,event_message
,adt.Event_id
FROM ppngaudit.ngauditprod.dbo.event_audit_mstr adt --dbo.event_audit_mstr_2016_17 adt
       where (adt.event_timestamp >= @Start_Date and adt.event_timestamp <= @End_Date)
              AND adt.category_id = 2000
              AND adt.action_id = 2003
              AND adt.event_message not like ('%(MRN)%')
              AND adt.event_message not like ('%(SSN)%')
              AND adt.event_message not like ('%(DOB)%')
              AND adt.event_message not like ('%(Policy Nbr)%')
              AND adt.event_message not like ('%(Enc Nbr)%')
			  AND adt.event_message not like ('%4%')
			  AND adt.event_message not like ('%3%')
			  AND adt.event_message not like ('%Test%')
			  AND adt.event_message not like ('%Person Nbr%')