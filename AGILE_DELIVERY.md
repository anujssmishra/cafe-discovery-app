# Agile Delivery Plan

Last updated: 2026-10-09. Status: delivery plan adopted for the first implementation increment; later sprint content is a forecast. This file describes how the team will build and inspect the product. [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md) records the work and its status; [README.md](README.md) describes the capabilities actually available.

## 1. Product Goal

Enable an adult visitor in one pilot area to find a café suited to their drink, budget and purpose, understand the recommendation, and optionally keep private saves and visit feedback. Validate usefulness with a checked catalogue and a small invited cohort before expanding coverage or adding community signals.

The proposed pilot targets remain 20–30 verified cafés and 30–50 adult participants. They are planning targets, not existing inventory or users. Synthetic development data does not satisfy either target.

## 2. One Team, Multiple Developer Agents

Anuj is the Product Owner. The root assistant integrates the work and facilitates the process. Specialist agents contribute within the same product team; these labels describe working responsibilities, not hired employees or independently accountable human Scrum roles. Human product, spending, data and release decisions remain with the designated owner.

| Responsibility | Lead | Work and handoff |
|---|---|---|
| Product ownership | Anuj | Product Goal, backlog ordering, pilot area/segment, feedback and scope decisions |
| Integration and facilitation | Root agent | Sprint Goal, task boundaries, shared contracts, configuration, integration review, validation record and handover |
| Backend and data development | Backend agent | Models, migrations, catalogue admin, seed/import behaviour and data constraints; hands off model/query contracts |
| Discovery experience | Frontend agent | Views, templates, forms and accessible user journeys; hands off routes, query parameters and interaction expectations |
| Quality and verification | QA agent | Independent acceptance checks, failure cases, meaningful automated tests and defects; hands off reproducible results |
| Delivery planning | Planning agent | Delivery plan, ordered backlog, requirement traceability and working agreements; reconciles status with evidence |
| Research, catalogue and operations | Anuj or a named human delegate | Interviews, café checks, original editorial observations, participant contact, provider accounts and pilot support |

One agent may cover more than one specialty when needed. Agent parallelism helps independent work proceed together, but integration, human decisions, field research and review remain dependencies. Do not divide the original estimate by the number of agents or claim a measured speedup without evidence.

## 3. Cadence and Forecast

Propose two-week Sprints. Confirm the first calendar start/end and available human review time during planning; this document does not silently schedule meetings or promise continuous background work. Active agent sessions can produce several increments within a Sprint. Work between sessions requires a person or an explicitly configured execution system to resume it.

The forecast below orders useful increments. It is not a fixed six-sprint delivery commitment. The earlier estimate remains **235–365 hours before contingency, or 282–438 hours with 20% contingency**, as described in [ROADMAP_AND_BUDGET.md](ROADMAP_AND_BUDGET.md). Six two-week Sprints describe an initial twelve-week planning horizon; actual capacity, research, pilot readiness and rework can extend it to the prior 12–18-week scenario or beyond. Reforecast from observed completion and remaining work after every review.

| Phase | Proposed Sprint | Sprint Goal and usable increment | Acceptance gate | Dependencies |
|---|---|---|---|---|
| 0. Readiness | Inside Sprint 1 | Agree the working method and establish a reproducible local foundation while pilot decisions and research begin | Setup, ownership, synthetic-data policy and backlog are clear; unresolved pilot decisions have owners | Repository access; local runtime; Anuj's review capacity |
| 1. Catalogue discovery | 1 | A guest can find and inspect a synthetic café through a usable mobile web catalogue | PHP 8.2+/MariaDB10.11+ runs; schema/guarded seed work; PHP admin remains future work; partial name and area filtering, pagination, UUID details and about page pass acceptance checks | Phase 0 technical readiness; no real-data collection required for this demo |
| 2. Useful content matches | 2 | A new visitor can express today's needs and receive explained matches without any visit history | Essential constraints, unknown/stale data, budget and empty-result behaviour pass; reasons correspond to stored facts | Catalogue attributes and sourced price/amenity data; matching examples agreed |
| 3. Personal records and control | 3 | A member can save cafés and manage private visits and their own data | Authentication, ownership, optional ratings, export/deletion and contribution choices are checked end to end | Stable catalogue IDs; account/retention decisions; content baseline remains useful without logs |
| 4A. Geographic discovery | 4 | A visitor can switch between the same filtered results on an accessible list and map | Deliberate map loading, named pins, area chips, detail dialog, directions, identical result sets and failure fallback pass | Public serialization contract; tile-provider terms/configuration; Phase 3 for member actions |
| 4B. Editorial curation | 5 | A visitor can understand attributed curator opinions and the criteria for the local collection | Published/draft separation, nullable scores, trip labels, ownership/count provenance and correction handling pass | Original permitted content; confirmed collection policy; authorized curator |
| 5. Hosted pilot readiness | 6 | Invited adults can use a stable hosted version with checked data and support | MariaDB database checks, deployment configuration, mobile usability, notices, monitoring and restore exercise pass; pilot readiness checklist complete | Hosting/spending decisions, 20–30 checked cafés, recruitment and support owner |
| 6. Learn and iterate | After readiness; refined Sprint by Sprint | Improve an observed user problem and decide whether to expand, simplify or stop | Report defined metrics and qualitative evidence; the next selected hypothesis has a measurable outcome | Sufficient observation time; do not report 14-day return before the cohort matures |

Readiness work is inside Sprint 1; a separate "Sprint Zero" is not a requirement of this process. Research and catalogue checking continue alongside development. A synthetic local increment can be useful for review while real-data and pilot prerequisites remain open. Before public release, unresolved release prerequisites must be addressed.

The two large later areas—accounts/data controls and maps/editorial—must be split or extended if they cannot meet the Definition of Done within capacity. Protect the Sprint Goal and quality; renegotiate selected scope rather than quietly carrying unfinished work as complete.

## 4. First Sprint and This Session

**Sprint Goal:** make café discovery concrete through a reproducible, tested catalogue that a guest can search and inspect, using explicitly fictional demonstration records.

The active review covers CAFE-101–105: PHP 8.2+/MariaDB10.11+ schema and guarded fictional seeding, guest search/area filters, pagination, details, about, routing/assets, generic errors, meaningful tests and reproducible docs. Root integrates backend/data, frontend/routing and QA packages with separate file ownership. PHP admin, accounts, matching, maps and ratings remain future work. A workflow is not a hosted CI result.

| Work package | Lead | First handoff | Integration dependency |
|---|---|---|---|
| W1: PHP foundation/integration, CAFE-101 | Root | Project/app names, dependency configuration, root routes, settings and file boundaries | All specialists work against this contract |
| W2: Schema and seed, CAFE-102/105 | Backend | Model fields, active-record rule, related names, ordering and seed command | Frontend/QA can then target stable behaviour |
| W3: Guest controllers/templates, CAFE-103/104 | Frontend | Query parameters, paginated context, public routes and accessible templates | Requires W1/W2 contracts, not the completion of every backend detail |
| W4: PHP/MariaDB verification | QA | Acceptance scenarios, executable tests and CI requirements | Tests integrated behaviour after W2/W3 land |
| W5: PHP delivery guide | Root | Plan, traceable backlog and operational agent rules | Root records actual implemented state after validation |

Root reviews each handoff, resolves conflicting interfaces and runs the integrated application checks. The handover must state exact commands and outcomes, remaining limitations, and whether a remote commit or CI result has actually been verified. This first increment is a development demonstration, not the complete pilot MVP.

## 5. Events and Feedback

The framework reference is the [official Scrum Guide](https://scrumguides.org/scrum-guide.html), reviewed 2026-10-06. The guide's Product Goal, Sprint Goal and Definition of Done inform this workflow. The working times and agent-specific rules below are project choices. Agent status messages supplement human collaboration; they do not establish that Scrum events occurred.

| Event | Proposed practice for this project | Recorded result |
|---|---|---|
| Sprint Planning | 45–60 minutes with Anuj and the active developers; choose a valuable goal, capacity, selected stories and delivery approach | Sprint Goal, selected stories, owners, dependencies and unresolved questions |
| Daily Scrum | Up to 15 minutes on active working days; inspect progress toward the goal and adapt the day's plan | Next actions and blockers, not a report of agent busyness |
| Backlog refinement | Short sessions during the Sprint; clarify the next work before selection | Smaller stories, observable acceptance criteria and updated dependencies |
| Sprint Review | 30–45 minutes with Anuj and relevant participants; try the usable increment and inspect outcomes | Feedback, changed assumptions and reordered backlog |
| Sprint Retrospective | 20–30 minutes after review; inspect collaboration, defects, test gaps and integration friction | One concrete improvement, with an owner, for the next Sprint |

These shorter proposed planning/review/retrospective sessions suit the small team; change them when collaboration needs more time. Do not claim a meeting took place merely because a document was generated. The Sprint Review is for inspection and adaptation; an already authorized release need not wait for it if release criteria are met.

## 6. Board and Work in Progress

Use one workflow: **Backlog → Ready → In progress → Review → Verify → Done**. Mark an impeded item **Blocked**, recording its previous state, cause, owner and next action; blocked work still counts against its work-in-progress limit. Return it to its prior active state after resolution.

The Markdown backlog is the initial source of truth. If a GitHub Projects board is later configured, record its URL here and choose one authoritative status location rather than allowing two to drift. GitHub issues/board entries are not implied by this document.

Working limits are one active work package per specialist, at most five active packages across this initial team, and at most two packages awaiting integration review. Several tightly related stories may be in one package, as shown for W2/W3. Finish or unblock existing work before pulling another package. Root may change a limit after the team reviews the reason; record the change rather than bypassing the limit invisibly.

Track cycle time, blocked time, defects and completed acceptance criteria. Story points are optional and should be estimated by the people doing the work if they prove useful. There is no established velocity. Never equate agent messages, tokens, file count or task count with delivered product value.

## 7. Ready and Done

**Ready is a team working agreement**, not an extra required Scrum artifact. A story is ready when its user outcome, boundaries, requirement IDs, dependencies, owner, testable acceptance criteria and data impact are clear enough to implement. It must be small enough for the planned Sprint; unresolved details can remain when they do not prevent the team from delivering the goal. Do not make a rigid form a barrier to useful refinement.

**Definition of Done for an implementation increment:**

1. Its acceptance criteria are met by integrated behaviour, and a second reviewer has inspected the change.
2. Relevant automated tests pass against the integrated code; failed or unrun checks are reported explicitly. PHP lint and MariaDB schema/upgrade checks are clean for the supported local setup.
3. A contributor can reproduce the documented setup and principal changed journey. Applicable mobile, keyboard, empty-state and failure behaviour has been checked.
4. Permission, input-validation and data-handling cases affected by the change are addressed. No committed credentials or misrepresented synthetic records exist.
5. Model changes include migrations; shared contracts and operational notes are updated. The implementation does not silently break existing requirements.
6. README/setup/backlog describe actual behaviour. Evidence identifies the reviewed revision or files, commands/results, reviewer and limitations.

A developer agent's "finished" message moves work to review, not automatically to Done. Root records integrated evidence before updating status. If an acceptance criterion cannot be verified, keep the item in Review/Verify or split an explicit follow-up with the Product Owner's scope agreement; do not hide a missing requirement in a footnote.

Hosted pilot release adds the requirements in the roadmap and data plan: real catalogue checks, configured persistent MariaDB database, participant notice/eligibility, permissions and deletion checks, working support arrangements, a restore exercise, and provider/operations readiness. Local Done does not mean deployed or validated with users.

## 8. Risks and Next Decisions

| Risk | Response and next evidence | Accountable lead |
|---|---|---|
| Many simultaneous edits create incompatible code | Agree fields/routes first; single writer per file; root integrates and tests every combined increment | Root |
| Agent-generated work appears complete without validation | Keep Review/Verify visible; record reproducible results; separate local checks from hosted CI/deployment | Root and QA |
| No pilot city, segment or verified records yet | Anuj selects an initial research area and recruits interviewees; demo records remain visibly synthetic | Anuj |
| Calendar promise exceeds available time | Set review/development capacity at planning, measure actual completion, and reforecast scope after each review | Anuj and root |
| Better ranking is assumed without evidence | Compare content matches with basic filters; keep community signals disabled until eligibility and usefulness are demonstrated | Product Owner and matching developer |
| Maps/editorial expand cost and data exposure | Choose provider and review public payloads; test fallback; use original permissioned notes | Root and data/curation lead |
| Private records leak or deletion misses derived data | Add ownership/withdrawal/export/deletion tests with the feature; separate public catalogue from member records | Backend and QA |

Next human decisions are pilot area/segment, time available for review and research, and a spending ceiling before service purchases. They do not block the synthetic local foundation. Provider selection, notices and public collection policy become dependencies before the related release stories are selected.

## 9. Related Documents

- [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md): epics, story criteria, ownership and status.
- [AGENTS.md](AGENTS.md): operating rules for concurrent implementation.
- [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md) and [FEATURES_REFERENCE.md](FEATURES_REFERENCE.md): product acceptance and reference-feature definitions.
- [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md): architecture and matching design.
- [ROADMAP_AND_BUDGET.md](ROADMAP_AND_BUDGET.md): effort, research, pilot metrics and costs.
- [DECISIONS.md](DECISIONS.md): confirmed choices, open decisions and changes.
