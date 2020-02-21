select count (txt_current_sexual_activity) as 'Times used', txt_current_sexual_activity
from hpi_sti_screening_
group by txt_current_sexual_activity
order by [Times used] desc

select COUNT(txt_current_sexual_activity)
from hpi_sti_screening_
where txt_current_sexual_activity is not null


select COUNT(txt_current_sexual_activity)
from hpi_sti_screening_
where txt_current_sexual_activity = 'Anal insertive' --99

select distinct txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity LIKE '%none%'

--*************************************************************
UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Anal insertive'
WHERE txt_current_sexual_activity IN 
(
select txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity = ' Anal insertive' 
)

UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Anal insertive, Anal receptive, Oral insertive and Oral receptive'
WHERE txt_current_sexual_activity IN
(
select txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity = ' Anal insertive, Anal receptive, Oral insertive and Oral receptive' 
)

UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Anal insertive, Anal receptive, Oral receptive and Oral receptive'
WHERE txt_current_sexual_activity IN
(
select txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity = ' Anal insertive, Anal receptive, Oral receptive and Oral receptive' 
)

UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Anal insertive, Oral insertive and Oral receptive'
WHERE txt_current_sexual_activity IN
(
select txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity = ' Anal insertive, Oral insertive and Oral receptive' 
)

UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Anal receptive, Oral insertive and Oral receptive'
WHERE txt_current_sexual_activity IN
(
select txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity = ' Anal receptive, Oral insertive and Oral receptive' 
)

UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Never Sexually Active'
WHERE txt_current_sexual_activity IN
(
select txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity = ' Never Sexually Active' 
)

UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Oral and Anal'
WHERE txt_current_sexual_activity IN
(
select txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity = ' Oral and Anal' 
)

UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Oral and Vaginal'
WHERE txt_current_sexual_activity IN
(
select txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity = ' Oral and Vaginal' 
)

UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Oral and Vaginal and Oral'
WHERE txt_current_sexual_activity IN
(
select txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity = ' Oral and Vaginal and Oral' 
)

UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Oral insertive and Vaginal'
WHERE txt_current_sexual_activity IN
(
select txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity = ' Oral insertive and Vaginal' 
)

UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Oral receptive'
WHERE txt_current_sexual_activity IN
(
select txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity = ' Oral receptive' 
)

UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Oral receptive and Anal receptive'
WHERE txt_current_sexual_activity IN
(
select txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity = ' Oral receptive and Anal receptive' 
)

UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Vaginal'
WHERE txt_current_sexual_activity IN
(
 select txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity = ' Vaginal' 
)

UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Vaginal and Oral'
WHERE txt_current_sexual_activity IN
(
 select txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity = ' Vaginal and Oral' 
)

UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Vaginal and Oral and Anal'
WHERE txt_current_sexual_activity IN
(
 select txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity = ' Vaginal and Oral and Anal' 
)

UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Vaginal and Oral insertive'
WHERE txt_current_sexual_activity IN
(
select txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity = ' Vaginal and Oral insertive'  
)

UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Vaginal, Oral and Anal'
WHERE txt_current_sexual_activity IN
(
select txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity = ' Vaginal, Oral and Anal'   
)

UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Never Sexually Active'
WHERE txt_current_sexual_activity IN
(
select distinct txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity = 'no ic yet' 
OR txt_current_sexual_activity = 'abstinent'
OR txt_current_sexual_activity = 'none'
OR txt_current_sexual_activity = 'not sexually active'
OR txt_current_sexual_activity = 'unknown'
OR txt_current_sexual_activity = 'not currently active'
OR txt_current_sexual_activity = 'No SIC ever'
OR txt_current_sexual_activity = 'abstinance'
OR txt_current_sexual_activity = 'none - No IC yet'
OR txt_current_sexual_activity = 'none currently'
OR txt_current_sexual_activity = 'Not currently SA'
OR txt_current_sexual_activity = 'Abstaining'
OR txt_current_sexual_activity = 'abstinent x 3 yrs'
OR txt_current_sexual_activity = 'No Current Partner'
OR txt_current_sexual_activity = 'no patner x 1yr'
OR txt_current_sexual_activity = 'no IC x 4 yrs '
OR txt_current_sexual_activity = 'none x 1 + year'
OR txt_current_sexual_activity = 'abstinent/none'
OR txt_current_sexual_activity = 'not active x 2 years'
OR txt_current_sexual_activity = 'abstinent; no Hx of IC'
OR txt_current_sexual_activity = 'Abstinent x 6yrs'
OR txt_current_sexual_activity = 'abstinent- no history of IC'
OR txt_current_sexual_activity = 'absitnent'
OR txt_current_sexual_activity = 'None, no h/o IC'
OR txt_current_sexual_activity = 'abstinent/no IC yet'
OR txt_current_sexual_activity = 'abstinent since last STI testing'
OR txt_current_sexual_activity = 'abstinent since STI testing 12/2016'
OR txt_current_sexual_activity = 'Abstinent x 8yrs'
OR txt_current_sexual_activity = 'abstinent x 6 mo'
OR txt_current_sexual_activity = 'adstinence'
OR txt_current_sexual_activity = 'NO SEXUAL PATNER AT THIS TIME'
OR txt_current_sexual_activity = 'abstinent x 1.5 yrs'
OR txt_current_sexual_activity = 'abstinent x 1 mo'
OR txt_current_sexual_activity = 'DECLINES TESTING'
OR txt_current_sexual_activity = 'abstinent, no IC yet'
OR txt_current_sexual_activity = 'Not Active currently'
OR txt_current_sexual_activity = 'none- abstinent'
OR txt_current_sexual_activity = 'no sexually active'
OR txt_current_sexual_activity = 'none (no IC yet)'
OR txt_current_sexual_activity = 'no IC in 5 months'
OR txt_current_sexual_activity LIKE '%not%'
OR txt_current_sexual_activity LIKE '%absti%'
OR txt_current_sexual_activity LIKE '%none%'
)

UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Vaginal'
WHERE txt_current_sexual_activity IN
(
select txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity = 'Vaginal,' 
)

UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Vaginal, oral'
WHERE txt_current_sexual_activity IN
(
select txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity = 'Vaginal, oral,' 
)

UPDATE hpi_sti_screening_
SET txt_current_sexual_activity = 'Never Sexually Active'
WHERE txt_current_sexual_activity IN
(
select txt_current_sexual_activity
from hpi_sti_screening_
where txt_current_sexual_activity LIKE '%never%' AND 
txt_current_sexual_activity != 'Never Sexually Active'
)

select DISTINCT txt_current_sexual_activity, COUNT(txt_current_sexual_activity) AS 'count'
from hpi_sti_screening_
group by txt_current_sexual_activity
order by [count] desc