# Contributing and Maintaining the Project

Updated: 2026-10-09. The active application is the PHP/MariaDB café catalogue under `php_app/`. `legacy_django/` is historical reference. Read the actual branch and working tree before editing; [DEVELOPMENT_HANDOFF.md](DEVELOPMENT_HANDOFF.md) records the continuation checkpoint and [QUALITY_REVIEW.md](QUALITY_REVIEW.md) records verification evidence.

## Understand the scope

Read [README.md](README.md), [DECISIONS.md](DECISIONS.md), [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md), [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md) and [DATA_AND_PRIVACY.md](DATA_AND_PRIVACY.md). Follow [AGENTS.md](AGENTS.md), [AGILE_DELIVERY.md](AGILE_DELIVERY.md) and [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md) for file ownership, current work and integration.

Use [GETTING_STARTED.md](GETTING_STARTED.md) for setup and checks, [HOSTINGER_DEPLOYMENT.md](HOSTINGER_DEPLOYMENT.md) for myfanverse.in hosting, and [RUNBOOK.md](RUNBOOK.md) for recovery. The selected runtime is PHP 8.2+ with PDO/`pdo_mysql` and MariaDB 10.11+, InnoDB and utf8mb4. The Zip extension is needed for packaging.

The current increment provides a public catalogue, partial-name/area filters, bounded pagination, full UUID details, about page, guarded synthetic seeding and meaningful tests. PHP catalogue admin, accounts, matching, maps, ratings, member export/deletion, editorial workflows and correction submission are future work. Do not describe legacy features or planned routes as active PHP capabilities.

## Repository and ownership

Keep the repository private. Use your own Git identity and the agreed credential manager; licence and public-release permission are not implied by access.

Preserve local edits. Use a focused branch, normally `codex/<description>`, and the owner-authorized integration/publication workflow. Root coordinates backend, frontend and QA, assigns exact file ownership and integrates shared changes. Agents leave commits/publication to root unless explicitly assigned. Do not write another contributor's files, reset their work or generate competing schema changes.

Each work package should define the user problem, scope, acceptance criteria, data impact, file ownership, dependencies and validation. Keep unrelated changes separate. Record material runtime/provider decisions in DECISIONS rather than silently changing the stack. Agent completion means ready for integration review; root records acceptance before status moves to Done.

## Review expectations

Lead a contribution description with the concrete problem and resulting behaviour. Include changed contracts, actual validation commands/runtime, observed results and remaining limitations. Update relevant documentation in the same change.

A change is ready for review when:

- Assigned acceptance and failure cases are checked, with output escaping and request validation maintained.
- Schema changes have one author, versioned schema/helper changes and an additive migration/recovery plan where needed.
- Public queries consistently exclude inactive cafés/areas and hidden demo rows.
- New configuration has a safe example and strict parsing without committed secrets.
- Runtime behaviour, backlog status and setup/handoff instructions agree.
- Unrun checks, blockers and future scope are reported explicitly.

Keep issues and PRs redacted or synthetic. Do not attach credentials, authenticated URLs, production exports, interviews or participant histories.

## Verify the PHP application

Start the isolated runtime using GETTING_STARTED, then run from the repository root:

```sh
docker compose -f php_app/compose.yaml run --rm test php php_app/scripts/lint.php
docker compose -f php_app/compose.yaml run --rm test php php_app/tests/unit.php
docker compose -f php_app/compose.yaml run --rm test php php_app/tests/config.php
docker compose -f php_app/compose.yaml run --rm test php php_app/tests/package.php
docker compose -f php_app/compose.yaml run --rm test
```

For native PHP, configure the separate disposable local MariaDB `_test` database/user described in GETTING_STARTED and run:

```sh
php php_app/scripts/lint.php
php php_app/tests/unit.php
php php_app/tests/config.php
php php_app/tests/package.php
php php_app/tests/integration.php --allow-reset
```

The integration suite drops/recreates catalogue tables in the explicitly guarded test database. Never run it against production or valuable local data. Rebuild the Docker test image after source edits, because the image copies source at build time.

Choose meaningful cases for changed behaviour: schema setup/upgrade, enforced constraints, seed repeatability and transaction rollback, historical evidence/UUID preservation, combined filters, literal wildcard search, bounded pagination, malformed inputs, active visibility, output escaping, 404/503 responses and packaging/private configuration. Inspect keyboard use and narrow screens for affected UI. Use the optional Hostinger ZIP-layout rehearsal documented in GETTING_STARTED when routing or packaging changes.

CI is configured for PHP 8.2/8.3 and MariaDB 10.11/11.4. An added workflow does not prove a remote CI pass; local/container tests do not prove a Hostinger deployment. Record exact commands, versions and results in QUALITY_REVIEW and the handoff. No Composer, Python, Django or PHPUnit installation is part of this setup.

## Data and configuration changes

Follow DATA_AND_PRIVACY. Use stable UUIDs, permitted/original data and documented sources. Missing evidence remains unknown; preserve historical verification dates. Do not mark old generic “Web research” or “Menu” labels as checked ownership or fresh verification.

For development fixtures, use `php php_app/scripts/seed.php --demo` only with development/test and `DEMO_MODE=true`, or use dedicated synthetic test fixtures. The seed is transactional and preserves existing demo/unrelated rows; it does not restore edited offerings or refresh facts. Production seeding is forbidden, and seeds are excluded from the release ZIP.

The private `php_app/config/local.php` file is ignored by Git and omitted from the ZIP; hosted `config/local.php` stays outside `public_html/`. Process environment overrides string values, and dotenv files are not loaded. Keep the configured database name, including hPanel prefixes, accurate. Use the guarded production schema procedure only for a separately authorized host operation.

## Maintain documentation and handoffs

| Change | Documents to review |
|---|---|
| Available behaviour | README, requirements, backlog and quality review |
| Runtime/configuration/schema | GETTING_STARTED, technical design, decisions and schema README |
| Hosting/package/recovery | HOSTINGER_DEPLOYMENT, RUNBOOK and RELEASE_CHECKLIST |
| Evidence/content/privacy | DATA_AND_PRIVACY and affected requirements/notices |
| Work checkpoint and ownership | DEVELOPMENT_HANDOFF, STARTER_PROMPT and AGENTS |

Date substantial updates and distinguish implemented source, local checks, remote CI and hosted acceptance. Remove obsolete operational/setup commands from the active path and keep historical references clearly marked. Hand over exact files, interfaces, commands/results, limitations and integration decisions so another contributor can continue without this chat.

Report security or sensitive data through an existing private owner channel with minimal redacted details. If a credential is exposed, coordinate revocation/rotation and assess history/exposure; deleting its latest file is insufficient. Do not publish sensitive reports or perform new external actions merely because a work item mentions them.
