# Café Discovery

Help a visitor find a café suited to their drink, budget and purpose. The current increment provides guest catalogue browsing; personalized matching is planned.

## Current application

The active application is `php_app/`: PHP 8.2, PDO with native MySQL prepared statements, MySQL 8/InnoDB, and server-rendered HTML/CSS. It provides partial-name and area filters, twelve-result pagination, stable UUID detail URLs and an about page. Public queries exclude inactive cafés and inactive areas; fictional entries are visible only in development/test demo mode.

The guarded local seed inserts eight fictional cafés, sixteen synthetic offerings and two fictional areas. It preserves existing rows, UUIDs, sources and verification dates. Missing evidence remains unknown. The earlier Lucknow seed's claims were not substantiated; it is no longer run by the active seed.

There is no PHP catalogue admin, member authentication, recommendation engine, map, ratings, editorial workflow or deployed pilot. `legacy_django/` is historical reference. Its tests and CI evidence do not establish PHP verification.

## Run locally

With Docker Desktop/Engine running, from the repository root:

```sh
docker compose -f php_app/compose.yaml up -d --build
docker compose -f php_app/compose.yaml exec app php php_app/scripts/schema.php --apply
docker compose -f php_app/compose.yaml exec app php php_app/scripts/seed.php --demo
```

Open [the local catalogue](http://127.0.0.1:8000/). The Compose setup uses a private container MySQL service and local-only example credentials; it is for synthetic development. It keeps database storage in a named volume. Stop it with `docker compose -f php_app/compose.yaml down`.

Native PHP/MySQL commands, Windows environment setup, integration checks and Hostinger file/routing requirements are in [GETTING_STARTED.md](GETTING_STARTED.md).

## Verification and continuation

The PHP fixes were prepared on `fix/php-catalogue-review` from clean main `ba97a0a` for integration into main. Local PHP 8.2.34/MySQL 8.0.46 verification passed: 21-file lint, 40 unit checks and 92 saved integration checks. [QUALITY_REVIEW.md](QUALITY_REVIEW.md) records commands and remaining browser/hosting checks; [DEVELOPMENT_HANDOFF.md](DEVELOPMENT_HANDOFF.md) identifies the next work. Inspect Git/CI for actual publication and hosted-run state.

## Project guide

| Need | Document |
|---|---|
| Reproduce the application | [GETTING_STARTED.md](GETTING_STARTED.md) |
| Resume development | [DEVELOPMENT_HANDOFF.md](DEVELOPMENT_HANDOFF.md), [STARTER_PROMPT.md](STARTER_PROMPT.md) |
| Architecture and data contracts | [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md), [DATA_AND_PRIVACY.md](DATA_AND_PRIVACY.md) |
| Scope and feature requirements | [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md), [FEATURES_REFERENCE.md](FEATURES_REFERENCE.md) |
| Priorities and delivery | [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md), [AGILE_DELIVERY.md](AGILE_DELIVERY.md) |
| Decisions and working agreement | [DECISIONS.md](DECISIONS.md), [AGENTS.md](AGENTS.md), [CONTRIBUTING.md](CONTRIBUTING.md) |
| Product hypotheses and cost forecast | [PROJECT_BRIEF.md](PROJECT_BRIEF.md), [ROADMAP_AND_BUDGET.md](ROADMAP_AND_BUDGET.md) |
| Sources and verification | [SOURCES.md](SOURCES.md), [QUALITY_REVIEW.md](QUALITY_REVIEW.md) |

A proposed pilot of 20–30 checked cafés and 30–50 consenting adults is a target, not existing data or users. Real sourcing, participant research, accounts, matching, maps, editorial content and production operations require their own acceptance evidence. Keep the repository private and credentials outside Git.
