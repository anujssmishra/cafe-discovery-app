# Decisions, Assumptions and Open Questions

Last updated: 2026-10-09. Use this file as the decision record and [DEVELOPMENT_HANDOFF.md](DEVELOPMENT_HANDOFF.md) for a new coding session. A documented proposal is not automatically an approved decision or implemented feature.

## 1. Status Definitions

- **Confirmed:** the project direction or repository action is explicitly established.
- **Proposed:** a suggested starting choice to review before implementation or spending.
- **Open:** an answer, owner or evidence is still needed.
- **Implemented locally:** actual source and local verification support the stated slice. This does not imply remote CI, deployment, full acceptance or pilot validation.

## 2. Confirmed Direction

| ID | Decision | Reason / evidence | Status |
|---|---|---|---|
| D01 | Scope is café discovery, rather than restaurant operations | Project owner's requested café adaptation | Confirmed |
| D02 | Personalization uses taste and visit purpose, with repeat behaviour as a potential later signal | Established concept in the project brief; usefulness still needs validation | Confirmed concept |
| D03 | Keep project documentation in the existing private GitHub repository | Repository created under anujssmishra; owner requested uploads | Confirmed repository arrangement |
| D04 | Use multiple connected Markdown documents with README as the entry point | Owner requested enough context for future readers and permitted multiple files | Confirmed documentation format |
| D05 | Add the reference site's map, search, detail, editorial and local-collection feature concepts | Owner requested features from Caffeine Chronicles; adaptation documented in FEATURES_REFERENCE.md | Confirmed scope direction; implementation choices proposed |
| D06 | Begin development through phased agile delivery with multiple developer agents | Owner explicitly requested building, phase-wise implementation and multiple agents, then asked to continue | Confirmed direction |
| D07 | Anuj is Product Owner; root integrates bounded backend, frontend, QA and planning work | Current agent team and working agreement; acceptance/status recorded in AGILE_DELIVERY.md and PRODUCT_BACKLOG.md | Confirmed current working arrangement |
| D08 | First increment is a synthetic catalogue before member, matching, map and editorial work | Area/Cafe/CafeOffering, admin, guarded seed, guest filters/pagination/details/about are present; final integrated run passed 49 tests on Python 3.12.14 / Django 5.2.18 | Published in draft PR #1; hosted CI passed through `3ccb330`; browser/mobile/keyboard review remains open |
| D09 | Use generated environment secrets, explicit local debug/hosts, and demo mode restricted to debug | Current settings and command guards; `.env` is a reference file, not an automatic loader | Implemented locally |
| D10 | Use `feat/sprint-1-catalogue` as the first integration branch | Keeps the first source increment reviewable; root owns remote publication and integration | Confirmed workflow; remote status recorded separately |
| D11 | Keep continuation context tool-neutral so Anuj can code with Codex, Claude, Gemini or another developer | Owner requested transfer for coding, then explicitly requested generic use across assistants on 2026-10-08 | Confirmed direction; shared DEVELOPMENT_HANDOFF/STARTER_PROMPT and assistant pointer files |
| D12 | Pivot entire application architecture from Python/Django to PHP/MySQL | Owner decision to utilize existing Hostinger Single Web Hosting plan; avoiding new infrastructure | Confirmed |

## 3. Proposed Starting Choices

| ID | Proposal | Reason | Review trigger |
|---|---|---|---|
| P01 | One area, 20–30 checked cafés, 30–50 adult pilot participants | Manageable data and support burden | After research/accessibility of recruitment is known |
| P02 | Responsive web with map/list fallback before native apps | Single-product validation with geographic discovery | After web usage and retention evidence |
| P03 (superseded by D12) | Python 3.13 preferred, with Python 3.12 supported; Django 5.2 LTS; default auth plus a future profile | Current local slice uses Python 3.12.14 / Django 5.2.18 and staff auth; product profile/member flows remain proposed | Version review and member increment; local foundation in D08 |
| P04 (superseded by D12) | SQLite only for local skeleton, PostgreSQL for hosted pilot | Durable multi-user operations | Before database and host selection |
| P05 | Content baseline first; optional 0.10 community repeat weight | Cold start without fabricated community evidence | After manual comparisons and real eligible data |
| P06 | Five eligible peers, 90-day window, one vote per peer | Limit dominance and disclosure risk | Privacy review and observed signal reliability |
| P07 | No GPS requirement, payment imports, banking access or LLM dependency | Core matching can be tested without these systems | Only for a separately justified feature |
| P08 | Private histories and separate community opt-in | Purpose control and understandable participation | Before collection; whenever data use changes |
| P09 | Free invited pilot; no selected revenue model | First establish usefulness and willingness to pay | After pilot/revenue interviews |
| P10 | Expanded effort 235–365 hours before contingency | Earlier baseline plus proposed 35–60 hours for map/editorial scope | After manual test, foundation and provider selection |
| P11 | Proposed service reserve ₹2,000–₹5,000 per month | Budget conversation starting point, not quotes | Actual provider selection and spending approval |
| P12 | Leaflet client with licensed tile provider and explicit list fallback | Requested map feature; provider/library responsibilities differ | Before implementation/provider purchase |
| P13 | Separate nullable coffee/experience/trip opinions, outside matching weights | Editorial context without conflating public opinions and private fit | Curator workflow and pilot evaluation |
| P14 | Local collection starts with a dated worldwide brand-count threshold of five locations | Proposed small-group definition; independent ownership needs separate evidence | Owner confirms policy before publishing |
| P15 | Additional map reserve ₹0–₹1,000 per month | Planning allocation only; no selected provider quote | Tile service selection and actual usage |
| P16 | Explicit nullable member coffee/vibe ratings with drink/purpose context; ownership defaults to unknown | Avoid manufactured 5/5 feedback and unverified independent labels; ownership default/evidence fields are now local source, ratings remain future work | Form/schema implementation and pilot feedback evaluation |
| P17 | Map-first mode, original named coffee-cup pins, floating area chips and café-prefilled Log visit | Make implicit map/detail UX requirements concrete | Mobile/accessibility validation before release |
| P18 | Purpose-specific badges and Apple Maps remain later candidates | Badge evidence rules and provider validation need separate scope | After pilot usefulness and implementation effort are reviewed |

Detailed scoring thresholds, retention targets and release criteria remain proposals in their respective files. The owner can change them; update all affected documents together and retain the reason.

## 4. Open Decisions Before Work or Launch

| Question | Needed by | Suggested accountable role | Current answer |
|---|---|---|---|
| Which city/neighbourhood and primary segment? | Research start | Product owner | Open |
| Who owns product decisions and weekly coordination? | Work start | Repository owner | Anuj is Product Owner; root coordinates agent sessions. Human review capacity/calendar remain open |
| Who develops, checks data, and handles support? | Work planning | Product owner | Developer/QA/planning agent work is assigned for the first increment; real catalogue, research and support owners remain open |
| How many hours/week and what cash ceiling? | Scheduling/purchases | Product owner | Open |
| What is the product name and any domain? | Public communication | Product owner | Open |
| Which café sources and image rights are usable? | Data collection | Catalogue lead | Open |
| What feedback shows enough value to build/continue? | Manual test | Product owner/research lead | Proposed metrics need confirmation |
| Which host/database/email providers and regions? | Hosted pilot | Developer/data owner | Open |
| Which tile provider, licence, restricted browser key and spending limit? | Map release | Developer/data owner | Open |
| Who writes original reviews and approves public attribution? | Editorial release | Product owner/catalogue lead | Open |
| Is the five-location worldwide criterion appropriate; how are unknowns handled? | Local collection release | Product owner | Proposed policy needs confirmation |
| Which notices, retention, eligibility and legal requirements apply? | Participant collection/launch | Data owner with suitable review | Open |
| Who is the support/data/security contact? | Pilot recruitment | Operations owner | Open |
| What licence and contributor ownership arrangements apply? | External contribution/public release | Repository owner | Open |
| Which revenue hypothesis will be tested first? | Commercial experiment | Product owner | Open |

Selecting an accountable role is not the same as assigning a named person. Fill the person, date and decision before depending on it. These remaining pilot decisions do not block the authorized local synthetic increment; resolve each before the work that actually depends on it.

## 5. Risks and Experiments

| Risk / assumption | Current mitigation | Evidence to collect |
|---|---|---|
| Too little data for collaborative matching | Content-only baseline and transparent fallback | Number of eligible distinct contributors per café |
| Repeat visits mostly reflect convenience | Combine structured satisfaction and purpose; cap individual influence | Interview reasons and baseline comparisons |
| Café attributes become stale | Provenance, dates, reports and regular checks | Error rate and maintenance hours |
| A generic filter is already sufficient | Compare personalization against a simple list | Actual choices and usefulness responses |
| Users rarely submit visits | Keep discovery useful without logs | Contribution rate and observed form friction |
| Low return use | Choose a recurring segment and inspect failed matches | 14-day return plus qualitative reasons |
| Small cohorts reveal personal patterns | Opt-in, minimum aggregate threshold, private histories and rate limits | Privacy review and adversarial query testing |
| Hosting/cash plan is unrealistic | Durable database and cost review before purchase | Complete quotes and actual monthly usage |
| Map tiles fail, exceed quotas or disclose unexpected location data | Deliberate map loading, provider review, area-based center and list fallback | Tile-failure tests, request inspection and actual cost |
| Editorial scores look like objective or community evidence | Clear opinion attribution, dates and separate match ordering | Usability checks and publication review |
| Split ratings create more form effort without better decisions | Optional unanswered values remain null; keep current scoring unchanged | Completion/friction and usefulness against simple feedback |
| Scope expands into restaurant software | Maintain café-first pilot acceptance criteria | Every proposed addition has a distinct user need |

## 6. Decision Record Template

```markdown
ID and date:
Status: proposed / confirmed / superseded / implemented
Decision and owner:
Problem / evidence:
Alternatives considered:
Consequences and affected files:
Validation / implementation evidence:
Review trigger:
```

When superseding a material choice, preserve its reason and link to the replacement. Avoid leaving incompatible instructions in different files.

## 7. Documentation History

- 2026-10-08: published the complete source and handover evidence in draft PR #1; all five GitHub checks passed at remote `3ccb330`. Prepared a tool-neutral development handoff, starter prompt and thin Claude/Gemini pointers to the shared agreement. Browser/mobile/keyboard acceptance remains open. This transfers project context through Git, not live chats, sessions or credentials.

- Initial repository: private café concept README uploaded; no application code.
- 2026-10-06: expanded into a ten-file planning and startup guide, with explicit proposed scope, setup, design, data operations, roadmap, budget and contribution rules. This entry records documentation work, not completion of the product milestones.
- 2026-10-06: added FEATURES_REFERENCE.md and integrated the requested Caffeine Chronicles feature concepts across the now eleven-file guide. Revised requirements, data flows, estimates and release gates; the application remains unimplemented.
- 2026-10-06: reviewed the supplied feature list against F01–F09; clarified map-first UX, original pins, area chips, Log visit, explicit nullable member ratings and separate ownership/count evidence. Documented purpose-specific badges and Apple Maps as later candidates, and distinguished unverified rubric/API assumptions from the proposed Django design. This is a documentation refinement, with no new implemented app features.
- 2026-10-07: continued the owner-authorized multi-agent build. Added phase-wise agile delivery, story backlog, working agreement and the first catalogue source. Replaced bootstrap-only instructions with reproducible setup for the existing application. The first integrated local suite passed 48 tests on Python 3.12.14 / Django 5.2.18; system checks, migration drift/application, seed repeatability and the twelve-permission catalogue role were checked. See the quality review/backlog for remaining lint/browser/remote evidence and final story status. No hosted pilot is implied.


## PHP review clarification — 2026-10-09

D12 remains authoritative: PHP 8.2 with PDO/MySQL for Hostinger. Earlier Django/PostgreSQL configuration and test claims are historical. The active application has no PHP admin or member/matching/map/editorial implementation.

The destructive Lucknow seed was replaced with guarded fictional fixtures because generic “Web research”/“Menu” labels do not substantiate verified ownership, counts, prices or current dates. Existing records and their UUIDs/evidence are preserved for a human audit; seed reruns supply no new verification. This is a correction within the authorized catalogue review, not a real-data collection or deployment decision.

Root/backend/frontend/QA review contracts and actual results are recorded in DEVELOPMENT_HANDOFF.md and QUALITY_REVIEW.md. No deployment, merge, production seed or public publication is implied.
