# Oracle RMAN Scripts

A production-style library of **RMAN backup, recovery, and maintenance scripts** for
Oracle databases — the backup strategy, the recovery playbooks, and the verification
routines a Senior Oracle DBA uses to keep enterprise databases recoverable.

The set covers the full lifecycle: configure and back up (full + incremental + archive
logs + control file/SPFILE), verify and maintain (validate, crosscheck, retention-based
cleanup), and recover (control file restore, database restore/recover, point-in-time,
and database duplication). A SQL\*Plus reporting script gives a one-screen view of
backup health.

---

## Purpose

A backup is only as good as the recovery it enables. This repository packages a
**tested, repeatable RMAN strategy** — weekly level-0 plus daily level-1 incrementals,
frequent archive log backups, a 14-day recovery window, control file/SPFILE protection,
and regular validation — alongside the **recovery procedures** that turn those backups
into a restored database under pressure.

Every script has a full header (purpose, version compatibility, which client to run it
in, an execution example, an explanation, and a sanitization note). The companion docs
turn the scripts into a documented backup procedure, a restore/recovery guide, and a
troubleshooting reference.

---

## Supported versions

| Oracle version | Status |
|---|---|
| Oracle Database **11g** | ✅ Supported (11g-specific duplicate syntax noted inline) |
| Oracle Database **12c** | ✅ Supported |
| Oracle Database **19c** | ✅ Supported |
| Oracle Database **21c** | ✅ Supported |

Scripts use RMAN commands and data-dictionary views stable across these releases, and
work on single-instance and RAC. Where syntax differs by version (e.g.,
`DUPLICATE ... USING BACKUPSET` on 12c+ vs. the 11g form), the alternative is included
as an inline comment.

---

## ⚠️ Disclaimer — sanitized & generic by design

All scripts, sample outputs, and documentation are **fully sanitized and generic**. They
contain **no** real hostnames, IP addresses, SIDs, service names, DBIDs, credentials, or
employer/company data. Every value in `sample_outputs/` is **fictional**, written purely
to show what a run looks like and how to read it. Placeholders such as
`/u01/app/oracle/...`, `ORADEMO`, `DBID 1234567890`, `SRCDB`/`AUXDB`, and tag names must
be set for your environment before use.

These are reference scripts for portfolio and educational use. **Several scripts are
destructive recovery operations** — test every script in a non-production environment and
apply under your own change-control process.

---

## A note on the `.sql` file extension

Most files here are **RMAN command scripts** run inside the RMAN client
(`rman target / cmdfile=full_backup.sql` or `RMAN> @full_backup.sql`) — RMAN accepts a
command file regardless of extension. **`rman_report.sql`** is the exception: it is a
**SQL\*Plus** script that queries the RMAN data-dictionary views. Each script's header
states exactly which client to use.

---

## Script index

| Script | Type | What it does |
|---|---|---|
| [`full_backup.sql`](scripts/full_backup.sql) | RMAN | One-time CONFIGURE + weekly level-0 full backup + archive logs + control file/SPFILE |
| [`archivelog_backup.sql`](scripts/archivelog_backup.sql) | RMAN | Daily level-1 incremental + archive log backup with space reclamation |
| [`controlfile_backup.sql`](scripts/controlfile_backup.sql) | RMAN | On-demand binary + trace control file backup; ensures autobackup on |
| [`spfile_backup.sql`](scripts/spfile_backup.sql) | RMAN | On-demand SPFILE backup + readable PFILE fallback |
| [`validate_database.sql`](scripts/validate_database.sql) | RMAN | Block validation + restore-feasibility check (proves backups are usable) |
| [`crosscheck_backup.sql`](scripts/crosscheck_backup.sql) | RMAN | Reconcile repository with media; clean EXPIRED records |
| [`delete_obsolete.sql`](scripts/delete_obsolete.sql) | RMAN | Report + delete backups outside the retention window |
| [`restore_controlfile.sql`](scripts/restore_controlfile.sql) | RMAN | Restore control file from autobackup (NOMOUNT → MOUNT) |
| [`recover_database.sql`](scripts/recover_database.sql) | RMAN | Restore + recover database (full or point-in-time) → OPEN RESETLOGS |
| [`duplicate_database.sql`](scripts/duplicate_database.sql) | RMAN | Clone a database to a new name/host (active or backup-based) |
| [`rman_report.sql`](scripts/rman_report.sql) | SQL\*Plus | Backup health report: jobs, last-success-by-type, failures, FRA usage |

A sanitized, annotated sample run of every script lives in
[`sample_outputs/`](sample_outputs/).

---

## Usage

**Prerequisites:** an Oracle client with the RMAN and SQL\*Plus executables, OS access to
the database host (or appropriate net-service connections), and an account that can
connect as `SYSDBA`/`SYSBACKUP` for RMAN operations. A read-only monitoring account is
sufficient for `rman_report.sql`.

**Run an RMAN script:**
```
rman target / cmdfile=scripts/full_backup.sql log=/u01/app/oracle/rman_logs/full.log
# or interactively:
rman target /
RMAN> @scripts/full_backup.sql
```

**Run the reporting script (SQL\*Plus):**
```
sqlplus -s monitor_user@DEMO_TNS @scripts/rman_report.sql
```

**Typical schedule** (full detail in [docs/RMAN Backup Procedure.md](docs/RMAN%20Backup%20Procedure.md)):

| When | Script |
|---|---|
| Weekly | `full_backup.sql` |
| Daily | `archivelog_backup.sql`, `crosscheck_backup.sql`, `delete_obsolete.sql` |
| Every 1–4 hrs | `archivelog_backup.sql` (archive section) |
| Weekly | `validate_database.sql` |
| Daily (morning) | `rman_report.sql` |

---

## Sample output

From `rman_report.sql` (fictional data):

```
============= RMAN BACKUP JOBS (LAST 14 DAYS) ===============

INPUT_TYPE       STATUS       START_TIME         END_TIME           DURATION       IN_GB   OUT_GB
---------------- ------------ ------------------ ------------------ ------------ -------- --------
DB INCR          COMPLETED    2026-06-17 04:00   2026-06-17 04:03   00:03:38        24.10     6.05
DB FULL          COMPLETED    2026-06-14 01:00   2026-06-14 01:09   00:09:12       238.00    61.30
```

From `recover_database.sql` (fictional data):

```
Starting recover at 2026-06-17 14:31:41
channel c1: applying incremental backup INCR_L1_DAILY
media recovery complete, elapsed time: 00:01:55
RMAN> ALTER DATABASE OPEN RESETLOGS;
Statement processed
```

Each file in [`sample_outputs/`](sample_outputs/) ends with a short **"Read:"** note
explaining what a DBA should conclude.

---

## Documentation

| Doc | Contents |
|---|---|
| [RMAN Backup Procedure](docs/RMAN%20Backup%20Procedure.md) | Strategy, retention model, daily/weekly schedule, scheduling, do's & don'ts |
| [Restore and Recovery Guide](docs/Restore%20and%20Recovery%20Guide.md) | Six recovery scenarios mapped to the exact scripts, plus restore drills |
| [RMAN Troubleshooting Guide](docs/RMAN%20Troubleshooting%20Guide.md) | The eight most common RMAN errors — cause and fix for each |

---

## Repository structure

```
oracle-rman-scripts/
├── README.md
├── LICENSE
├── .gitignore
├── scripts/             # 11 RMAN command scripts + 1 SQL*Plus report
├── sample_outputs/      # fictional, sanitized example output for each script
├── docs/                # backup procedure, restore/recovery, troubleshooting
└── screenshots/         # (optional) RMAN session captures for the portfolio
```

---

## Future enhancements

- **`run_all` orchestration** — shell/PowerShell wrappers with failure alerting, plus
  cron / Task Scheduler examples for the weekly/daily/hourly cadence.
- **Block change tracking setup script** — to make level-1 incrementals even faster.
- **SBT / cloud object-storage examples** — backing up to tape and to OCI/AWS S3.
- **Recovery catalog setup** — `CREATE CATALOG` / `REGISTER DATABASE` for repository
  resilience across many databases.
- **Data Guard-aware backups** — offloading backups to a physical standby.
- **`RECOVER TABLE` example** (12c+) — single-table point-in-time recovery without a
  full PITR.

---

## License

Released under the [MIT License](LICENSE) — free to use, adapt, and share with
attribution.
