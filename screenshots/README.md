# Screenshots

Optional RMAN/SQL\*Plus session captures used in the main README and for portfolio
presentation. Images are not required for the scripts to work — they exist to show
recruiters and hiring managers real RMAN output at a glance.

## Capture guidance

- Run each script against a **non-production / lab** database and capture the terminal
  output (dark theme, monospaced font, wide enough that RMAN output is not wrapped).
- **Sanitize before capturing.** Confirm no real hostnames, IPs, service names, DBIDs,
  schema/user names, or company identifiers are visible. Use a demo database (e.g.,
  `ORADEMO`) so visible names are generic, as in `sample_outputs/`.
- Save as PNG named to match the script, e.g. `full_backup.png`, `recover_database.png`.

## Recommended screenshots (highest portfolio signal first)

1. **`full_backup.png`** — a clean level-0 run finishing with control file/SPFILE
   autobackup. Shows you own the backup strategy end to end.
2. **`recover_database.png`** — RESTORE + RECOVER + `OPEN RESETLOGS`. Recovery is the
   skill interview panels probe hardest; a real recovery transcript is strong proof.
3. **`restore_controlfile.png`** — control file restored from autobackup (NOMOUNT →
   MOUNT). Demonstrates the disaster-recovery starting point.
4. **`validate_database.png`** — `BACKUP VALIDATE` with 0 corrupt blocks + restore
   validate. Signals that you verify recoverability, not just take backups.
5. **`rman_report.png`** — the SQL\*Plus backup-health report. Shows operational
   monitoring discipline.

Five well-chosen, sanitized screenshots beat capturing all eleven. Reference them in the
README with standard markdown image links once added.
