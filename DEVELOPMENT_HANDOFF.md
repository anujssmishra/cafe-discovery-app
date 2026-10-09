# Café Discovery — Development Handoff

Updated: 2026-10-09. Context transfers through source/evidence, not credentials or live agent sessions.

## Checkpoint

- Private repository: anujssmishra/cafe-discovery-app.
- Previous review merged/pushed to main: 5c25b1d3a2bf7b3ca1addb35444a06d778ecca7d.
- Continuation branch: main. The verified MariaDB implementation was merged and pushed at checkpoint 1db5344 after user-authorized integration of codex/hostinger-mariadb, based on clean main 5c25b1d. Inspect actual current status/head and preserve edits; never reset to a recorded hash.
- Active app: PHP8.2+/MariaDB10.11+ under php_app/. PDO keeps its mysql driver and native prepares. No Composer/Django/PHPUnit setup required.
- Target: Hostinger Web/Cloud at myfanverse.in. Actual account runtime, deployment, DNS/SSL remain unverified. No live changes or production seed have run.
- Verified: PHP 8.2.34/8.3.35 × MariaDB 10.11.19/11.4.13, 118 integration checks per pair; 27-file lint, 40 unit, 47 config and 105 package checks per PHP runtime; 27 local Apache ZIP-layout checks on PHP 8.2.34. Current test evidence and limits: QUALITY_REVIEW.md. Historical MySQL/Django passes are separate evidence.

## Implementation and contracts

Guest name/area catalogue, literal-wildcard search, stable ordering, bounded twelve-result pagination, full UUID details and about. GET/HEAD, scalar validation, consistent active café/area/demo visibility, escaped output and generic errors. No PHP admin, authentication, recommendations, map, ratings/editorial or checked pilot directory.

InnoDB/utf8mb4 Area/Cafe/CafeOffering schema. MariaDB10.11+ CHECK metadata/session guards; disabled CHECK/FK enforcement is refused before mutation. Schema is additive/non-atomic and does not reconcile arbitrary custom column definitions. Valuable databases require backups and reviewed logical migration; never reuse old MySQL data directories for MariaDB.

Local seed inserts eight fictional cafés/sixteen offerings/two areas with stable UUIDs, one transaction and collision guards. Repeats preserve IDs, evidence, historical dates, edited and unrelated rows. Synthetic dates stay null. Production seeding is prohibited and seed files are excluded from the upload ZIP.

Optional private config/local.php returns allowed uppercase string keys. Environment overrides each value, including empty values. APP_CONFIG_FILE selects an absolute private PHP file; malformed/missing explicit files fail closed. Public paths, aliases and resolved targets are refused. No dotenv loading. Git/Docker/packaging exclude actual local.php; local.example.php has safe placeholders.

Release command: scripts/package.php --output=<absolute new ZIP path outside public>. Explicit allowlist with SHA256 release.json for myfanverse.in. ZIP layout: served public_html with private sibling includes/templates/config/schema/scripts. No tests/demo seeds/private config/Git/Docker content. Production schema CLI requires --apply --production --database=<exact configured DB>, production config and demo disabled. HOSTINGER_DEPLOYMENT.md gives private layout, PHP/phpMyAdmin alternatives, staging, DNS/HTTPS and rollback. Production starts empty until checked real records are entered.

## Start and verify

With Docker's Linux engine running, from the repository root:

```sh
docker compose -f php_app/compose.yaml up -d --build
docker compose -f php_app/compose.yaml exec app php php_app/scripts/schema.php --apply
docker compose -f php_app/compose.yaml exec app php php_app/scripts/seed.php --demo
docker compose -f php_app/compose.yaml run --rm test php php_app/scripts/lint.php
docker compose -f php_app/compose.yaml run --rm test php php_app/tests/unit.php
docker compose -f php_app/compose.yaml run --rm test php php_app/tests/config.php
docker compose -f php_app/compose.yaml run --rm test php php_app/tests/package.php
docker compose -f php_app/compose.yaml run --rm test
```

Open http://127.0.0.1:8000/. Compose uses new cafe-catalogue-mariadb-local storage and separate development/test databases, preserving old MySQL storage. Integration resets only the guarded disposable local _test DB. Source is copied at build time; rebuild after changes. The optional hosting profile serves the actual extracted ZIP at localhost:8081 using private-file production config and the test DB. Native commands are in GETTING_STARTED.md.

## Ownership and next work

Root owns configuration/settings/CI/packaging/compose/shared docs/integration. Backend owns assigned schema/seed files and migrations, frontend routes/templates/styles, QA dedicated tests. One writer per file; agree interfaces and leave commits/publication to root. Backend and QA reviewed MariaDB contracts; independent review fixed path-boundary issues. No prior live agent session is assumed.

Next: actual Hostinger runtime/staging smoke checks, DNS/HTTPS and restore with account access; observe hosted CI; finish keyboard/narrow-screen browser acceptance (previous Windows browser helper initialization failed); audit real catalogue evidence before a pilot. PHP admin/later features stay separate backlog work. No hosting/DNS changes, external messages, purchases or production seed follow from this handoff alone.