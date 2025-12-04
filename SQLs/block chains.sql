-- blocking_chain.sql
WITH blocking AS (
  SELECT
    r.session_id,
    r.blocking_session_id,
    s.login_name,
    DB_NAME(r.database_id) as database_name,
    r.status, r.cpu_time, r.total_elapsed_time/1000.0 AS elapsed_sec,
    st.text AS sql_text
  FROM sys.dm_exec_requests r
  CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
  LEFT JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
  WHERE r.blocking_session_id <> 0
)
SELECT *
FROM blocking
ORDER BY blocking_session_id, elapsed_sec DESC;
