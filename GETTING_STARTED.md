# Getting Started

Last updated: 2026-10-07. This guide runs the existing local Django catalogue. The first increment is under integration review; use [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md) and [QUALITY_REVIEW.md](QUALITY_REVIEW.md) for actual evidence. A local demo is not a hosted pilot.

## 1. What Is Needed

| Need | Starting arrangement | Needed when |
|---|---|---|
| Product ownership | Anuj prioritizes the backlog, reviews increments and decides the pilot scope/spending | Throughout delivery |
| Development | Python/Django, HTML/CSS, database and Git capability; agents coordinate through the root integrator | Current build |
| Equipment and tools | Existing laptop, Git, Python 3.12 or 3.13, an editor, browser and private repository access | Local development |
| Research and catalogue | Someone who can interview visitors and check café facts, provenance and dates | Before real recommendations |
| Pilot data and participants | Proposed 20–30 checked cafés in one area and 30–50 adult participants | Later pilot |
| Production services | Persistent PostgreSQL, a web host, email, monitoring and tested backups | Before hosting |
| Maps and editorial | Licensed tiles, checked destinations, original curator content and publication permission | Later feature increments |
| Operating arrangements | Data/support contact, correction process, notices and agreed time/cash budget | Before participant use |

Python 3.13 remains the preferred target; Python 3.12 is also a development target. The first integrated local run used Python 3.12.14 and Django 5.2.18. Use the exact dependency versions recorded in the requirements files. The local stack needs no GPU, LLM API, banking integration or native app-store account. Do not substitute fictional seed records for checked pilot data.

## 2. Understand the Current Sprint

Read [AGILE_DELIVERY.md](AGILE_DELIVERY.md), [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md) and [AGENTS.md](AGENTS.md). Sprint 1's goal is a reproducible synthetic catalogue that a guest can search and inspect. The selected stories cover foundation, models/admin, seed data, browsing/details, tests and delivery documentation.

The current source has `config`, `cafes` and `discovery` packages. Member accounts, taste profiles, recommendations, private saves/visits, maps and editorial publication have not yet been built. Do not run `startproject` or recreate these packages over the existing source.

## 3. Clone and Select the Development Branch

Use normal GitHub authentication for the private repository; keep tokens out of clone URLs.

```bash
git clone https://github.com/anujssmishra/cafe-discovery-app.git
cd cafe-discovery-app
git fetch origin
git switch feat/sprint-1-catalogue
```

`feat/sprint-1-catalogue` is published and is the current integration branch, under review in [draft PR #1](https://github.com/anujssmishra/cafe-discovery-app/pull/1). Clone that branch as shown above; the older `main` branch does not yet contain this increment. See the backlog and quality review for validation evidence. Contributors should branch from the current integrated revision for their assigned task. Do not overwrite an existing checkout or discard someone else's changes.

## 4. Create an Isolated Python Environment

On macOS/Linux with Python 3.13 installed:

```bash
python3.13 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements-dev.txt
```

If using the supported Python 3.12 target, substitute `python3.12` in the first command.

On Windows Command Prompt with Python 3.13 and its launcher installed:

```bat
py -3.13 -m venv .venv
.venv\Scripts\activate.bat
python -m pip install --upgrade pip
python -m pip install -r requirements-dev.txt
```

Use `py -3.12` instead for Python 3.12. In PowerShell, using `.venv\Scripts\python.exe` directly is an alternative to activation; change each subsequent `python` command accordingly. No machine-wide execution-policy change is required.

Check the interpreter and framework selected by the environment:

```bash
python --version
python -m django --version
```

`requirements-dev.txt` includes application requirements and the formatter/linter used by CI. Avoid replacing the pinned dependency files with an unbounded framework install. See [SOURCES.md](SOURCES.md) for compatibility and version review references.

## 5. Set Local Configuration

`config/settings.py` reads process environment variables. `.env.example` documents names only: copying it to `.env` does **not** load it. The following commands configure the current terminal session. Repeat them in a new terminal before running Django. Never commit a generated secret.

On macOS/Linux:

```bash
export DJANGO_SECRET_KEY="$(python -c 'import secrets; print(secrets.token_urlsafe(48))')"
export DJANGO_DEBUG=true
export DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1
export DJANGO_DEMO_MODE=true
```

On Windows Command Prompt (interactive terminal, not a batch file):

```bat
for /f "delims=" %K in ('python -c "import secrets; print(secrets.token_urlsafe(48))"') do set "DJANGO_SECRET_KEY=%K"
set "DJANGO_DEBUG=true"
set "DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1"
set "DJANGO_DEMO_MODE=true"
```

In a Windows batch file use `%%K` instead of `%K`. PowerShell alternative, using the environment's interpreter directly:

```powershell
$env:DJANGO_SECRET_KEY = & .\.venv\Scripts\python.exe -c "import secrets; print(secrets.token_urlsafe(48))"
$env:DJANGO_DEBUG = "true"
$env:DJANGO_ALLOWED_HOSTS = "localhost,127.0.0.1"
$env:DJANGO_DEMO_MODE = "true"
```

The generated key exceeds the required 50 characters. Boolean settings accept `true` or `false`. `DJANGO_DEMO_MODE=true` enables fictional catalogue display and is allowed only with debug enabled. Set it to `false` to work with an empty or manually maintained non-demo catalogue. Wildcard allowed hosts are rejected. The local development server should stay bound to `127.0.0.1`.

## 6. Migrate, Seed and Verify

From the repository root, in the configured environment:

```bash
python manage.py migrate
python manage.py seed_demo
python manage.py check
python manage.py makemigrations --check --dry-run
python manage.py test
python -m ruff check .
python -m ruff format --check .
```

Skip `seed_demo` when demo mode is disabled. It requires both debug and demo mode, creates eight clearly fictional cafés and sixteen offerings across two fictional areas, and may be rerun to restore its own fixture values. It does not create users, delete unrelated records or supply real café verification. Reserved identifier conflicts with other data are errors; investigate rather than removing records to force a seed.

These are the required commands, not a statement that they passed on every platform. Record the actual environment, command result and reviewed revision in the quality/backlog evidence. A hosted CI run has separate evidence from these local checks.

## 7. Start and Inspect the Catalogue

```bash
python manage.py runserver 127.0.0.1:8000
```

Open `http://127.0.0.1:8000/`. Search a partial name such as `Paper`, select a fictional area, combine/clear filters, try a query with no matches, then open a café's full detail page and `/about/`. Results are alphabetical and paginated at twelve per page; the eight-record seed alone will not produce a second page. Pagination is covered by larger synthetic test fixtures.

The interface should identify fictional data and display unknown prices/evidence explicitly. Inspect narrow-screen layout, labelled controls, keyboard navigation and focus. Record actual browser checks separately from server-side tests. Stop the local server with `Ctrl+C`.

## 8. Optional Local Catalogue Administration

In a second terminal configured as above, create your own local administrator interactively and prepare the editor role:

```bash
python manage.py createsuperuser
python manage.py setup_catalogue_editors
```

Use `/admin/` to maintain areas, cafés and offerings. The setup command creates or resets the **Catalogue editors** group's twelve catalogue permissions only. It creates no account and grants no staff access. An administrator must deliberately give an editor `is_staff` and the group; routine catalogue editors should not be superusers. Re-running the command replaces that group's permissions with the defined catalogue set, so do not use it as a general-purpose role containing unrelated permissions.

Record known sources and dates; ownership starts as unknown. A verified ownership status requires separate evidence and a checking date. A small branch count alone does not establish independence. Keep participant histories, credentials and real operational exports out of development fixtures and Git.

## 9. Troubleshooting and Next Work

| Symptom | Check |
|---|---|
| Missing/short secret error | Generate and set `DJANGO_SECRET_KEY` in the terminal running Django |
| Demo/debug configuration error | Use demo mode only with `DJANGO_DEBUG=true`; non-debug deployment is later work |
| Missing database table | Run the committed migrations with `python manage.py migrate` |
| Empty catalogue | Seed in debug/demo mode, or add active non-demo records in active areas |
| Demo cafés disappear | `DJANGO_DEMO_MODE=false` deliberately excludes them |
| Host error | Use `127.0.0.1:8000` or `localhost:8000` and explicit allowed hosts |
| Changes to `.env` have no effect | Settings read process environment; export/set values as above |
| Editor cannot open admin | Check active/staff status and the Catalogue editors group; do not solve by granting superuser |

Select the pilot area and segment, arrange research and check real café data alongside the next development work. The next candidate increment adds factual amenities, guest preferences and content-based matching. Private member tools, maps, editorial content and production operations follow the dependencies in [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md).

The current SQLite settings and development server do not implement production hosting. Before a pilot, build and test PostgreSQL configuration, production static delivery, HTTPS/proxy settings, email, monitoring, backups/restoration, account/data controls and the relevant notices. Choose providers and spending deliberately. These are later release gates in [AGILE_DELIVERY.md](AGILE_DELIVERY.md), not reasons to delay local review.
