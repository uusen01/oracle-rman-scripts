--------------------------------------------------------------------------------
-- Script:        restore_controlfile.sql
-- Purpose:       Restore the control file from autobackup when all current control
--                files are lost or corrupt -- the first step of a full database
--                restore. Brings the instance from NOMOUNT to MOUNT so the rest of
--                the database can be restored and recovered.
-- Compatibility: Oracle 11g, 12c, 19c, 21c. Single-instance and RAC.
-- Client:        RMAN command script. *** DESTRUCTIVE / RECOVERY OPERATION ***
--                Intended for a real or simulated control file loss. Read the
--                Restore and Recovery Guide before running against any real system.
--                Run with:  rman target / cmdfile=restore_controlfile.sql log=rc.log
--
-- Example execution:
--   $ rman target /
--   RMAN> @scripts/restore_controlfile.sql
--
-- Explanation:
--   * Restoring the control file requires control file autobackup to have been ON
--     (see controlfile_backup.sql). RMAN locates the autobackup by DBID + format.
--   * SET DBID is required when the control file is gone, because RMAN cannot read the
--     database identity from a control file that no longer exists. Replace the
--     placeholder with your real DBID (recorded from backup logs / RMAN output).
--   * After RESTORE, the database is MOUNTed so datafile restore/recovery can proceed.
--   * Because backups were taken with the old control file, a RECOVER + OPEN
--     RESETLOGS is required afterward (handled in recover_database.sql).
--
-- Sanitization:  DBID and paths are placeholders. No hostnames, IPs, SIDs,
--                credentials, or company data.
--------------------------------------------------------------------------------

-- Database identity (REQUIRED when no control file exists). Replace placeholder.
SET DBID 1234567890;

-- Start the instance with no control file mounted.
STARTUP NOMOUNT;

RUN {
    ALLOCATE CHANNEL c1 DEVICE TYPE DISK;

    -- Tell RMAN where autobackups live, then restore the control file.
    SET CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO
        '/u01/app/oracle/fast_recovery_area/%d/autobackup/%F';

    RESTORE CONTROLFILE FROM AUTOBACKUP;

    -- Mount using the freshly restored control file.
    ALTER DATABASE MOUNT;

    RELEASE CHANNEL c1;
}

-- Make the repository aware of any backups not yet catalogued, then list them.
CROSSCHECK BACKUP;
LIST BACKUP OF DATABASE SUMMARY;

-- Next step: run recover_database.sql to restore datafiles, recover, and OPEN RESETLOGS.
