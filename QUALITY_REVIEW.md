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
