SELECT ml.mstr_list_item_desc AS '211 patient', ps.last_name, ps.first_name, pt.med_rec_nbr
FROM person ps
	JOIN patient pt ON pt.person_id = ps.person_id
	JOIN 
	JOIN person_ud ud ON ud.person_id = ps.person_id
	JOIN mstr_lists ml ON ml.mstr_list_item_id = ud.ud_demo6_id AND mstr_list_type = 'ud_demo6'
WHERE ml.mstr_list_item_desc = 'yes'
ORDER BY ml.mstr_list_item_desc


SELECT * 
FROM person_ud ud
--JOIN   mstr_lists ml on ml.mstr_list_item_id = ud.ud_demo4_id AND mstr_list_type = 'ud_demo6'
WHERE person_id = 'F908CE0C-C864-4AE3-B491-C0A7692C1211'


select * from mstr_lists
where mstr_list_type LIKE 'ud_demo%'

select * from 

mstr_list_item_desc = '211 referral'




82C713EC-3F18-4BA3-8587-7CA23F9BB299
yes

F3195071-4D99-4486-806D-276081F13F5C
no
