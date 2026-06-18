--------------------------------------------------------------------------------
-- Script:        delete_obsolete.sql
-- Purpose:       Reclaim space by deleting backups that fall outside the configured
--                retention policy. REPORT first shows what WOULD be removed; DELETE
--                then removes it -- the controlled way to keep the FRA from filling
--                while preserving recoverability within the retention window.
-- Compatibility: Oracle 11g, 12c, 19c, 21c. Single-instance and RAC.
-- Client:        RMAN command script.
--                Run with:  rman target / cmdfile=delete_obsolete.sql log=del.log
--
-- Example execution:
--   $ rman target / cmdfile=scripts/delete_obsolete.sql \
--         log=/u01/app/oracle/rman_logs/delete_obsolete_$(date +%F).log
--
-- Explanation:
--   * "Obsolete" is defined entirely by the retention policy (set in full_backup.sql,
--     e.g. RECOVERY WINDOW OF 14 DAYS). DELETE OBSOLETE never removes anything needed
--     to recover within that window.
--   * REPORT OBSOLETE is run first so the log shows exactly what is about to go --
--     review this in a real environment before trusting the automated DELETE.
--   * Run crosscheck_backup.sql BEFORE this so the repository accurately reflects the
--     media; otherwise retention math can be skewed by stale records.
--   * DELETE NOPROMPT suppresses the interactive confirmation for unattended runs;
--     in ad-hoc use you may prefer to run DELETE OBSOLETE without NOPROMPT.
--
-- Sanitization:  No hostnames, IPs, SIDs, credentials, or company data.
--------------------------------------------------------------------------------

-- Show the active retention policy and what it considers obsolete.
SHOW RETENTION POLICY;
REPORT OBSOLETE;

RUN {
    ALLOCATE CHANNEL c1 DEVICE TYPE DISK;

    -- Remove backups outside the retention window. Safe within the policy.
    DELETE NOPROMPT OBSOLETE;

    RELEASE CHANNEL c1;
}

-- Show remaining backups and FRA recoverability after cleanup.
LIST BACKUP SUMMARY;
REPORT NEED BACKUP;
