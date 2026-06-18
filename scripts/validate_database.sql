--------------------------------------------------------------------------------
-- Script:        validate_database.sql
-- Purpose:       Prove the database and its backups are recoverable WITHOUT making
--                any changes -- physical/logical block validation of the live
--                database and a restore-feasibility check of the backups. This is
--                the "are my backups actually good?" routine every senior DBA runs.
-- Compatibility: Oracle 11g, 12c, 19c, 21c. Single-instance and RAC.
-- Client:        RMAN command script.
--                Run with:  rman target / cmdfile=validate_database.sql log=val.log
--
-- Example execution:
--   $ rman target / cmdfile=scripts/validate_database.sql \
--         log=/u01/app/oracle/rman_logs/validate_$(date +%F).log
--
-- Explanation:
--   * BACKUP VALIDATE ... CHECK LOGICAL reads every block of the database and reports
--     physical AND logical corruption without writing a backup -- a non-intrusive
--     integrity check you can run on a schedule.
--   * RESTORE DATABASE VALIDATE confirms the existing backups could actually be used
--     to restore, catching missing/corrupt backup pieces before you need them in a
--     real recovery.
--   * Any corruption surfaces in V$DATABASE_BLOCK_CORRUPTION (queried at the end).
--   * Nothing here modifies the database or the backups -- safe to run in production.
--
-- Sanitization:  No hostnames, IPs, SIDs, credentials, or company data.
--------------------------------------------------------------------------------

RUN {
    ALLOCATE CHANNEL c1 DEVICE TYPE DISK;
    ALLOCATE CHANNEL c2 DEVICE TYPE DISK;

    -- Read every block; report physical and logical corruption. No backup written.
    BACKUP VALIDATE CHECK LOGICAL DATABASE ARCHIVELOG ALL;

    -- Confirm the database could be restored from existing backups.
    RESTORE DATABASE VALIDATE;

    -- Confirm the control file and SPFILE could be restored.
    RESTORE CONTROLFILE VALIDATE;
    RESTORE SPFILE VALIDATE;

    RELEASE CHANNEL c1;
    RELEASE CHANNEL c2;
}

-- Report any blocks flagged corrupt by the validation above.
SQL "SELECT file#, block#, blocks, corruption_type
       FROM v\$database_block_corruption";
