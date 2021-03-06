USE [NGProd]
GO
/****** Object:  StoredProcedure [dbo].[PPPSW_Charge_Mod_and_Narr_Update]    Script Date: 10/13/2017 12:06:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[PPPSW_Charge_Mod_and_Narr_Update] 
	@Mode varchar(20)  -- either Update to change mods or Review to preview changes that would be made by Update
    ,@user_id int  -- will default to 0 if not a valid user id

AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

---- Code
-- Clean Up
--drop table #chg_mod


-- Step 1. Declare our Variables
--declare @user_id int
--DECLARE @Mode varchar(10)

--set @user_id = 0
--SET @Mode = 'Review'


-- Step 1: create our modification list

CREATE table #chg_mod
(
	charge_id uniqueidentifier,
	modifier_1 varchar (2),
	modifier_2 varchar (2),
	modifier_3 varchar (2),
	modifier_4 varchar (2),
	narrative varchar(255),
	Prov_Narrative varchar(255),
	Prov_specialty varchar(5),
	Enc_Payer varchar(80)
)

--Step 2: Get all charges with an AG modifier for a NP, PA, CNM for the relevent payer finclasses

insert into #chg_mod
select ch.charge_id, '', '', '', '',NULL, prov.first_name + ' ' + prov.last_name + ' ' + isnull(prov.national_provider_id,''), prov.specialty_code_1,
	payer_finl_class = case
    when charindex('FINCLASS=', pay.note) > 0
      and charindex(';', pay.note, charindex('FINCLASS=', pay.note)+1) > 0
    then left(substring(pay.note, 
      charindex('FINCLASS=', pay.note) + len('FINCLASS='),
      charindex(';', pay.note, charindex('FINCLASS=', pay.note)) -
        (charindex('FINCLASS=', pay.note) + len('FINCLASS='))
      ),20) 
    else ''
    end
from charges ch
	join provider_mstr prov on prov.provider_id = ch.rendering_id
	inner join NGProd.dbo.patient_encounter pe on ch.source_id = pe.enc_id AND ch.source_type = 'V'
	inner join NGProd.dbo.encounter_payer ep on pe.enc_id = ep.enc_id
	inner join NGProd.dbo.payer_mstr pay on ep.payer_id = pay.payer_id
where prov.specialty_code_1 in ('NP','PA','CNM')
	AND ch.modifier_1 = 'AG'
	AND ch.status in ('U','R')


--remove unneeded payers
delete from #chg_mod
where Enc_Payer not in ('MDCAID','MDCAIDWAIV')

-- Step 2. Update the Modifier_1 per Role
--Modifier codes (for replacing AG)
--NP = 'SA'
--PA = 'U7'
--CNM = 'SB'

update #chg_mod
SET modifier_1 = 'SA', modifier_2 = '', modifier_3='', modifier_4 = ''
WHERE Prov_specialty in ('NP')

update #chg_mod
SET modifier_1 = 'U7', modifier_2 = '', modifier_3='', modifier_4 = ''
WHERE Prov_specialty in ('PA')

update #chg_mod
SET modifier_1 = 'SB', modifier_2 = '', modifier_3='', modifier_4 = ''
WHERE Prov_specialty in ('CNM')

-- Step 3: build Narrative

update #chg_mod
  set narrative = rtrim(Prov_Narrative)


-- modify
if @Mode = 'Update'
BEGIN
	declare @chg_id uniqueidentifier
	declare @mod1 varchar(2)
	declare @mod2 varchar(2)
	declare @mod3 varchar(2)
	declare @mod4 varchar(2)
    declare @newnarr varchar(250)
	
	declare mod_inf cursor
	for
	select charge_id,
		modifier_1,modifier_2,modifier_3, modifier_4, narrative
	from #chg_mod

	open mod_inf

	fetch next from mod_inf
	into @chg_id,
	@mod1, @mod2, @mod3, @mod4, @newnarr

	while @@fetch_status = 0
		BEGIN

		-- update modifiers
			exec NGProd.dbo.ncs_update_charge_modifiers @user_id, @chg_id, @mod1, @mod2, @mod3, @mod4

		-- update narrative
			exec NGProd.dbo.ncs_update_charges_narrative @user_id, @chg_id, @newnarr
			fetch next from mod_inf
			into @chg_id, @mod1, @mod2, @mod3, @mod4, @newnarr
		END
		close mod_inf
		deallocate mod_inf
END

if @Mode = 'Review'
	select * from #chg_mod
END
