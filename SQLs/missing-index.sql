-- missing_indexes.sql
SELECT TOP(50
) avg_total_user_cost, avg_user_impact, user_seeks, user_scans, last_user_seek,
       statement AS table_schema, equality_columns, inequality_columns, included_columns
FROM sys.dm_db_missing_index_groups mig
JOIN sys.dm_db_missing_index_group_stats migs on mig.index_group_handle = migs.group_handle
JOIN sys.dm_db_missing_index_details mid on mig.index_handle = mid.index_handle
ORDER BY migs.avg_total_user_cost * migs.avg_user_impact DESC;
