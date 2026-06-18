# RMAN Backup Procedure

A practical backup strategy for Oracle 11g/12c/19c/21c using the scripts in this
repository. It defines the schedule, the retention model, and the daily/weekly tasks
that keep a database recoverable and the Fast Recovery Area (FRA) under control.

> **Scope:** single-instance and RAC, disk/FRA-based backups (adaptable to SBT/tape).
> All paths, tags, and DBIDs in the scripts are placeholders — set them for your
> environment before use. Nothing here references any real or confidential system.

---

## Strategy at a glance

| Element | Choice | Rationale |
|---|---|---|
| Backup model | Weekly **level 0** (full) + daily **level 1** (incremental) | Small, fast daily backups; full recovery from base + increments |
| Archive logs | Backed up every 1–4 hours, `DELETE INPUT` | Bounds RPO; keeps FRA from filling |
| Retention | `RECOVERY WINDOW OF 14 DAYS` | Recover to any point in the last two weeks |
| Control file / SPFILE | `AUTOBACKUP ON` + explicit on-demand backups | Metadata always recoverable |
| Compression | `COMPRESSED BACKUPSET` | Less storage and I/O |
| Parallelism | 2 channels (tune to CPU/IO) | Faster backups |
| Verification | Weekly `BACKUP VALIDATE` + monthly restore drill | Proves backups are actually usable |

RPO/RTO are policy decisions — set the archive backup frequency to your tolerable data
loss, and rehearse restores to know your real recovery time.

---

## One-time configuration

Run the `CONFIGURE` block in **`full_backup.sql`** once. It sets retention, control
file autobackup, compression, channel parallelism, and the backup destination format.
These persist in the RMAN repository, so subsequent scripts inherit them. Confirm with
`SHOW ALL;` inside RMAN.

If you use a recovery catalog (recommended at scale), register the database
(`REGISTER DATABASE;`) so backup metadata survives loss of the control file and is
shared across databases.

---

## Daily / weekly schedule

| When | Script | Purpose |
|---|---|---|
| Weekly (e.g., Sat 01:00) | `full_backup.sql` | Level-0 base + archive logs + control file/SPFILE |
| Daily (e.g., 04:00) | `archivelog_backup.sql` | Level-1 incremental + archive log backup |
| Every 1–4 hours | `archivelog_backup.sql` (archive section) | Frequent archive backups for tight RPO |
| Daily | `crosscheck_backup.sql` | Reconcile repository with media |
| Daily (after crosscheck) | `delete_obsolete.sql` | Reclaim space outside the retention window |
| On demand / pre-change | `controlfile_backup.sql`, `spfile_backup.sql` | Extra metadata safety before risky changes |
| Weekly | `validate_database.sql` | Prove database + backups are corruption-free and restorable |
| Daily (morning) | `rman_report.sql` (SQL\*Plus) | One-screen "are we protected?" report |

Order matters for cleanup: **crosscheck before delete_obsolete**, so retention math
runs against an accurate picture of what is really on the media.

---

## Scheduling the scripts

These are RMAN command scripts (except `rman_report.sql`, which is SQL\*Plus). Wrap each
in a small shell/PowerShell job that captures a timestamped log, and schedule with cron
(Linux) or Task Scheduler (Windows). Example Linux job:

```bash
#!/bin/bash
export ORACLE_SID=ORADEMO
export ORACLE_HOME=/u01/app/oracle/product/21.0.0/dbhome_1
LOG=/u01/app/oracle/rman_logs/full_$(date +%F_%H%M).log
$ORACLE_HOME/bin/rman target / cmdfile=/path/scripts/full_backup.sql log=$LOG
# then check $? and the log for "RMAN-" / "ORA-" errors and alert on failure
```

Always alert on failure — a backup job that fails silently is the same as having no
backup. `rman_report.sql` is the safety net that catches a silently-missed run.

---

## What "good" looks like

- The weekly full and the daily incrementals all show **COMPLETED** in
  `rman_report.sql`.
- Archive log backups are current to within your RPO window.
- FRA `PCT_USED` stays comfortably below 90%.
- `validate_database.sql` reports **0** corrupt blocks and a successful
  `RESTORE ... VALIDATE`.
- A periodic restore drill (see the Restore and Recovery Guide) succeeds within your
  RTO target.

---

## Don'ts

- Don't delete archive logs or backup files at the OS level — always go through RMAN
  (`DELETE ... `) so the repository stays consistent and recoverability is preserved.
- Don't run `NOARCHIVELOG`-mode online backups — online backup and point-in-time
  recovery require `ARCHIVELOG` mode.
- Don't trust an untested backup — verification (`VALIDATE`) and rehearsed restores are
  part of the strategy, not optional extras.
- Don't store the only copy of backups on the same storage as the database — keep an
  off-host/off-site copy for true disaster recovery.

See **Restore and Recovery Guide.md** for recovery scenarios and **RMAN Troubleshooting
Guide.md** for common errors and fixes.
