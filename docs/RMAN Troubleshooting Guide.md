# RMAN Troubleshooting Guide

The errors a DBA most often hits with RMAN backup and recovery, what causes them, and
how to resolve them. Commands are templates — adapt paths, DBIDs, and file numbers to
your environment and apply under change control.

> All examples use placeholders. Nothing here references any real or confidential system.

---

## 1. ORA-00257 — archiver stuck / FRA full

**Symptom:** new connections fail; backups hang; alert log shows the archiver cannot
write. The Fast Recovery Area is full.
**Cause:** archive logs accumulated faster than they were backed up/reclaimed — usually
because the archive backup job lapsed.

**Resolve:**
- Back up archive logs to free reclaimable space, then delete what is safely backed up:
  ```
  RMAN> BACKUP ARCHIVELOG ALL;
  RMAN> DELETE ARCHIVELOG ALL BACKED UP 1 TIMES TO DISK COMPLETED BEFORE 'SYSDATE-1';
  ```
- As a controlled temporary measure, increase `DB_RECOVERY_FILE_DEST_SIZE`.
- Fix the root cause: restore the regular `archivelog_backup.sql` schedule.
- **Never** delete archive logs at the OS level — it breaks recoverability.

---

## 2. RMAN-06059 — expected archived log not found

**Symptom:** a backup or recovery fails because an archived log RMAN expected is missing
from disk.
**Cause:** the log was removed outside RMAN (manual delete, OS cleanup, tape cycle).

**Resolve:**
```
RMAN> CROSSCHECK ARCHIVELOG ALL;          -- mark missing logs EXPIRED
RMAN> DELETE EXPIRED ARCHIVELOG ALL;      -- clean stale repository records
```
Then re-run the backup. Run `crosscheck_backup.sql` regularly to prevent this.

---

## 3. RMAN-06026 / RMAN-06023 — unable to find / no backup or copy for restore

**Symptom:** a restore cannot find a usable backup of a datafile.
**Cause:** the needed backup is missing, expired, or never existed (e.g., a datafile
added after the last full and not yet backed up).

**Resolve:**
- Reconcile the repository: `CROSSCHECK BACKUP;` then `LIST BACKUP SUMMARY;`.
- Confirm what is recoverable: `RESTORE DATABASE VALIDATE;` (see `validate_database.sql`).
- If a backup truly does not exist, recover as far as possible and escalate. Prevent
  recurrence by backing up immediately after adding datafiles and by monitoring
  `REPORT NEED BACKUP;`.

---

## 4. ORA-19809 / ORA-19804 — recovery file limit / cannot reclaim space

**Symptom:** RMAN cannot create a backup piece because the FRA size limit is reached.
**Cause:** `DB_RECOVERY_FILE_DEST_SIZE` is too small for the retention + archive volume.

**Resolve:**
- Reclaim first: run `crosscheck_backup.sql` then `delete_obsolete.sql`.
- If genuinely undersized, raise the limit:
  ```sql
  ALTER SYSTEM SET DB_RECOVERY_FILE_DEST_SIZE = 300G SCOPE=BOTH;
  ```
- Size the FRA against real daily archive generation (see `rman_report.sql`'s FRA
  section and the daily archive volume).

---

## 5. RMAN-20242 / "specification does not match any backup" during control file restore

**Symptom:** `RESTORE CONTROLFILE FROM AUTOBACKUP` cannot find the autobackup.
**Cause:** wrong DBID, wrong autobackup format/location, or autobackup was never on.

**Resolve:**
- Set the correct `DBID` (from backup logs / `rman_report.sql` history).
- Point RMAN at the right location/format:
  ```
  RMAN> SET CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO
          '/u01/app/oracle/fast_recovery_area/%d/autobackup/%F';
  RMAN> RESTORE CONTROLFILE FROM AUTOBACKUP;
  ```
- If you know the exact piece: `RESTORE CONTROLFILE FROM '/path/c-<dbid>-<date>-00';`
- Prevent it: keep `CONFIGURE CONTROLFILE AUTOBACKUP ON` (see `controlfile_backup.sql`).

---

## 6. ORA-19870 / ORA-19573 — cannot restore datafile; file in use

**Symptom:** restore fails because the datafile is currently open/locked.
**Cause:** trying to restore a datafile that is online in an open database.

**Resolve:** take it offline first (Scenario 1 in the Restore and Recovery Guide), or
for a full restore mount the database rather than opening it:
```
RMAN> SQL "ALTER DATABASE DATAFILE 7 OFFLINE";
RMAN> RESTORE DATAFILE 7;  RMAN> RECOVER DATAFILE 7;
RMAN> SQL "ALTER DATABASE DATAFILE 7 ONLINE";
```

---

## 7. Slow backups / channels bottlenecked

**Symptom:** backups take far longer than the maintenance window allows.
**Cause:** too few channels, no compression, or contention with other I/O.

**Resolve:**
- Increase parallelism to match CPU/IO headroom:
  `CONFIGURE DEVICE TYPE DISK PARALLELISM 4;`
- Use `COMPRESSED BACKUPSET` to cut I/O (already in these scripts).
- Use incrementals + block change tracking to shrink daily backups:
  ```sql
  ALTER DATABASE ENABLE BLOCK CHANGE TRACKING
    USING FILE '/u01/app/oracle/oradata/ORADEMO/bct.chg';
  ```
  Block change tracking lets level-1 backups skip unchanged blocks entirely.

---

## 8. Duplicate (clone) fails — auxiliary not ready / name conflicts

**Symptom:** `duplicate_database.sql` errors on connect, file paths, or naming.
**Cause:** auxiliary instance not started NOMOUNT, missing password file, missing TNS
entries, or file-name convert paths that collide with the source.

**Resolve:**
- Start the auxiliary NOMOUNT with its own init parameters and a password file.
- Verify both TNS aliases connect (`tnsping`, `sqlplus`).
- Set `DB_FILE_NAME_CONVERT` / `LOG_FILE_NAME_CONVERT` to distinct auxiliary paths and
  keep `NOFILENAMECHECK` only when paths genuinely differ from the source.

---

## General troubleshooting method

1. Read the **full** error stack in the RMAN log — the first `RMAN-`/`ORA-` line names
   the real cause; later lines are consequences.
2. Reconcile the repository (`CROSSCHECK`) before concluding a backup is missing.
3. Validate before you trust (`RESTORE ... VALIDATE`, `BACKUP VALIDATE`).
4. Reproduce and rehearse on a test database so the fix is known before it is needed in
   production.

See **RMAN Backup Procedure.md** for the strategy and **Restore and Recovery Guide.md**
for end-to-end recovery sequences.
