drop table #temp1

DECLARE @Start_Date_1 datetime
DECLARE @End_Date_1 Datetime

SET @Start_Date_1 = '20160101'
SET @End_Date_1 = '20160201'

SELECT pp.enc_id, pp.person_id, 
       pp.diagnosis_code_id_1, pp.diagnosis_code_id_2, pp.diagnosis_code_id_3, pp.diagnosis_code_id_4, 
       pp.service_item_id, pp.service_date, pe.location_id
INTO #temp1
FROM patient_procedure pp
JOIN patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN person	p			  ON pp.person_id = p.person_id
WHERE (pp.service_date >= @Start_Date_1 AND pp.service_date <= @End_Date_1)

--Creates temp 2 and concatenates same encounters on multiple rows into a single with all service items 
--drop table #temp3
SELECT enc_id, person_id, service_date, location_id,
	(SELECT ' ' + t2.service_item_id
	FROM #temp1 t2
	WHERE t2.enc_id = t1.enc_id
	FOR XML PATH('')) [Service_Item],
	(SELECT ' ' + t2.diagnosis_code_id_1 + ' ' + t2.diagnosis_code_id_2 + ' ' + t2.diagnosis_code_id_3 + ' ' + t2.diagnosis_code_id_4
	FROM #temp1 t2
	WHERE t2.enc_id = t1.enc_id
	FOR XML PATH('')) [dx]
INTO #temp2
FROM #temp1 t1
GROUP BY t1.enc_id, t1.person_id, service_date, location_id
--drop table #temp3

select * from #temp2
where Service_Item LIKE '%11981%' --and Service_Item LIKE '%58100%'

SELECT DISTINCT t2.enc_id, t2.service_date, lm.location_name,
CASE
	WHEN (Service_Item LIKE '%59840A%' OR Service_Item LIKE '%59841[C-N]%') THEN 'TAB'
	WHEN Service_Item LIKE '%S0199%' OR Service_Item LIKE '%S0199A%' THEN 'MAB'
END AS [Appointment Type]
INTO #temp3
FROM #temp2 t2
JOIN location_mstr lm ON lm.location_id = t2.location_id
WHERE 
(	Service_Item LIKE '%59840A%' --TAB
OR  Service_Item LIKE '%59841[C-N]%' --TAB
OR  Service_Item LIKE '%S0199%' --MAB
OR  Service_Item LIKE '%S0199A%' --MAB
) order by location_name, service_date, enc_id

--INSERT INTO #ab_count
--VALUES 
-- (2006, 'Jan', null)
--,(2006, 'Feb', null)
--,(2006, 'Mar', null)
--,(2006, 'Apr', null)
--,(2006, 'May', null)
--,(2006, 'Jun', null)
--,(2006, 'Jul', null)
--,(2006, 'Aug', null)
--,(2006, 'Sept', null)
--,(2006, 'Oct', null)
--,(2006, 'Nov', null)
--,(2006, 'Dec', null)
--,(2007, 'Jan', null)
--,(2007, 'Feb', null)
--,(2007, 'Mar', null)
--,(2007, 'Apr', null)
--,(2007, 'May', null)
--,(2007, 'Jun', null)
--,(2007, 'Jul', null)
--,(2007, 'Aug', null)
--,(2007, 'Sept', null)
--,(2007, 'Oct', null)
--,(2007, 'Nov', null)
--,(2007, 'Dec', null)
--,(2008, 'Jan', null)
--,(2008, 'Feb', null)
--,(2008, 'Mar', null)
--,(2008, 'Apr', null)
--,(2008, 'May', null)
--,(2008, 'Jun', null)
--,(2008, 'Jul', null)
--,(2008, 'Aug', null)
--,(2008, 'Sept', null)
--,(2008, 'Oct', null)
--,(2008, 'Nov', null)
--,(2008, 'Dec', null)
--,(2009, 'Jan', null)
--,(2009, 'Feb', null)
--,(2009, 'Mar', null)
--,(2009, 'Apr', null)
--,(2009, 'May', null)
--,(2009, 'Jun', null)
--,(2009, 'Jul', null)
--,(2009, 'Aug', null)
--,(2009, 'Sept', null)
--,(2009, 'Oct', null)
--,(2009, 'Nov', null)
--,(2009, 'Dec', null)
--,(2010, 'Jan', null)
--,(2010, 'Feb', null)
--,(2010, 'Mar', null)
--,(2010, 'Apr', null)
--,(2010, 'May', null)
--,(2010, 'Jun', null)
--,(2010, 'Jul', null)
--,(2010, 'Aug', null)
--,(2010, 'Sept', null)
--,(2010, 'Oct', null)
--,(2010, 'Nov', null)
--,(2010, 'Dec', null)
--,(2011, 'Jan', null)
--,(2011, 'Feb', null)
--,(2011, 'Mar', null)
--,(2011, 'Apr', null)
--,(2011, 'May', null)
--,(2011, 'Jun', null)
--,(2011, 'Jul', null)
--,(2011, 'Aug', null)
--,(2011, 'Sept', null)
--,(2011, 'Oct', null)
--,(2011, 'Nov', null)
--,(2011, 'Dec', null)
--,(2012, 'Jan', null)
--,(2012, 'Feb', null)
--,(2012, 'Mar', null)
--,(2012, 'Apr', null)
--,(2012, 'May', null)
--,(2012, 'Jun', null)
--,(2012, 'Jul', null)
--,(2012, 'Aug', null)
--,(2012, 'Sept', null)
--,(2012, 'Oct', null)
--,(2012, 'Nov', null)
--,(2012, 'Dec', null)
--,(2013, 'Jan', null)
--,(2013, 'Feb', null)
--,(2013, 'Mar', null)
--,(2013, 'Apr', null)
--,(2013, 'May', null)
--,(2013, 'Jun', null)
--,(2013, 'Jul', null)
--,(2013, 'Aug', null)
--,(2013, 'Sept', null)
--,(2013, 'Oct', null)
--,(2013, 'Nov', null)
--,(2013, 'Dec', null)
--,(2014, 'Jan', null)
--,(2014, 'Feb', null)
--,(2014, 'Mar', null)
--,(2014, 'Apr', null)
--,(2014, 'May', null)
--,(2014, 'Jun', null)
--,(2014, 'Jul', null)
--,(2014, 'Aug', null)
--,(2014, 'Sept', null)
--,(2014, 'Oct', null)
--,(2014, 'Nov', null)
--,(2014, 'Dec', null)
--,(2015, 'Jan', null)
--,(2015, 'Feb', null)
--,(2015, 'Mar', null)
--,(2015, 'Apr', null)
--,(2015, 'May', null)
--,(2015, 'Jun', null)
--,(2015, 'Jul', null)
--,(2015, 'Aug', null)
--,(2015, 'Sept', null)
--,(2015, 'Oct', null)
--,(2015, 'Nov', null)
--,(2015, 'Dec', null)
--,(2016, 'Jan', null)
--,(2016, 'Feb', null)
--,(2016, 'Mar', null)
--,(2016, 'Apr', null)
--,(2016, 'May', null)
--,(2016, 'Jun', null)
--,(2016, 'Jul', null)
--,(2016, 'Aug', null)
--,(2016, 'Sept', null)
--,(2016, 'Oct', null)
--,(2016, 'Nov', null)
--,(2016, 'Dec', null)
--,(2017, 'Jan', null)
--,(2017, 'Feb', null)
--,(2017, 'Mar', null)
--,(2017, 'Apr', null)
--,(2017, 'May', null)
--,(2017, 'Jun', null)
--,(2017, 'Jul', null)
--,(2017, 'Aug', null)
--,(2017, 'Sept', null)
--,(2017, 'Oct', null)
--,(2017, 'Nov', null)
--,(2017, 'Dec', null)


--select DISTINCT
--(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20130101' AND service_date <= '20130201') AS [Jan 2013] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20130201' AND service_date <= '20130301') AS [Feb 2013]
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20130301' AND service_date <= '20130401') AS [Mar 2013] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20130401' AND service_date <= '20130501') AS [Apr 2013] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20130501' AND service_date <= '20130601') AS [May 2013] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20130601' AND service_date <= '20130701') AS [June 2013]
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20130701' AND service_date <= '20130801') AS [July 2013] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20130801' AND service_date <= '20130901') AS [Aug 2013]
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20130901' AND service_date <= '20131001') AS [Sept 2013] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20131001' AND service_date <= '20131101') AS [Oct 2013]
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20131101' AND service_date <= '20131201') AS [Nov 2013] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20131201' AND service_date <= '20140101') AS [Dec 2013]
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20140101' AND service_date <= '20140201') AS [Jan 2014] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20140201' AND service_date <= '20140301') AS [Feb 2014]
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20140301' AND service_date <= '20140401') AS [Mar 2014] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20140401' AND service_date <= '20140501') AS [Apr 2014] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20140501' AND service_date <= '20140601') AS [May 2014] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20140601' AND service_date <= '20140701') AS [June 2014]
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20140701' AND service_date <= '20140801') AS [July 2014] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20140801' AND service_date <= '20140901') AS [Aug 2014]
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20140901' AND service_date <= '20141001') AS [Sept 2014] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20141001' AND service_date <= '20141101') AS [Oct 2014]
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20141101' AND service_date <= '20141201') AS [Nov 2014] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20141201' AND service_date <= '20150101') AS [Dec 2014]
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20150101' AND service_date <= '20150201') AS [Jan 2015] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20150201' AND service_date <= '20150301') AS [Feb 2015]
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20150301' AND service_date <= '20150401') AS [Mar 2015] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20150401' AND service_date <= '20150501') AS [Apr 2015] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20150501' AND service_date <= '20150601') AS [May 2015] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20150601' AND service_date <= '20150701') AS [June 2015]
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20150701' AND service_date <= '20150801') AS [July 2015] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20150801' AND service_date <= '20150901') AS [Aug 2015]
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20150901' AND service_date <= '20151001') AS [Sept 2015] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20151001' AND service_date <= '20151101') AS [Oct 2015]
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20151101' AND service_date <= '20151201') AS [Nov 2015] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20151201' AND service_date <= '20160101') AS [Dec 2015]
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20160101' AND service_date <= '20160201') AS [Jan 2016] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20160201' AND service_date <= '20160301') AS [Feb 2016]
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20160301' AND service_date <= '20160401') AS [Mar 2016] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20160401' AND service_date <= '20160501') AS [Apr 2016] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20160501' AND service_date <= '20160601') AS [May 2016] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20160601' AND service_date <= '20160701') AS [June 2016]
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20160701' AND service_date <= '20160801') AS [July 2016] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20160801' AND service_date <= '20160901') AS [Aug 2016]
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20160901' AND service_date <= '20161001') AS [Sept 2016] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20161001' AND service_date <= '20161101') AS [Oct 2016]
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20161101' AND service_date <= '20161201') AS [Nov 2016] 
--,(SELECT COUNT(*) FROM #temp3 WHERE service_date >= '20161201' AND service_date <= '20170101') AS [Dec 2016]
--from #temp3
--into #
--WHERE 

select YEAR(service_date)AS 'Year', DATENAME (MONTH, service_date) AS 'Month', COUNT(*) [Count]
from #temp3
GROUP BY  MONTH(service_date)--'Year', 'month', service_date
ORDER BY 'Year', 'month', service_date

select * from #temp3
--ave diff between creation and service date
avg datediff


select * from patient_encounter

SELECT DATENAME (MONTH, service_date) [Month]
from #temp3