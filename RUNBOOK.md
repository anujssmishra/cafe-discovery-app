# Café Discovery Runbook

Updated: 2026-10-09. This runbook covers the current PHP catalogue and manual Hostinger release operations. [GETTING_STARTED.md](GETTING_STARTED.md) is authoritative for local setup; [HOSTINGER_DEPLOYMENT.md](HOSTINGER_DEPLOYMENT.md) is authoritative for the myfanverse.in deployment layout and host checks. Actual deployment, backup schedules and restore drills require recorded host-specific evidence.

## Runtime and configuration

The active application is in `php_app/`: PHP 8.2+ with PDO/`pdo_mysql`, MariaDB 10.11+, InnoDB and utf8mb4. The PDO driver remains named `mysql` when connecting to MariaDB. The PHP Zip extension is required to build a release archive; serving the application does not require Zip.

Production uses `APP_ENV=production`, `DEMO_MODE=false` and an empty `APP_BASE_PATH` for https://myfanverse.in/. Configure `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER` and `DB_PASS` in the private `config/local.php` outside `public_html/`. Values are strings. Process environment takes precedence, including empty values; optional `APP_CONFIG_FILE` must select an absolute private file outside the web root. The application does not load dotenv files. Use the safe example and exact hPanel database names described in the deployment guide.

Keep logs, credentials, ZIP archives, database exports and Git history outside the public web root. Preserve the host's private configuration on each upload; it is excluded from release archives.

## Local development and verification

Run from the repository root with Docker's Linux engine available:

```sh
docker compose -f php_app/compose.yaml up -d --build
docker compose -f php_app/compose.yaml exec app php php_app/scripts/schema.php --apply
docker compose -f php_app/compose.yaml exec app php php_app/scripts/seed.php --demo
```

Open http://127.0.0.1:8000/. These commands create the local MariaDB schema and clearly fictional demo catalogue. Seeding is allowed only in development/test with `DEMO_MODE=true` and the explicit `--demo` flag. It preserves existing UUIDs, records and historical evidence. Never run seeds against production.

Run the five lint, unit, configuration, package and integration commands in [GETTING_STARTED.md](GETTING_STARTED.md). The integration suite resets only the disposable local database ending `_test`; do not point it at valuable data. The optional `hosting` profile rehearses the extracted ZIP layout locally at http://127.0.0.1:8081/ with a private production-mode reader configuration and synthetic QA records.

Docker copies source at build time. Rebuild/recreate affected services after edits. Stop local services without deleting database storage:

```sh
docker compose -f php_app/compose.yaml --profile hosting --profile routing down
```

Keep historical MySQL storage separate from the new MariaDB volume. Transfer valuable data through a reviewed logical export/import into a separate database, followed by row/constraint checks; never mount an old MySQL data directory into MariaDB.

## Availability and incident checks

The current PHP app has no `/health/` endpoint. Check the catalogue root, `/about/` and `/static/site.css` using the expected origin. A successful catalogue response also exercises a database query; the about page and stylesheet alone do not establish database availability. An empty catalogue can be a valid 200 response.

| Symptom | Investigation |
|---|---|
| Generic 503 | Check private PHP/server logs, PDO availability, database access, schema and private configuration; keep visitor error display off |
| Detail 404 | Check full UUID, active café/area flags and demo visibility |
| Empty catalogue | Check filters and visibility; a new production database has no real café data |
| Missing CSS or routing 404 | Check public_html layout, hidden .htaccess upload and APP_BASE_PATH |
| Schema command refused | Confirm actual MariaDB version, enabled checks, environment and explicit database acknowledgement |
| Seed refused | Confirm isolated development/test settings and inspect identifier collisions; production refusal is expected |

Visitors receive a generic error page; server logs record exception class/code. Keep connection diagnostics, credentials and submitted private values out of public reports. Do not force a database outage on the live site to test error handling; use staging for failure cases.

## Backup and restore

Before a release or schema change, save the existing runtime files, private configuration and a logical MariaDB database export in protected storage outside the web root and repository. Use the hosting account's available backup/export tools, such as phpMyAdmin, and confirm the backup includes all relevant tables and schema. A Docker volume or an untested backup file is not restore evidence.

Record the backup timestamp, source database, release, location, responsible owner and retention. Check the actual hosting plan's backup availability and schedule rather than assuming they are configured. Never include backup content or credentials in Git, issues or release archives.

Rehearse restoration into a separate isolated database using the supported MariaDB runtime. Verify table engines, schema/constraints, row counts and UUIDs, historical sources/dates, and catalogue/detail behaviour against the restored copy. Record the observed results and the time required. Keep `check_constraint_checks` and `foreign_key_checks` enabled during normal application operation and schema/seed checks.

For an actual recovery, assess newer records and coordinate the outage before replacing a live database. Restore the chosen backup through the authorized hosting/database tools, restore compatible application files and private configuration, then repeat the smoke checks in the deployment guide. A database restore can discard changes since the backup.

## Schema changes, release and rollback

Build the allowlisted ZIP from a tested checkout and retain its `release.json` manifest with the release record. Only `public_html/` is served; private sibling folders preserve the application include paths. Follow the deployment guide for upload, MariaDB verification, explicitly acknowledged production schema setup, myfanverse.in DNS and HTTPS.

MariaDB DDL implicitly commits. The additive schema helper does not delete records, but statements completed before a failure can remain applied and table locks can occur. Rehearse changes on staging, take a restorable backup, inspect failures and recover deliberately. Do not disable constraints or drop existing tables to bypass an error.

If an application/configuration update fails, restore the previous compatible runtime package and private configuration, then repeat availability checks. Reverting source files does not undo schema changes. Inspect applied DDL and use the reviewed recovery plan or database backup when necessary, preserving any newer records before replacement.

## Operational record

For each release or incident, record the revision/package, actual PHP/MariaDB versions, environment, backup and restore evidence, schema commands and exit results, smoke checks, limitations, owner and rollback decision. Keep local tests, remote CI, Apache rehearsal and actual Hostinger/DNS/SSL acceptance distinct. Update [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md), [QUALITY_REVIEW.md](QUALITY_REVIEW.md) and [DEVELOPMENT_HANDOFF.md](DEVELOPMENT_HANDOFF.md) with observed evidence.
