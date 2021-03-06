--USE [ppreporting]
--GO
--/****** Object:  StoredProcedure [dbo].[colors]    Script Date: 3/1/2018 8:33:34 AM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

----============================================= 
---- Author:    Eric Born 
---- Create date: 1 February 2016 
---- Last Modified: 10 January 2018
---- Description: Created for Annual Report document that is created yearly

---- Change log:
---- 11 January 2018 - Added HIV test code 87806
---- =============================================

--ALTER proc [dbo].[colors]
--(
--	@color VARCHAR(10), -- Start of date range 
--	@age VARCHAR(10)	-- End of date range 
--)

--AS

--DROP TABLE #temp

DECLARE @age VARCHAR(10)
DECLARE @color VARCHAR(10)
SET @age   = 'Yes'
SET @color = 'Yes'

DECLARE @sqlCommand VARCHAR(1000)
DECLARE @columnList VARCHAR(100)

SET @columnList = 
CASE
	WHEN @color = 'Yes' AND @age = 'Yes' THEN 'color, age'
	WHEN @color = 'no'  AND @age = 'Yes' THEN 'age'
	WHEN @color = 'Yes' AND @age = 'No'  THEN 'color'
END

CREATE TABLE #temp
(
 [location] VARCHAR(20)
,[Color]    VARCHAR(20)
,[Age] INT
,[<18] INT
,[>18] INT
)

INSERT INTO #temp (location, Color, Age, [<18], [>18])
VALUES
 ('college','Blue', 20, NULL, NULL)
,('college','Green', 8, NULL, NULL)
,('city heights','Red', 60, NULL, NULL)
,('cochella','Orange', 5, NULL, NULL)
,('rancho','Blue', 1, NULL, NULL)

UPDATE #temp
SET [>18] = 1
--(
--SELECT COUNT(age)
WHERE Age >= 17
--)
--select * from #temp
SET @sqlCommand = 'SELECT location, ' + @columnList + ' FROM #temp'

SELECT * 
FROM #temp
WHERE age_ind = @age
AND color_ind = @color

DECLARE @output TABLE ([location] VARCHAR(20), [Color] VARCHAR(50), [Age] VARCHAR(50), [<18] INT, [>18] INT)
INSERT @output EXEC (@sqlCommand)
SELECT * FROM @output