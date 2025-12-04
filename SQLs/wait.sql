-- wait_stats_delta.sql
IF OBJECT_ID('tempdb..#waits_prev') IS NOT NULL DROP TABLE #waits_prev;
IF OBJECT_ID('tempdb..#waits_cur') IS NOT NULL DROP TABLE #waits_cur;

-- load previous from persistent table if exists
IF OBJECT_ID('dbo.WaitStatsBaseline') IS NOT NULL
BEGIN
  SELECT * INTO #waits_prev FROM dbo.WaitStatsBaseline;
END

-- current snapshot
SELECT wait_type, wait_time_ms, waiting_tasks_count, max_wait_time_ms
INTO #waits_cur
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','SLEEP_TASK','SLEEP_SYSTEMTASK','SQLTRACE_BUFFER_FLUSH','BROKER_EVENTHANDLER','XE_TIMER_EVENT','XE_DISPATCHER_WAIT', 'BROKER_RECEIVE_WAITFOR') -- filter common benign
;

-- persist current snapshot for next run
IF OBJECT_ID('dbo.WaitStatsBaseline') IS NULL
  CREATE TABLE dbo.WaitStatsBaseline(wait_type NVARCHAR(60), wait_time_ms BIGINT, waiting_tasks_count BIGINT, max_wait_time_ms BIGINT);

TRUNCATE TABLE dbo.WaitStatsBaseline;
INSERT dbo.WaitStatsBaseline(wait_type, wait_time_ms, waiting_tasks_count, max_wait_time_ms)
SELECT wait_type, wait_time_ms, waiting_tasks_count, max_wait_time_ms FROM #waits_cur;

-- delta (if prev exists)
IF OBJECT_ID('tempdb..#waits_prev') IS NOT NULL
BEGIN
  SELECT c.wait_type,
         c.wait_time_ms - ISNULL(p.wait_time_ms,0) AS delta_wait_time_ms,
         c.waiting_tasks_count - ISNULL(p.waiting_tasks_count,0) AS delta_waiting_tasks,
         c.max_wait_time_ms
  FROM #waits_cur c
  LEFT JOIN #waits_prev p ON c.wait_type = p.wait_type
  ORDER BY delta_wait_time_ms DESC;
END
ELSE
BEGIN
  SELECT * FROM #waits_cur ORDER BY wait_time_ms DESC;
END
