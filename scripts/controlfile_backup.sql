--------------------------------------------------------------------------------
-- Script:        controlfile_backup.sql
-- Purpose:       Explicitly back up the current control file (binary and as a
--                human-readable trace/CREATE CONTROLFILE script) and confirm
--                control file autobackup is enabled. The control file is the
--                database's metadata map; losing all copies makes recovery far harder.
-- Compatibility: Oracle 11g, 12c, 19c, 21c. Single-instance and RAC.
-- Client:        RMAN command script. The trace dump line uses SQL run from RMAN
--                via the SQL command, so the whole file runs inside RMAN.
--                Run with:  rman target / cmdfile=controlfile_backup.sql log=cf.log
--
-- Example execution:
--   $ rman target / cmdfile=scripts/controlfile_backup.sql \
--         log=/u01/app/oracle/rman_logs/cf_$(date +%F).log
--
-- Explanation:
--   * CONFIGURE CONTROLFILE AUTOBACKUP ON makes RMAN automatically back up the control
--     file and SPFILE after every backup and structural change -- the safety net you
--     rely on in restore_controlfile.sql.
--   * BACKUP CURRENT CONTROLFILE creates an on-demand binary copy with a known tag.
--   * The ALTER DATABASE BACKUP CONTROLFILE TO TRACE produces a readable script that
--     can recreate the control file manually if every binary copy is lost.
--
-- Sanitization:  No hostnames, IPs, SIDs, credentials, or company data.
--------------------------------------------------------------------------------

-- Ensure autobackup is on (idempotent).
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO
    '/u01/app/oracle/fast_recovery_area/%d/autobackup/%F';

RUN {
    ALLOCATE CHANNEL c1 DEVICE TYPE DISK;

    -- On-demand binary control file backup.
    BACKUP CURRENT CONTROLFILE TAG 'CF_ONDEMAND';

    -- Human-readable CREATE CONTROLFILE script written to the trace directory.
    SQL "ALTER DATABASE BACKUP CONTROLFILE TO TRACE AS
         ''/u01/app/oracle/rman_logs/create_controlfile.trc'' REUSE";

    RELEASE CHANNEL c1;
}

-- Show control file backups on record.
LIST BACKUP OF CONTROLFILE;
