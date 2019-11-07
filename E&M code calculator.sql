
select em_code_calc, em_code_submitted 
from em_history_
where create_timestamp >= '20180101'
AND em_code_calc IS NOT NULL
AND em_code_calc != em_code_submitted

