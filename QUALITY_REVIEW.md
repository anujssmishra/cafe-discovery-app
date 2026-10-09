# MariaDB and Hostinger release verification

Updated: 2026-10-09. Review prepared on codex/hostinger-mariadb at implementation checkpoint 1db5344, based on clean main 5c25b1d3a2bf7b3ca1addb35444a06d778ecca7d. User-authorized integration was merged and pushed to main on 2026-10-09; use main for continuation. Fetch found no newer origin/main at the start of this work. The user requested MariaDB and a Hostinger-ready deployment for myfanverse.in. This section supersedes the earlier runtime target; historical review evidence follows below.

## Fixes and independent review

- P1: MySQL-only version/CHECK metadata blocked Hostinger's MariaDB family. Schema and transactional seed now target MariaDB10.11+, use MariaDB CHECK_CONSTRAINTS, retain native PDO prepares, and reject disabled session CHECK/FK enforcement before mutations. The schema is additive/non-atomic; old custom types/defaults/same-named constraint definitions require manual review.
- P1: Shared-host web PHP cannot rely on shell-only DB environment. Private sibling config/local.php now works without web process environment. Explicit config paths fail closed, environment overrides strings including empty values, and public paths/aliases/targets are refused. Credentials stay outside Git/Docker/ZIP/public_html.
- P2: Added an explicit allowlisted Hostinger ZIP with public_html and private sibling directories, 20 content hashes and release.json. It excludes seeds/tests/private config/Git/Docker/legacy source. Independent backend review identified symlinked source directories, public configuration aliases and cross-OS absolute-path validation defects; root fixed them and QA regression tests passed. Output aliases under public directories are refused too.
- P2: Production schema setup is CLI-only, requires explicit --apply --production --database=<exact configured DB>, validates production/demo-off config and connected DB, and never enables seeding. Deployment guide includes a fresh-empty-db phpMyAdmin alternative, staging/backup/rollback, actual hPanel DNS values and HTTPS for myfanverse.in.
- Local Compose switched to a new MariaDB service/project/volume. Historical cafe-catalogue-local_mysql-data remains preserved; no MySQL data directory was reused. Old PHP/Apache containers were stopped to free local ports.
- CI runs lint (nonzero on any failure), unit/config/package and MariaDB/HTTP checks across PHP8.2/8.3 × MariaDB10.11/11.4. Runtime dependency/package contracts were independently reviewed by QA; operational documents by the hosting/documentation agent. Root reviewed the integrated source and ZIP hashes.

## Actual results

Tests ran in Linux containers on Docker Desktop from the Windows checkout. No native PHP/MariaDB runtime was used.

| Runtime | Command / check | Observed result |
|---|---|---|
| PHP8.2.34 and PHP8.3.35 | php php_app/scripts/lint.php | 27 PHP files passed on each runtime |
| PHP8.2.34 and PHP8.3.35 | php php_app/tests/unit.php | 40 passed on each |
| PHP8.2.34 and PHP8.3.35 | php php_app/tests/config.php | 47 passed on each, including Linux symlink/cross-OS probes |
| PHP8.2.34 and PHP8.3.35 | php php_app/tests/package.php | 105 passed on each, including 20 file hashes and secret/symlink/output exclusions |
| PHP8.2.34 / MariaDB10.11.19-MariaDB-ubu2204 | php php_app/tests/integration.php --allow-reset | 118 passed |
| PHP8.3.35 / MariaDB10.11.19-MariaDB-ubu2204 | same integration command | 118 passed |
| PHP8.2.34 / MariaDB11.4.13-MariaDB-ubu2404 | same integration command | 118 passed |
| PHP8.3.35 / MariaDB11.4.13-MariaDB-ubu2404 | same integration command | 118 passed |
| PHP8.2.34 / local Apache / MariaDB10.11.19 | php php_app/tests/hosting.php http://hosting | 27 passed against the extracted ZIP, private production config and Host: myfanverse.in |
| PHP8.2.34 | Temporary invalid.php containing '<?php if (' passed to scripts/lint.php | Correctly returned exit1; probe removed |
| Delivered release | SHA256 manifest compared with current checkout | All20 runtime/schema/template file hashes match; 21 ZIP entries |

Integration covers fresh/additive schema, stable legacy fixture UUIDs, two seeds preserving complete rows/counts/IDs/unrelated records/historical evidence, collision/fault rollback, CHECK/FK validation, disabled-session refusal before DDL/writes, caller-owned transactions, guarded production CLI (ONLY disposable local _test database), combined filters, ordering/pagination, malformed input, empty results, active/demo visibility, detail404s and generic configuration/database errors. No production database was contacted.

Apache checks cover catalogue/combined filters/page2/filter-preserving links/full UUID details/about/empty states/array queries/404s/demo hiding/CSS MIME/HEAD/405 and HTTP denial of config/includes/scripts/schema/manifest/dotfiles. They confirm Apache .htaccess and actual public_html/sibling layout, not Hostinger's LiteSpeed service or visual accessibility.

From the repository root, the exact primary checks were:

```sh
docker compose -f php_app/compose.yaml build app test hosting
docker compose -f php_app/compose.yaml up -d app
docker compose -f php_app/compose.yaml exec -T app php php_app/scripts/schema.php --apply
docker compose -f php_app/compose.yaml exec -T app php php_app/scripts/seed.php --demo
docker compose -f php_app/compose.yaml run --rm test php php_app/scripts/lint.php
docker compose -f php_app/compose.yaml run --rm test php php_app/tests/unit.php
docker compose -f php_app/compose.yaml run --rm test php php_app/tests/config.php
docker compose -f php_app/compose.yaml run --rm test php php_app/tests/package.php
docker compose -f php_app/compose.yaml run --rm test
docker compose -f php_app/compose.yaml --profile hosting up -d hosting
docker compose -f php_app/compose.yaml run --rm test php php_app/tests/hosting.php http://hosting
```

Additional compatibility runs used `docker build --build-arg PHP_VERSION=8.3 -t cafe-catalogue-php83-local php_app`, the mariadb:11.4 official image in a separate cafe-catalogue-compat-local network, a local alias mariadb, no published DB port and disposable tmpfs storage. Set APP_ENV=test, DEMO_MODE=true, DB_HOST=mariadb, DB_NAME=cafe_discovery_test, DB_USER=cafe, DB_PASS=local-demo-only on each runner; execute the same commands in the table using docker run --rm --network <isolated-network> <PHP-image> php <test-path>. PHP8.3/MariaDB10.11 used cafe-catalogue-mariadb-local_default; PHP8.2/MariaDB11.4 used cafe-catalogue-mariadb-local-test. The temporary11.4 container/network were stopped/removed afterward; development/test10.11 and the historical MySQL volume remain intact.

A configuration test first failed because proc_open omitted empty env-array values in spawned PHP; the harness now sets explicit keys in the isolated child with putenv, and the full47 checks passed. The loader itself correctly respected actual process environment. No failed test was recorded as passing.

## Release and remaining acceptance

Release: localdata/releases/hostinger-myfanverse.in.zip (ignored, outside public). SHA256: 2835d397219653b7dca4201c86138ef04483fa04ecfa34ba57821828ec7b59b5. The manifest identifies the intended domain; it does not configure DNS. HOSTINGER_DEPLOYMENT.md provides upload/private-config/schema/DNS/SSL steps.

Actual Hostinger account PHP/MariaDB versions, staging/live responses, DNS/SSL, host permissions/logging and backup restoration remain unrun because no live hosting access/values were supplied. GitHub-hosted CI is unobserved; its matrix is configuration, not an observed pass. Apache hosting.php is a local check and is not run by the current CI workflow. Windows-native optional test branches are unrun. Keyboard/narrow-screen visual acceptance remains open from the previous browser helper initialization failure; no new browser pass is claimed. Production starts empty; real catalogue sourcing and PHP admin/later features are separate work.

No live deployment, DNS changes, production schema/seed or external communications occurred. The verified MariaDB implementation was merged and pushed to main at checkpoint 1db5344 following user authorization on 2026-10-09. Both remote main and the feature branch were independently confirmed at that SHA. No hosted CI pass is inferred from publication.

---
# PHP catalogue review and verification

Updated: 2026-10-09. Baseline: `ba97a0a`; review branch: `fix/php-catalogue-review`. Fetches found no newer `origin/main` at the start of this review. The user subsequently authorized merging the reviewed fixes into main and pushing. Git history and the remote head are authoritative for publication; this document is local implementation evidence, not deployment evidence.

## Prioritized findings and fixes

| Priority | Reproducible baseline defect | Final behavior and evidence |
|---|---|---|
| P1 | seed.php deleted every café/offering before inserting random UUIDs; a later error could leave unrelated data deleted | CLI-only local demo guard, explicit --demo, fixed legacy demo UUIDs, InnoDB transaction, reserved-identifier collision refusal; existing cafés and their whole offering sets remain untouched. Full-row snapshots verify repeatability and rollback. |
| P1 | The café INSERT reused :checked three times with native PDO prepares | Positional parameters are used in every seed INSERT. MySQL reproduces the original HY093 in the regression suite, then executes the corrected seed successfully. |
| P1 | DB exceptions were rethrown before a visitor error boundary | Strict process-environment configuration and a buffered front controller return generic 503 responses. HTTP tests deliberately use invalid local credentials with display_errors enabled and verify no database/internal details appear. |
| P2 | Every run assigned today to unsourced real-data claims labelled Web research/Menu | New fixtures are explicitly fictional, with null evidence dates and unknown ownership/counts. Existing sources/dates/URLs are preserved. Generic source labels never establish verified ownership in the UI. |
| P2 | q/area accepted arrays; page was ignored; the UUID route accepted malformed shapes | Scalar, UTF-8, length, control-character, slug, page and full UUID validation. Invalid filters receive informative 400 responses; unavailable/malformed details receive 404. |
| P2 | Unbounded results, no filter-preserving pagination, and inactive areas still exposed cafés | Twelve results per page; bounded requested pages; literal LIKE wildcards; name/UUID tie ordering; shared café/area/demo visibility; informative empty states. |
| P2 | Missing static/site.css, no development router/Apache rewrite configuration, no about page | Public-only document root, working CSS, local router and .htaccess; APP_BASE_PATH-aware links; about/error templates, labelled controls, skip link and visible focus styles. |
| P2 | Schema lacked validation for flags, coordinates, UUIDs, prices, drinks, currency and ownership | Enforced MySQL CHECK constraints, foreign keys and query indexes; guarded additive setup repairs missing/disabled checks without altering records. Negative tests verify exact MySQL constraint error codes. |
| P2 | A shell lint loop could hide an earlier failure; active documentation described obsolete Django setup/features | The lint runner accumulates failures and returns nonzero. CI runs PHP 8.2/MySQL tests. README, setup/design/handoff/backlog use the actual PHP contracts and distinguish future features. |

## Integrated checks actually run

Environment: Windows workspace with Docker Desktop's Linux engine; container PHP **8.2.34**, pdo_mysql, native prepares; **MySQL 8.0.46**, InnoDB/utf8mb4. No native PHP/MySQL executable was available on PATH. No Composer, Python/Django setup or PHPUnit installation is required.

All commands below ran from the repository root against local containers:

| Command/check | Observed result |
|---|---|
| docker compose -f php_app/compose.yaml --profile test build --quiet app test | Exit 0; source-copy images rebuilt after integration.php was saved |
| docker compose -f php_app/compose.yaml run --rm test php php_app/scripts/lint.php | Exit 0; **21 PHP files** |
| docker compose -f php_app/compose.yaml run --rm test php php_app/tests/unit.php | Exit 0; **40 checks** |
| docker compose -f php_app/compose.yaml run --rm test | Exit 0; saved integration runner **92 checks**, PHP 8.2.34/MySQL 8.0.46 |
| Deliberately invalid temporary PHP file followed by a valid file, using scripts/lint.php | Runner exited **1**; temporary fixtures removed |
| Schema --apply, then seed --demo twice on the separate local development DB | Initial insertion: 2 areas/8 cafés/16 offerings. Second run: 0 inserts; 8 existing cafés preserved |
| Read-only HTTP checks at localhost:8000 and Apache localhost:8080/guide | **19 checks passed**: catalogue/details/about/CSS, array inputs, empty/missing records, hidden files, Apache subdirectory rewrites and prefixed links |
| Production-mode seed refusal and missing --demo on the isolated test configuration | Expected exits **1** and **2** respectively; production-mode guard rejects before connection |

The saved integration suite resets only a disposable local database whose name ends `_test`, requires APP_ENV=test plus `--allow-reset`, and refuses unapproved hosts. It verifies schema creation/reapplication, all eight independently recorded legacy demo UUIDs, unrelated rows, multiple full-row seed snapshots including historical dates/sources/flags, collision safety, caller transaction ownership, and an injected CHECK failure after a café and its first offering are inserted. Transaction state is captured before cleanup DDL; a subsequent successful seed verifies recovery. No SUPER privilege or database-global setting change is needed.

Catalogue/HTTP coverage includes 26 combined-filter results over three pages, very large page bounds, wildcard decoys, equal-name UUID ordering, inactive cafés/areas, active-demo hiding, malformed arrays/control characters/lengths, safe empty/404 responses, escaped malicious names/addresses, zero prices, unknown evidence, methods/HEAD, subdirectory assets/details, blocked nonpublic paths and generic connection failures. Temporary HTTP processes are cleaned up.

Earlier direct temporary probes passed 21 MySQL and 42 catalogue/HTTP checks. They are supplemental evidence, not substitutes for the final saved 92-check runner.

## Independent review and remaining limits

Backend/data, frontend/routing and QA packages had separate file ownership. Root applied/integrated their handoffs, independently inspected the schema/controllers/templates, and ran the combined checks. QA strengthened rollback error matching, transaction-state capture before DDL, wildcard decoys, name ties and active-demo visibility. Backend reviewed the final seed/schema contracts and reported no remaining backend blocker.

- Browser automation was attempted twice but its Windows helper failed to initialize (`helper_unknown_error: setup refresh had errors`). CSS/labels/focus/skip-link/table markup were inspected; **visual narrow-screen and interactive keyboard acceptance remain unverified**. Keep CAFE-104 in Verify.
- Hostinger/LiteSpeed installation, actual host DB/version compatibility, private environment delivery, HTTPS/log/backup/restore and production readiness are **unrun**. Local Apache rewrites are useful evidence, not proof of Hostinger deployment.
- Remote CI is configured; record a hosted run only after observing its actual result. Local tests do not imply remote success.
- Existing databases with valuable data need a backup and manual review of custom column types/defaults or same-named custom constraints. MySQL DDL is additive and non-atomic; invalid old records may prevent a constraint from being added. No automatic data deletion/engine conversion occurs.
- Existing edited/incomplete demo offering sets stay untouched; the seed does not repair curator edits or recreate deleted offerings. InnoDB AUTO_INCREMENT gaps after rollback are expected.
- Existing Lucknow facts, sources, prices, ownership and counts require a factual audit before a real pilot. Seeds supply no real verification.
- PHP admin, accounts, matching, maps, ratings/editorial UI and pilot operations remain backlog work.

No deployment or production seed was performed. The repository remains private.
