--opted yes to texting
--electronic consent in chart (b_HIE_Text Msg_E-mail)
--MRN

--DROP TABLE #email

CREATE TABLE #email
(
	 person_nbr INT
	,email VARCHAR(50)
	,consent_name VARCHAR(40)
	,texting VARCHAR(1)
)

INSERT INTO #email
SELECT DISTINCT person_nbr, email_address, document_desc, 'n'
FROM patient_documents pd
JOIN person p ON pd.person_id = p.person_id
WHERE document_desc like '%mail%' 

DELETE FROM #email
WHERE email IS NULL
OR email NOT LIKE '%@%'

UPDATE #email
SET texting = 'y'
WHERE #email.person_nbr IN (
select person_nbr
from person ps
	join patient pt on pt.person_id = ps.person_id
	join person_ud ud on ud.person_id = ps.person_id
	join mstr_lists ml on ml.mstr_list_item_id = ud.ud_demo5_id AND mstr_list_type = 'ud_demo5'
where mstr_list_item_desc != '1 - no'
)

SELECT * FROM #email
