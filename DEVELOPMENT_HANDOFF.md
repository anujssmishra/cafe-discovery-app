# Café Discovery — Development Handoff

Updated: 2026-10-09. This file transfers project context through source and evidence, not live agent sessions or credentials.

## Checkpoint

| Item | Current state |
|---|---|
| Repository | Private anujssmishra/cafe-discovery-app |
| Base | Clean main ba97a0a; fetch origin/main on 2026-10-09 found no newer commits |
| Review branch | fix/php-catalogue-review; main is the continuation branch after user-authorized integration |
| Active application | PHP 8.2 / MySQL, under php_app/ |
| Local review | Seed/schema, controller/validation/errors, routing/assets/templates, MySQL/HTTP tests and documentation |
| Publication | User authorized merge into main and push; inspect remote/Git history for the completed publication. No PR or deployment is part of this review |
| Verification | PHP 8.2.34/MySQL 8.0.46: lint 21 files, unit 40, saved MySQL/HTTP suite 92 passed. See QUALITY_REVIEW.md for exact commands and limits |
| Historical reference | legacy_django/; its earlier 49-test record is not PHP evidence |

Inspect actual Git status and head first. Preserve Anuj's edits; do not reset to a recorded hash. Prior handoffs describing feat/sprint-1-catalogue as an unmerged Django implementation are superseded by this PHP checkpoint.

## Implemented scope and contracts

- Environment configuration, native PDO MySQL prepares and generic visitor error responses. PHP reads process environment only.
- InnoDB Area/Cafe/CafeOffering schema with stable café UUIDs, optional prices/coordinates and separate provenance fields.
- Eight fictional cafés, sixteen synthetic offerings and two fictional areas; CLI-only local demo seeding with explicit --demo, stable identifiers, transaction rollback and collision checks. Existing rows and historical evidence are preserved.
- GET/HEAD catalogue, partial-name/area filtering, literal wildcard handling, twelve-result bounded pagination, full UUID details and about page. List and detail enforce active café/area and demo visibility consistently.
- Validated scalar q/area/page input, informative 400/404/503 states, escaped UTF-8 output, working static CSS and local/Apache routing.
- MySQL integration and HTTP regression suite plus portable lint that fails CI on invalid PHP.

There is no PHP catalogue admin, authentication, personalized matching, map, visit/ratings UI, editorial workflow, real verified pilot directory or production deployment. Preserve those as future work.

## Repository map

| Path | Responsibility |
|---|---|
| php_app/includes/config.php, db.php | Strict environment parsing; db_connect() with native prepares |
| php_app/includes/request.php, catalogue.php, web.php | Request validation, shared public queries, output/URL helpers |
| php_app/public/index.php, router.php, .htaccess | Front controller, PHP development routing, Apache/LiteSpeed routing |
| php_app/public/static/, templates/ | Responsive assets and server-rendered pages |
| php_app/schema/, scripts/ | Schema setup/upgrade and guarded synthetic seed |
| php_app/tests/ | Unit, MySQL and HTTP acceptance checks |
| php_app/Dockerfile, compose.yaml, docker/ | Local isolated PHP/MySQL runtime and separate test DB |
| .env.example, .github/workflows/ci.yml | Configuration reference and PHP/MySQL CI |
| legacy_django/ | Previous source/reference; excluded from active setup |

## Start and verify

From the repository root with Docker running:

```sh
docker compose -f php_app/compose.yaml up -d --build
docker compose -f php_app/compose.yaml exec app php php_app/scripts/schema.php --apply
docker compose -f php_app/compose.yaml exec app php php_app/scripts/seed.php --demo
docker compose -f php_app/compose.yaml run --rm test php php_app/scripts/lint.php
docker compose -f php_app/compose.yaml run --rm test php php_app/tests/unit.php
docker compose -f php_app/compose.yaml run --rm test
```

Open [the local application](http://127.0.0.1:8000/). Native startup is `php -S 127.0.0.1:8000 -t php_app/public php_app/public/router.php` after local DB/environment/schema/seed setup in [GETTING_STARTED.md](GETTING_STARTED.md).

The integration command explicitly resets only the disposable local `_test` database. Never run it against production or a database containing work to keep. Compose's development database and test database are separate.

## Review decisions and remaining work

The destructive real-data seed was replaced by fictional inserts because its “Web research”/“Menu” claims did not identify evidence. Existing Lucknow rows are not rewritten or removed. Their URLs/dates are preserved, but provenance, ownership, counts and prices still need a factual audit before any pilot. No seed run supplies verification.

For existing PHP databases, review the additive schema upgrade in php_app/schema/; CREATE TABLE IF NOT EXISTS alone does not alter existing constraints. Back up before applying any schema change to a database with valuable local data. Hostinger deployment/runtime, private configuration delivery, backups/restoration and release readiness need independent checks.

Next, complete interactive keyboard/narrow-screen inspection once browser tooling works; CAFE-104 remains Verify. Observe the hosted CI run for the pushed commit rather than inferring success. Hostinger and real-data validation remain unrun. PHP admin is a separate future work package. Guest matching, accounts/privacy, maps/editorial and real data remain governed by product/data requirements. Do not interpret historical unsupported Done flags as implementation.

## Working agreement

Root coordinates integration and shared settings/docs/CI. Backend owns assigned schema/seed files, frontend assigned templates/routing/assets, QA assigned tests and evidence. Read existing changes and assign exact files before parallel work. Agents leave commits/publication to root unless explicitly assigned. All substantive checks must state actual environment/results; local passes do not imply hosted CI or deployment.

Anuj remains Product Owner. Keep the repository private, unknowns unknown and content original/permitted. No deployment, merging, production seed, communications, purchases or account creation follows from this handoff.
