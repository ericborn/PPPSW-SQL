select *-- reason_for_visit 
from master_im_
where create_timestamp >= '20170101'


SELECT DISTINCT txt_reason_for_visit_2, COUNT(txt_reason_for_visit_2) AS [count]
--,txt_reason_for_visit_2
--,txt_reason_for_visit_3
--,txt_reason_for_visit_4
--,txt_reason_for_visit_5
--,txt_reason_for_visit_6
from reason_for_visit_
where create_timestamp >= '20170101'
GROUP BY txt_reason_for_visit_2
ORDER BY [count] DESC


USE ngprod
GO 
SELECT *
FROM sys.Tables
WHERE NAME LIKE 'hpi%'
ORDER BY name
GO

SELECT 
    t.NAME AS TableName,
    s.Name AS SchemaName,
    p.rows AS RowCounts,
    SUM(a.total_pages) * 8 AS TotalSpaceKB, 
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB, 
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB
--INTO #t
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.NAME NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255
	AND t.NAME LIKE 'hpi%'
	--AND [rowCounts] > 0
GROUP BY 
    t.Name, s.Name, p.Rows
ORDER BY 
    t.Name

select TableName, [rowCounts] 
from #t
where [rowCounts] > 0
order by [rowCounts]