# Contributing and Maintaining the Project

Last updated: 2026-10-07. The repository now includes the first local catalogue source and its planning documents. Integration evidence and remaining checks are tracked in the backlog and quality review.

## 1. Understand the Project First

Read [README.md](README.md), [PROJECT_BRIEF.md](PROJECT_BRIEF.md) and [DECISIONS.md](DECISIONS.md). Developers should also read [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md), [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md) and [DATA_AND_PRIVACY.md](DATA_AND_PRIVACY.md). The existing application's setup is in [GETTING_STARTED.md](GETTING_STARTED.md). Read [AGILE_DELIVERY.md](AGILE_DELIVERY.md), [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md) and [AGENTS.md](AGENTS.md) for the current Sprint Goal, ownership and integration rules.

Read [FEATURES_REFERENCE.md](FEATURES_REFERENCE.md) before map or editorial work. Implement the documented behaviours with original content; do not assume permission to reuse another site's café records, reviews, code or assets. Keep individual curator opinions distinct from private member feedback and personalized scores.

Keep the focus on cafés and the first pilot. Larger menus, restaurant ordering, table management and full hospitality operations are outside the current concept. A café's drink/snack preferences may inform discovery without turning this into restaurant management software.

## 2. Repository Access and Working Method

The repository is private under [anujssmishra/cafe-discovery-app](https://github.com/anujssmishra/cafe-discovery-app). Request access from the project owner when needed. Use your own GitHub identity and normal credential manager. A project licence and any future public-release policy have not been selected; do not assume this is already an open-source project.

For implementation, create a focused branch, make a reviewable change, and open a pull request using the agreed team process. Suggested branch names include `feat/catalogue`, `fix/visit-ownership` and `docs/setup-update`. Direct owner-authorized documentation updates may use the owner's requested workflow.

The first integration branch is `feat/sprint-1-catalogue`; its remote status is recorded in the backlog. Anuj is Product Owner; root coordinates backend, frontend, QA and delivery agents. Each agent owns an agreed file set, reports dependencies and hands off evidence. Root integrates the shared change. Do not edit another agent's files, generate competing migrations, publish independently or count an agent handoff as a completed Sprint story. Keep the working limits and review gates in the agile plan.

Each work item should state the user problem, scope, acceptance criteria, data impact and validation needed. Keep unrelated changes separate. Record material scope/stack/provider decisions rather than introducing them silently.

## 3. Suggested Issue Format

```markdown
Problem / user need:
Proposed change:
In scope:
Acceptance criteria:
Data or permission impact:
Validation:
Dependencies:
Owner:
```

Use redacted or synthetic examples. Do not include passwords, access tokens, database URLs with credentials, interview transcripts, identifiable participant histories or production exports in issues or pull requests.

## 4. Pull Request Expectations

Lead the description with the concrete behaviour and why it helps. Include relevant validation and remaining limitations. If setup changes, update the setup file in the same change. If a feature becomes implemented, update the status only after its acceptance checks pass.

A contribution is ready for review when:

- The stated acceptance criteria are met and important behaviour is checked.
- Authorization, validation, consent and deletion are addressed where affected.
- Schema changes include migrations and an operational plan if needed.
- New settings have an example variable name, safe default or explanation, and no committed secret.
- README links and related requirements/decisions remain accurate.
- The PR distinguishes completed behaviour from proposed follow-up work.

For current application code, configure the environment and install dependencies as described in the setup guide, then run:

```bash
python manage.py check
python manage.py makemigrations --check --dry-run
python manage.py test
python -m ruff check .
python -m ruff format --check .
```

Also apply committed migrations to a clean local database when a schema changes. Current meaningful cases include combined filters, active visibility, pagination, detail 404s, data constraints, seed idempotence and catalogue-editor permissions. Add ownership, matching and withdrawal cases when those features arrive. Record exact versions and results in [QUALITY_REVIEW.md](QUALITY_REVIEW.md) and the backlog; an added workflow is not proof of a hosted CI pass, and local checks are not deployment validation.

## 5. Data Contributions

Follow the source, permission and verification rules in [DATA_AND_PRIVACY.md](DATA_AND_PRIVACY.md). Use stable IDs and checking dates. Do not publish private contact details or copied third-party review collections. Clearly label unknown, stale and subjective attributes.

During development, use the guarded `seed_demo` command or clearly identified synthetic test fixtures. The current command creates no users or visit logs. Fictional cafés must be visibly marked and excluded from public non-demo queries; future synthetic member activity must also be excluded from pilot metrics and community explanations. Never let demo records appear to be real participants or real evidence of repeat visits.

## 6. Keeping Documentation Current

| Change | Files to review |
|---|---|
| Stage or available features | README and product requirements |
| Product scope/segment | Project brief, requirements, roadmap and decisions |
| Stack, authentication or deployment | Technical design, getting started, sources and decisions |
| Models or ranking logic | Technical design, data plan, requirements and metric definitions |
| Providers, consent or retention | Data plan, technical design, sources and notice implementation |
| New budget, staffing or results | Roadmap/budget and decision log |

Every substantial document update should include its date and status. Keep implemented source, locally verified behaviour, remote CI and deployed capabilities distinct. Maintain actual prerequisites, environment-only configuration, migrations, tests and run instructions. Preserve historical notes as history; remove obsolete bootstrap instructions from current setup.

During active work, review progress and open decisions weekly. Review café freshness weekly during a pilot. Recheck versions, provider terms/prices and relevant regulation before selecting services or launching, and whenever those dependencies change. Link to original authoritative references.

## 7. Security and Sensitive Reports

Do not place an exploitable vulnerability or personal data in a public issue. Contact the project owner through an existing private channel, using a minimal redacted description. A dedicated support/security contact must be chosen before pilot launch and then documented here and in the app.

If a secret is accidentally committed, removing it from the latest file is insufficient: revoke/rotate it, assess exposure, and coordinate necessary repository cleanup. Do not use this repository as a place to store operational credentials even while it remains private.

## 8. Handover to a New Contributor

Give the contributor repository access, reading order, current milestone, one specific task, synthetic/local data instructions and the actual tested setup procedure. Identify who can answer product, data and deployment questions. They should be able to tell what exists, what is proposed and what is undecided from the files without needing this chat.
