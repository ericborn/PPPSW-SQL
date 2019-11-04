--DROP TABLE #temp
--DROP TABLE #temp2

DECLARE @Start_Date DATETIME
DECLARE @End_Date DATETIME

SET @Start_Date = '20180101'
SET @End_Date   = '20180131'

--Table stores data where encounter is active
CREATE TABLE #temp
(
 [enc_id] UNIQUEIDENTIFIER
,[enc_nbr] INT
,[DOS] DATE
,[enc_date] DATE
,[billable] VARCHAR(1)
,[clinical] VARCHAR(1)
,[Status] VARCHAR(50)
)

--Table stores data where encounter is deleted/merged/supressed
CREATE TABLE #temp2
(
 [enc_id] UNIQUEIDENTIFIER
,[enc_nbr] INT
,[DOS] DATE
,[enc_date] DATE
,[billable] VARCHAR(1)
,[clinical] VARCHAR(1)
,[Status] VARCHAR(50)
)

--Insert active encounters
INSERT INTO #temp
SELECT DISTINCT pe.enc_id, enc_nbr, NULL, pe.enc_timestamp, billable_ind, clinical_ind, 'Active'
FROM ngprod.dbo.patient_encounter pe
WHERE pe.create_timestamp BETWEEN @Start_Date AND @End_Date
ORDER BY enc_nbr

--Insert inactive encounters
--Uses udf_GetNumeric to drop text from the column and only include the numbers
INSERT INTO #temp2
SELECT DISTINCT 
NULL, ngprod.dbo.udf_GetNumeric(sig_msg), NULL, NULL, NULL, NULL, sig_msg
FROM ngprod.dbo.sig_events
WHERE create_timestamp BETWEEN @Start_Date AND @End_Date
AND (sig_msg LIKE 'encounter deleted%' OR sig_msg LIKE 'encounter merge%' 
 OR  sig_msg LIKE 'merge encounter%' )
 --Removed for causing duplicate entries. Supressed encounters still appear in patient_encounter table
 --OR sig_msg LIKE 'encounter suppress%')

--Find earliest active encounter during time period
DECLARE @nbr INT
SET @nbr = (SELECT MIN(enc_nbr) FROM #temp)

--Insert inactive data into active data table where encounter number is greater than lowest active encounter
INSERT INTO #temp
SELECT DISTINCT [enc_id],[enc_nbr],[DOS],[enc_date],[billable],[clinical],[Status]
FROM #temp2
WHERE enc_nbr > @nbr

UPDATE #temp
SET [DOS] = 
service_date
FROM ngprod.dbo.patient_procedure pp
JOIN #temp t ON pp.enc_id = t.enc_id

--Output
SELECT [enc_nbr],[DOS],[enc_date],[billable],[clinical],[Status]
FROM #temp
ORDER BY enc_nbr