--drop TABLE #a

create table #a
(
appt_id uniqueidentifier,
msg varchar(max),
Language_Type varchar(30)
)

insert into #a
values
 ('5F40440C-BF4F-4A45-B157-9215971F3B52', '', '2 - English')
,('5F40440C-BF4F-4A45-B157-9215971F3B52', '', '3 - Spanish')

Update #a 
SET Msg = REPLACE(Replace('Thank you for scheduling an appointment on xxxxxxxx at xx:xx am/pm. You have opted-in for text reminders, charges from your carrier may apply. To opt-out reply ‘S’ to this message. This is an automated message, to contact us please call 1-888-743-7526.','xx:xx am/pm',right(convert(varchar,DateAdd(ss, 3600*(A.beginTime/100) + 60*((A.beginTime % 100)) , '19000101'),0),7))
, 'xxxxxxxx', CONVERT(VARCHAR(10),CAST(appt_date AS DATE), 110))
From NGProd.dbo.appointments A 
Where A.Appt_ID = #a.appt_Id AND Language_Type = '2 - English' 

Update #a 
SET Msg = REPLACE(Replace('Gracias por hacer una cita para el dia xxxxxxxx a las xx:xx am/pm. Ha optado recibir mensajes de texto; puede haber cargos extra de su compañía de teléfono. Para cancelar los mensajes responda ‘S’. Este es un mensaje automático; para comunicarse con nosotros, llame al 1-888-743-7526','xx:xx am/pm',right(convert(varchar,DateAdd(ss, 3600*(A.beginTime/100) + 60*((A.beginTime % 100)) , '19000101'),0),7))
, 'xxxxxxxx', CONVERT(VARCHAR(10),CAST(appt_date AS DATE), 105))
From NGProd.dbo.appointments A 
Where A.Appt_ID = #a.appt_Id AND Language_Type = '3 - Spanish' 

select * from #a



UPDATE #TempAppt 
SET Msg = 
REPLACE(REPLACE('Thank you for scheduling an appointment on xxxxxxxx at xx:xx am/pm. You have opted-in for text reminders, charges from your carrier may apply. To opt-out reply ‘S’ to this message. This is an automated message, to contact us please call 1-888-743-7526.','xx:xx am/pm',right(convert(varchar,DateAdd(ss, 3600*(A.beginTime/100) + 60*((A.beginTime % 100)) , '19000101'),0),7))
, 'xxxxxxxx', CONVERT(VARCHAR(10),CAST(appt_date AS DATE), 110))
From NGProd.dbo.appointments A 
Where A.Appt_ID = #TempAppt.appt_Id AND Language_Type = '2 - English' 
			
UPDATE #TempAppt 
SET Msg = REPLACE(REPLACE('Gracias por hacer una cita para el dia xxxxxxxx a las xx:xx am/pm. Ha optado recibir mensajes de texto; puede haber cargos extra de su compañía de teléfono. Para cancelar los mensajes responda ‘S’. Este es un mensaje automático; para comunicarse con nosotros, llame al 1-888-743-7526','xx:xx am/pm',right(convert(varchar,DateAdd(ss, 3600*(A.beginTime/100) + 60*((A.beginTime % 100)) , '19000101'),0),7))
, 'xxxxxxxx', CONVERT(VARCHAR(10),CAST(appt_date AS DATE), 105))
From NGProd.dbo.appointments A 
Where A.Appt_ID = #TempAppt.appt_Id AND Language_Type = '3 - Spanish'

