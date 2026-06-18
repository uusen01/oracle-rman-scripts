--------------------------------------------------------------------------------
-- Script:        archivelog_backup.sql
-- Purpose:       Back up all archived redo logs (and optionally take a daily
--                incremental level-1 database backup), then reclaim space by
--                deleting archive logs already safely in the backup set. This is
--                the frequent, lightweight companion to the weekly full_backup.sql.
-- Compatibility: Oracle 11g, 12c, 19c, 21c. Single-instance and RAC.
-- Client:        RMAN command script (NOT SQL*Plus).
--                Run with:  rman target / cmdfile=archivelog_backup.sql log=arch.log
--
-- Example execution:
--   $ rman target / cmdfile=scripts/archivelog_backup.sql \
--         log=/u01/app/oracle/rman_logs/arch_$(date +%F_%H%M).log
--
-- Explanation:
--   * Frequent archive log backups bound how much redo can be lost and keep the Fast
--     Recovery Area from filling -- the classic ORA-00257 "archiver stuck" outage.
--   * The level-1 incremental captures only blocks changed since the last level-0,
--     so daily backups are small and fast while still enabling full recovery when
--     combined with the weekly base.
--   * DELETE INPUT removes only archive logs that have been written to the backup
--     set, never unbacked-up redo -- safe space reclamation.
--   * Run this as often as your RPO requires (e.g., every 1-4 hours for tight RPO).
--
-- Sanitization:  No hostnames, IPs, SIDs, credentials, or company data. Paths/tags
--                are generic placeholders.
--------------------------------------------------------------------------------

RUN {
    ALLOCATE CHANNEL c1 DEVICE TYPE DISK;
    ALLOCATE CHANNEL c2 DEVICE TYPE DISK;

    -- Daily incremental (level 1) -- comment out if you only want archive backups.
    BACKUP AS COMPRESSED BACKUPSET
        INCREMENTAL LEVEL 1
        DATABASE
        TAG 'INCR_L1_DAILY';

    -- Back up all archive logs and reclaim the ones now safely in the backup set.
    BACKUP AS COMPRESSED BACKUPSET
        ARCHIVELOG ALL
        TAG 'ARCH_DAILY'
        DELETE INPUT;

    RELEASE CHANNEL c1;
    RELEASE CHANNEL c2;
}

-- Confirm archive log backups and current FRA pressure.
LIST BACKUP OF ARCHIVELOG ALL SUMMARY;
