--USE [ppreporting]
--GO
--/****** Object:  StoredProcedure [dbo].[pp_HIE_Consent_Audit_v2]    Script Date: 1/13/2015 10:08:56 AM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

--ALTER proc [dbo].[pp_HIE_Consent_Audit_v2]
--(
--      @Start_Date datetime,
--      @End_Date datetime
--)

--AS
--BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	--SET NOCOUNT ON;

---- yes or emergency in ud4 and a consent form 


---- Step 1: Gather a list of patients seen in a timeframe
drop table #demo_tank

---- Declare and set Variables

DECLARE @Start_Date date
DECLARE @End_Date date

SET @Start_Date = '20140901'
SET @End_Date = '20140925'

-- step 1 - Gather all patients within our scope

create table #demo_tank (
      person_id uniqueidentifier,
      UD4_HIE varchar(1),
      Document_HIE varchar(1),
	  Last_Appt varchar(50)
	  --Last_Mod varchar(50)
)

-- populate the tank
insert into #demo_tank
SELECT Distinct
      pe.person_id,
      'N',
      'N',
	  '20150101'
FROM ngprod.dbo.patient_encounter pe
WHERE (convert(date,pe.billable_timestamp) >= convert(date,@Start_Date) AND convert(date,pe.billable_timestamp) <= convert(date,@End_Date)) -- just consider dates 
      AND pe.billable_ind = 'Y'
      AND pe.clinical_ind = 'Y' 


-- step 2: indicate anyone with a UD4 value with a consent
Update #demo_tank
SET UD4_HIE = 'Y'
where person_id in (
      select distinct pe.person_id
      FROM ngprod.dbo.patient_encounter pe
            join ngprod.dbo.person_ud psud on psud.person_id = pe.person_id
      WHERE (convert(date,pe.billable_timestamp) >= convert(date,@Start_Date) AND convert(date,pe.billable_timestamp) <= convert(date,@End_Date)) -- just consider dates 
            AND pe.billable_ind = 'Y'
            AND pe.clinical_ind = 'Y'
            AND psud.ud_demo4_id in ( 'FF821480-C2CD-413F-9C0D-1394EF19DADA', '01769FD7-AC7A-476E-B55B-4442925B95AA') -- 3-yes or 2-emergency
)

-- step 3 - indicate encounters with a document attached
Update #demo_tank
SET Document_HIE = 'Y'
where person_id in (
      select distinct pe.person_id
      FROM ngprod.dbo.patient_encounter pe
            join ngprod.dbo.patient_documents pd on pd.enc_id = pe.enc_id
            
      WHERE (pe.billable_timestamp > '20140101')      -- any documents form 2014 and on
            AND pe.clinical_ind = 'Y'
            AND pd.document_desc in ('_HIE_', '_HIE(S)_','_B__HIE_Text Msg_E-Mail_','_B__HIE_Text Msg_E-Mail_(S)')
)

-- Step 4 - select last encounter timestamp
Update #demo_tank
SET Last_Appt = ' '
where enc_timestamp in (
	select distinct pe.enc_timestamp
	FROM ngprod.dbo.patient_encounter pe
            join ngprod.dbo.patient_documents pd on pd.enc_id = pe.enc_id

	WHERE (pe.billable_timestamp > '20140101')      -- any documents from 2014 and on
            AND pe.clinical_ind = 'Y'
            AND pd.document_desc in ('_HIE_', '_HIE(S)_','_B__HIE_Text Msg_E-Mail_','_B__HIE_Text Msg_E-Mail_(S)')
)

--select * from ngprod.dbo.patient_documents
--select * from ngprod.dbo.patient_encounter


-- Step 5 - select last modified ud4
--select u.first_name + ' ' + u.last_name as staff_name, sig_msg as consent, s.create_timestamp 
--	FROM ngprod.dbo.sig_events s (nolock), ngprod.dbo.user_mstr u (nolock)
--			join ngprod.dbo.s on s.source1_id = ps.person_id
--	WHERE s.created_by = u.user_id and s.modify_timestamp > '2015-01-01' and s.sig_msg like 'HIE Consent%'


-- Step 6 - report out findings

select      SUBSTRING(pt.med_rec_nbr, PATINDEX('%[^0]%', pt.med_rec_nbr+'.'), LEN(pt.med_rec_nbr)) as MRN,
      ps.last_name + ', '+ ps.first_name as Patient_name, 
      #demo_tank.UD4_HIE, 
      #demo_tank.Document_HIE,
	  #demo_tank.Last_Appt
	  --#demo_tank.Last_Mod
from #demo_tank
      join ngprod.dbo.person ps on ps.person_id = #demo_tank.person_id
      join ngprod.dbo.patient pt on pt.person_id = #demo_tank.person_id
where UD4_HIE = 'Y'
order by Document_HIE, Patient_name

--END