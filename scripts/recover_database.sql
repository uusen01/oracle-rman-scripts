--------------------------------------------------------------------------------
-- Script:        recover_database.sql
-- Purpose:       Restore datafiles from backup and recover the database -- either
--                fully (all redo applied) or to a point in time. Completes the
--                recovery that begins with restore_controlfile.sql.
-- Compatibility: Oracle 11g, 12c, 19c, 21c. Single-instance and RAC.
-- Client:        RMAN command script. *** DESTRUCTIVE / RECOVERY OPERATION ***
--                Run only during a real recovery or a rehearsed drill on a test DB.
--                Run with:  rman target / cmdfile=recover_database.sql log=rec.log
--
-- Example execution:
--   $ rman target /
--   RMAN> @scripts/recover_database.sql
--
-- Explanation:
--   * Assumes the control file is already restored and the database is MOUNTed
--     (see restore_controlfile.sql).
--   * FULL RECOVERY path: RESTORE DATABASE then RECOVER DATABASE applies all available
--     archived + online redo, recovering to the most recent consistent point.
--   * POINT-IN-TIME path (commented): SET UNTIL TIME/SCN/SEQUENCE recovers to just
--     before a logical error (e.g., a bad batch run). Use exactly one path.
--   * OPEN RESETLOGS is required after incomplete recovery or when recovering with a
--     restored/older control file; it starts a new redo stream. Take a fresh full
--     backup immediately afterward.
--
-- Sanitization:  Times/SCNs and paths are placeholders. No hostnames, IPs, SIDs,
--                credentials, or company data.
--------------------------------------------------------------------------------

-- ============ OPTION A: FULL RECOVERY (apply all redo) ============
RUN {
    ALLOCATE CHANNEL c1 DEVICE TYPE DISK;
    ALLOCATE CHANNEL c2 DEVICE TYPE DISK;

    RESTORE DATABASE;
    RECOVER DATABASE;

    RELEASE CHANNEL c1;
    RELEASE CHANNEL c2;
}

-- ============ OPTION B: POINT-IN-TIME RECOVERY (use INSTEAD of Option A) ============
-- RUN {
--     ALLOCATE CHANNEL c1 DEVICE TYPE DISK;
--     ALLOCATE CHANNEL c2 DEVICE TYPE DISK;
--
--     -- Choose ONE of these UNTIL clauses:
--     SET UNTIL TIME "TO_DATE('2026-06-17 02:30:00','YYYY-MM-DD HH24:MI:SS')";
--     -- SET UNTIL SCN 12345678;
--     -- SET UNTIL SEQUENCE 4567 THREAD 1;
--
--     RESTORE DATABASE;
--     RECOVER DATABASE;
--
--     RELEASE CHANNEL c1;
--     RELEASE CHANNEL c2;
-- }

-- Open the database. RESETLOGS required after incomplete recovery or restored controlfile.
ALTER DATABASE OPEN RESETLOGS;

-- IMPORTANT: take a fresh full backup now that a new redo incarnation has started.
-- (Run full_backup.sql immediately after this completes.)
