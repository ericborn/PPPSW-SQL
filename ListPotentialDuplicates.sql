/* 
SQL Queries for finding Potential Duplicate Person Accounts

Queries are in the decreasing order of constraints

*/

--Same First Name, Last Name, DOB, Zip and one of the phone numbers
Select 
	DUP.Person_Nbr_A 				as Person_Nbr_A, 
	pta.med_rec_nbr 				as MRN_A, 
	DUP.First_Name_A 				as First_Name_A, 
	DUP.Last_Name_A 				as Last_Name_A, 
	DUP.DOB_A 					as DOB_A, 
	DUP.Zip_A 					as Zip_A, 
	DUP.Home_Phone_A 				as Home_Phone_A, 
	DUP.Day_Phone_A 				as Day_Phone_A, 
	DUP.Alt_Phone_A 				as Alt_Phone_A, 
	DUP.Cell_Phone_A 				as Cell_Phone_A, 
	DUP.Create_Timestamp_A 				as Create_Date_A, 
	(ua.first_name + ' ' + ua.last_name)		as Creator_A,

	DUP.Person_Nbr_B 				as Person_Nbr_B, 
	ptb.med_rec_nbr 				as MRN_B, 
	DUP.First_Name_B 				as First_Name_B, 
	DUP.Last_Name_B 				as Last_Name_B, 
	DUP.DOB_B 					as DOB_B, 
	DUP.Zip_B 					as Zip_B, 
	DUP.Home_Phone_B 				as Home_Phone_B, 
	DUP.Day_Phone_B 				as Day_Phone_B, 
	DUP.Alt_Phone_B 				as Alt_Phone_B, 
	DUP.Cell_Phone_B 				as Cell_Phone_B, 
	DUP.Create_Timestamp_B 				as Create_Date_B, 
	(ub.first_name + ' ' + ub.last_name)		as Creator_B

FROM (SELECT 
    	a.person_id                     						as Person_Id_A,
    	a.created_by                     						as Creator_A,
	a.person_nbr 									as Person_Nbr_A, 
	a.first_name 									as First_Name_A, 
	a.last_name 									as Last_Name_A, 
	dbo.fn_convertdate_slashes(a.date_of_birth) 					as DOB_A, 
	a.zip 										as Zip_A, 
	a.home_phone 									as Home_Phone_A, 
	a.day_phone 									as Day_Phone_A, 
	a.alt_phone 									as Alt_Phone_A, 
	a.cell_phone 									as Cell_Phone_A, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),a.create_timestamp, 112)) 	as Create_Timestamp_A, 

    	b.person_id                     						as Person_Id_B,
    	b.created_by                     						as Creator_B,
	b.person_nbr 									as Person_Nbr_B, 
	b.first_name 									as First_Name_B, 
	b.last_name 									as Last_Name_B, 
	dbo.fn_convertdate_slashes(b.date_of_birth) 					as DOB_B, 
	b.zip 										as Zip_B, 
	b.home_phone 									as Home_Phone_B, 
	b.day_phone 									as Day_Phone_B, 
	b.alt_phone 									as Alt_Phone_B, 
	b.cell_phone 									as Cell_Phone_B, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),b.create_timestamp, 112)) 	as Create_Timestamp_B 

	FROM person a, person b

	WHERE 
		a.first_name=b.first_name 
		and a.last_name=b.last_name 
		and a.date_of_birth=b.date_of_birth 
		and a.zip=b.zip
		and (
    			(a.home_phone<>'' and a.home_phone IS NOT NULL and (
    				a.home_phone=b.home_phone or a.home_phone=b.day_phone or a.home_phone=b.cell_phone or a.home_phone=b.alt_phone))
    			or (a.day_phone<>'' and a.day_phone IS NOT NULL and (
    				a.day_phone=b.home_phone or a.day_phone=b.day_phone or a.day_phone=b.cell_phone or a.day_phone=b.alt_phone))
    			or (a.cell_phone<>'' and a.cell_phone IS NOT NULL and (
    				a.cell_phone=b.home_phone or a.cell_phone=b.day_phone or a.cell_phone=b.cell_phone or a.cell_phone=b.alt_phone))
    			or (a.alt_phone<>'' and a.alt_phone IS NOT NULL and (
    				a.alt_phone=b.home_phone or a.alt_phone=b.day_phone or a.alt_phone=b.cell_phone or a.alt_phone=b.alt_phone))
    		)
		and a.person_nbr<>b.person_nbr 
		and a.create_timestamp < b.create_timestamp

	) DUP

JOIN patient pta on DUP.Person_Id_A=pta.person_id
JOIN patient ptb on DUP.Person_Id_B=ptb.person_id
JOIN user_mstr ua on DUP.Creator_A=ua.user_id
JOIN user_mstr ub on DUP.Creator_B=ub.user_id

-- End of Same First Name, Last Name, DOB, Zip and one of the phone numbers
-----------------------------------------------------------------------------------------------------


--Same First Name, Last Name, DOB, and one of the phone numbers 
--but 
--Different Zips
Select 
	DUP.Person_Nbr_A 				as Person_Nbr_A, 
	pta.med_rec_nbr 				as MRN_A, 
	DUP.First_Name_A 				as First_Name_A, 
	DUP.Last_Name_A 				as Last_Name_A, 
	DUP.DOB_A 					as DOB_A, 
	DUP.Zip_A 					as Zip_A, 
	DUP.Home_Phone_A 				as Home_Phone_A, 
	DUP.Day_Phone_A 				as Day_Phone_A, 
	DUP.Alt_Phone_A 				as Alt_Phone_A, 
	DUP.Cell_Phone_A 				as Cell_Phone_A, 
	DUP.Create_Timestamp_A 				as Create_Date_A, 
	(ua.first_name + ' ' + ua.last_name)		as Creator_A,

	DUP.Person_Nbr_B 				as Person_Nbr_B, 
	ptb.med_rec_nbr 				as MRN_B, 
	DUP.First_Name_B 				as First_Name_B, 
	DUP.Last_Name_B 				as Last_Name_B, 
	DUP.DOB_B 					as DOB_B, 
	DUP.Zip_B 					as Zip_B, 
	DUP.Home_Phone_B 				as Home_Phone_B, 
	DUP.Day_Phone_B 				as Day_Phone_B, 
	DUP.Alt_Phone_B 				as Alt_Phone_B, 
	DUP.Cell_Phone_B 				as Cell_Phone_B, 
	DUP.Create_Timestamp_B 				as Create_Date_B, 
	(ub.first_name + ' ' + ub.last_name)		as Creator_B

FROM (SELECT 
    	a.person_id                     						as Person_Id_A,
    	a.created_by                     						as Creator_A,
	a.person_nbr 									as Person_Nbr_A, 
	a.first_name 									as First_Name_A, 
	a.last_name 									as Last_Name_A, 
	dbo.fn_convertdate_slashes(a.date_of_birth) 					as DOB_A, 
	a.zip 										as Zip_A, 
	a.home_phone 									as Home_Phone_A, 
	a.day_phone 									as Day_Phone_A, 
	a.alt_phone 									as Alt_Phone_A, 
	a.cell_phone 									as Cell_Phone_A, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),a.create_timestamp, 112)) 	as Create_Timestamp_A, 

    	b.person_id                     						as Person_Id_B,
    	b.created_by                     						as Creator_B,
	b.person_nbr 									as Person_Nbr_B, 
	b.first_name 									as First_Name_B, 
	b.last_name 									as Last_Name_B, 
	dbo.fn_convertdate_slashes(b.date_of_birth) 					as DOB_B, 
	b.zip 										as Zip_B, 
	b.home_phone 									as Home_Phone_B, 
	b.day_phone 									as Day_Phone_B, 
	b.alt_phone 									as Alt_Phone_B, 
	b.cell_phone 									as Cell_Phone_B, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),b.create_timestamp, 112)) 	as Create_Timestamp_B 

	FROM person a, person b

	WHERE 
		a.first_name=b.first_name 
		and a.last_name=b.last_name 
		and a.date_of_birth=b.date_of_birth 
		and a.zip<>b.zip
		and (
    			(a.home_phone<>'' and a.home_phone IS NOT NULL and (
    				a.home_phone=b.home_phone or a.home_phone=b.day_phone or a.home_phone=b.cell_phone or a.home_phone=b.alt_phone))
    			or (a.day_phone<>'' and a.day_phone IS NOT NULL and (
    				a.day_phone=b.home_phone or a.day_phone=b.day_phone or a.day_phone=b.cell_phone or a.day_phone=b.alt_phone))
    			or (a.cell_phone<>'' and a.cell_phone IS NOT NULL and (
    				a.cell_phone=b.home_phone or a.cell_phone=b.day_phone or a.cell_phone=b.cell_phone or a.cell_phone=b.alt_phone))
    			or (a.alt_phone<>'' and a.alt_phone IS NOT NULL and (
    				a.alt_phone=b.home_phone or a.alt_phone=b.day_phone or a.alt_phone=b.cell_phone or a.alt_phone=b.alt_phone))
    		)
		and a.person_nbr<>b.person_nbr 
		and a.create_timestamp < b.create_timestamp

	) DUP

JOIN patient pta on DUP.Person_Id_A=pta.person_id
JOIN patient ptb on DUP.Person_Id_B=ptb.person_id
JOIN user_mstr ua on DUP.Creator_A=ua.user_id
JOIN user_mstr ub on DUP.Creator_B=ub.user_id

-- End of Same First Name, Last Name, DOB, and one of the phone numbers 
--but 
--Different Zips
-----------------------------------------------------------------------------------------------------


--Same First Name, DOB, Zip and one of the phone numbers 
--but 
--Different Last Name
Select 
	DUP.Person_Nbr_A 				as Person_Nbr_A, 
	pta.med_rec_nbr 				as MRN_A, 
	DUP.First_Name_A 				as First_Name_A, 
	DUP.Last_Name_A 				as Last_Name_A, 
	DUP.DOB_A 					as DOB_A, 
	DUP.Zip_A 					as Zip_A, 
	DUP.Home_Phone_A 				as Home_Phone_A, 
	DUP.Day_Phone_A 				as Day_Phone_A, 
	DUP.Alt_Phone_A 				as Alt_Phone_A, 
	DUP.Cell_Phone_A 				as Cell_Phone_A, 
	DUP.Create_Timestamp_A 				as Create_Date_A, 
	(ua.first_name + ' ' + ua.last_name)		as Creator_A,

	DUP.Person_Nbr_B 				as Person_Nbr_B, 
	ptb.med_rec_nbr 				as MRN_B, 
	DUP.First_Name_B 				as First_Name_B, 
	DUP.Last_Name_B 				as Last_Name_B, 
	DUP.DOB_B 					as DOB_B, 
	DUP.Zip_B 					as Zip_B, 
	DUP.Home_Phone_B 				as Home_Phone_B, 
	DUP.Day_Phone_B 				as Day_Phone_B, 
	DUP.Alt_Phone_B 				as Alt_Phone_B, 
	DUP.Cell_Phone_B 				as Cell_Phone_B, 
	DUP.Create_Timestamp_B 				as Create_Date_B, 
	(ub.first_name + ' ' + ub.last_name)		as Creator_B

FROM (SELECT 
    	a.person_id                     						as Person_Id_A,
    	a.created_by                     						as Creator_A,
	a.person_nbr 									as Person_Nbr_A, 
	a.first_name 									as First_Name_A, 
	a.last_name 									as Last_Name_A, 
	dbo.fn_convertdate_slashes(a.date_of_birth) 					as DOB_A, 
	a.zip 										as Zip_A, 
	a.home_phone 									as Home_Phone_A, 
	a.day_phone 									as Day_Phone_A, 
	a.alt_phone 									as Alt_Phone_A, 
	a.cell_phone 									as Cell_Phone_A, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),a.create_timestamp, 112)) 	as Create_Timestamp_A, 

    	b.person_id                     						as Person_Id_B,
    	b.created_by                     						as Creator_B,
	b.person_nbr 									as Person_Nbr_B, 
	b.first_name 									as First_Name_B, 
	b.last_name 									as Last_Name_B, 
	dbo.fn_convertdate_slashes(b.date_of_birth) 					as DOB_B, 
	b.zip 										as Zip_B, 
	b.home_phone 									as Home_Phone_B, 
	b.day_phone 									as Day_Phone_B, 
	b.alt_phone 									as Alt_Phone_B, 
	b.cell_phone 									as Cell_Phone_B, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),b.create_timestamp, 112)) 	as Create_Timestamp_B 

	FROM person a, person b

	WHERE 
		a.first_name=b.first_name 
		and a.last_name<>b.last_name 
		and a.date_of_birth=b.date_of_birth 
		and a.zip=b.zip
		and (
    			(a.home_phone<>'' and a.home_phone IS NOT NULL and (
    				a.home_phone=b.home_phone or a.home_phone=b.day_phone or a.home_phone=b.cell_phone or a.home_phone=b.alt_phone))
    			or (a.day_phone<>'' and a.day_phone IS NOT NULL and (
    				a.day_phone=b.home_phone or a.day_phone=b.day_phone or a.day_phone=b.cell_phone or a.day_phone=b.alt_phone))
    			or (a.cell_phone<>'' and a.cell_phone IS NOT NULL and (
    				a.cell_phone=b.home_phone or a.cell_phone=b.day_phone or a.cell_phone=b.cell_phone or a.cell_phone=b.alt_phone))
    			or (a.alt_phone<>'' and a.alt_phone IS NOT NULL and (
    				a.alt_phone=b.home_phone or a.alt_phone=b.day_phone or a.alt_phone=b.cell_phone or a.alt_phone=b.alt_phone))
    		)
		and a.person_nbr<>b.person_nbr 
		and a.create_timestamp < b.create_timestamp

	) DUP

JOIN patient pta on DUP.Person_Id_A=pta.person_id
JOIN patient ptb on DUP.Person_Id_B=ptb.person_id
JOIN user_mstr ua on DUP.Creator_A=ua.user_id
JOIN user_mstr ub on DUP.Creator_B=ub.user_id

--End Same First Name, DOB, Zip and one of the phone numbers 
--but 
--Different Last Name
-----------------------------------------------------------------------------------------------------

--Same Last Name, DOB, Zip and one of the phone numbers 
--but 
--Different First Name
Select 
	DUP.Person_Nbr_A 				as Person_Nbr_A, 
	pta.med_rec_nbr 				as MRN_A, 
	DUP.First_Name_A 				as First_Name_A, 
	DUP.Last_Name_A 				as Last_Name_A, 
	DUP.DOB_A 					as DOB_A, 
	DUP.Zip_A 					as Zip_A, 
	DUP.Home_Phone_A 				as Home_Phone_A, 
	DUP.Day_Phone_A 				as Day_Phone_A, 
	DUP.Alt_Phone_A 				as Alt_Phone_A, 
	DUP.Cell_Phone_A 				as Cell_Phone_A, 
	DUP.Create_Timestamp_A 				as Create_Date_A, 
	(ua.first_name + ' ' + ua.last_name)		as Creator_A,

	DUP.Person_Nbr_B 				as Person_Nbr_B, 
	ptb.med_rec_nbr 				as MRN_B, 
	DUP.First_Name_B 				as First_Name_B, 
	DUP.Last_Name_B 				as Last_Name_B, 
	DUP.DOB_B 					as DOB_B, 
	DUP.Zip_B 					as Zip_B, 
	DUP.Home_Phone_B 				as Home_Phone_B, 
	DUP.Day_Phone_B 				as Day_Phone_B, 
	DUP.Alt_Phone_B 				as Alt_Phone_B, 
	DUP.Cell_Phone_B 				as Cell_Phone_B, 
	DUP.Create_Timestamp_B 				as Create_Date_B, 
	(ub.first_name + ' ' + ub.last_name)		as Creator_B

FROM (SELECT 
    	a.person_id                     						as Person_Id_A,
    	a.created_by                     						as Creator_A,
	a.person_nbr 									as Person_Nbr_A, 
	a.first_name 									as First_Name_A, 
	a.last_name 									as Last_Name_A, 
	dbo.fn_convertdate_slashes(a.date_of_birth) 					as DOB_A, 
	a.zip 										as Zip_A, 
	a.home_phone 									as Home_Phone_A, 
	a.day_phone 									as Day_Phone_A, 
	a.alt_phone 									as Alt_Phone_A, 
	a.cell_phone 									as Cell_Phone_A, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),a.create_timestamp, 112)) 	as Create_Timestamp_A, 

    	b.person_id                     						as Person_Id_B,
    	b.created_by                     						as Creator_B,
	b.person_nbr 									as Person_Nbr_B, 
	b.first_name 									as First_Name_B, 
	b.last_name 									as Last_Name_B, 
	dbo.fn_convertdate_slashes(b.date_of_birth) 					as DOB_B, 
	b.zip 										as Zip_B, 
	b.home_phone 									as Home_Phone_B, 
	b.day_phone 									as Day_Phone_B, 
	b.alt_phone 									as Alt_Phone_B, 
	b.cell_phone 									as Cell_Phone_B, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),b.create_timestamp, 112)) 	as Create_Timestamp_B 

	FROM person a, person b

	WHERE 
		a.first_name<>b.first_name 
		and a.last_name=b.last_name 
		and a.date_of_birth=b.date_of_birth 
		and a.zip=b.zip
		and (
    			(a.home_phone<>'' and a.home_phone IS NOT NULL and (
    				a.home_phone=b.home_phone or a.home_phone=b.day_phone or a.home_phone=b.cell_phone or a.home_phone=b.alt_phone))
    			or (a.day_phone<>'' and a.day_phone IS NOT NULL and (
    				a.day_phone=b.home_phone or a.day_phone=b.day_phone or a.day_phone=b.cell_phone or a.day_phone=b.alt_phone))
    			or (a.cell_phone<>'' and a.cell_phone IS NOT NULL and (
    				a.cell_phone=b.home_phone or a.cell_phone=b.day_phone or a.cell_phone=b.cell_phone or a.cell_phone=b.alt_phone))
    			or (a.alt_phone<>'' and a.alt_phone IS NOT NULL and (
    				a.alt_phone=b.home_phone or a.alt_phone=b.day_phone or a.alt_phone=b.cell_phone or a.alt_phone=b.alt_phone))
    		)
		and a.person_nbr<>b.person_nbr 
		and a.create_timestamp < b.create_timestamp

	) DUP

JOIN patient pta on DUP.Person_Id_A=pta.person_id
JOIN patient ptb on DUP.Person_Id_B=ptb.person_id
JOIN user_mstr ua on DUP.Creator_A=ua.user_id
JOIN user_mstr ub on DUP.Creator_B=ub.user_id

--End Same Last Name, DOB, Zip and one of the phone numbers 
--but 
--Different First Name
-----------------------------------------------------------------------------------------------------

--Same First Name, Last Name, DOB and Zip
--but 
--Different Phone Numbers
Select 
	DUP.Person_Nbr_A 				as Person_Nbr_A, 
	pta.med_rec_nbr 				as MRN_A, 
	DUP.First_Name_A 				as First_Name_A, 
	DUP.Last_Name_A 				as Last_Name_A, 
	DUP.DOB_A 					as DOB_A, 
	DUP.Zip_A 					as Zip_A, 
	DUP.Home_Phone_A 				as Home_Phone_A, 
	DUP.Day_Phone_A 				as Day_Phone_A, 
	DUP.Alt_Phone_A 				as Alt_Phone_A, 
	DUP.Cell_Phone_A 				as Cell_Phone_A, 
	DUP.Create_Timestamp_A 				as Create_Date_A, 
	(ua.first_name + ' ' + ua.last_name)		as Creator_A,

	DUP.Person_Nbr_B 				as Person_Nbr_B, 
	ptb.med_rec_nbr 				as MRN_B, 
	DUP.First_Name_B 				as First_Name_B, 
	DUP.Last_Name_B 				as Last_Name_B, 
	DUP.DOB_B 					as DOB_B, 
	DUP.Zip_B 					as Zip_B, 
	DUP.Home_Phone_B 				as Home_Phone_B, 
	DUP.Day_Phone_B 				as Day_Phone_B, 
	DUP.Alt_Phone_B 				as Alt_Phone_B, 
	DUP.Cell_Phone_B 				as Cell_Phone_B, 
	DUP.Create_Timestamp_B 				as Create_Date_B, 
	(ub.first_name + ' ' + ub.last_name)		as Creator_B

FROM (SELECT 
    	a.person_id                     						as Person_Id_A,
    	a.created_by                     						as Creator_A,
	a.person_nbr 									as Person_Nbr_A, 
	a.first_name 									as First_Name_A, 
	a.last_name 									as Last_Name_A, 
	dbo.fn_convertdate_slashes(a.date_of_birth) 					as DOB_A, 
	a.zip 										as Zip_A, 
	a.home_phone 									as Home_Phone_A, 
	a.day_phone 									as Day_Phone_A, 
	a.alt_phone 									as Alt_Phone_A, 
	a.cell_phone 									as Cell_Phone_A, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),a.create_timestamp, 112)) 	as Create_Timestamp_A, 

    	b.person_id                     						as Person_Id_B,
    	b.created_by                     						as Creator_B,
	b.person_nbr 									as Person_Nbr_B, 
	b.first_name 									as First_Name_B, 
	b.last_name 									as Last_Name_B, 
	dbo.fn_convertdate_slashes(b.date_of_birth) 					as DOB_B, 
	b.zip 										as Zip_B, 
	b.home_phone 									as Home_Phone_B, 
	b.day_phone 									as Day_Phone_B, 
	b.alt_phone 									as Alt_Phone_B, 
	b.cell_phone 									as Cell_Phone_B, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),b.create_timestamp, 112)) 	as Create_Timestamp_B 

	FROM person a, person b

	WHERE 
		a.first_name=b.first_name 
		and a.last_name=b.last_name 
		and a.date_of_birth=b.date_of_birth 
		and a.zip=b.zip
		and (a.home_phone='' or a.home_phone IS NULL 
			or (a.home_phone<>b.home_phone and a.home_phone<>b.day_phone and a.home_phone<>b.cell_phone and a.home_phone<>b.alt_phone))
		and (a.day_phone='' or a.day_phone IS NULL 
			or (a.day_phone<>b.home_phone and a.day_phone<>b.day_phone and a.day_phone<>b.cell_phone and a.day_phone<>b.alt_phone))
		and (a.cell_phone='' or a.cell_phone IS NULL 
			or (a.cell_phone<>b.home_phone and a.cell_phone<>b.day_phone and a.cell_phone<>b.cell_phone and a.cell_phone<>b.alt_phone))
		and (a.alt_phone='' or a.alt_phone IS NULL 
			or (a.alt_phone<>b.home_phone and a.alt_phone<>b.day_phone and a.alt_phone<>b.cell_phone and a.alt_phone<>b.alt_phone))
		
		and a.person_nbr<>b.person_nbr 
		and a.create_timestamp < b.create_timestamp

	) DUP

JOIN patient pta on DUP.Person_Id_A=pta.person_id
JOIN patient ptb on DUP.Person_Id_B=ptb.person_id
JOIN user_mstr ua on DUP.Creator_A=ua.user_id
JOIN user_mstr ub on DUP.Creator_B=ub.user_id

--End Same First Name, Last Name, DOB and Zip
--but 
--Different Phone Numbers
-----------------------------------------------------------------------------------------------------

--Same First Name, Last Name, Zip and one of the phone numbers
--but 
--Different DOB
Select 
	DUP.Person_Nbr_A 				as Person_Nbr_A, 
	pta.med_rec_nbr 				as MRN_A, 
	DUP.First_Name_A 				as First_Name_A, 
	DUP.Last_Name_A 				as Last_Name_A, 
	DUP.DOB_A 					as DOB_A, 
	DUP.Zip_A 					as Zip_A, 
	DUP.Home_Phone_A 				as Home_Phone_A, 
	DUP.Day_Phone_A 				as Day_Phone_A, 
	DUP.Alt_Phone_A 				as Alt_Phone_A, 
	DUP.Cell_Phone_A 				as Cell_Phone_A, 
	DUP.Create_Timestamp_A 				as Create_Date_A, 
	(ua.first_name + ' ' + ua.last_name)		as Creator_A,

	DUP.Person_Nbr_B 				as Person_Nbr_B, 
	ptb.med_rec_nbr 				as MRN_B, 
	DUP.First_Name_B 				as First_Name_B, 
	DUP.Last_Name_B 				as Last_Name_B, 
	DUP.DOB_B 					as DOB_B, 
	DUP.Zip_B 					as Zip_B, 
	DUP.Home_Phone_B 				as Home_Phone_B, 
	DUP.Day_Phone_B 				as Day_Phone_B, 
	DUP.Alt_Phone_B 				as Alt_Phone_B, 
	DUP.Cell_Phone_B 				as Cell_Phone_B, 
	DUP.Create_Timestamp_B 				as Create_Date_B, 
	(ub.first_name + ' ' + ub.last_name)		as Creator_B

FROM (SELECT 
    	a.person_id                     						as Person_Id_A,
    	a.created_by                     						as Creator_A,
	a.person_nbr 									as Person_Nbr_A, 
	a.first_name 									as First_Name_A, 
	a.last_name 									as Last_Name_A, 
	dbo.fn_convertdate_slashes(a.date_of_birth) 					as DOB_A, 
	a.zip 										as Zip_A, 
	a.home_phone 									as Home_Phone_A, 
	a.day_phone 									as Day_Phone_A, 
	a.alt_phone 									as Alt_Phone_A, 
	a.cell_phone 									as Cell_Phone_A, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),a.create_timestamp, 112)) 	as Create_Timestamp_A, 

    	b.person_id                     						as Person_Id_B,
    	b.created_by                     						as Creator_B,
	b.person_nbr 									as Person_Nbr_B, 
	b.first_name 									as First_Name_B, 
	b.last_name 									as Last_Name_B, 
	dbo.fn_convertdate_slashes(b.date_of_birth) 					as DOB_B, 
	b.zip 										as Zip_B, 
	b.home_phone 									as Home_Phone_B, 
	b.day_phone 									as Day_Phone_B, 
	b.alt_phone 									as Alt_Phone_B, 
	b.cell_phone 									as Cell_Phone_B, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),b.create_timestamp, 112)) 	as Create_Timestamp_B 

	FROM person a, person b

	WHERE 
		a.first_name=b.first_name 
		and a.last_name=b.last_name 
		and a.date_of_birth<>b.date_of_birth 
		and a.zip=b.zip
		and (
    			(a.home_phone<>'' and a.home_phone IS NOT NULL and (
    				a.home_phone=b.home_phone or a.home_phone=b.day_phone or a.home_phone=b.cell_phone or a.home_phone=b.alt_phone))
    			or (a.day_phone<>'' and a.day_phone IS NOT NULL and (
    				a.day_phone=b.home_phone or a.day_phone=b.day_phone or a.day_phone=b.cell_phone or a.day_phone=b.alt_phone))
    			or (a.cell_phone<>'' and a.cell_phone IS NOT NULL and (
    				a.cell_phone=b.home_phone or a.cell_phone=b.day_phone or a.cell_phone=b.cell_phone or a.cell_phone=b.alt_phone))
    			or (a.alt_phone<>'' and a.alt_phone IS NOT NULL and (
    				a.alt_phone=b.home_phone or a.alt_phone=b.day_phone or a.alt_phone=b.cell_phone or a.alt_phone=b.alt_phone))
    		)
		and a.person_nbr<>b.person_nbr 
		and a.create_timestamp < b.create_timestamp

	) DUP

JOIN patient pta on DUP.Person_Id_A=pta.person_id
JOIN patient ptb on DUP.Person_Id_B=ptb.person_id
JOIN user_mstr ua on DUP.Creator_A=ua.user_id
JOIN user_mstr ub on DUP.Creator_B=ub.user_id

-- End Same First Name, Last Name, Zip and one of the phone numbers
--but 
--Different DOB
-----------------------------------------------------------------------------------------------------



--Same First Name, DOB and one of the phone numbers 
--but 
--Different Last Name, Zip
Select 
	DUP.Person_Nbr_A 				as Person_Nbr_A, 
	pta.med_rec_nbr 				as MRN_A, 
	DUP.First_Name_A 				as First_Name_A, 
	DUP.Last_Name_A 				as Last_Name_A, 
	DUP.DOB_A 					as DOB_A, 
	DUP.Zip_A 					as Zip_A, 
	DUP.Home_Phone_A 				as Home_Phone_A, 
	DUP.Day_Phone_A 				as Day_Phone_A, 
	DUP.Alt_Phone_A 				as Alt_Phone_A, 
	DUP.Cell_Phone_A 				as Cell_Phone_A, 
	DUP.Create_Timestamp_A 				as Create_Date_A, 
	(ua.first_name + ' ' + ua.last_name)		as Creator_A,

	DUP.Person_Nbr_B 				as Person_Nbr_B, 
	ptb.med_rec_nbr 				as MRN_B, 
	DUP.First_Name_B 				as First_Name_B, 
	DUP.Last_Name_B 				as Last_Name_B, 
	DUP.DOB_B 					as DOB_B, 
	DUP.Zip_B 					as Zip_B, 
	DUP.Home_Phone_B 				as Home_Phone_B, 
	DUP.Day_Phone_B 				as Day_Phone_B, 
	DUP.Alt_Phone_B 				as Alt_Phone_B, 
	DUP.Cell_Phone_B 				as Cell_Phone_B, 
	DUP.Create_Timestamp_B 				as Create_Date_B, 
	(ub.first_name + ' ' + ub.last_name)		as Creator_B

FROM (SELECT 
    	a.person_id                     						as Person_Id_A,
    	a.created_by                     						as Creator_A,
	a.person_nbr 									as Person_Nbr_A, 
	a.first_name 									as First_Name_A, 
	a.last_name 									as Last_Name_A, 
	dbo.fn_convertdate_slashes(a.date_of_birth) 					as DOB_A, 
	a.zip 										as Zip_A, 
	a.home_phone 									as Home_Phone_A, 
	a.day_phone 									as Day_Phone_A, 
	a.alt_phone 									as Alt_Phone_A, 
	a.cell_phone 									as Cell_Phone_A, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),a.create_timestamp, 112)) 	as Create_Timestamp_A, 

    	b.person_id                     						as Person_Id_B,
    	b.created_by                     						as Creator_B,
	b.person_nbr 									as Person_Nbr_B, 
	b.first_name 									as First_Name_B, 
	b.last_name 									as Last_Name_B, 
	dbo.fn_convertdate_slashes(b.date_of_birth) 					as DOB_B, 
	b.zip 										as Zip_B, 
	b.home_phone 									as Home_Phone_B, 
	b.day_phone 									as Day_Phone_B, 
	b.alt_phone 									as Alt_Phone_B, 
	b.cell_phone 									as Cell_Phone_B, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),b.create_timestamp, 112)) 	as Create_Timestamp_B 

	FROM person a, person b

	WHERE 
		a.first_name=b.first_name 
		and a.last_name<>b.last_name 
		and a.date_of_birth=b.date_of_birth 
		and a.zip<>b.zip
		and (
    			(a.home_phone<>'' and a.home_phone IS NOT NULL and (
    				a.home_phone=b.home_phone or a.home_phone=b.day_phone or a.home_phone=b.cell_phone or a.home_phone=b.alt_phone))
    			or (a.day_phone<>'' and a.day_phone IS NOT NULL and (
    				a.day_phone=b.home_phone or a.day_phone=b.day_phone or a.day_phone=b.cell_phone or a.day_phone=b.alt_phone))
    			or (a.cell_phone<>'' and a.cell_phone IS NOT NULL and (
    				a.cell_phone=b.home_phone or a.cell_phone=b.day_phone or a.cell_phone=b.cell_phone or a.cell_phone=b.alt_phone))
    			or (a.alt_phone<>'' and a.alt_phone IS NOT NULL and (
    				a.alt_phone=b.home_phone or a.alt_phone=b.day_phone or a.alt_phone=b.cell_phone or a.alt_phone=b.alt_phone))
    		)
		and a.person_nbr<>b.person_nbr 
		and a.create_timestamp < b.create_timestamp

	) DUP

JOIN patient pta on DUP.Person_Id_A=pta.person_id
JOIN patient ptb on DUP.Person_Id_B=ptb.person_id
JOIN user_mstr ua on DUP.Creator_A=ua.user_id
JOIN user_mstr ub on DUP.Creator_B=ub.user_id

--End Same First Name, DOB, and one of the phone numbers 
--but 
--Different Last Name, Zip
-----------------------------------------------------------------------------------------------------

--Same Last Name, DOB and one of the phone numbers 
--but 
--Different First Name, Zip
Select 
	DUP.Person_Nbr_A 				as Person_Nbr_A, 
	pta.med_rec_nbr 				as MRN_A, 
	DUP.First_Name_A 				as First_Name_A, 
	DUP.Last_Name_A 				as Last_Name_A, 
	DUP.DOB_A 					as DOB_A, 
	DUP.Zip_A 					as Zip_A, 
	DUP.Home_Phone_A 				as Home_Phone_A, 
	DUP.Day_Phone_A 				as Day_Phone_A, 
	DUP.Alt_Phone_A 				as Alt_Phone_A, 
	DUP.Cell_Phone_A 				as Cell_Phone_A, 
	DUP.Create_Timestamp_A 				as Create_Date_A, 
	(ua.first_name + ' ' + ua.last_name)		as Creator_A,

	DUP.Person_Nbr_B 				as Person_Nbr_B, 
	ptb.med_rec_nbr 				as MRN_B, 
	DUP.First_Name_B 				as First_Name_B, 
	DUP.Last_Name_B 				as Last_Name_B, 
	DUP.DOB_B 					as DOB_B, 
	DUP.Zip_B 					as Zip_B, 
	DUP.Home_Phone_B 				as Home_Phone_B, 
	DUP.Day_Phone_B 				as Day_Phone_B, 
	DUP.Alt_Phone_B 				as Alt_Phone_B, 
	DUP.Cell_Phone_B 				as Cell_Phone_B, 
	DUP.Create_Timestamp_B 				as Create_Date_B, 
	(ub.first_name + ' ' + ub.last_name)		as Creator_B

FROM (SELECT 
    	a.person_id                     						as Person_Id_A,
    	a.created_by                     						as Creator_A,
	a.person_nbr 									as Person_Nbr_A, 
	a.first_name 									as First_Name_A, 
	a.last_name 									as Last_Name_A, 
	dbo.fn_convertdate_slashes(a.date_of_birth) 					as DOB_A, 
	a.zip 										as Zip_A, 
	a.home_phone 									as Home_Phone_A, 
	a.day_phone 									as Day_Phone_A, 
	a.alt_phone 									as Alt_Phone_A, 
	a.cell_phone 									as Cell_Phone_A, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),a.create_timestamp, 112)) 	as Create_Timestamp_A, 

    	b.person_id                     						as Person_Id_B,
    	b.created_by                     						as Creator_B,
	b.person_nbr 									as Person_Nbr_B, 
	b.first_name 									as First_Name_B, 
	b.last_name 									as Last_Name_B, 
	dbo.fn_convertdate_slashes(b.date_of_birth) 					as DOB_B, 
	b.zip 										as Zip_B, 
	b.home_phone 									as Home_Phone_B, 
	b.day_phone 									as Day_Phone_B, 
	b.alt_phone 									as Alt_Phone_B, 
	b.cell_phone 									as Cell_Phone_B, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),b.create_timestamp, 112)) 	as Create_Timestamp_B 

	FROM person a, person b

	WHERE 
		a.first_name<>b.first_name 
		and a.last_name=b.last_name 
		and a.date_of_birth=b.date_of_birth 
		and a.zip<>b.zip
		and (
    			(a.home_phone<>'' and a.home_phone IS NOT NULL and (
    				a.home_phone=b.home_phone or a.home_phone=b.day_phone or a.home_phone=b.cell_phone or a.home_phone=b.alt_phone))
    			or (a.day_phone<>'' and a.day_phone IS NOT NULL and (
    				a.day_phone=b.home_phone or a.day_phone=b.day_phone or a.day_phone=b.cell_phone or a.day_phone=b.alt_phone))
    			or (a.cell_phone<>'' and a.cell_phone IS NOT NULL and (
    				a.cell_phone=b.home_phone or a.cell_phone=b.day_phone or a.cell_phone=b.cell_phone or a.cell_phone=b.alt_phone))
    			or (a.alt_phone<>'' and a.alt_phone IS NOT NULL and (
    				a.alt_phone=b.home_phone or a.alt_phone=b.day_phone or a.alt_phone=b.cell_phone or a.alt_phone=b.alt_phone))
    		)
		and a.person_nbr<>b.person_nbr 
		and a.create_timestamp < b.create_timestamp

	) DUP

JOIN patient pta on DUP.Person_Id_A=pta.person_id
JOIN patient ptb on DUP.Person_Id_B=ptb.person_id
JOIN user_mstr ua on DUP.Creator_A=ua.user_id
JOIN user_mstr ub on DUP.Creator_B=ub.user_id

--End Same Last Name, DOB, and one of the phone numbers 
--but 
--Different First Name, Zip
-----------------------------------------------------------------------------------------------------

--Same First Name, Last Name, DOB
--but 
--Different Zip and Phone Numbers
Select 
	DUP.Person_Nbr_A 				as Person_Nbr_A, 
	pta.med_rec_nbr 				as MRN_A, 
	DUP.First_Name_A 				as First_Name_A, 
	DUP.Last_Name_A 				as Last_Name_A, 
	DUP.DOB_A 					as DOB_A, 
	DUP.Zip_A 					as Zip_A, 
	DUP.Home_Phone_A 				as Home_Phone_A, 
	DUP.Day_Phone_A 				as Day_Phone_A, 
	DUP.Alt_Phone_A 				as Alt_Phone_A, 
	DUP.Cell_Phone_A 				as Cell_Phone_A, 
	DUP.Create_Timestamp_A 				as Create_Date_A, 
	(ua.first_name + ' ' + ua.last_name)		as Creator_A,

	DUP.Person_Nbr_B 				as Person_Nbr_B, 
	ptb.med_rec_nbr 				as MRN_B, 
	DUP.First_Name_B 				as First_Name_B, 
	DUP.Last_Name_B 				as Last_Name_B, 
	DUP.DOB_B 					as DOB_B, 
	DUP.Zip_B 					as Zip_B, 
	DUP.Home_Phone_B 				as Home_Phone_B, 
	DUP.Day_Phone_B 				as Day_Phone_B, 
	DUP.Alt_Phone_B 				as Alt_Phone_B, 
	DUP.Cell_Phone_B 				as Cell_Phone_B, 
	DUP.Create_Timestamp_B 				as Create_Date_B, 
	(ub.first_name + ' ' + ub.last_name)		as Creator_B

FROM (SELECT 
    	a.person_id                     						as Person_Id_A,
    	a.created_by                     						as Creator_A,
	a.person_nbr 									as Person_Nbr_A, 
	a.first_name 									as First_Name_A, 
	a.last_name 									as Last_Name_A, 
	dbo.fn_convertdate_slashes(a.date_of_birth) 					as DOB_A, 
	a.zip 										as Zip_A, 
	a.home_phone 									as Home_Phone_A, 
	a.day_phone 									as Day_Phone_A, 
	a.alt_phone 									as Alt_Phone_A, 
	a.cell_phone 									as Cell_Phone_A, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),a.create_timestamp, 112)) 	as Create_Timestamp_A, 

    	b.person_id                     						as Person_Id_B,
    	b.created_by                     						as Creator_B,
	b.person_nbr 									as Person_Nbr_B, 
	b.first_name 									as First_Name_B, 
	b.last_name 									as Last_Name_B, 
	dbo.fn_convertdate_slashes(b.date_of_birth) 					as DOB_B, 
	b.zip 										as Zip_B, 
	b.home_phone 									as Home_Phone_B, 
	b.day_phone 									as Day_Phone_B, 
	b.alt_phone 									as Alt_Phone_B, 
	b.cell_phone 									as Cell_Phone_B, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),b.create_timestamp, 112)) 	as Create_Timestamp_B 

	FROM person a, person b

	WHERE 
		a.first_name=b.first_name 
		and a.last_name=b.last_name 
		and a.date_of_birth=b.date_of_birth 
		and a.zip<>b.zip
		and (a.home_phone='' or a.home_phone IS NULL 
			or (a.home_phone<>b.home_phone and a.home_phone<>b.day_phone and a.home_phone<>b.cell_phone and a.home_phone<>b.alt_phone))
		and (a.day_phone='' or a.day_phone IS NULL 
			or (a.day_phone<>b.home_phone and a.day_phone<>b.day_phone and a.day_phone<>b.cell_phone and a.day_phone<>b.alt_phone))
		and (a.cell_phone='' or a.cell_phone IS NULL 
			or (a.cell_phone<>b.home_phone and a.cell_phone<>b.day_phone and a.cell_phone<>b.cell_phone and a.cell_phone<>b.alt_phone))
		and (a.alt_phone='' or a.alt_phone IS NULL 
			or (a.alt_phone<>b.home_phone and a.alt_phone<>b.day_phone and a.alt_phone<>b.cell_phone and a.alt_phone<>b.alt_phone))
		
		and a.person_nbr<>b.person_nbr 
		and a.create_timestamp < b.create_timestamp

	) DUP

JOIN patient pta on DUP.Person_Id_A=pta.person_id
JOIN patient ptb on DUP.Person_Id_B=ptb.person_id
JOIN user_mstr ua on DUP.Creator_A=ua.user_id
JOIN user_mstr ub on DUP.Creator_B=ub.user_id

--End Same First Name, Last Name, DOB
--but 
--Different Zip and Phone Numbers
-----------------------------------------------------------------------------------------------------


--Same First Name, DOB and Zip
--but 
--Different Last Name and Phone Numbers
Select 
	DUP.Person_Nbr_A 				as Person_Nbr_A, 
	pta.med_rec_nbr 				as MRN_A, 
	DUP.First_Name_A 				as First_Name_A, 
	DUP.Last_Name_A 				as Last_Name_A, 
	DUP.DOB_A 					as DOB_A, 
	DUP.Zip_A 					as Zip_A, 
	DUP.Home_Phone_A 				as Home_Phone_A, 
	DUP.Day_Phone_A 				as Day_Phone_A, 
	DUP.Alt_Phone_A 				as Alt_Phone_A, 
	DUP.Cell_Phone_A 				as Cell_Phone_A, 
	DUP.Create_Timestamp_A 				as Create_Date_A, 
	(ua.first_name + ' ' + ua.last_name)		as Creator_A,

	DUP.Person_Nbr_B 				as Person_Nbr_B, 
	ptb.med_rec_nbr 				as MRN_B, 
	DUP.First_Name_B 				as First_Name_B, 
	DUP.Last_Name_B 				as Last_Name_B, 
	DUP.DOB_B 					as DOB_B, 
	DUP.Zip_B 					as Zip_B, 
	DUP.Home_Phone_B 				as Home_Phone_B, 
	DUP.Day_Phone_B 				as Day_Phone_B, 
	DUP.Alt_Phone_B 				as Alt_Phone_B, 
	DUP.Cell_Phone_B 				as Cell_Phone_B, 
	DUP.Create_Timestamp_B 				as Create_Date_B, 
	(ub.first_name + ' ' + ub.last_name)		as Creator_B

FROM (SELECT 
    	a.person_id                     						as Person_Id_A,
    	a.created_by                     						as Creator_A,
	a.person_nbr 									as Person_Nbr_A, 
	a.first_name 									as First_Name_A, 
	a.last_name 									as Last_Name_A, 
	dbo.fn_convertdate_slashes(a.date_of_birth) 					as DOB_A, 
	a.zip 										as Zip_A, 
	a.home_phone 									as Home_Phone_A, 
	a.day_phone 									as Day_Phone_A, 
	a.alt_phone 									as Alt_Phone_A, 
	a.cell_phone 									as Cell_Phone_A, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),a.create_timestamp, 112)) 	as Create_Timestamp_A, 

    	b.person_id                     						as Person_Id_B,
    	b.created_by                     						as Creator_B,
	b.person_nbr 									as Person_Nbr_B, 
	b.first_name 									as First_Name_B, 
	b.last_name 									as Last_Name_B, 
	dbo.fn_convertdate_slashes(b.date_of_birth) 					as DOB_B, 
	b.zip 										as Zip_B, 
	b.home_phone 									as Home_Phone_B, 
	b.day_phone 									as Day_Phone_B, 
	b.alt_phone 									as Alt_Phone_B, 
	b.cell_phone 									as Cell_Phone_B, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),b.create_timestamp, 112)) 	as Create_Timestamp_B 

	FROM person a, person b

	WHERE 
		a.first_name=b.first_name 
		and a.last_name<>b.last_name 
		and a.date_of_birth=b.date_of_birth 
		and a.zip=b.zip
		and (a.home_phone='' or a.home_phone IS NULL 
			or (a.home_phone<>b.home_phone and a.home_phone<>b.day_phone and a.home_phone<>b.cell_phone and a.home_phone<>b.alt_phone))
		and (a.day_phone='' or a.day_phone IS NULL 
			or (a.day_phone<>b.home_phone and a.day_phone<>b.day_phone and a.day_phone<>b.cell_phone and a.day_phone<>b.alt_phone))
		and (a.cell_phone='' or a.cell_phone IS NULL 
			or (a.cell_phone<>b.home_phone and a.cell_phone<>b.day_phone and a.cell_phone<>b.cell_phone and a.cell_phone<>b.alt_phone))
		and (a.alt_phone='' or a.alt_phone IS NULL 
			or (a.alt_phone<>b.home_phone and a.alt_phone<>b.day_phone and a.alt_phone<>b.cell_phone and a.alt_phone<>b.alt_phone))
		
		and a.person_nbr<>b.person_nbr 
		and a.create_timestamp < b.create_timestamp

	) DUP

JOIN patient pta on DUP.Person_Id_A=pta.person_id
JOIN patient ptb on DUP.Person_Id_B=ptb.person_id
JOIN user_mstr ua on DUP.Creator_A=ua.user_id
JOIN user_mstr ub on DUP.Creator_B=ub.user_id

--End Same First Name, DOB and Zip
--but 
--Different Last Name and Phone Numbers
-----------------------------------------------------------------------------------------------------


--Same Last Name, DOB and Zip
--but 
--Different First Name and Phone Numbers
Select 
	DUP.Person_Nbr_A 				as Person_Nbr_A, 
	pta.med_rec_nbr 				as MRN_A, 
	DUP.First_Name_A 				as First_Name_A, 
	DUP.Last_Name_A 				as Last_Name_A, 
	DUP.DOB_A 					as DOB_A, 
	DUP.Zip_A 					as Zip_A, 
	DUP.Home_Phone_A 				as Home_Phone_A, 
	DUP.Day_Phone_A 				as Day_Phone_A, 
	DUP.Alt_Phone_A 				as Alt_Phone_A, 
	DUP.Cell_Phone_A 				as Cell_Phone_A, 
	DUP.Create_Timestamp_A 				as Create_Date_A, 
	(ua.first_name + ' ' + ua.last_name)		as Creator_A,

	DUP.Person_Nbr_B 				as Person_Nbr_B, 
	ptb.med_rec_nbr 				as MRN_B, 
	DUP.First_Name_B 				as First_Name_B, 
	DUP.Last_Name_B 				as Last_Name_B, 
	DUP.DOB_B 					as DOB_B, 
	DUP.Zip_B 					as Zip_B, 
	DUP.Home_Phone_B 				as Home_Phone_B, 
	DUP.Day_Phone_B 				as Day_Phone_B, 
	DUP.Alt_Phone_B 				as Alt_Phone_B, 
	DUP.Cell_Phone_B 				as Cell_Phone_B, 
	DUP.Create_Timestamp_B 				as Create_Date_B, 
	(ub.first_name + ' ' + ub.last_name)		as Creator_B

FROM (SELECT 
    	a.person_id                     						as Person_Id_A,
    	a.created_by                     						as Creator_A,
	a.person_nbr 									as Person_Nbr_A, 
	a.first_name 									as First_Name_A, 
	a.last_name 									as Last_Name_A, 
	dbo.fn_convertdate_slashes(a.date_of_birth) 					as DOB_A, 
	a.zip 										as Zip_A, 
	a.home_phone 									as Home_Phone_A, 
	a.day_phone 									as Day_Phone_A, 
	a.alt_phone 									as Alt_Phone_A, 
	a.cell_phone 									as Cell_Phone_A, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),a.create_timestamp, 112)) 	as Create_Timestamp_A, 

    	b.person_id                     						as Person_Id_B,
    	b.created_by                     						as Creator_B,
	b.person_nbr 									as Person_Nbr_B, 
	b.first_name 									as First_Name_B, 
	b.last_name 									as Last_Name_B, 
	dbo.fn_convertdate_slashes(b.date_of_birth) 					as DOB_B, 
	b.zip 										as Zip_B, 
	b.home_phone 									as Home_Phone_B, 
	b.day_phone 									as Day_Phone_B, 
	b.alt_phone 									as Alt_Phone_B, 
	b.cell_phone 									as Cell_Phone_B, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),b.create_timestamp, 112)) 	as Create_Timestamp_B 

	FROM person a, person b

	WHERE 
		a.first_name<>b.first_name 
		and a.last_name=b.last_name 
		and a.date_of_birth=b.date_of_birth 
		and a.zip=b.zip
		and (a.home_phone='' or a.home_phone IS NULL 
			or (a.home_phone<>b.home_phone and a.home_phone<>b.day_phone and a.home_phone<>b.cell_phone and a.home_phone<>b.alt_phone))
		and (a.day_phone='' or a.day_phone IS NULL 
			or (a.day_phone<>b.home_phone and a.day_phone<>b.day_phone and a.day_phone<>b.cell_phone and a.day_phone<>b.alt_phone))
		and (a.cell_phone='' or a.cell_phone IS NULL 
			or (a.cell_phone<>b.home_phone and a.cell_phone<>b.day_phone and a.cell_phone<>b.cell_phone and a.cell_phone<>b.alt_phone))
		and (a.alt_phone='' or a.alt_phone IS NULL 
			or (a.alt_phone<>b.home_phone and a.alt_phone<>b.day_phone and a.alt_phone<>b.cell_phone and a.alt_phone<>b.alt_phone))
		
		and a.person_nbr<>b.person_nbr 
		and a.create_timestamp < b.create_timestamp

	) DUP

JOIN patient pta on DUP.Person_Id_A=pta.person_id
JOIN patient ptb on DUP.Person_Id_B=ptb.person_id
JOIN user_mstr ua on DUP.Creator_A=ua.user_id
JOIN user_mstr ub on DUP.Creator_B=ub.user_id

--End Same Last Name, DOB and Zip
--but 
--Different First Name and Phone Numbers
-----------------------------------------------------------------------------------------------------

--***Same first name and day phone with an encounter***
drop table #temp

Select 
	DUP.Person_ID_A 				as Person_Id_A, 
	pta.med_rec_nbr 				as MRN_A, 
	DUP.First_Name_A 				as First_Name_A, 
	DUP.Last_Name_A 				as Last_Name_A, 
	DUP.DOB_A 					as DOB_A, 
	DUP.Day_Phone_A 				as Day_Phone_A,
	DUP.Create_Timestamp_A 				as Create_Date_A,
	(ua.first_name + ' ' + ua.last_name)		as Creator_A,


	DUP.Person_ID_B 				as Person_Id_B,  
	ptb.med_rec_nbr 				as MRN_B, 
	DUP.First_Name_B 				as First_Name_B, 
	DUP.Last_Name_B 				as Last_Name_B, 
	DUP.DOB_B 					as DOB_B, 
	DUP.Day_Phone_B 				as Day_Phone_B, 
	DUP.Create_Timestamp_B 				as Create_Date_B, 
	(ub.first_name + ' ' + ub.last_name)		as Creator_B

into #temp
	
FROM (SELECT 
    	a.person_id                     						as Person_Id_A,
    	a.created_by                     						as Creator_A,
	a.person_nbr 									as Person_Nbr_A, 
	a.first_name 									as First_Name_A, 
	a.last_name 									as Last_Name_A, 
	dbo.fn_convertdate_slashes(a.date_of_birth) 					as DOB_A, 
	a.day_phone 									as Day_Phone_A, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),a.create_timestamp, 112)) 	as Create_Timestamp_A,


    	b.person_id                     						as Person_Id_B,
    	b.created_by                     						as Creator_B,
	b.person_nbr 									as Person_Nbr_B, 
	b.first_name 									as First_Name_B, 
	b.last_name 									as Last_Name_B, 
	dbo.fn_convertdate_slashes(b.date_of_birth) 					as DOB_B, 
	b.day_phone 									as Day_Phone_B, 
	dbo.fn_convertdate_slashes(CONVERT(varchar(10),b.create_timestamp, 112)) 	as Create_Timestamp_B


	FROM person a, person b

	

	WHERE 
	--exclude blank, all 0, and our phone number
	a.day_phone != '6198814500' and b.day_phone != '6198814500' and a.day_phone != '8002307526' and b.day_phone != '8002307526'
	and a.day_phone != '0000000000' and b.day_phone != '0000000000' and a.day_phone != '7600000000' and b.day_phone != '7600000000'
	and a.day_phone != '6190000000' and b.day_phone != '6190000000' and b.day_phone is not NULL and a.day_phone is not NULL
	and a.day_phone != '' and b.day_phone != ''
	--exclude test and anonymous patients
	and a.first_name != 'Test' and b.first_name != 'Test' and a.first_name != 'Female' and b.first_name != 'Female'  
	and a.first_name not like '%HIV%' and b.first_name not like '%HIV%' and a.first_name != 'Male' and b.first_name != 'Male'
	--similar first names, different person nbr, same day phone
	and a.first_name like b.first_name and a.create_timestamp < b.create_timestamp	and a.person_nbr<>b.person_nbr 	and a.day_phone = 	b.day_phone
			
	) DUP
	
JOIN patient pta on DUP.Person_Id_A=pta.person_id
JOIN patient ptb on DUP.Person_Id_B=ptb.person_id
JOIN user_mstr ua on DUP.Creator_A=ua.user_id
JOIN user_mstr ub on DUP.Creator_B=ub.user_id


select distinct

MRN_A, First_Name_A, Last_Name_A, DOB_A, Day_Phone_A, Create_Date_A, Creator_A, MRN_B, 
First_Name_B, Last_Name_B, DOB_B, Day_Phone_B, Create_Date_B, Creator_B 

from #temp t
JOIN appointments apa on t.Person_Id_A=apa.person_id
where apa.enc_id is not NULL