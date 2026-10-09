# PHP catalogue schema

PHP 8.2 with PDO MySQL and MySQL 8.0.16+ are the reviewed targets. All catalogue tables require InnoDB and utf8mb4; CHECK constraints must be enforced. MariaDB/Hostinger engine compatibility is not established.

For an empty local development database, set APP_ENV=development and private DB_* process environment values, then run:

    php php_app/scripts/schema.php --apply

The same command upgrades the original reviewed PHP schema by adding missing named constraints, visibility/order indexes and foreign keys. It never deletes or updates rows. Existing non-InnoDB tables, missing columns and invalid values require a separately reviewed migration. It verifies required column names, not arbitrary custom column types/defaults. A same-named custom constraint may need separate semantic review.

Back up valuable development data first. MySQL DDL implicitly commits: earlier statements can remain if a later statement fails. Inspect the failure rather than dropping tables or inventing evidence. This command refuses APP_ENV=production.

For fictional demo data, set DEMO_MODE=true and run:

    php php_app/scripts/seed.php --demo

The seed owns a transaction and refuses missing/non-InnoDB tables. Eight cafés use fixed UUIDs from the legacy demo; two areas use reserved unique slugs. A slug with a different name/city or a café UUID belonging to a non-demo record is rejected, with transaction rollback. Reserved demo area identity must remain unchanged to rerun; other curator edits are preserved. Existing demo cafés, their entire offering sets, inactive flags, names, sources, dates and IDs remain untouched; the seed does not repair deleted/edited offerings. All unrelated records are preserved.

New demo rows have null checking dates, unknown independence/counts and an explicit synthetic source. The old real Lucknow rows are not refreshed or deleted; their provenance needs a human audit. Transactions restore rows on failure, but MySQL AUTO_INCREMENT sequence gaps may remain. Never run seeds or setup against production.
