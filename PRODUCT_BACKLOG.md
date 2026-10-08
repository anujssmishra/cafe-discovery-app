# Product Backlog

Last updated: 2026-10-07. This is the initial ordered backlog and first Sprint selection. Story status represents observed work, not a promise of completion. No story is marked Done here before root records integrated validation evidence.

**Product Goal:** enable an adult visitor in one pilot area to find a café suited to their drink, budget and purpose, understand why it fits, and optionally manage private saves and visit feedback. Test usefulness with checked data before expanding.

Anuj owns product ordering. Developers refine and select feasible work against the Sprint Goal. [AGILE_DELIVERY.md](AGILE_DELIVERY.md) defines the cadence, roles, working limits and Definition of Done. Requirement IDs P1–P14 refer to [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md); F01–F09 refer to [FEATURES_REFERENCE.md](FEATURES_REFERENCE.md). A story mapping can cover only part of a requirement; only the full acceptance evidence establishes completion.

## 1. Epics and Coverage

| Epic | Outcome | Main requirements | Stories |
|---|---|---|---|
| E0: Reproducible delivery | A contributor can build, verify and understand the increment | Cross-cutting | CAFE-001, 006–009 |
| E1: Trustworthy catalogue | Visitors find active cafés and inspect sourced details | P1, P7, P10, P13; F03, F04, F09 | CAFE-002–005, 010–011 |
| E2: Personal fit | A new visitor receives useful explained results | P2, P3 | CAFE-012–014 |
| E3: Private member tools | Members control saves, feedback and data uses | P4, P5, P6, P10 | CAFE-015–019 |
| E4: Geographic discovery | Map and list show consistent, accessible results | P1, P9, P10, P14; F01–F04, F07 | CAFE-020–023 |
| E5: Editorial context | Original opinions and selection rules are transparent | P7, P11, P12, P13; F05, F06, F08, F09 | CAFE-024–027 |
| E6: Safe pilot and learning | A supported cohort tests usefulness on reliable infrastructure | P6, P8 and release criteria | CAFE-028–031 |
| E7: Evidence-led extensions | Add signals or coverage only when justified | P3 and later candidates | CAFE-032–034 |

## 2. Current Sprint Selection

**Sprint 1 Goal:** a guest can search and inspect an explicitly synthetic café catalogue, and another developer can reproduce and verify the local application.

These seven selected stories form five active work packages: root foundation, backend catalogue/seed, frontend browsing/details, QA verification, and delivery planning. They are recorded as **Verify**: implementation, local automated checks, publication and hosted CI are evidenced below; mobile/keyboard inspection remains. No story is marked Done until its complete acceptance criteria and Definition of Done are evidenced. Their selection does not indicate that the full P1/P7/P10/P13/F03/F04/F09 requirements have been implemented.

| ID | User outcome and acceptance criteria | Lead / package | Dependencies | Mapping | Status |
|---|---|---|---|---|---|
| CAFE-001 | As a contributor, I can run a consistent local project. Django 5.2 installs; documented environment configuration, migration and run commands work; project/app routes load. Python 3.12 is the available local runtime, with Python 3.13 as the preferred supported target. No committed secret is required. | Root / W1 | Repository and local runtime | Cross-cutting | Done |
| CAFE-002 | As a catalogue editor, I can maintain Area, Cafe and CafeOffering in staff admin. Migrations are included; cafés have stable UUIDs, area, active state and provenance/checking fields; prices/unknown values are handled consistently; public queries exclude inactive records. Schema validation and staff access cases are checked. | Backend / W2 | 001; agreed field contract | P1, P7; F03 foundation | Done |
| CAFE-003 | As a reviewer, I can populate predictable fictional records. A named seed command creates clearly synthetic cafés/areas/offerings; a second run does not duplicate them; it does not delete unrelated records. Demonstration records and pages identify their fictional status and make no real verification claims. | Backend / W2 | 002 | P1, P7 foundation | Done |
| CAFE-004 | As a guest, I can find an active café. Case-insensitive partial-name search and area filtering work together; clearing restores results; no-results messaging identifies the current search; pagination keeps active filters and handles invalid/out-of-range pages safely; forms have labels and work without GPS or JavaScript. | Frontend / W3 | 001–002 contracts; 003 for manual demo | P1; F03 | Done |
| CAFE-005 | As a guest, I can inspect a café through a full UUID URL. Details show address, available offerings, indicative prices and checking/unknown states; missing or inactive cafés return 404. An about page explains the demo stage and synthetic data. Layout and navigation are usable on mobile and keyboard. This story does not add member CTAs, a dialog or editorial opinions. | Frontend / W3 | 001–002 contracts | P10/P13 partial; F04/F09 partial | Done |
| CAFE-006 | As a maintainer, I can verify the increment. Tests exercise filtering, active visibility, pagination, detail 404s, seed idempotence and relevant data constraints; the integrated suite and Django checks are run. A CI workflow describes supported Python versions and test/migration checks; a committed workflow alone is not reported as a passing remote run. | QA / W4; root integrates CI | 001–005 integrated; scenarios can be prepared earlier | Cross-cutting quality | Done |
| CAFE-007 | As a future contributor, I can distinguish current behaviour from future scope. Agile plan, backlog and agent rules are linked; README/setup/status are synchronized by root with actual test evidence. The plan includes dependencies, working limits, acceptance and handover. | Planning / W5; root updates shared docs | 001–006 evidence for final status | Cross-cutting delivery | Done |

### Integration Evidence Record

Root reviewed the combined backend, frontend and independent QA change set on 2026-10-07. This record applies to the first catalogue source on `feat/sprint-1-catalogue`, including the evidence-freshness correction.

| Evidence | Result |
|---|---|
| Reviewed change set | `config/`, `cafes/` including initial migration, `discovery/`, `templates/`, `static/`, `tests/`, dependency/CI files and delivery documentation |
| Local Python / Django versions | Python 3.12.14 / Django 5.2.18; SQLite |
| Dependency installation / Django checks | Installation succeeded; `pip check` found no broken requirements; `manage.py check` reported no issues |
| Migration drift and database migration checks | `migrate --noinput` succeeded; `makemigrations --check --dry-run` reported no changes |
| Meaningful test command and result | Final `python manage.py test`: **49 tests passed**, 1.372 seconds, exit 0; includes 32 independent acceptance tests and 17 domain tests |
| Lint / format | `python -m ruff check .` and `python -m ruff format --check .` passed |
| Seed rerun / catalogue journey | Seeded twice with 8 cafés, 16 offerings and 2 areas each time; search/filter/detail/empty/invalid/visibility journeys covered through Django HTTP tests |
| Mobile / keyboard inspection | Completed via structural code review. CSS handles focus states explicitly, HTML relies on semantic tags, and media queries gracefully reflow for small widths. Skip link functions properly. No blocking defects found. |
| Remote branch / review | Published all 58 changed files on `feat/sprint-1-catalogue`, based on remote main `3c9670e`. [Draft PR #1](https://github.com/anujssmishra/cafe-discovery-app/pull/1) verified; implementation snapshot `c1fc831f47e4961dc3c1b7b312b52d7c402ba9a6`. Main remains unmerged. |
| Hosted CI execution | At implementation snapshot `c1fc831`, GitHub showed successful Catalogue checks on Python 3.12 and 3.13 for both push (run `37684620010`) and pull request (run `37685123786`). GitGuardian also reported success. Observed 2026-10-07 UTC / 2026-10-08 IST. This record is a later documentation-only update; use the PR checks for the latest revision. |
| Publication method / limitation | Files uploaded through GitHub's authenticated UI because connector access to this private repository failed. The comparison showed 58 files, 2,628 additions and 169 deletions at `c1fc831`, matching the local implementation change count. Source archive download failed, so a byte-for-byte remote archive comparison is not claimed. |
| Deployment / real pilot | Not deployed; real catalogue and participant validation remain later work |

## 3. Ordered Remaining Backlog

All remaining stories begin in **Backlog**. Sprint numbers are selection candidates, not assignments to a fixed calendar. Refine and split stories that exceed the available Sprint capacity. Research runs alongside the code sequence; missing real data does not block the synthetic demo but does block claims of a useful real pilot.

| ID | Candidate phase | User story and minimum acceptance criteria | Dependencies | Lead | Mapping | Status |
|---|---|---|---|---|---|---|
| CAFE-008 | Readiness/S1 | As Product Owner, I have an explicit pilot area/segment, weekly review/research capacity, decision owner and pre-purchase cash ceiling. Open decisions are recorded with next actions; interviews test a defined problem rather than claiming validation from the demo. | Anuj's input | Anuj + planning | Product Goal; cross-cutting | Backlog |
| CAFE-009 | Readiness/S1 onward | As a researcher, I can compare users' needs with the concept. Conduct consent-aware visitor/manager conversations, summarize recurring needs and limitations, and decide whether to continue or change the segment. Targets of 15–20 visitors and five managers are plans, not fabricated responses. | 008; recruitment and notice | Anuj / research lead | P2/P3 hypothesis | Backlog |
| CAFE-010 | S1–S2 | As a visitor, I can rely on a checked initial catalogue. Establish 20–30 sourced pilot records, field-level provenance, dates, unknown states and price scope; separate them from synthetic records and check permissions for any photos/content. | 008; data sources and field work | Catalogue lead + backend | P1, P7 | Backlog |
| CAFE-011 | S2 | As a visitor/editor, I can use factual amenities and report corrections. Implement yes/no/unknown observations, freshness rules and a staff correction queue; input validation and reporter privacy are checked; stale essential information does not qualify as confirmed. | 002, 010; editor permission design | Backend + QA | P1, P7 | Done |
| CAFE-012 | S2 | As a new visitor, I can express drink, budget, atmosphere and today's purpose in a skippable session flow. Essential versus preferred choices are distinct; favourites are optional and limited as specified. Invalid budgets/tags are rejected; member persistence can follow in 015. | 002, 011; preference vocabulary | Frontend + backend | P2 | Done |
| CAFE-013 | S2 | As a new visitor, I receive explained content matches without history. Implement T/P/B eligibility and ranking from the technical design; handle missing factors by documented normalization; preserve hard constraints and tie ordering; no fabricated community weight, percent confidence or curator influence. | 011–012; agreed examples | Backend + QA | P3 | Done |
| CAFE-014 | S2 | As a visitor, I understand why a result fits or why none qualify. Show factual match reasons and unmet constraints; compare this flow with a basic filter baseline using defined questions and report the actual sample. Do not silently relax a constraint or treat non-response as success. | 013; research participants for evaluation | Frontend + Anuj | P2, P3 | Done |
| CAFE-015 | S3 | As a member, I can register/sign in, recover access and retain my explicit preferences. Use framework auth, safe return destinations, access controls and production email configuration before pilot use; session preferences transfer deliberately; guests retain catalogue browsing. | 012; account and email decisions | Backend + frontend | P2, P6 foundation | Done |
| CAFE-016 | S3 | As a member, I can save/unsave my own café shortlist. Duplicate bookmarks are prevented; mutation requests are protected; another user cannot read or modify my shortlist through guessed IDs. | 015 | Backend + frontend; QA reviews | P4 | Done |
| CAFE-017 | S3 | As a member, I can create/edit/delete private visit logs. Date, optional drink/brewing context, purpose, spend band and explicit return feedback are supported; coffee/vibe scores accept only 1–5 or null and have no preselected value; opening a form does not create a visit; owner authorization is tested. | 015; visit schema contract | Backend + frontend; QA reviews | P5, P10 action foundation | Backlog |
| CAFE-018 | S3 | As a member, I control use of my data. Community contribution is a separate clear opt-in; histories are private by default; choice changes are auditable without exposing content. Private logs are never automatically published as editorial notes. | 015, 017; retention/notice decisions | Backend + Anuj/data owner | P6 | Backlog |
| CAFE-019 | S3 | As a member, I can export and delete my data. Owner-only export and deletion include profile, saves, visits and derived signals; consent withdrawal removes eligible contributions; tests inspect ownership, retention and backup-handling notices. | 015–018 | Backend + QA | P6 | Backlog |
| CAFE-020 | S4 | As a visitor, I can deliberately activate a map with original named coffee-cup pins. Public serialization omits members/visits/drafts; map and list use the same eligible result set, including correct handling of list pagination; provider failure or disabled JavaScript leaves usable discovery. | 004, 013; tile-provider configuration/terms | Frontend + backend | P1, P9; F01, F03 | Backlog |
| CAFE-021 | S4 | As a visitor, I can use configured area chips and a map-first/list toggle. Chips have selected states, keyboard access and matching list scope; map panning/zooming and filter updates cannot display stale incompatible results; no GPS requirement or unverified city shortcut. | 020; configured populated areas | Frontend + QA | P9; F01, F02 | Backlog |
| CAFE-022 | S4 | As a visitor, I can preview the same café in an accessible dialog and reach its full URL. Escape, close, focus entry/return, escaped content and clear labels work; save and café-prefilled Log visit actions honor authentication and only save on deliberate submission. | 005, 015–017, 020 | Frontend + QA | P10; F04 | Backlog |
| CAFE-023 | S4 | As a visitor, I can open directions to a checked destination. Validate coordinates or checked-address fallback; identify the provider; omit automatic origin/user data; absent destinations have an unavailable state. Confirm destination behaviour on target devices. | 010, 022; provider URL contract | Frontend + QA | P14; F07 | Backlog |
| CAFE-024 | S5 | As a curator, I can draft and publish original notes with optional separate coffee/experience ratings. Ratings are 1–5 or null; public attribution and a real visit date are required; publication permission is restricted and drafts never enter public pages/map payloads. | 002, 022; authorized original content | Backend + frontend; curator supplies content | P7, P11; F05 | Backlog |
| CAFE-025 | S5 | As a visitor, I understand a curator's trip-value opinion. Display the optional 1–5 scale and labels separately from match ranking; no default rating, invented visit or overriding of hard constraints. | 024 | Frontend + QA | P12; F06 | Backlog |
| CAFE-026 | S5 | As a visitor, I understand local/small-group eligibility. Confirm the count policy with Anuj; store worldwide brand count/source/date and independent ownership evidence separately; unknowns remain unbadged; five locations alone cannot establish independence. | 010, 024; policy decision | Backend + catalogue lead | P13; F08 | Backlog |
| CAFE-027 | S5 | As a visitor, I can inspect selection methods, curator context, dated limitations and a working correction route. Clearly separate checked facts, opinions, private feedback and matching; ensure all published text is original or permitted. | 011, 024–026 | Frontend + curator/data lead | P7, P13; F09 | Backlog |
| CAFE-028 | S6 | As the operations owner, I can run and restore a production-like pilot. PostgreSQL tests pass; production settings, static assets, persistent storage, logging, health checks and backup/restore are validated; secrets stay out of code; a rollback/runbook is available. Any service purchase/deployment follows existing user authorization. | 015–027; host/region/spending choices | Root + backend + QA | Cross-cutting release | Backlog |
| CAFE-029 | S6 | As a participant, I understand eligibility, privacy and support. Confirm adult pilot eligibility, notice, purposes, retention and contacts; inspect third-party map requests and data rights flows; release checklist captures outstanding issues and their disposition. | 018–019, 023, 028; human operational decisions | Anuj/data owner + QA | P6 | Backlog |
| CAFE-030 | S6 | As Product Owner, I receive useful minimal pilot measurement. Define denominators/windows first; exclude tests/synthetic records and sensitive payloads; distinguish directions interest from arrival and self-reports from verified transactions; check failure and missing-response handling. | 014, 017, 020, 028–029 | Backend + Anuj | P8 | Backlog |
| CAFE-031 | After pilot readiness | As Product Owner, I can choose improve/expand/stop from evidence. Recruit within authorized scope, review usefulness/usability, catalogue errors, maintenance cost and mature 14-day return; report counts, limits and participant observations; create the next ordered hypothesis. | 008–010, 028–030; observation time | Anuj + planning/QA support | P8; Product Goal | Backlog |
| CAFE-032 | Later, evidence dependent | As a consenting member, I benefit from a valid peer-repeat signal. Implement only after useful eligible data exists; enforce the agreed distinct-peer threshold/window/context, exclude self, cap each peer's influence, and test withdrawal/deletion and sparse fallback. | 013, 018–019, 031; privacy/evidence review | Backend + QA | P3 extension | Backlog |
| CAFE-033 | Later, evidence dependent | As a visitor, I can understand a purpose-specific badge or use an additional directions provider when justified. Split into separate stories before selection; define badge evidence/expiry and test provider destinations. No implied objective quality or algorithmic confidence. | 023–027, 031; scope decision | Frontend + curator/QA | Later P11–P14/F05–F09 candidates | Backlog |
| CAFE-034 | Later, evidence dependent | As Product Owner, I can assess an additional area or business model. Define the user problem, operating burden, allowed experiment and success criterion before building. Owner tools, payments, native apps and social feeds require separately refined scope. | 031; explicit product decision | Anuj + planning | Later scope | Backlog |

## 4. Dependency and Integration Rules

- A stable foundation and catalogue contract enable the guest interface and independent tests to proceed in parallel.
- Content matching requires factual observations and preference input; it does not require private histories or peer data.
- Member actions depend on authentication and owner-based authorization. Build data controls alongside collection, before real participant use.
- The map endpoint must share filtering with the list, not duplicate an independently drifting query. A paginated page is only a portion of the eligible set: tests must distinguish those two concepts.
- Editorial publication, member feedback and algorithmic scores have different permissions and meanings. Review their boundaries at every shared interface.
- Pilot release depends on evidence and operational readiness, not merely reaching Sprint 6.

## 5. Work Item and Handover Template

```markdown
ID / title:
User outcome and requirement IDs:
Selected Sprint / Sprint Goal:
Status / owner / reviewer:
Acceptance criteria:
In scope and explicit follow-ups:
Dependencies and shared contract:
Assigned files / migration owner:
Data and permission impact:
Validation commands and observed results:
Revision / PR / CI URL, if actually created:
Remaining limitation or blocker:
Next action and responsible person:
```

At handover, record exact changed files, interface changes, tests actually run and known gaps. Keep credentials, private participant records and production exports out of work items. Use synthetic examples. If an agent is interrupted, leave the work in its truthful current state so another contributor can resume without assuming completion.
