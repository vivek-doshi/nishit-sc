-- io_stats_per_db.sql
SELECT
    DB_NAME(vfs.database_id) AS database_name,
    mf.physical_name,
    vfs.num_of_reads, vfs.num_of_writes,
    CAST(vfs.io_stall_read_ms AS FLOAT)/NULLIF(vfs.num_of_reads,0) AS avg_read_latency_ms,
    CAST(vfs.io_stall_write_ms AS FLOAT)/NULLIF(vfs.num_of_writes,0) AS avg_write_latency_ms,
    vfs.size_on_disk_bytes/1024/1024 AS size_mb
FROM sys.dm_io_virtual_file_stats(NULL,NULL) vfs
JOIN sys.master_files mf ON mf.database_id = vfs.database_id AND mf.file_id = vfs.file_id
ORDER BY (vfs.num_of_reads+vfs.num_of_writes) DESC;
