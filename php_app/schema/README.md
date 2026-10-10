# PHP catalogue schema

The target runtime is PHP 8.2 with the PDO MySQL driver and MariaDB 10.11 or newer, matching the selected Hostinger Shared database family. The PDO driver remains named `mysql` when it connects to MariaDB. All catalogue tables require InnoDB and utf8mb4. MySQL servers and older MariaDB versions are refused by schema setup and demo seeding.

MariaDB enforces CHECK constraints while `check_constraint_checks` is enabled. Both setup and seeding refuse connections with either session `check_constraint_checks=0` or `foreign_key_checks=0` before performing any DDL or writes. They never disable or change either setting. The additive setup checks MariaDB's `information_schema.CHECK_CONSTRAINTS`; it does not use MySQL's `ENFORCED` metadata or `ALTER CHECK` syntax. See the [MariaDB constraint documentation](https://mariadb.com/docs/server/reference/sql-statements/data-definition/constraint) and [constraint metadata](https://mariadb.com/docs/server/reference/system-tables/information-schema/information-schema-tables/information-schema-check_constraints-table).

For an empty local development database, set APP_ENV=development and the private DB_* configuration values described in GETTING_STARTED, then run:

    php php_app/scripts/schema.php --apply

The same command upgrades the original reviewed PHP schema by adding missing named constraints, visibility/order indexes and foreign keys. It never deletes or updates rows. Existing non-InnoDB tables, missing columns and invalid values require a separately reviewed migration. It verifies required column names, not arbitrary custom column types/defaults. A same-named custom constraint may need separate semantic review.

Back up existing data and confirm the backup can be restored before applying schema changes. [MariaDB DDL implicitly commits](https://mariadb.com/docs/server/reference/sql-statements/transactions/sql-statements-that-cause-an-implicit-commit): earlier statements can remain if a later statement fails. Schema setup is additive, but it can acquire table locks. Run it during a maintenance window, inspect any failure and recover deliberately rather than dropping tables or inventing evidence. Keep backups and credentials outside Git and the public web root.

For a separately authorized production schema installation or additive upgrade, configure APP_ENV=production, DEMO_MODE=false and the private database settings. The normal `--apply` command refuses production. An explicit acknowledgement must match the configured database name exactly, including case:

    php php_app/scripts/schema.php --apply --production --database=<exact configured DB_NAME>

Replace the entire `<exact configured DB_NAME>` placeholder with the actual configured name. The script also checks the connected database before applying DDL. The production flags are refused in development/test environments. This acknowledgement permits schema setup only; it does not enable demo seeding or create production catalogue content. Do not put passwords in command arguments. See HOSTINGER_DEPLOYMENT for the private configuration and public-file layout.

For fictional demo data, set DEMO_MODE=true and run:

    php php_app/scripts/seed.php --demo

The seed remains restricted to APP_ENV=development or test, DEMO_MODE=true and the explicit `--demo` argument. It is never allowed in production. It owns a transaction and refuses missing/non-InnoDB tables. Eight cafés use fixed UUIDs from the legacy demo; two areas use reserved unique slugs. A slug with a different name/city or a café UUID belonging to a non-demo record is rejected, with transaction rollback. Reserved demo area identity must remain unchanged to rerun; other curator edits are preserved. Existing demo cafés, their entire offering sets, inactive flags, names, sources, dates and IDs remain untouched; the seed does not repair deleted/edited offerings. All unrelated records are preserved.

New demo rows have null checking dates, unknown independence/counts and an explicit synthetic source. The old real Lucknow rows are not refreshed or deleted; their provenance needs a human audit. Transactions restore rows on failure, but MariaDB AUTO_INCREMENT sequence gaps may remain. Production schema setup requires the acknowledgement above; production seeding remains prohibited. Local MariaDB compatibility checks do not establish a successful Hostinger deployment.
