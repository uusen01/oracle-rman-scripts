# Repository Setup Guide (publishing checklist)

> This file is for you, Usen — it is NOT portfolio content. After you set the GitHub
> topics and confirm everything looks right, delete it (or keep it private). It explains
> where every file belongs, the topics to add, the screenshots to capture, and how to
> publish `oracle-rman-scripts`.

---

## 1. Where every file belongs

```
oracle-rman-scripts/                         <- repository root
├── README.md                                <- main landing page
├── LICENSE                                   <- MIT license (GitHub auto-detects at root)
├── .gitignore                               <- keeps logs, backup pieces, credentials out of git
├── REPO_SETUP.md                             <- THIS file (delete before/after publishing)
│
├── scripts/                                  <- 11 executable scripts
│   ├── full_backup.sql
│   ├── archivelog_backup.sql
│   ├── controlfile_backup.sql
│   ├── spfile_backup.sql
│   ├── validate_database.sql
│   ├── crosscheck_backup.sql
│   ├── delete_obsolete.sql
│   ├── restore_controlfile.sql
│   ├── recover_database.sql
│   ├── duplicate_database.sql
│   └── rman_report.sql                       <- the only SQL*Plus script
│
├── sample_outputs/                           <- one fictional, sanitized sample per script
│   ├── full_backup_sample.txt
│   ├── archivelog_backup_sample.txt
│   ├── controlfile_backup_sample.txt
│   ├── spfile_backup_sample.txt
│   ├── validate_database_sample.txt
│   ├── crosscheck_backup_sample.txt
│   ├── delete_obsolete_sample.txt
│   ├── restore_controlfile_sample.txt
│   ├── recover_database_sample.txt
│   ├── duplicate_database_sample.txt
│   └── rman_report_sample.txt
│
├── docs/
│   ├── RMAN Backup Procedure.md
│   ├── Restore and Recovery Guide.md
│   └── RMAN Troubleshooting Guide.md
│
└── screenshots/
    └── README.md
```

Rationale: `README.md` and `LICENSE` live at the root so GitHub renders/detects them.
Executable scripts under `scripts/`; fictional results under `sample_outputs/` so a
reviewer can read outcomes without opening code; markdown docs render on GitHub.

---

## 2. GitHub topics (add via the ⚙️ next to "About")

```
oracle
oracle-database
rman
backup-and-recovery
disaster-recovery
dba
database-administration
oracle-19c
oracle-21c
backup
recovery
high-availability
database-engineering
point-in-time-recovery
```

Suggested **About** description:
> *Production-style Oracle RMAN backup, recovery, and maintenance scripts (11g–21c) —
> full/incremental backups, validation, retention, restore, PITR, and duplication.
> Sanitized.*

---

## 3. Screenshots to capture (optional, high-impact)

From a lab DB, sanitized, dark terminal. Priority order:

1. `full_backup.png` — clean level-0 + autobackup
2. `recover_database.png` — RESTORE + RECOVER + OPEN RESETLOGS
3. `restore_controlfile.png` — control file from autobackup (NOMOUNT → MOUNT)
4. `validate_database.png` — 0 corrupt blocks + restore validate
5. `rman_report.png` — backup-health report

See `screenshots/README.md` for detail. Five is plenty.

---

## 4. Publishing steps

```bash
cd oracle-rman-scripts
git init
git add .
git commit -m "Oracle RMAN backup, recovery, and maintenance scripts (11g-21c)"
git branch -M main
git remote add origin https://github.com/uusen01/oracle-rman-scripts.git
git push -u origin main
```

Then on github.com/uusen01/oracle-rman-scripts:
1. Add the **topics** from section 2 and set the **About** description.
2. Confirm `LICENSE` shows "MIT" in the sidebar.
3. (Optional) add screenshots and link them in the README.
4. **Pin** the repo on your profile.
5. Make sure the profile README "Featured" link points here as a clickable markdown link.

---

## 5. Final sanitization pass before pushing

- [ ] No real hostnames, IPs, SIDs, service names, or DBIDs (scripts use placeholders;
      `DBID 1234567890`, `ORADEMO`, `SRCDB`/`AUXDB` are fictional).
- [ ] No credentials; no `tnsnames.ora`/`login.sql`/password files committed (.gitignore covers these).
- [ ] No backup pieces, datafiles, or real logs committed (.gitignore covers these).
- [ ] No USPS / AT&T / GM / employer identifiers in any file.
- [ ] Sample outputs are clearly fictional and labeled in the README disclaimer.
- [ ] Delete this `REPO_SETUP.md` if you don't want it public.
