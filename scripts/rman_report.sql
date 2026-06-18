--------------------------------------------------------------------------------
-- Script:        rman_report.sql
-- Purpose:       Report on RMAN backup health from the data dictionary -- last
--                successful backup per type, recent job status/duration, failures,
--                and FRA usage -- so a DBA can confirm at a glance that the backup
--                strategy is actually running and succeeding.
-- Compatibility: Oracle 11g, 12c, 19c, 21c.
-- Client:        SQL*Plus (NOT the RMAN client). These query V$ / data dictionary
--                views and run read-only.
--                Run with:  sqlplus monitor_user@DB @rman_report.sql
--
-- Example execution:
--   $ sqlplus -s monitor_user@DEMO_TNS @scripts/rman_report.sql
--
-- Explanation:
--   * Section 1 (V$RMAN_BACKUP_JOB_DETAILS) lists recent backup jobs with status,
--     start/end, duration, and size -- the fastest "did last night's backup run and
--     succeed?" view.
--   * Section 2 shows the most recent COMPLETED backup per object type, so a stale
--     backup (e.g., no full in 10 days) stands out.
--   * Section 3 flags FAILED/ERROR jobs in the lookback window.
--   * Section 4 reports Fast Recovery Area usage -- the space that, if full, stalls
--     archiving and backups.
--   * Read-only: no RMAN repository changes, no database changes.
--
-- Sanitization:  No hostnames, IPs, SIDs, credentials, or company data.
--------------------------------------------------------------------------------

SET LINESIZE 200
SET PAGESIZE 100
SET FEEDBACK OFF
COLUMN input_type     FORMAT A16
COLUMN status         FORMAT A12
COLUMN start_time     FORMAT A18
COLUMN end_time       FORMAT A18
COLUMN duration       FORMAT A12
COLUMN in_gb          FORMAT 999,990.00
COLUMN out_gb         FORMAT 999,990.00
COLUMN object_type    FORMAT A24
COLUMN last_completed FORMAT A20
COLUMN name           FORMAT A40
COLUMN pct_used       FORMAT 990.0

DEFINE lookback_days = 14

PROMPT
PROMPT ============= RMAN BACKUP JOBS (LAST &lookback_days DAYS) ===============
SELECT input_type,
       status,
       TO_CHAR(start_time, 'YYYY-MM-DD HH24:MI') AS start_time,
       TO_CHAR(end_time,   'YYYY-MM-DD HH24:MI') AS end_time,
       time_taken_display                         AS duration,
       ROUND(input_bytes  /1024/1024/1024, 2)     AS in_gb,
       ROUND(output_bytes /1024/1024/1024, 2)     AS out_gb
FROM   v$rman_backup_job_details
WHERE  start_time >= SYSDATE - &lookback_days
ORDER  BY start_time DESC;

PROMPT
PROMPT ============== MOST RECENT COMPLETED BACKUP BY TYPE ====================
SELECT object_type,
       TO_CHAR(MAX(completion_time), 'YYYY-MM-DD HH24:MI') AS last_completed
FROM   (
    SELECT 'Datafile Full/Incr' AS object_type, completion_time
      FROM v$backup_set bs JOIN v$backup_piece bp ON bp.set_stamp = bs.set_stamp
     WHERE bs.backup_type IN ('D','I')
    UNION ALL
    SELECT 'Archived Log', completion_time
      FROM v$backup_redolog
    UNION ALL
    SELECT 'Control File', completion_time
      FROM v$backup_set bs2 JOIN v$backup_piece bp2 ON bp2.set_stamp = bs2.set_stamp
     WHERE bs2.controlfile_included = 'YES'
)
GROUP BY object_type
ORDER BY object_type;

PROMPT
PROMPT ================= FAILED / ERRORED BACKUP JOBS =========================
SELECT TO_CHAR(start_time, 'YYYY-MM-DD HH24:MI') AS start_time,
       input_type,
       status,
       time_taken_display AS duration
FROM   v$rman_backup_job_details
WHERE  status LIKE '%FAILED%' OR status LIKE '%ERROR%'
ORDER  BY start_time DESC
FETCH FIRST 20 ROWS ONLY;

PROMPT
PROMPT ===================== FAST RECOVERY AREA USAGE =========================
SELECT name,
       ROUND(space_limit/1024/1024/1024, 2)               AS limit_gb,
       ROUND(space_used /1024/1024/1024, 2)               AS used_gb,
       ROUND(space_used * 100 / NULLIF(space_limit,0), 1) AS pct_used
FROM   v$recovery_file_dest;

PROMPT
SET FEEDBACK ON
