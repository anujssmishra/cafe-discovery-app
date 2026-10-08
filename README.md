# Personalized Café Discovery App

**Find your kind of coffee. Find your kind of café.**

An app that recommends cafés using drink preferences, the purpose of today's visit, budget, atmosphere, and, when enough consenting user data exists, repeat visits by people with similar tastes.

It answers: **“Which café suits my taste and what I want to do today?”** Someone looking for light-roast pour-over and quiet reading should receive different suggestions from someone meeting friends over affordable iced coffee.

## Project Status

**Stage: first catalogue increment published for review in [draft PR #1](https://github.com/anujssmishra/cafe-discovery-app/pull/1). Last updated: 2026-10-07 UTC.**

The source now includes a PHP catalogue with `Area`, `Cafe` and `CafeOffering`, staff administration, a guarded synthetic-data command, guest name/area search, pagination, full café detail pages and an about page. This is the first local development slice. The recommendation engine, member journeys, maps, editorial workflow and hosted pilot are still future work.

The included demo contains eight fictional cafés, sixteen synthetic offerings and two fictional areas. It is not a verified café directory. The final integrated local run passed 49 tests on PHP 3.12.14 and PHP 5.2.18, with clean PHP checks and migration drift checks. Seed reruns retained the expected counts. Hosted CI passed on PHP 3.12 and 3.13 for implementation snapshot `c1fc831`. Check [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md) and [QUALITY_REVIEW.md](QUALITY_REVIEW.md) for exact evidence and the PR for checks on its latest revision. Browser/mobile/keyboard review remains open. No hosted pilot, customers, revenue or partnerships are claimed.

The architecture, budgets, thresholds, and timeline below are proposed starting decisions. The pilot city, team availability, spending limit, brand, and launch date still need the project owner's decisions. See [DECISIONS.md](DECISIONS.md).

## Start Here

| You want to understand… | Read |
|---|---|
| Continue in Codex, Claude, Gemini or another development environment | [DEVELOPMENT_HANDOFF.md](DEVELOPMENT_HANDOFF.md) and [STARTER_PROMPT.md](STARTER_PROMPT.md) |
| Phases, agile cadence, agent roles and Definition of Done | [AGILE_DELIVERY.md](AGILE_DELIVERY.md) |
| Selected Sprint 1 stories, dependencies and actual progress | [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md) |
| Verification evidence and remaining quality checks | [QUALITY_REVIEW.md](QUALITY_REVIEW.md) |
| The idea, customer problem, validation, and business model | [PROJECT_BRIEF.md](PROJECT_BRIEF.md) |
| What is needed and what to do first | [GETTING_STARTED.md](GETTING_STARTED.md) |
| User journeys, features, scope, and acceptance criteria | [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md) |
| Features adapted from Caffeine Chronicles and how to implement them | [FEATURES_REFERENCE.md](FEATURES_REFERENCE.md) |
| Architecture, database, matching logic, testing, and deployment | [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md) |
| Café information, consent, privacy, and operational data handling | [DATA_AND_PRIVACY.md](DATA_AND_PRIVACY.md) |
| People, effort, milestones, costs, and pilot measurement | [ROADMAP_AND_BUDGET.md](ROADMAP_AND_BUDGET.md) |
| How to contribute and keep these documents current | [CONTRIBUTING.md](CONTRIBUTING.md) |
| Which choices are settled, proposed, or still open | [DECISIONS.md](DECISIONS.md) |
| Official references and when to recheck them | [SOURCES.md](SOURCES.md) |
| Agent file ownership and handovers | [AGENTS.md](AGENTS.md) |

**Suggested reading order:** this README, getting started, agile delivery and backlog, then the document relevant to your role. A developer should read the agent agreement, technical design and data plan before editing source.

## Run the Current Increment

Follow [GETTING_STARTED.md](GETTING_STARTED.md) to clone the development branch, create a PHP 3.12 or 3.13 environment, install `requirements-dev.txt`, set the required environment variables, migrate, optionally seed the fictional catalogue, run checks and start PHP locally. Settings do not automatically read `.env`.

The current public routes are `/`, `/cafes/<uuid>/` and `/about/`; authorized staff use `/admin/`. The catalogue is alphabetically ordered, with combined partial-name and area filters. It does not yet rank personal matches. The full planned product is described below.

## First Pilot

The proposed pilot is a mobile-friendly web app covering **20–30 verified cafés in one city or neighbourhood**, tested with **30–50 adult participants**. These are planning targets, not current inventory or users.

Users can browse, choose their drink and atmosphere preferences, set today's purpose and budget, optionally add up to three favourite cafés, receive explained recommendations, save cafés, and log visits with short feedback. A fresh user receives preference-based matches immediately; recommendations do not depend on having a transaction history or friends on the app.

## Planned Pilot Scope

- Taste and purpose profiles: espresso, pour-over, cold brew, milk-based drinks, tea, matcha, snacks, work, reading, dates, or socialising.
- A manually checked catalogue with drink availability, indicative prices, amenities, and verification dates.
- Map and list browsing with name search, pilot-area shortcuts, café detail dialogs and external directions.
- Original curator notes with separate coffee/experience scores, trip-value opinions and a documented local-café collection.
- Explained recommendations and a clear response when no café fits the requested constraints.
- Private saved cafés and self-reported visit/return feedback.
- Staff catalogue management, account data deletion, and basic pilot measurement.

Friends, café owner dashboards, native mobile apps, receipt imports, payment-history connections, subscriptions, and booking payments are later candidates. They are not required to test the first version.

The feature expansion requested from [Caffeine Chronicles](https://caffeinechronicles.vercel.app/) is specified in [FEATURES_REFERENCE.md](FEATURES_REFERENCE.md). Editorial opinions remain distinct from verified facts and personalized ranking. The first pilot still covers one area; additional city shortcuts depend on new verified catalogue data.

## What You Need to Begin

At minimum: a product owner, PHP/web development capability, a laptop, access to this repository, a small café catalogue, pilot participants, and time for customer interviews and usability testing. One person can cover multiple roles. A GPU, a large language model service, and banking integrations are not prerequisites for the proposed matching baseline.

The local build uses PHP 5.2 LTS, responsive HTML/CSS and SQLite, with PHP 3.12/3.13 as the development targets. Exact dependency pins live in `requirements.txt` and `requirements-dev.txt`. PostgreSQL and a production host remain later implementation and provider decisions. [GETTING_STARTED.md](GETTING_STARTED.md) runs the existing application; it does not create a replacement PHP project.

## Next Three Actions

1. Complete the first increment's integrated checks and review the synthetic catalogue against Sprint 1 acceptance criteria.
2. Anuj, as Product Owner, selects the pilot area/segment and review capacity; research and checking real café information can proceed alongside development.
3. Refine factual amenities, guest preferences and explained content matching. Accounts/private feedback, maps/editorial and pilot operations follow the phase gates in the agile plan.

## Keeping This Repository Useful

Update the project status and decision log when assumptions become decisions or features become implemented. Keep setup commands aligned with actual code. Never present proposed capabilities as completed work. The maintenance rules are in [CONTRIBUTING.md](CONTRIBUTING.md).

