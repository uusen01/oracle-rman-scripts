# Restore and Recovery Guide

The scenarios a DBA is most likely to face, and the exact sequence of scripts to use
for each. Recovery is the moment a backup strategy is judged — these procedures are
written to be followed under pressure.

> **⚠️ These are destructive operations.** Practice them on a test/lab database first.
> Replace every placeholder (DBID, paths, instance names, times/SCNs) with your real
> values. When in doubt, open an SR with Oracle Support before acting on production.

---

## Before you begin (every recovery)

1. **Stay calm and assess.** What exactly is lost — a datafile, the control file, the
   whole database? Read the alert log and the exact `ORA-` error.
2. **Protect what remains.** Do not delete files or overwrite backups. If possible,
   copy current redo logs and any surviving files aside.
3. **Know your DBID.** It is in your backup logs and `rman_report.sql` history. You need
   it if the control file is gone.
4. **Confirm backups exist and are valid** — `LIST BACKUP SUMMARY;` and, time
   permitting, `RESTORE ... VALIDATE` (see `validate_database.sql`).

---

## Scenario 1 — Single datafile lost or corrupt (database stays open)

The least disruptive case. The rest of the database keeps running.

```
RMAN> SQL "ALTER DATABASE DATAFILE 7 OFFLINE";
RMAN> RESTORE DATAFILE 7;
RMAN> RECOVER DATAFILE 7;
RMAN> SQL "ALTER DATABASE DATAFILE 7 ONLINE";
```

Only the affected tablespace's data is unavailable during the operation. No RESETLOGS,
no full outage.

---

## Scenario 2 — Block corruption only

Detected by `validate_database.sql` (rows in `V$DATABASE_BLOCK_CORRUPTION`).

```
RMAN> RECOVER CORRUPTION LIST;
```

This repairs just the corrupt blocks from backup/redo while the database stays open —
the most surgical recovery available.

---

## Scenario 3 — Control file loss (all copies)

Use **`restore_controlfile.sql`** then **`recover_database.sql`**.

1. `restore_controlfile.sql` — sets DBID, starts NOMOUNT, restores the control file
   from autobackup, mounts the database.
2. `recover_database.sql` — restores datafiles, recovers, and `OPEN RESETLOGS`.
3. Take a fresh `full_backup.sql` immediately (RESETLOGS starts a new incarnation).

Why RESETLOGS: the restored control file and the recovery are not perfectly aligned with
the original online redo thread, so Oracle requires a new redo stream.

---

## Scenario 4 — Complete database loss (full restore)

The full disaster path — host rebuilt, storage lost, etc.

1. **Restore the SPFILE/PFILE** so you can start an instance. With autobackup on, RMAN
   restores it during the control file step; otherwise use your saved `init_backup.ora`
   (see `spfile_backup.sql`) to `STARTUP NOMOUNT`.
2. **Restore the control file** — `restore_controlfile.sql` (sets DBID, NOMOUNT →
   restore from autobackup → MOUNT).
3. **Restore and recover the database** — `recover_database.sql` (Option A, full
   recovery) → `OPEN RESETLOGS`.
4. **Re-backup** — run `full_backup.sql`.
5. **Validate** — `validate_database.sql` and application smoke tests.

---

## Scenario 5 — Point-in-time recovery (logical error)

A bad batch run, an accidental `DELETE`/`DROP`, or corrupt data introduced at a known
time. Recover the whole database to just *before* the event.

Use **`recover_database.sql` Option B** (the commented point-in-time block). Choose one
`SET UNTIL` clause:

```
SET UNTIL TIME "TO_DATE('2026-06-17 02:30:00','YYYY-MM-DD HH24:MI:SS')";
-- or  SET UNTIL SCN 12345678;
-- or  SET UNTIL SEQUENCE 4567 THREAD 1;
RESTORE DATABASE;
RECOVER DATABASE;
ALTER DATABASE OPEN RESETLOGS;
```

For recovering a *single table* without rolling back the whole database, 12c+ offers
`RECOVER TABLE ... UNTIL ...` (RMAN automates an auxiliary instance + Data Pump) — a
lower-impact option when only one object is affected.

---

## Scenario 6 — Clone/refresh an environment (not a failure)

To refresh test/QA from production, use **`duplicate_database.sql`** (active network
duplication or backup-based). This is the same restore machinery applied to building a
copy rather than recovering the original.

---

## After every recovery

- **Take a fresh full backup** (especially after RESETLOGS).
- **Validate** the database and backups (`validate_database.sql`).
- **Run application checks** with the app team before declaring "recovered."
- **Write a short post-incident note**: what was lost, the steps taken, the actual RTO,
  and any gap to fix. This is how a recovery becomes an improvement, not just a save.

---

## Practice makes recovery routine

Schedule a **periodic restore drill** — restore the latest backups to a scratch host (or
use `duplicate_database.sql`) and time it. The number you get is your real RTO, and the
drill is what turns these procedures from theory into muscle memory. See
**RMAN Troubleshooting Guide.md** for the errors you are most likely to hit along the way.
