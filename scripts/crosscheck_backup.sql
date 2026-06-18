--------------------------------------------------------------------------------
-- Script:        crosscheck_backup.sql
-- Purpose:       Reconcile the RMAN repository with what actually exists on disk/tape.
--                CROSSCHECK marks backups and archive logs EXPIRED if their files are
--                missing, so LIST/REPORT reflect reality and obsolete-deletion works
--                correctly.
-- Compatibility: Oracle 11g, 12c, 19c, 21c. Single-instance and RAC.
-- Client:        RMAN command script.
--                Run with:  rman target / cmdfile=crosscheck_backup.sql log=xchk.log
--
-- Example execution:
--   $ rman target / cmdfile=scripts/crosscheck_backup.sql \
--         log=/u01/app/oracle/rman_logs/crosscheck_$(date +%F).log
--
-- Explanation:
--   * CROSSCHECK does NOT delete anything -- it only updates each object's status to
--     AVAILABLE (file present) or EXPIRED (file gone, e.g. removed by an OS process or
--     tape cycle). It is completely safe to run any time.
--   * After a crosscheck, DELETE EXPIRED purges the repository records for files that
--     no longer exist, keeping the catalog clean and accurate.
--   * Run this before delete_obsolete.sql so retention-based deletion operates on an
--     accurate picture of what is really on the media.
--
-- Sanitization:  No hostnames, IPs, SIDs, credentials, or company data.
--------------------------------------------------------------------------------

RUN {
    ALLOCATE CHANNEL c1 DEVICE TYPE DISK;

    -- Verify existence of every recorded backup/copy/archive log.
    CROSSCHECK BACKUP;
    CROSSCHECK COPY;
    CROSSCHECK ARCHIVELOG ALL;

    RELEASE CHANNEL c1;
}

-- Remove repository records for files confirmed missing (status EXPIRED).
DELETE NOPROMPT EXPIRED BACKUP;
DELETE NOPROMPT EXPIRED COPY;
DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;

-- Show the reconciled state.
LIST EXPIRED BACKUP SUMMARY;
