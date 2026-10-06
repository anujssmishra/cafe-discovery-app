# Getting Started

Last updated: 2026-10-06. This is a startup guide for a documentation-only repository. The commands below create the first application skeleton; there is no existing application to run yet.

## 1. What Is Needed

| Need | Minimum starting arrangement | Needed when |
|---|---|---|
| Product ownership | One person who can decide scope, recruit users and approve spending | Before work starts |
| Development capability | Python, Django, HTML/CSS, database and Git basics; one developer can cover the MVP | Before implementation |
| Research and catalogue work | Someone able to interview visitors and verify café details | Before ranking can be useful |
| Equipment | Existing laptop and internet; an 8 GB laptop is a planning minimum, 16 GB is more comfortable | Development |
| Tools | Git, Python 3.13, editor, browser and access to this private repository | Development |
| Pilot data | Proposed 20–30 checked café records in one area, with sources and dates | Manual test and pilot |
| Participants | Proposed 30–50 adults, with clear recruitment and data notices | Pilot |
| Production services | Web host, PostgreSQL, domain if desired, email delivery, monitoring and backups | Before a hosted pilot |
| Maps and editorial content | Proposed Leaflet client, licensed tile service, checked café coordinates, original curator visits/notes and public-attribution permission | Before map/editorial pilot release |
| Operating arrangements | Data contact, correction process, privacy review and an agreed cash/time budget | Before participant data collection |

These are planning requirements, not purchases already made. The proposed baseline needs no GPU, large-model API, payment integration or native app-store account. One person may cover several roles; outside design, security or legal help depends on that person's experience and the launch context.

## 2. The First Week

1. Read [PROJECT_BRIEF.md](PROJECT_BRIEF.md) and pick the pilot area and primary customer segment.
2. Fill the open owner, availability and budget items in [DECISIONS.md](DECISIONS.md).
3. Schedule visitor and café-manager interviews. Ask about recent choices and actual frustrations.
4. Verify a small initial catalogue, then expand toward 20–30 cafés. Follow [DATA_AND_PRIVACY.md](DATA_AND_PRIVACY.md).
5. Test manual recommendations using a short preference form. Record which attributes made a suggestion useful.
6. Decide whether the evidence justifies building the pilot. Agree on a small milestone and its acceptance criteria before coding.

Do not wait for community visit data to begin. Taste, purpose, budget and verified café attributes provide the first matching baseline.

## 3. Accounts and Services

Start with repository access and a local development environment. Before the hosted pilot, select a provider for the web process and a persistent PostgreSQL database, define who controls the accounts, enable suitable account protection, and arrange backups and transactional email.

The manual validation stage can use a list and area selection. The expanded pilot includes a map, so select a tile service, review its licence/attribution and privacy, configure allowed browser keys if required, and set request/spending limits. Analytics vendors and other paid APIs remain optional. Keep list browsing usable when maps fail. Record any service's cost, permissions, terms and data handling before integrating it; keep production and development data separate.

## 4. Developer Bootstrap Recipe

**This section creates new code. It is not a command sequence for an already implemented café app.** The proposed stack is Python 3.13 and the latest maintained Django 5.2 patch. Review [SOURCES.md](SOURCES.md) and confirm the stack decision before starting. Django 5.2 is an LTS release with extended support scheduled through April 2028; this guide needs a version review before then.

### A. Clone and create a branch

Use your normal GitHub authentication for this private repository. Do not put a token in the clone URL.

```bash
git clone https://github.com/anujssmishra/cafe-discovery-app.git
cd cafe-discovery-app
git switch -c feat/mvp-foundation
```

### B. Create a clean environment

On macOS/Linux with Python 3.13 installed:

```bash
python3.13 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install "Django>=5.2,<5.3"
```

On Windows Command Prompt with Python 3.13 and its launcher installed:

```bat
py -3.13 -m venv .venv
.venv\Scripts\activate.bat
python -m pip install --upgrade pip
python -m pip install "Django>=5.2,<5.3"
```

In PowerShell, you can use `.venv\Scripts\python.exe` directly for Python commands if activation is unavailable. Do not change a machine's execution policy merely to follow this guide. Confirm that `python --version` and `python -m django --version` refer to the intended environment. See official [Python environment instructions](SOURCES.md#s7-python-environments).

### C. Create the project and domain apps

From the repository root, with the environment active:

```bash
django-admin startproject config .
python manage.py startapp cafes
python manage.py startapp members
python manage.py startapp visits
python manage.py startapp discovery
```

`config` holds settings and root URLs. `cafes` owns the catalogue, `members` owns preferences and data choices, `visits` owns private logs and saves, and `discovery` owns matching. These are proposed boundaries; record a change if implementation needs different ones.

### D. Ignore local and private files

Create `.gitignore` before committing code:

```gitignore
.venv/
__pycache__/
*.py[cod]
db.sqlite3
.env
.env.*
!.env.example
localdata/
exports/
media/
.DS_Store
```

Keep local uploads, interview notes, user exports and production backups outside Git. A future `.env.example` may contain variable names and harmless placeholders. This recipe reads process environment variables; it does **not** automatically load a `.env` file.

### E. Make settings use environment variables

In the generated `config/settings.py`, add `import os`, replace the generated `SECRET_KEY`, `DEBUG` and `ALLOWED_HOSTS` assignments, and add the four apps after the generated `INSTALLED_APPS` list:

```python
SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]
DEBUG = os.environ.get("DJANGO_DEBUG", "false").lower() == "true"
ALLOWED_HOSTS = [
    host.strip()
    for host in os.environ.get("DJANGO_ALLOWED_HOSTS", "").split(",")
    if host.strip()
]
INSTALLED_APPS += ["cafes", "members", "visits", "discovery"]
```

Set a development secret in the same terminal, without saving it to Git. On macOS/Linux:

```bash
export DJANGO_SECRET_KEY="$(python -c 'import secrets; print(secrets.token_urlsafe(48))')"
export DJANGO_DEBUG=true
export DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1
```

On PowerShell:

```powershell
$env:DJANGO_SECRET_KEY = .venv\Scripts\python.exe -c "import secrets; print(secrets.token_urlsafe(48))"
$env:DJANGO_DEBUG = "true"
$env:DJANGO_ALLOWED_HOSTS = "localhost,127.0.0.1"
```

Command Prompt users can run this environment-setting step in PowerShell, then use the virtual environment's Python there for the following commands. A new terminal needs its environment set again. Production needs a separate stable secret, `DEBUG=false`, explicit host names, HTTPS and the deployment checks in [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md).

### F. Run the skeleton

Leave Django's generated SQLite configuration in place for this first local step:

```bash
python manage.py migrate
python manage.py createsuperuser
python manage.py check
python manage.py runserver
```

Visit `http://127.0.0.1:8000/` and `/admin/`. At this stage, expect Django's initial page and an admin sign-in screen, **not café discovery features**. The development server is for local work only. Stop it with Ctrl+C.

Then record the installed versions from this clean environment:

```bash
python -m pip freeze > requirements.txt
```

Review the generated files and confirm the default hard-coded secret has been removed. Commit explicit project paths rather than private data:

```bash
git add config manage.py cafes members visits discovery requirements.txt .gitignore
git commit -m "Create Django application foundation"
```

This document does not claim the recipe has been executed or that tests for application behaviour exist. Once code is added, replace this bootstrap section with the actual clone/install/configure/migrate/test/run procedure, including PostgreSQL dependencies and an environment example.

## 5. What to Build After the Skeleton

| Order | Work | Evidence of completion |
|---|---|---|
| 1 | Café models, provenance and restricted catalogue admin | An editor can maintain checked records; private user data is inaccessible to that role |
| 2 | Mobile catalogue, area selection, name search and full café detail | Works with no account and no location permission |
| 3 | Preferences, purpose and content-based ranking | New users receive explainable matches; essential constraints are respected |
| 4 | Member saves, private visits and return feedback | Ownership checks and editing/deletion work |
| 5 | Data settings, export/deletion and minimal measurement | Consent changes affect derived signals; data flows match the notice |
| 6 | Map/list synchronization, area shortcuts, detail dialogs and external directions | Same eligible IDs, accessible navigation, correct destinations and tile-failure fallback |
| 7 | Original curator reviews, trip value and local collection/about | Optional scores are attributed/dated; eligibility has checked provenance; drafts stay private |
| 8 | PostgreSQL, deployment, backups and pilot usability | Real restore exercise, production checks and mobile journeys pass |
| Later | Opted-in aggregate community signal | Minimum evidence threshold is met and privacy safeguards are tested |

Use [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md) for acceptance criteria, [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md) for implementation, and [ROADMAP_AND_BUDGET.md](ROADMAP_AND_BUDGET.md) for effort and release gates.

## 6. Common Starting Problems

| Symptom | Check |
|---|---|
| Python/Django command not found | Python installation and active virtual environment; use its Python executable directly |
| Private repository clone denied | GitHub account and repository permissions; use your normal credential manager |
| `DJANGO_SECRET_KEY` error | Set the environment variable in the terminal running Django |
| Disallowed host | Add the intended local host to the development environment variable; do not use a production wildcard |
| No café results | The catalogue and feature implementation do not exist until built; later distinguish an empty catalogue from strict filters |
| Deployment loses data | Check for an ephemeral filesystem or local SQLite; the pilot requires persistent PostgreSQL and verified backups |
| Map tiles fail or request a key | Check selected provider configuration, restrictions and quotas; preserve the list instead of removing valid cafés |
| Map and list disagree | Use the same filtered result snapshot/IDs and prevent old search responses replacing current ones |

Review [FEATURES_REFERENCE.md](FEATURES_REFERENCE.md) before implementing map, rating or collection behaviour. The reference's café data and review text are not seed data for this project.

If the recipe becomes stale, fix it together with the implementation and record the tested versions in the repository.
