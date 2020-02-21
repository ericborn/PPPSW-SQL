select category_id, event_timestamp, event_message 
from event_audit_mstr
where create_timestamp >= '20170419'
AND category_id = '1000'

select COUNT(*) from event_audit_mstr
where category_id = '1000'


CREATE NONCLUSTERED INDEX
[IX_event_audit_mstr_category_id_INCLUDES]
ON event_audit_mstr
([category_id])
INCLUDE ([event_timestamp], [event_message])
--WITH (ONLINE = ON);
GO

drop table STAFF_TRACKING

CREATE TABLE staff_tracking
(
 [event_message] VARCHAR(100)
,[event_timestamp] DATETIME
,[category_id] VARCHAR(4)
)

SELECT * FROM staff_tracking

DECLARE @now datetime
DECLARE @later datetime
SET @now = CONVERT (date, GETUTCDATE());
SET @later = CONVERT (date, GETUTCDATE()+1);

INSERT INTO staff_tracking ([event_message], [event_timestamp], [category_id]) 
SELECT [event_message], [event_timestamp], [category_id]
FROM [ppngaudit].ngauditprod.dbo.event_audit_mstr
WHERE create_timestamp >= @now AND create_timestamp <= @later
AND category_id = '1000' AND [event_message] != 'BBP logged off' AND [event_message] != 'logged off'
AND [event_timestamp] NOT IN (SELECT DISTINCT [event_timestamp] FROM staff_tracking)