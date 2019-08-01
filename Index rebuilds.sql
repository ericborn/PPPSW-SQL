--TO BE IMPLEMENTED 1/25
drop index appointments.inx_appointments2
drop index batch_groups.inx_batch_groups2
drop index DiagnosesExtPop_.inx_DiagnosesExtPop_tmp1
drop index enterprise_prefs.inx_enterprise_prefs1
drop index imm_order_vaccines.inx_imm_order_vaccines1
drop index macro_master.inx_macro_master1
drop index resource_templates._inx_resource_templates_20150908_76D4D0C8
create index inx_intrf_export_queue3 on intrf_export_queue(export_agent_name, is_exported_ind) INCLUDE(enterprise_id, practice_id, export_id, person_id, enc_id, export_type, order_num, created_by, create_timestamp, modified_by, modify_timestamp, uniq_id) WITH (ONLINE=ON, DROP_EXISTING=ON) ON NEXTGEN_INDEX_1
create index inx_opk_payhed3 on opk_payhed(delete_ind, cancel_ind) INCLUDE(payhed_id, person_id, order_type, order_id, order_date, receive_date, unit_bac, lens_bac, tax, taxable_amount, nontaxable_amount, manual_adjustment, invoice_number, original_amount, balance_due, taxable_adjustment, nontaxable_adjustment, lens_invoice, created_by, create_timestamp, modified_by, modify_timestamp, enterprise_id, practice_id, lens_bac_on_sale, lens_bac_on_receive, bac_rt, bac_lt) WITH (ONLINE=ON, DROP_EXISTING=ON) ON NEXTGEN_INDEX_1
create index inx_patient_recall_plans2 on patient_recall_plans(person_id, practice_id, recall_plan_id, seq_nbr, active_plan_ind) WITH (ONLINE=ON, DROP_EXISTING=ON) ON NEXTGEN_INDEX_1
create index inx_clinical_guidelines_5 on clinical_guidelines_(enterprise_id, practice_id, person_id, enc_id) INCLUDE(seq_no, txt_compliance_exclusion, txt_date_last_addressed, txt_due_date, txt_guideline, txt_status) WITH (ONLINE=ON, DROP_EXISTING=ON) ON NEXTGEN_INDEX_1
create index inx_problem_note_xref1 on problem_note_xref(delete_ind) INCLUDE(problem_id) WITH (ONLINE=ON, DROP_EXISTING=ON) ON NEXTGEN_INDEX_1
create index inx_erx_provider_mstr2 on erx_provider_mstr(icw_provider_ind, practice_id, provider_id, spi_nbr) WITH (ONLINE=ON, DROP_EXISTING=ON) ON NEXTGEN_INDEX_1
create index inx_erx_provider_mstr3 on erx_provider_mstr(spi_nbr) INCLUDE(practice_id, provider_id) WITH (ONLINE=ON, DROP_EXISTING=ON) ON NEXTGEN_INDEX_1
create index inx_ngkbm_custom_nav_setup_tmp1 on ngkbm_custom_nav_setup_(practice_id, caption) WITH (ONLINE=ON) ON NEXTGEN_INDEX_1
create index _inx_intrf_mstr_lists_20141220_A669F247 on intrf_mstr_lists(internal_rec_id) INCLUDE(code_type, external_rec_id, external_system_id, coding_system) WITH (ONLINE=ON, DROP_EXISTING=ON) ON NEXTGEN_INDEX_1
create index inx_templates_tmp1 on templates(alias_template) WITH (ONLINE=ON) ON NEXTGEN_INDEX_1
create index inx_ngkbm_foundtn_contnt_items_tmp1 on ngkbm_foundtn_contnt_items_(txt_specialty,kbm_ind) INCLUDE(txt_caption, txt_content_type, txt_practice_id, txt_provider_id, txt_sort_order, txt_template_name, txt_visit_type, txt_template_type) WITH (ONLINE=ON) ON NEXTGEN_INDEX_1
create index inx_fax_result3 on fax_result(user_id, modify_timestamp) INCLUDE(fax_result_id, location_id, to_name, to_company, to_fax, to_comments, fax_status, doc_id, doc_type, modified_by, person_id, toll_ind, area_code_rules_ind, coverpage_ind, failure_reason, modify_timestamp_tz) WITH (ONLINE=ON, DROP_EXISTING=ON) ON NEXTGEN_INDEX_1

--TO BE IMPLEMENTED 2/1
drop index cpt4_categ_matrix.xcpt4_code_id
drop index person_payer.inx_person_payer6
drop index macro_master.ak_macro_master1
drop index mstr_lists.inx_mstr_lists2
drop index resource_templates._inx_resource_templates_20150908_88C3DBCB
drop index resource_templates.inx_resource_templates_ngdba1
drop index template_members.inx_template_members_ngdba1
--create unique clustered index ak_macro_master1 on macro_master(macro_name) WITH (ONLINE=ON) ON NEXTGEN_CORE
create index inx_tracked_problem_xref_tmp1 on tracked_problem_xref(problem_id) WITH (ONLINE=ON) ON NEXTGEN_INDEX_1
create index inx_ngkbm_my_phrases_tmp1 on ngkbm_my_phrases_(phrase_type, userID) INCLUDE(kbm_ind, phrase, phrase_summary) WITH (ONLINE=ON) ON NEXTGEN_INDEX_1
create index inx_intrf_queue4 on intrf_queue(state, enterprise_id, practice_id, type) INCLUDE(queue_id, comments, person_id, create_timestamp, external_person_id, last_name, first_name, date_of_birth, ssn_id, enc_date, provider_id, location_id, filler_order_num, ufo_num) WITH (ONLINE=ON, DROP_EXISTING=ON) ON NEXTGEN_INDEX_1
create index inx_fields_master2 on fields_master(table_name, field_comment, field_name) WITH (ONLINE=ON, DROP_EXISTING=ON) ON NEXTGEN_INDEX_1
create index _inx_user_todo_list_20140911_6D9B5171 on user_todo_list(task_completed, task_deleted) INCLUDE(user_id, task_id, task_assgn, task_owner) WITH (ONLINE=ON, DROP_EXISTING=ON) ON NEXTGEN_INDEX_1
create index inx_ngweb_audit_log_tmp1 on ngweb_audit_log(person_id, log_type_id, delete_ind) INCLUDE(audit_event_timestamp) WITH (ONLINE=ON) ON NEXTGEN_INDEX_1
create index inx_ngweb_audit_log_tmp2 on ngweb_audit_log(log_type_id, delete_ind) INCLUDE(person_id, audit_event_timestamp, nx_practice_id) WITH (ONLINE=ON) ON NEXTGEN_INDEX_1
create index inx_order_tmp1 on order_(person_id, encounterID) INCLUDE(enterprise_id, practice_id, actClass, actDiagnosisCode, actMood, actReasonCode, actStatus, actTextDisplay, apptDate, completedDate, completedReason, obtainedDate, receivedDate, sortOrderDisplay, apptTimeframeDisp, apptTimeLimit, actSubClass, actTextDispDoc) WITH (ONLINE=ON) ON NEXTGEN_INDEX_1
create index inx_order_tmp2 on order_(enterprise_id, person_id, actStatus) INCLUDE(practice_id, actClass, actMood, cancelled, completedDate, deleted, encounterID, orderedDate, order_module_order_num, order_module_lab_id) WITH (ONLINE=ON) ON NEXTGEN_INDEX_1
create index inx_lab_results_obx_tmp1 on lab_results_obx(observ_value, delete_ind) INCLUDE(unique_obr_num) WITH (ONLINE=ON) ON NEXTGEN_INDEX_1
create index inx_trans_detail_tmp1 on trans_detail(charge_id, post_ind) INCLUDE(adj_amt,paid_amt) WITH (ONLINE=ON) ON NEXTGEN_INDEX_1



--TO REVERT DROPS 1/25
USE [NGProd]
GO

/****** Object:  Index [inx_appointments2]    Script Date: 1/23/2018 3:14:29 PM ******/
CREATE NONCLUSTERED INDEX [inx_appointments2] ON [dbo].[appointments]
(
	[practice_id] ASC,
	[event_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [NEXTGEN_INDEX_1]
GO


USE [NGProd]
GO

/****** Object:  Index [inx_batch_groups2]    Script Date: 1/23/2018 3:15:49 PM ******/
CREATE NONCLUSTERED INDEX [inx_batch_groups2] ON [dbo].[batch_groups]
(
	[practice_id] ASC,
	[row_timestamp] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [NEXTGEN_INDEX_1]
GO

USE [NGProd]
GO

/****** Object:  Index [inx_DiagnosesExtPop_tmp1]    Script Date: 1/23/2018 3:17:31 PM ******/
CREATE NONCLUSTERED INDEX [inx_DiagnosesExtPop_tmp1] ON [dbo].[DiagnosesExtPop_]
(
	[enc_id] ASC,
	[create_timestamp] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 95) ON [NEXTGEN_INDEX_1]
GO


USE [NGProd]
GO

/****** Object:  Index [inx_enterprise_prefs1]    Script Date: 1/23/2018 3:18:18 PM ******/
CREATE NONCLUSTERED INDEX [inx_enterprise_prefs1] ON [dbo].[enterprise_prefs]
(
	[row_timestamp] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [NEXTGEN_INDEX_1]
GO

USE [NGProd]
GO

/****** Object:  Index [inx_imm_order_vaccines1]    Script Date: 1/23/2018 3:19:14 PM ******/
CREATE NONCLUSTERED INDEX [inx_imm_order_vaccines1] ON [dbo].[imm_order_vaccines]
(
	[order_num] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [NEXTGEN_INDEX_1]
GO


USE [NGProd]
GO

/****** Object:  Index [inx_macro_master1]    Script Date: 1/23/2018 3:19:58 PM ******/
CREATE CLUSTERED INDEX [inx_macro_master1] ON [dbo].[macro_master]
(
	[macro_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [NEXTGEN_CORE]
GO


/****** Object:  Index [_inx_resource_templates_20150908_76D4D0C8]    Script Date: 1/23/2018 3:22:32 PM ******/
CREATE NONCLUSTERED INDEX [_inx_resource_templates_20150908_76D4D0C8] ON [dbo].[resource_templates]
(
	[practice_id] ASC,
	[resource_id] ASC,
	[seq_nbr] ASC,
	[week_start_date] ASC
)
INCLUDE ( 	[appt_template_id],
	[template_count]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [NEXTGEN_CORE]
GO

--TO REVERT IMPLEMENTS 1/25
DROP index inx_intrf_export_queue3 
DROP index inx_opk_payhed3 
DROP INDEX inx_patient_recall_plans2 
DROP INDEX inx_clinical_guidelines_5
DROP INDEX inx_problem_note_xref1 
DROP INDEX inx_erx_provider_mstr2
DROP INDEX inx_erx_provider_mstr3
DROP INDEX inx_ngkbm_custom_nav_setup_tmp1
DROP INDEX _inx_intrf_mstr_lists_20141220_A669F247
DROP INDEX inx_templates_tmp1
DROP INDEX inx_ngkbm_foundtn_contnt_items_tmp1
DROP INDEX inx_fax_result3



--TO REVERT DROPS 2/1
USE [NGProd]
GO

/****** Object:  Index [xcpt4_code_id]    Script Date: 1/23/2018 3:16:53 PM ******/
CREATE NONCLUSTERED INDEX [xcpt4_code_id] ON [dbo].[cpt4_categ_matrix]
(
	[cpt4_code_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [NEXTGEN_CORE]
GO

USE [NGProd]
GO

/****** Object:  Index [ak_macro_master1]    Script Date: 1/23/2018 3:20:08 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [ak_macro_master1] ON [dbo].[macro_master]
(
	[macro_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [NEXTGEN_INDEX_1]
GO


USE [NGProd]
GO

/****** Object:  Index [inx_mstr_lists2]    Script Date: 1/23/2018 3:20:51 PM ******/
CREATE NONCLUSTERED INDEX [inx_mstr_lists2] ON [dbo].[mstr_lists]
(
	[row_timestamp] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [NEXTGEN_INDEX_1]
GO


USE [NGProd]
GO

/****** Object:  Index [inx_person_payer6]    Script Date: 1/23/2018 3:21:39 PM ******/
CREATE NONCLUSTERED INDEX [inx_person_payer6] ON [dbo].[person_payer]
(
	[row_timestamp] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [NEXTGEN_INDEX_1]
GO


USE [NGProd]
GO

USE [NGProd]
GO

/****** Object:  Index [_inx_resource_templates_20150908_88C3DBCB]    Script Date: 1/23/2018 3:22:44 PM ******/
CREATE NONCLUSTERED INDEX [_inx_resource_templates_20150908_88C3DBCB] ON [dbo].[resource_templates]
(
	[practice_id] ASC,
	[resource_id] ASC,
	[seq_nbr] ASC,
	[week_start_date] ASC,
	[week_end_date] ASC
)
INCLUDE ( 	[appt_template_id]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [NEXTGEN_CORE]
GO


USE [NGProd]
GO

/****** Object:  Index [inx_resource_templates_ngdba1]    Script Date: 1/23/2018 3:23:05 PM ******/
CREATE NONCLUSTERED INDEX [inx_resource_templates_ngdba1] ON [dbo].[resource_templates]
(
	[week_end_date] ASC,
	[practice_id] ASC,
	[resource_id] ASC,
	[week_start_date] ASC,
	[appt_template_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [NEXTGEN_INDEX_1]
GO


USE [NGProd]
GO

/****** Object:  Index [inx_template_members_ngdba1]    Script Date: 1/23/2018 3:24:22 PM ******/
CREATE NONCLUSTERED INDEX [inx_template_members_ngdba1] ON [dbo].[template_members]
(
	[appt_template_id] ASC,
	[practice_id] ASC,
	[begintime] ASC,
	[endtime] ASC
)
INCLUDE ( 	[category_id]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [NEXTGEN_INDEX_1]
GO


--TO REVERT IMPLEMENTS 2/1
DROP INDEX ak_macro_master1
DROP INDEX inx_tracked_problem_xref_tmp1
DROP INDEX inx_ngkbm_my_phrases_tmp1
DROP INDEX inx_intrf_queue4
DROP INDEX inx_fields_master2
DROP INDEX _inx_user_todo_list_20140911_6D9B5171
DROP INDEX inx_ngweb_audit_log_tmp1
DROP INDEX inx_ngweb_audit_log_tmp2
DROP INDEX inx_order_tmp1
DROP INDEX inx_order_tmp2
DROP INDEX inx_lab_results_obx_tmp1
DROP INDEX inx_trans_detail_tmp1