select * 
from pe_gu_male_ pe
JOIN person p on pe.person_id = p.person_id
where pe.create_timestamp >= '20151001' AND pe.create_timestamp <= '20160930'
AND p.sex != 'f'
AND
(CVA_Tenderness IS NOT NULL OR details IS NOT NULL OR Flank_Mass IS NOT NULL OR	inguinal IS NOT NULL OR	inguinal1 IS NOT NULL OR
inguinal2 IS NOT NULL OR	lymph IS NOT NULL OR	lymph1 IS NOT NULL OR	lymph2 IS NOT NULL OR	penis IS NOT NULL OR
penis1 IS NOT NULL OR	penis2 IS NOT NULL OR	scrotum IS NOT NULL OR	scrotum1 IS NOT NULL OR	scrotum2 IS NOT NULL OR	suprapubic_tndr 
IS NOT NULL OR	teste1 IS NOT NULL OR	teste2 IS NOT NULL OR	testes IS NOT NULL OR	urethra IS NOT NULL OR	urethra1 IS NOT NULL OR	
urethra2 IS NOT NULL OR	testesMassLoc1 IS NOT NULL OR	testesMassLoc2 IS NOT NULL OR	testesMassTexture1 IS NOT NULL OR	testesMassTexture2
 IS NOT NULL OR	rb_circumcised IS NOT NULL OR	bladder IS NOT NULL OR	bladder1 IS NOT NULL OR	bladder2 IS NOT NULL OR	chk_epididymides IS NOT NULL OR
 	hernia IS NOT NULL OR	txt_epididymides1 IS NOT NULL OR	txt_epididymides2 IS NOT NULL OR	txt_testes_lsize IS NOT NULL OR
txt_testes_rsize IS NOT NULL OR	cva_tenderness_side IS NOT NULL OR	Flank_Mass_side IS NOT NULL OR	opt_friable IS NOT NULL OR	txt_appearance
 IS NOT NULL OR	txt_color IS NOT NULL OR	txt_location IS NOT NULL OR	txt_mass_size IS NOT NULL OR	txt_mass_size_cm IS NOT NULL OR
txt_position IS NOT NULL OR	txt_shape IS NOT NULL OR	txt_tenderness IS NOT NULL OR	atxt_details_hernia IS NOT NULL OR	atxt_lesion_mass IS NOT NULL OR
atxt_penis_dtl IS NOT NULL OR	chk_adhesions IS NOT NULL OR	chk_bands IS NOT NULL OR	chk_concealed_penis IS NOT NULL OR
chk_dorsal_hood IS NOT NULL OR	chk_fistula IS NOT NULL OR	chk_hypospadia IS NOT NULL OR	chk_inc_fusion_of_fores	 IS NOT NULL OR chk_inclusion_cyst
 IS NOT NULL OR chk_incomplete_circ IS NOT NULL OR	chk_mass IS NOT NULL OR	chk_penile_torsion IS NOT NULL OR	chk_phallic_length IS NOT NULL OR
chk_phimosis_meatus_not_seen IS NOT NULL OR	chk_phimosis_retractable IS NOT NULL OR	CHK_physiological_phimosis IS NOT NULL OR
chk_prom_suprapubic_fat_pad IS NOT NULL OR	chk_redundant_foreskin IS NOT NULL OR	chk_retrusive IS NOT NULL OR	chk_scarring IS NOT NULL OR
chk_skin_tag IS NOT NULL OR	chk_witness_urinary_stream IS NOT NULL OR	txt_degrees_curve IS NOT NULL OR	txt_fistula	 IS NOT NULL OR txt_hypospadia
 IS NOT NULL OR	txt_mass  IS NOT NULL)



SELECT COUNT(DISTINCT PERSON_ID) AS 'COUNT', service_item_id --MAX(create_timestamp), service_item_id
FROM patient_procedure pp
where pp.create_timestamp >= '20151001' AND pp.create_timestamp <= '20160930'
AND service_item_id in  -- LIKE '%vasec%'
('55250'
,'B013'
,'SOC- VAS')
group by service_item_id