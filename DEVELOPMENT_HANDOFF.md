# Café Discovery — Development Handoff

Updated: 2026-10-08. Audience: Anuj, another developer, or any coding assistant, including Codex, Claude and Gemini. This is a portable project-context handoff, not a transfer of chat sessions, credentials, running agents or installed environments.

## 1. Resume the Existing Project

| Item | Current checkpoint |
|---|---|
| Repository | Private `anujssmishra/cafe-discovery-app` |
| Integration branch | `feat/sprint-1-catalogue` |
| Review | [Draft PR #1](https://github.com/anujssmishra/cafe-discovery-app/pull/1), targeting `main` |
| Complete implementation snapshot | `c1fc831f47e4961dc3c1b7b312b52d7c402ba9a6` |
| Last verified pre-handoff remote revision | `3ccb330c548dc8b794830100b36e316688625008`, including publication/CI evidence updates |
| Current increment | Runnable Django café catalogue; selected CAFE-001–007 stories remain **Verify** |
| Remaining Sprint 1 gate | Browser, mobile/narrow-screen and keyboard inspection, followed by evidence updates |
| Deployment | None; no production database, real café catalogue or participant validation |

This handoff is a later documentation-only change. Fetch the branch and inspect its actual head and PR checks; the hashes above identify historical evidence, not a command to reset the project. At this checkpoint, `main` still contains the earlier planning baseline and has not received the application. Do not start from `main` and build a second application.

The authoritative continuation path is a fresh GitHub clone or a normal existing clone of the remote repository. The earlier tool workspace used independently initialized local Git history because authenticated cloning was unavailable, then published through GitHub UI uploads. Those local hashes are not the remote history. Do not force-push that old workspace or merge unrelated histories. The source archive download also failed; remote byte-for-byte archive comparison was not claimed.

## 2. Product Intent and Scope

Help a visitor answer: **“Which café suits my taste and what I want to do today?”** The proposed product combines drink preferences, visit purpose, budget and atmosphere with transparent recommendation reasons. A later optional community signal uses consenting users' repeat/return feedback when sufficient data exists. A new visitor must receive useful discovery without an account or visit history.

The owner narrowed the original business idea to cafés and requested a durable Markdown project guide in this private repository. Later, the owner added feature concepts from Caffeine Chronicles and requested phased agile development with multiple developer agents. The latest request is to make the project transferable across coding tools. Anuj remains Product Owner; assistant sessions provide implementation support and do not become independent product owners.

Scope includes a café discovery web app. Restaurant operations, POS, reservations, payments, banking integrations, native apps, owner dashboards and social feeds are outside the initial pilot. No GPU, LLM service or AI API is needed for the proposed deterministic matching baseline.

The original reel and reference site are recorded in [SOURCES.md](SOURCES.md). Their contents are inspiration, not a licence to copy a café dataset, source code, branding, images or reviews. This handoff is a project summary, not a claimed verbatim video/chat transcript.

## 3. What Already Works

- Django 5.2.18 project with server-rendered HTML, responsive CSS and an original coffee-cup icon; Python 3.12/3.13 supported and SQLite used locally.
- `Area`, `Cafe` and `CafeOffering`, stable café UUIDs, initial migration, staff admin and a catalogue editor group with twelve catalogue-only model permissions.
- Required generated environment secret, explicit hosts, strict boolean settings and demo mode restricted to debug. `.env.example` documents variables; Django does not automatically load a `.env` file.
- Guarded, atomic, repeatable `seed_demo`: eight fictional cafés, sixteen offerings and two fictional areas. It creates no users, does not delete unrelated data and rejects reserved-identifier collisions.
- Guest partial-name search (`q`), area filtering (`area`), list area chips, combined filters, empty/error states and twelve-result pagination preserving filters.
- `/`, `/cafes/<uuid>/`, `/about/` and restricted `/admin/`. Public list/detail queries share active café/area and demo visibility rules.
- Current/stale/incomplete source evidence, nullable prices, separate ownership/count provenance, escaped content and defensive external-link validation. Demo entries do not link to invented external destinations.
- Seventeen developer tests plus thirty-two independent acceptance tests; GitHub CI on Python 3.12 and 3.13.

Not implemented: public member registration/login, saved cafés, visits/ratings, preferences, recommendations, amenities/corrections workflow, map canvas/live markers, directions, detail dialogs, editorial publishing or production hosting. The existence of a proposed model or route in a design document does not mean it exists in source.

## 4. Repository Map and Reading Order

Start with this file, [AGENTS.md](AGENTS.md), [GETTING_STARTED.md](GETTING_STARTED.md) and the selected stories in [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md). Read the relevant detailed specification before changing its behavior. Do not require every document to be reread for a small unrelated edit.

| File or directory | Responsibility |
|---|---|
| [README.md](README.md) | Product entry point, implemented/planned scope and document index |
| [PROJECT_BRIEF.md](PROJECT_BRIEF.md) | Problem, audience, business hypotheses and validation |
| [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md) | Requirements P1–P14, journeys and acceptance |
| [FEATURES_REFERENCE.md](FEATURES_REFERENCE.md) | Adapted feature concepts F01–F09 and implementation boundaries |
| [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md) | Target schema, matching, interfaces and deployment design |
| [DATA_AND_PRIVACY.md](DATA_AND_PRIVACY.md) | Provenance, consent, private data and operational handling |
| [GETTING_STARTED.md](GETTING_STARTED.md) | Full macOS/Linux/Windows setup and local admin instructions |
| [AGILE_DELIVERY.md](AGILE_DELIVERY.md) | Phases, sprint cadence, roles and Definition of Done |
| [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md) | 34 ordered stories, dependencies, status and evidence |
| [QUALITY_REVIEW.md](QUALITY_REVIEW.md) | Independent QA findings, integrated results and release boundary |
| [DECISIONS.md](DECISIONS.md) | Confirmed direction, proposals, open choices and history |
| [ROADMAP_AND_BUDGET.md](ROADMAP_AND_BUDGET.md) | Capacity, cost assumptions and pilot measurement |
| [CONTRIBUTING.md](CONTRIBUTING.md), [AGENTS.md](AGENTS.md) | Contribution rules and shared agent/developer working agreement |
| [SOURCES.md](SOURCES.md) | Source references, dates and limits |
| `config/` | Settings, root routing, context processors and application entry points |
| `cafes/` | Models, migration, admin, management commands and domain tests |
| `discovery/` | Shared public visibility, list/detail views and URLs |
| `templates/`, `static/discovery/site.css` | Public pages, original icon and styling |
| `tests/` | Independent catalogue, editor and configuration acceptance tests |
| `requirements*.txt`, `pyproject.toml`, `.github/workflows/ci.yml` | Pinned dependencies, lint configuration and CI |

`CLAUDE.md` and `GEMINI.md` are convenience pointers to these same shared documents. Tool-specific instruction discovery varies; explicitly ask any assistant to read this handoff and `AGENTS.md` if they were not loaded. [STARTER_PROMPT.md](STARTER_PROMPT.md) supplies a paste-ready task. There is no parallel product specification for each assistant.

## 5. Start Locally

Use normal private-repository authentication without embedding tokens in URLs. For a **new checkout**:

```bash
git clone --branch feat/sprint-1-catalogue https://github.com/anujssmishra/cafe-discovery-app.git
cd cafe-discovery-app
git status --short
git log -1 --oneline
```

For an existing checkout, inspect `git status`, remotes and branches first. Preserve current work; fetch normally and select the existing integration branch without resetting another contributor's changes. Create a focused work branch for the next change using the workflow in `AGENTS.md`.

On macOS/Linux with Python 3.13 installed (substitute `python3.12` if needed):

```bash
python3.13 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-dev.txt
export DJANGO_SECRET_KEY="$(python -c 'import secrets; print(secrets.token_urlsafe(48))')"
export DJANGO_DEBUG=true
export DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1
export DJANGO_DEMO_MODE=true
python manage.py migrate
python manage.py seed_demo
python manage.py check
python manage.py makemigrations --check --dry-run
python manage.py test
python -m ruff check .
python -m ruff format --check .
python -m pip check
python manage.py runserver 127.0.0.1:8000
```

These are local development instructions, not production settings. Generate the secret in your own environment and keep it out of Git. Shell variables must be set again in a new terminal. See `GETTING_STARTED.md` for Windows and editor-admin setup. If dependency/network/browser access is unavailable, report the specific limitation; do not claim an unrun check passed.

## 6. Verification Already Observed

| Evidence | Actual result and scope |
|---|---|
| Local integrated suite, 2026-10-07 | 49 tests passed in 1.372 seconds on Python 3.12.14 / Django 5.2.18 |
| Local independent QA | 32 acceptance tests passed in 0.826 seconds; details in `QUALITY_REVIEW.md` |
| Local static/setup checks | Django check, migration application/drift, Ruff 0.16.10 lint/format and dependency checks passed |
| Demo repeatability | Two seed runs retained 8 cafés, 16 offerings and 2 areas |
| Hosted implementation checks | At `c1fc831`, Python 3.12/3.13 push run `37684620010` and PR run `37685123786` succeeded; GitGuardian succeeded |
| Last pre-handoff remote check | At `3ccb330`, PR #1 displayed all five checks passed, including the documentation update |
| Remaining acceptance | No recorded application browser/mobile/keyboard review; no deployment or real-user validation |

Prior passes are a baseline, not proof for later source changes. Record the revision, environment and actual results for new work. Earlier history mentioning 48 tests records an intermediate run; the final integrated baseline is 49.

## 7. First Coding Session

1. Confirm repository/branch/head, preserve existing changes and read this handoff plus the shared agreement.
2. Reproduce local setup and the relevant baseline checks. Start the existing application; do not scaffold a replacement.
3. Complete the remaining Sprint 1 UI review: desktop and narrow viewport, keyboard-only movement and visible focus, search and combined filters, area chips, clearing, empty/invalid states, detail/back navigation, fictional-data labels and about page. Check overflow, readable controls, labels and meaningful links. The eight-café seed does not create a second page; pagination has larger automated fixtures.
4. Fix observed defects with focused regression checks. Record the browser/viewport and exact behavior checked in `QUALITY_REVIEW.md`; keep unsupported device claims out of the record.
5. Update CAFE-001–007 only when their acceptance criteria and Definition of Done are met. Keep unfinished items in Verify; the current draft state reflects these missing checks.
6. Refine Sprint 2 CAFE-010–014. Begin CAFE-011's factual amenities/correction foundation, then CAFE-012 guest preferences, CAFE-013 deterministic matching and CAFE-014 explanations. Real catalogue sourcing in CAFE-010 and participant evaluation need human evidence; synthetic development can proceed with explicit labels.

Do not automatically implement every sprint in one request. Select the next coherent work package, agree its model/view/test contracts, implement, verify and hand over. The starter prompt can launch the review-and-fix session without further product decisions.

## 8. Important Product and Data Decisions

- Preserve the existing Django architecture. SQLite is local-only; PostgreSQL and provider decisions are later work. No speculative service split or model API dependency is required.
- Unknown stays unknown. Missing ratings remain null, never 5; missing amenities are not confirmed. Independent ownership defaults to unknown, not true.
- A dated worldwide count of at most five locations is a proposed small-group policy; it does not establish independent ownership. Ownership needs separate evidence. Owner confirmation of the collection policy remains open.
- Current evidence uses a nonempty source and a checking date from today through 30 days ago. Older evidence is stale; absent/whitespace sources or future dates are incomplete. Preserve these distinctions and validate programmatic imports.
- Matching applies hard area/budget/essential constraints before ranking. Never silently relax them. Initial T/P/B weights are 0.40/0.30/0.20, renormalized across available dimensions; with all three available they are 4/9, 3/9, 2/9. Require relevant supported taste/purpose evidence for a personalized result; otherwise label area browsing honestly.
- The later R community term is disabled until the documented consenting-peer rules are met. Do not invent history or confidence percentages. Editorial scores and private coffee/vibe feedback are separate from the content baseline.
- Requested reference concepts remain in the backlog: map/list parity, original coffee pins, area quick-jumps, lightweight detail overlays, directions, independent/small-group evidence, separate coffee/experience editorial scores and descriptive trip-value labels. Purpose-specific badges and Apple Maps are later candidates.
- Histories are private; community contribution is a separate choice. Build ownership, export/deletion and consent handling alongside member data collection. Public payloads must exclude members, private visits and editorial drafts.
- Keep the repository private and preserve ordinary review branches. No deployment, purchase, public launch, licence selection or third-party outreach follows merely from this handoff.

Exact scoring edge cases, tie rules and privacy requirements are in the linked design and data documents; consult them before implementing those stories.

## 9. Agile Phases and Team Continuity

| Proposed sprint | Outcome |
|---|---|
| 1 | Readiness and catalogue discovery; implemented slice awaiting UI review |
| 2 | Checked attributes, guest preferences and explainable content matching |
| 3 | Member accounts, private saves/visits and data controls |
| 4 | Accessible map/list discovery, previews and directions |
| 5 | Original editorial curation, separate scores and collection policy |
| 6 | PostgreSQL/operations, support/privacy gates and hosted pilot readiness |
| After readiness | Measure usefulness, revise the backlog and decide whether to expand |

Two-week sprints are a planning proposal, not scheduled meetings or guaranteed completion dates. The 34-story backlog is the working scope. The existing estimate is 235–365 hours before contingency, 282–438 with 20%; reforecast from actual capacity. Pilot targets of 20–30 checked cafés and 30–50 adult participants are targets, not existing data or users.

The earlier implementation used backend, frontend, independent QA and planning agents, coordinated by an integrator. Their live sessions do not transfer. The receiving tool may use equivalent roles when it supports delegation and the active request authorizes it; otherwise one developer follows the same bounded sequence. Anuj can now code directly, and assistants must preserve his edits. File ownership, a single migration author, review gates and handover rules are defined in `AGENTS.md`.

## 10. Open Owner Decisions

Pilot city/neighbourhood and audience; available weekly time and spending ceiling; product name/domain; real data sources and content rights; research/support owners; host/database/email region and provider; map tiles and costs; original curators and attribution; collection policy; applicable notices/retention; licence/contributor arrangements; and revenue experiments remain open in `DECISIONS.md`.

Resolve each when its dependent work needs it. These choices do not prevent running the synthetic catalogue or reviewing its interface. Do not fabricate answers, interviews, visits or customers to make a story appear finished.

## 11. Leave the Next Developer a Clear Checkpoint

After each meaningful increment, update the relevant specification, backlog and evidence. Report: branch/revision, changed files and contracts, what now works, commands actually run, outstanding checks, decisions needed and the next bounded task. Prefer these repository files over reliance on chat memory. The handoff is complete only when the next person can identify implemented behavior separately from planned behavior.
