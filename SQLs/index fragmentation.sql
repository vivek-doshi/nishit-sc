-- index_fragmentation.sql  -- run in each user DB
SET NOCOUNT ON;
SELECT TOP(50)
 db_name() AS database_name,
 OBJECT_SCHEMA_NAME(ps.object_id) AS schema_name,
 OBJECT_NAME(ps.object_id) AS table_name,
 i.name AS index_name,
 ps.index_id,
 ps.avg_fragmentation_in_percent,
 ps.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ps
JOIN sys.indexes i ON ps.object_id = i.object_id AND ps.index_id = i.index_id
WHERE ps.page_count > 1000 -- threshold
ORDER BY ps.avg_fragmentation_in_percent DESC;
