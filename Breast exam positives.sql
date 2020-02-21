SELECT p.person_nbr, pb.*--COUNT(distinct pe.enc_id) 
FROM patient_encounter pe
JOIN person p ON p.person_id = pe.person_id
JOIN pe_breast_ pb 
	ON pb.enc_id = pe.enc_id
--JOIN pe_breast_palp_ bp
	--ON pb.enc_id = bp.enc_id
WHERE pe.create_timestamp >= '20161001' and pe.create_timestamp <= '20170930' 
AND (pb.palpR_nl = '0' or pb.palpL_nL = '0' or pb.palpB_nl = '0') --Normal not checked
AND (pb.palponly1 IS NOT NULL OR pb.palponly2 IS NOT NULL OR pb.palponly3 IS NOT NULL OR pb.palponly4 IS NOT NULL --No abnormalities detected
OR pb.palpb1 IS NOT NULL OR pb.palpb2 IS NOT NULL)