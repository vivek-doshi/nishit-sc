-- log_usage_and_long_txn.sql
-- 1) log usage
SELECT database_name, 
       log_size_in_mb = CAST(size/128.0 AS DECIMAL(9,2)),
       log_used_percent
FROM sys.dm_db_log_space_usage;  -- SQL Server 2022+
-- Fallback for older versions:
-- EXEC('DBCC SQLPERF(LOGSPACE) WITH NO_INFOMSGS');

-- 2) long-running transactions
SELECT at.transaction_id, at.transaction_type, at.transaction_state, at.transaction_begin_time,
       DATEDIFF(MINUTE, at.transaction_begin_time, GETUTCDATE()) AS minutes_open,
       at.transaction_uow, s.session_id, s.login_name, r.status, r.command
FROM sys.dm_tran_active_transactions at
LEFT JOIN sys.dm_tran_session_transactions st ON at.transaction_id = st.transaction_id
LEFT JOIN sys.dm_exec_sessions s ON st.session_id = s.session_id
LEFT JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
ORDER BY minutes_open DESC;
