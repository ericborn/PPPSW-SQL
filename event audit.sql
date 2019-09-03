select * from event_audit_mstr_2016_17
where event_message LIKE '%deleted encounter%'
AND event_message NOT LIKE '%deleted encounter insurance%'
order by event_timestamp

select * from event_audit_mstr_bak
where event_timestamp >= '20160701' AND event_message LIKE '%deleted encounter%'
AND event_message NOT LIKE '%deleted encounter insurance%'
order by event_timestamp


select * from event_audit_mstr_bak
where event_timestamp >= '20160701' and event_message LIKE '%merged encounter%'
order by event_timestamp