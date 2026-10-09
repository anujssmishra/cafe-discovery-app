# Agent Working Agreement

Last updated: 2026-10-08. Applies to human developers and any coding assistant working in this repository. Follow the user's current instructions and the active assignment; this file documents collaboration rules and does not expand user authorization.

For a new project session, read [DEVELOPMENT_HANDOFF.md](DEVELOPMENT_HANDOFF.md) for the verified branch/checkpoint and next work, then the documents relevant to the active task. [STARTER_PROMPT.md](STARTER_PROMPT.md) provides an optional tool-neutral continuation prompt. `CLAUDE.md` and `GEMINI.md` point here; all tools share these same project rules. Prior live agent sessions are not assumed to exist. Anuj is now also coding directly: preserve his edits and coordinate file ownership before parallel changes.

## Product and Current Increment

Build the café discovery product described in [README.md](README.md), [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md), [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md) and [DATA_AND_PRIVACY.md](DATA_AND_PRIVACY.md). Read [DECISIONS.md](DECISIONS.md) before changing a material choice. The process and work status are in [AGILE_DELIVERY.md](AGILE_DELIVERY.md) and [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md).

The first selected increment is a runnable PHP/MariaDB catalogue with Area/Cafe/CafeOffering, catalogue schema, clearly synthetic demo data, guest partial-name/area filtering, pagination, full UUID details, about page, meaningful tests and CI configuration. PHP catalogue admin is not implemented and remains future work. The target runtime is PHP 8.2+ with MariaDB 10.11+ on Hostinger at myfanverse.in. Use the runtime/dependency choices documented by the actual implementation. Accounts, matching, maps and ratings UI are future work unless an active task assigns them.

## Roles and Task Boundaries

- Anuj is Product Owner. The root agent coordinates the current team, owns integration and resolves cross-file conflicts.
- Developer agents cover backend/data, frontend/discovery and QA; a planning agent maintains delivery artifacts. They are collaborators within one team, not separate companies or autonomous employees.
- Spawn or delegate only when the current user request or active assignment permits it. Multiple agents are explicitly requested for this implementation effort; avoid redundant agents with overlapping ownership.
- Before editing, obtain an explicit work package and file ownership from root. Read existing changes first. Treat unassigned or shared files as root-owned until a handoff says otherwise.
- Keep one active work package per specialist. The initial team limit is five active packages with at most two awaiting integration review. Report blockers instead of silently expanding scope.

## File Ownership and Shared Contracts

The exact assignment takes precedence over illustrative paths below. Root may divide files more narrowly for a given task.

| Area | Default owner | Handoff contract |
|---|---|---|
| Project settings, root URLs, dependencies, environment examples, CI, shared README/setup/status docs | Root | App names, runtime, configuration and validation commands |
| Catalogue models, migrations, admin, seed/import commands | Backend | Field names, defaults, constraints, related names, visibility rules and migration ordering |
| Catalogue views/URLs/forms, templates and static styles | Frontend | Route/query parameter names, template context, form validation and accessibility behaviour |
| Dedicated test modules and acceptance scenarios | QA | Relevant behaviour, fixtures, failure cases, exact commands and results |
| AGILE_DELIVERY.md, PRODUCT_BACKLOG.md, AGENTS.md | Planning; root reconciles final evidence | Story mapping, selected scope, truthful status and working agreements |

Do not let two agents write the same file concurrently. Agree model/query/route contracts before dependent changes. If a required field or endpoint is missing, message root with the concrete dependency and proposed change. Do not create an incompatible parallel model or endpoint to bypass coordination.

Keep a single migration author for a model change. Root handles settings, dependency and root-routing integration. Agents do not overwrite another contributor's work, reset the repository, discard uncommitted changes or rewrite shared history to resolve a conflict.

Use focused feature branches and pull requests when repository tooling permits; root owns branch creation/integration and publication for the current work. In a shared workspace, agents edit only assigned files and leave commits to root unless explicitly instructed otherwise. If access/tooling requires a different authorized workflow, record how the reviewed changes were published; do not imply a PR exists when it does not.

## Implementation Rules

1. Deliver the smallest coherent user outcome in the assigned story; preserve café scope and the selected Sprint Goal.
2. Use framework-supported features and readable code. Match the existing project structure and avoid speculative abstractions or unrelated dependencies.
3. Validate user input, protect mutations and enforce object ownership when applicable. Public catalogue queries must exclude inactive records; future public payloads must exclude members, visits and editorial drafts.
4. Unknown facts remain unknown. Do not default independent ownership to true, unanswered ratings to five, or missing amenities to confirmed. Keep curator opinions separate from private feedback and content matching.
5. Use clearly labelled fictional development data. Make seed commands repeatable without deleting unrelated records. Do not copy another site's café collection, reviews, source code, branding or imagery without permission.
6. Do not commit credentials, authenticated URLs, production databases, private interviews or participant histories. Environment examples contain safe placeholders only.
7. Core catalogue forms must work without GPS or optional JavaScript. Use labelled controls, meaningful links, keyboard access and informative empty states.
8. Update relevant tests and documentation when changing behaviour. Keep available capabilities distinct from planned features and researched hypotheses.

## Verification and Definition of Done

Read the actual setup instructions before running commands. For this PHP project, the normal integrated checks include `php php_app/scripts/lint.php`, `php php_app/tests/unit.php`, `php php_app/tests/config.php`, `php php_app/tests/package.php` and `php php_app/tests/integration.php --allow-reset` against a disposable local MariaDB `_test` database; root records the precise environment and outcomes. Use project-specific commands if the implementation changes. Do not claim an unrun check passed.

Choose meaningful tests for the changed behaviour: active/inactive visibility, combined filters, pagination preservation, detail 404s, seed idempotence and data validation for the initial catalogue; ownership, hard constraints, privacy/deletion and map/list consistency when those features arrive. A test that repeats the same implementation logic provides weak independent evidence.

Each developer checks their assigned change; QA reviews acceptance and failure cases; root validates the integrated result. Inspect affected mobile/keyboard/empty states where applicable. A workflow file is configuration, not proof of a successful remote CI run. Local tests are not deployment or pilot validation.

Move work to Done only after the [Definition of Done](AGILE_DELIVERY.md#7-ready-and-done) is met and root records integration evidence. An agent's completion message means ready for review. Report missing checks, blockers and remaining gaps plainly.

## Required Handover

Send root a concise handover containing:

- Story/work package and exact files changed.
- Behaviour implemented and any shared interface/migration changes.
- Commands actually run, observed results and the tested runtime.
- Acceptance criteria not yet verified, known limitations and follow-ups.
- Any conflict or decision needed before integration.

Do not mark another agent's work Done. Root may update the backlog and shared status after verification. When interrupted, leave a truthful checkpoint so a new contributor can continue.

## Authorization and External Actions

This agreement authorizes no new external communications, purchases, deployments, permission changes, public data collection or account creation. Follow the user's existing authorization for the requested work; do not repeat permission requests for actions already authorized. Route genuinely new consequential scope through root with a concrete proposed action and reason. Never send email, invitations, recruitment messages or other person-directed communications merely because a story lists a human dependency.

Keep the repository private unless the owner explicitly changes that instruction. Never infer a licence, production release or spending approval from a planning table. Report access failures accurately and use only authorized alternatives.
