--USE [ppreporting]
--GO
--/****** Object:  StoredProcedure [dbo].[Annual_Report]    Script Date: 2/28/2018 9:06:57 PM ******/
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

DECLARE @color VARCHAR(10)
DECLARE @age VARCHAR(10)
SET @color = 'Yes'
SET @age = 'no'

DECLARE @sqlCommand VARCHAR(1000)
DECLARE @columnList VARCHAR(100)

SET @columnList = 
CASE
	WHEN @color = 'Yes' AND @age = 'Yes' THEN 'color, age'
	WHEN @color = 'no' AND @age = 'Yes' THEN 'age'
	WHEN @color = 'Yes' AND @age = 'No' THEN 'color'
END

CREATE TABLE #temp
(
 Color VARCHAR(20)
,Age INT
)

INSERT INTO #temp (Color, Age)
VALUES
('Blue', 20)
,('Green', NULL)
,('Red', 60)
,(NULL, 5)

SET @sqlCommand = 'SELECT ' + @columnList + ' FROM #temp'

DECLARE @output TABLE ([Color] VARCHAR(50), [Age] VARCHAR(50))
INSERT @output EXEC (@sqlCommand)
SELECT * FROM @output