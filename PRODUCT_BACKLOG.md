# Product Backlog

Last updated: 2026-10-09. This is the initial ordered backlog and first Sprint selection. Story status represents observed work, not a promise of completion. No story is marked Done here before root records integrated validation evidence.

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
| E8: PHP Rebuild | Entire application rebuilt in PHP to support Hostinger Shared Hosting | D12 | CAFE-101–106 |

## 2. Current Sprint Selection (PHP Pivot)

**Current Goal:** repair and verify the existing PHP 8.2+/MariaDB10.11+ catalogue and prepare a secure Hostinger release for myfanverse.in. Actual deployment, DNS/SSL, hosted CI and browser acceptance require separate evidence.

| ID | User outcome | Lead / package | Status |
|---|---|---|---|
| CAFE-101 | Initialize PHP project structure, DB connection, and routing | Root | Done — supported local runtime verified |
| CAFE-102 | Create MariaDB schemas for Area, Cafe, and Offerings | Database | Done — local schema/upgrade/constraints verified |
| CAFE-103 | Build PHP backend API/controllers for search and details | Backend | Done — query/HTTP acceptance verified |
| CAFE-104 | Migrate frontend HTML/CSS to PHP templates | Frontend | Verify |
| CAFE-105 | Guarded, transactional, repeatable fictional development seed | Backend/data | Done — local MariaDB preservation/rollback verified |
| CAFE-106 | MariaDB support, private shared-host config, allowlisted ZIP and myfanverse.in deployment runbook | Root/backend/QA/docs | Verify — local release checks complete; actual Hostinger staging remains open |

Root integration evidence (2026-10-09): PHP 8.2.34/MySQL 8.0.46; 21 PHP files linted, 40 unit checks and 92 saved MySQL/HTTP integration checks passed, plus a negative lint probe and 19 live PHP/Apache routing checks. Backend/data and QA independently reviewed their contracts/acceptance cases; root integrated and reviewed the combined source. [QUALITY_REVIEW.md](QUALITY_REVIEW.md) records exact commands, failure probes and limitations. CAFE-104 remains Verify because interactive keyboard and narrow-screen browser checks could not run (Windows browser helper initialization failed). Hosted CI is unverified until its actual run is observed; Hostinger/pilot deployment and real-data acceptance are outside these completed local packages. User-authorized Git merge/push does not imply deployment or frontend acceptance.

MariaDB/Hostinger release evidence (2026-10-09, codex/hostinger-mariadb): PHP8.2.34/MariaDB10.11.19 passed 27-file lint, 40 unit, 47 config, 105 package and 118 database/HTTP checks. The extracted ZIP under local Apache with private-file production configuration passed 27 further HTTP checks. PHP8.3.35 also passed lint27/unit40/config47/package105; integration118 passed on all four PHP8.2/8.3 × MariaDB10.11.19/11.4.13 pairs. The previous MySQL evidence above is historical. CAFE-106 remains Verify pending actual hPanel runtime/staging smoke checks; DNS/SSL/backups are not configured by local tests. CAFE-104 still needs browser/keyboard/narrow-screen inspection. QUALITY_REVIEW.md records compatibility checks and exact commands. Production seeds remain forbidden; live data is a separate factual sourcing package.
## 2.1 Historical catalogue stories

CAFE-001–007 described the previous Django catalogue. Its historical 49-test/CI evidence applies to legacy_django/, not PHP, and is retained in Git history. Old Done flags do not establish PHP feature acceptance. CAFE-101–105 are the active PHP catalogue packages above.

| Historical story | Current PHP treatment |
|---|---|
| CAFE-001 foundation | CAFE-101 configuration/runtime/routing |
| CAFE-002 schema/admin | CAFE-102 schema; PHP staff admin remains Backlog and needs its own refined package |
| CAFE-003 fictional seed | CAFE-105 guarded repeatable synthetic fixtures |
| CAFE-004 guest search | CAFE-103/104 list/filter/pagination |
| CAFE-005 details/about | CAFE-103/104 full UUID pages and navigation |
| CAFE-006 verification | PHP lint/unit/config/package/MariaDB/HTTP acceptance and CI configuration |
| CAFE-007 handoff | Current README/setup/design/status/evidence documents |

## 3. Ordered Remaining Backlog

All remaining stories begin in **Backlog**. Unsupported Done flags for CAFE-011–030 were corrected during the PHP review; those features are absent from the active PHP implementation. Sprint numbers are selection candidates, not assignments to a fixed calendar. Refine and split stories that exceed the available Sprint capacity. Research runs alongside the code sequence; missing real data does not block the synthetic demo but does block claims of a useful real pilot.

| ID | Candidate phase | User story and minimum acceptance criteria | Dependencies | Lead | Mapping | Status |
|---|---|---|---|---|---|---|
| CAFE-008 | Readiness/S1 | As Product Owner, I have an explicit pilot area/segment, weekly review/research capacity, decision owner and pre-purchase cash ceiling. Open decisions are recorded with next actions; interviews test a defined problem rather than claiming validation from the demo. | Anuj's input | Anuj + planning | Product Goal; cross-cutting | Backlog |
| CAFE-009 | Readiness/S1 onward | As a researcher, I can compare users' needs with the concept. Conduct consent-aware visitor/manager conversations, summarize recurring needs and limitations, and decide whether to continue or change the segment. Targets of 15–20 visitors and five managers are plans, not fabricated responses. | 008; recruitment and notice | Anuj / research lead | P2/P3 hypothesis | Backlog |
| CAFE-010 | S1–S2 | As a visitor, I can rely on a checked initial catalogue. Establish 20–30 sourced pilot records, field-level provenance, dates, unknown states and price scope; separate them from synthetic records and check permissions for any photos/content. | 008; data sources and field work | Catalogue lead + backend | P1, P7 | Backlog |
| CAFE-011 | S2 | As a visitor/editor, I can use factual amenities and report corrections. Implement yes/no/unknown observations, freshness rules and a staff correction queue; input validation and reporter privacy are checked; stale essential information does not qualify as confirmed. | 002, 010; editor permission design | Backend + QA | P1, P7 | Backlog |
| CAFE-012 | S2 | As a new visitor, I can express drink, budget, atmosphere and today's purpose in a skippable session flow. Essential versus preferred choices are distinct; favourites are optional and limited as specified. Invalid budgets/tags are rejected; member persistence can follow in 015. | 002, 011; preference vocabulary | Frontend + backend | P2 | Backlog |
| CAFE-013 | S2 | As a new visitor, I receive explained content matches without history. Implement T/P/B eligibility and ranking from the technical design; handle missing factors by documented normalization; preserve hard constraints and tie ordering; no fabricated community weight, percent confidence or curator influence. | 011–012; agreed examples | Backend + QA | P3 | Backlog |
| CAFE-014 | S2 | As a visitor, I understand why a result fits or why none qualify. Show factual match reasons and unmet constraints; compare this flow with a basic filter baseline using defined questions and report the actual sample. Do not silently relax a constraint or treat non-response as success. | 013; research participants for evaluation | Frontend + Anuj | P2, P3 | Backlog |
| CAFE-015 | S3 | As a member, I can register/sign in, recover access and retain my explicit preferences. Use framework auth, safe return destinations, access controls and production email configuration before pilot use; session preferences transfer deliberately; guests retain catalogue browsing. | 012; account and email decisions | Backend + frontend | P2, P6 foundation | Backlog |
| CAFE-016 | S3 | As a member, I can save/unsave my own café shortlist. Duplicate bookmarks are prevented; mutation requests are protected; another user cannot read or modify my shortlist through guessed IDs. | 015 | Backend + frontend; QA reviews | P4 | Backlog |
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
| CAFE-028 | S6 | As the operations owner, I can run and restore a production-like pilot. Target MariaDB database checks pass; production settings, static assets, persistent storage, logging, health checks and backup/restore are validated; secrets stay out of code; a rollback/runbook is available. Any service purchase/deployment follows existing user authorization. | 015–027; host/region/spending choices | Root + backend + QA | Cross-cutting release | Backlog |
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
