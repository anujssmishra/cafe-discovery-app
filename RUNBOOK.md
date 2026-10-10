# Café Discovery Runbook

## Overview
This runbook covers routine operations, backup/restore, and rollback procedures for the Café Discovery pilot.

## Environment Variables
- `DJANGO_SECRET_KEY`: Minimum 50 chars, secret.
- `DJANGO_ALLOWED_HOSTS`: Explicit comma-separated hosts (e.g. `cafes.example.com`).
- `DJANGO_DEBUG`: Usually `false` in production.
- `DATABASE_URL`: PostgreSQL connection string (e.g. `postgres://user:password@host:port/db`).

## Health Check
The application exposes a health check endpoint at `/health/` which verifies database connectivity.

## Backup
To back up the PostgreSQL database:
```bash
pg_dump $DATABASE_URL -F c -f backup_$(date +%Y%m%d).dump
```

## Restore
To restore from a backup:
```bash
pg_restore -d $DATABASE_URL -1 backup_YYYYMMDD.dump
```

## Rollback Procedure
If a deployment fails:
1. Revert to the previous stable Git commit: `git checkout <previous-tag-or-commit>`.
2. Restore the database from the pre-deployment backup using the restore command above.
3. Restart the application server.
