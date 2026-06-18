--------------------------------------------------------------------------------
-- Script:        full_backup.sql
-- Purpose:       Take a full, compressed RMAN database backup (level 0) including
--                the current control file, SPFILE, and archived redo logs, suitable
--                as the weekly base of an incremental backup strategy.
-- Compatibility: Oracle 11g, 12c, 19c, 21c. Runs against single-instance and RAC.
--                For a non-CDB the syntax is identical; for a CDB this backs up the
--                whole container (root + all PDBs).
-- Client:        RMAN command script (NOT SQL*Plus).
--                Run with:  rman target / cmdfile=full_backup.sql log=full_backup.log
--                or inside RMAN:  RMAN> @full_backup.sql
--
-- Example execution:
--   $ rman target / cmdfile=scripts/full_backup.sql log=/u01/app/oracle/rman_logs/full_backup_$(date +%F).log
--
-- Explanation:
--   * CONFIGURE lines are shown once as the recommended persistent settings; they are
--     idempotent and safe to re-run. Adjust channel count and the FORMAT/destination
--     to match your media (disk, FRA, or SBT/tape).
--   * BACKUP AS COMPRESSED BACKUPSET INCREMENTAL LEVEL 0 creates the base image that
--     later level-1 backups build on (see archivelog_backup.sql for the daily piece).
--   * PLUS ARCHIVELOG ... DELETE INPUT captures redo generated during the backup and
--     reclaims space once it is safely in the backup set.
--   * The control file and SPFILE are autobacked up via CONFIGURE CONTROLFILE
--     AUTOBACKUP ON, guaranteeing a recoverable copy of the database's metadata.
--
-- Sanitization:  No hostnames, IPs, SIDs, credentials, or company data. Paths such as
--                /u01/app/oracle/... and tags are generic placeholders -- edit before use.
--------------------------------------------------------------------------------

-- ---------- Recommended persistent configuration (run once; safe to re-run) ----------
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 14 DAYS;
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE BACKUP OPTIMIZATION ON;
CONFIGURE DEVICE TYPE DISK PARALLELISM 2 BACKUP TYPE TO COMPRESSED BACKUPSET;
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '/u01/app/oracle/fast_recovery_area/%d/backupset/%U';

-- ---------- Full (level 0) database backup + archive logs ----------
RUN {
    ALLOCATE CHANNEL c1 DEVICE TYPE DISK;
    ALLOCATE CHANNEL c2 DEVICE TYPE DISK;

    BACKUP AS COMPRESSED BACKUPSET
        INCREMENTAL LEVEL 0
        DATABASE
        TAG 'FULL_L0_WEEKLY'
        PLUS ARCHIVELOG
        TAG 'ARCH_WITH_FULL'
        DELETE INPUT;

    -- Explicit control file + SPFILE backup (in addition to autobackup) for clarity.
    BACKUP CURRENT CONTROLFILE TAG 'CF_WITH_FULL';
    BACKUP SPFILE TAG 'SPFILE_WITH_FULL';

    RELEASE CHANNEL c1;
    RELEASE CHANNEL c2;
}

-- ---------- Confirm what was produced ----------
LIST BACKUP OF DATABASE SUMMARY;
