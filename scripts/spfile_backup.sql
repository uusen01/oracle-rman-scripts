--------------------------------------------------------------------------------
-- Script:        spfile_backup.sql
-- Purpose:       Back up the server parameter file (SPFILE) on demand so the
--                instance's initialization parameters can be restored after loss
--                or corruption -- a prerequisite for starting the instance to NOMOUNT
--                during a full restore.
-- Compatibility: Oracle 11g, 12c, 19c, 21c. Single-instance and RAC.
-- Client:        RMAN command script.
--                Run with:  rman target / cmdfile=spfile_backup.sql log=spfile.log
--
-- Example execution:
--   $ rman target / cmdfile=scripts/spfile_backup.sql \
--         log=/u01/app/oracle/rman_logs/spfile_$(date +%F).log
--
-- Explanation:
--   * The SPFILE is small but essential: without it (or a usable PFILE) you cannot
--     start the instance, and you cannot restore the control file or database.
--   * With control file autobackup ON, the SPFILE is included in every autobackup;
--     this script adds an explicit, tagged copy and also dumps a text PFILE as an
--     extra readable fallback.
--   * Keep an off-host copy of the PFILE text -- it lets you bootstrap a NOMOUNT
--     instance even if all backups are temporarily unreachable.
--
-- Sanitization:  No hostnames, IPs, SIDs, credentials, or company data.
--------------------------------------------------------------------------------

CONFIGURE CONTROLFILE AUTOBACKUP ON;   -- SPFILE rides along with autobackup

RUN {
    ALLOCATE CHANNEL c1 DEVICE TYPE DISK;

    -- Explicit, tagged SPFILE backup.
    BACKUP SPFILE TAG 'SPFILE_ONDEMAND';

    -- Readable text PFILE fallback (created from the running SPFILE).
    SQL "CREATE PFILE=''/u01/app/oracle/rman_logs/init_backup.ora'' FROM SPFILE";

    RELEASE CHANNEL c1;
}

-- Show SPFILE backups on record.
LIST BACKUP OF SPFILE;
