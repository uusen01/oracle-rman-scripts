--------------------------------------------------------------------------------
-- Script:        duplicate_database.sql
-- Purpose:       Clone a database to a new name/host for refreshing a test, QA, or
--                reporting environment using RMAN DUPLICATE. Demonstrates both the
--                active (network) method and the backup-based method.
-- Compatibility: Oracle 11g, 12c, 19c, 21c. FROM ACTIVE DATABASE ... USING
--                BACKUPSET is the preferred active method on 12c+; 11g uses the
--                image-copy form (noted inline).
-- Client:        RMAN command script connected to BOTH target (source) and auxiliary
--                (clone) instances. *** Creates/overwrites the auxiliary database. ***
--                Run with:  rman target sys@SRC_TNS auxiliary sys@AUX_TNS \
--                                cmdfile=duplicate_database.sql log=dup.log
--
-- Example execution:
--   $ rman target sys@PRODSRC auxiliary sys@TESTAUX \
--         cmdfile=scripts/duplicate_database.sql \
--         log=/u01/app/oracle/rman_logs/duplicate_$(date +%F).log
--
-- Pre-requisites (done outside this script):
--   * Auxiliary instance started NOMOUNT with its own init params and a password file.
--   * Net services (TNS) entries for both source and auxiliary configured.
--   * DB_FILE_NAME_CONVERT / LOG_FILE_NAME_CONVERT chosen for the new file paths.
--
-- Explanation:
--   * DUPLICATE FROM ACTIVE DATABASE copies directly over the network with no prior
--     backup needed -- convenient for ad-hoc clones. USING BACKUPSET (12c+) streams
--     compressed backup sets for efficiency.
--   * The *_FILE_NAME_CONVERT pairs remap source file paths to the auxiliary's paths.
--   * SET NEWNAME or the CONVERT parameters keep the clone's files separate from the
--     source -- essential when cloning onto the same host.
--   * For point-in-time clones, add UNTIL TIME/SCN as in recover_database.sql.
--
-- Sanitization:  All instance names, paths, and TNS aliases are placeholders. No
--                hostnames, IPs, SIDs, credentials, or company data.
--------------------------------------------------------------------------------

RUN {
    ALLOCATE CHANNEL c1 DEVICE TYPE DISK;
    ALLOCATE CHANNEL c2 DEVICE TYPE DISK;
    ALLOCATE AUXILIARY CHANNEL aux1 DEVICE TYPE DISK;

    -- Active duplication over the network (Oracle 12c+ preferred form).
    DUPLICATE TARGET DATABASE TO AUXDB
        FROM ACTIVE DATABASE
        USING COMPRESSED BACKUPSET
        SPFILE
            SET DB_UNIQUE_NAME 'AUXDB'
            SET DB_FILE_NAME_CONVERT '/u01/app/oracle/oradata/SRCDB/',
                                     '/u01/app/oracle/oradata/AUXDB/'
            SET LOG_FILE_NAME_CONVERT '/u01/app/oracle/oradata/SRCDB/',
                                      '/u01/app/oracle/oradata/AUXDB/'
        NOFILENAMECHECK;

    RELEASE CHANNEL c1;
    RELEASE CHANNEL c2;
    RELEASE CHANNEL aux1;
}

-- ---- Alternative: backup-based duplication (no source connection needed) ----
-- DUPLICATE DATABASE TO AUXDB
--     BACKUP LOCATION '/u01/app/oracle/backups/SRCDB'
--     NOFILENAMECHECK
--     DB_FILE_NAME_CONVERT '/oradata/SRCDB/','/oradata/AUXDB/';
--
-- ---- 11g active form (no USING BACKUPSET) ----
-- DUPLICATE TARGET DATABASE TO AUXDB FROM ACTIVE DATABASE
--     DB_FILE_NAME_CONVERT '/oradata/SRCDB/','/oradata/AUXDB/'
--     SPFILE SET DB_UNIQUE_NAME 'AUXDB' NOFILENAMECHECK;
