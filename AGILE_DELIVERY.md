# Agile Delivery Plan

Last updated: 2026-10-11. Status: Sprint 2 (PHP/MySQL Catalogue) is deployed and verified live on Hostinger (`myfanverse.in`). Active Sprint 3 implements friend-informed discovery (Vibes, Food highlights, Price bands, and Friends' private reviews). [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md) records work/status; [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) documents system architecture.

## 1. Product Goal

Enable an adult visitor in one pilot area to find a café suited to their drink, budget, food needs, and desired ambiance, understand why it fits, and read trusted reviews from their own circle of friends rather than noisy public star ratings. Validate usefulness with a checked Lucknow pilot catalogue (19 verified cafés) before expanding coverage.

The pilot targets 19–30 verified Lucknow cafés and an invited cohort of friends/coffee enthusiasts. Synthetic development data has been superseded by real, verified Lucknow pilot records.

## 2. One Team, Multiple Developer Agents

Anuj is the Product Owner. The root assistant integrates the work and facilitates the process. Specialist agents contribute within the same product team; these labels describe working responsibilities, not hired employees or independently accountable human Scrum roles. Human product, spending, data and release decisions remain with the designated owner.

| Responsibility | Lead | Work and handoff |
|---|---|---|
| Product ownership | Anuj | Product Goal, backlog ordering, pilot area/segment, feedback and scope decisions |
| Integration and facilitation | Root agent | Sprint Goal, task boundaries, shared contracts, configuration, integration review, validation record and handover |
| Backend and data development | Backend agent | Models, migrations, catalogue queries, seed/import behaviour and data constraints; hands off model/query contracts |
| Discovery experience | Frontend agent | Views, templates, forms, accessible user journeys and live UI interactions; hands off routes, query parameters and templates |
| Quality and verification | QA agent | Independent acceptance checks, failure cases, meaningful automated tests and defects; hands off reproducible results |
| Delivery planning | Planning agent | Delivery plan, ordered backlog, requirement traceability and working agreements; reconciles status with evidence |
| Research, catalogue and operations | Anuj or a named human delegate | User feedback collection, café checks, original editorial observations, participant contact, and Hostinger pilot support |

One agent may cover more than one specialty when needed. Agent parallelism helps independent work proceed together, but integration, human decisions, field research and review remain dependencies.

## 3. Cadence and Forecast

Propose two-week Sprints. Active agent sessions can produce several increments within a Sprint.

| Phase | Proposed Sprint | Sprint Goal and usable increment | Acceptance gate | Dependencies |
|---|---|---|---|---|
| 1. PHP/MySQL Catalogue | Sprint 2 (Done) | Build lightweight PHP/MySQL catalogue, seed 19 Lucknow cafés, and deploy to Hostinger | Site live at `myfanverse.in`, debounced live search, clickable directions, 404s, mobile CSS | Hostinger web hosting, MySQL DB |
| 2. Friend-Informed Discovery | Sprint 3 (Active) | Deliver user-requested factors: Ambiance/Vibes, Food Highlights, Price Bands, and "Friends' Take" private circle reviews | Vibe filtering, food badges on cards & detail, price indicators, `friend_review` table & UI | Sprint 2 live catalogue; Lucknow field data |
| 3. Geographic Discovery | Sprint 4 | Interactive map-first toggle with Leaflet.js pins using verified GPS coordinates | Map/list consistency, mobile layout, tile fallback | Sprint 2 coordinates (already in DB) |
| 4. Personal Records & Saves | Sprint 5 | Private member bookmarks, private visit logging, data export/deletion | Authentication, privacy by design, zero public exposure | Account decisions, email provider |
| 5. Learn and Iterate | Post-Pilot | Evaluate real friend usage, return visits, and expand to additional neighbourhoods | Usage metrics, feedback interviews, next hypothesis | Active pilot cohort |

## 4. Current Sprint Plan: Sprint 3 (Friend-Informed Discovery & Private Circles)

**Sprint 3 Goal:** Deliver the user-requested café evaluation factors identified in primary user research: Ambiance & Aesthetics ("Vibes"), Food Variety & Quality highlights, Indicative Price Bands, and "Friends' Take" trusted private reviews (zero public aggregator spam).

Primary user feedback collected by Anuj from his cohort identified seven decisive criteria before visiting a café:
1. **Food Quality:** Freshness, artisan standards (in-house baking, specialty ingredients).
2. **Food Variety:** Type of food offered (bakery, brunch, sourdough sandwiches, desserts, vegan).
3. **Ambiance:** Work-friendly vs social vs quiet retreat.
4. **Aesthetics:** Visual appeal, cozy interior, Instagrammable/aesthetic corners.
5. **Price (sometimes):** Indicative spend tier per person.
6. **Location:** Clickable directions & neighbourhood clarity (already delivered in Sprint 2).
7. **Reviews by friends, not public:** Trusted recommendations from friends, explicitly rejecting public/commercial review spam.

| Work package | Lead | Focus | Integration dependency |
|---|---|---|---|
| W1: Vibe & Aesthetics Taxonomy (CAFE-106) | Backend + Frontend | Vibe tags schema, filtering by atmosphere, card badge rendering | Schema migration |
| W2: Food Quality & Variety Badges (CAFE-107, 108) | Backend + Frontend | Food highlight badges, menu category previews, price band indicator | W1 schema contract |
| W3: "Friends' Take" Review Architecture (CAFE-109) | Backend + Frontend | `friend_review` table, private circle notes, must-try items, detail page section | W1/W2 interfaces |
| W4: Lucknow Pilot Dataset Enrichment (CAFE-110) | Anuj (Curator) | Enrich 19 Lucknow cafés with verified vibe tags, food highlights, and friend notes | W1–W3 models |
| W5: Hostinger DB Migration & Verification (CAFE-111) | Operations / QA | `migration_sprint3_vibes_and_friends.sql` script, phpMyAdmin execution guide | Hostinger MariaDB |

## 5. Events and Feedback

The framework reference is the [official Scrum Guide](https://scrumguides.org/scrum-guide.html), reviewed 2026-10-06. The guide's Product Goal, Sprint Goal and Definition of Done inform this workflow.

| Event | Proposed practice for this project | Recorded result |
|---|---|---|
| Sprint Planning | 45–60 minutes with Anuj and the active developers; choose a valuable goal, capacity, selected stories and delivery approach | Sprint Goal, selected stories, owners, dependencies and unresolved questions |
| Daily Scrum | Up to 15 minutes on active working days; inspect progress toward the goal and adapt the day's plan | Next actions and blockers, not a report of agent busyness |
| Backlog refinement | Short sessions during the Sprint; clarify the next work before selection | Smaller stories, observable acceptance criteria and updated dependencies |
| Sprint Review | 30–45 minutes with Anuj and relevant participants; try the usable increment and inspect outcomes | Feedback, changed assumptions and reordered backlog |
| Sprint Retrospective | 20–30 minutes after review; inspect collaboration, defects, test gaps and integration friction | One concrete improvement, with an owner, for the next Sprint |

## 6. Board and Work in Progress

Use one workflow: **Backlog → Ready → In progress → Review → Verify → Done**. Mark an impeded item **Blocked**, recording its previous state, cause, owner and next action; blocked work still counts against its work-in-progress limit. Return it to its prior active state after resolution.

The Markdown backlog in `PRODUCT_BACKLOG.md` is the authoritative source of truth.

Working limits are one active work package per specialist, at most five active packages across this initial team, and at most two packages awaiting integration review.

## 7. Ready and Done

**Definition of Done for an implementation increment:**

1. Its acceptance criteria are met by integrated behaviour, and a second reviewer has inspected the change.
2. Relevant integrated automated and manual checks pass; failed/unrun checks are explicit. PHP syntax (`php -l`) and templates render cleanly.
3. A contributor can reproduce the documented setup and principal changed journey. Applicable mobile, keyboard, empty-state and failure behaviour has been checked.
4. Permission, input-validation and data-handling cases affected by the change are addressed. No committed credentials or misrepresented synthetic records exist.
5. Model changes include migrations; shared contracts and operational notes are updated. The implementation does not silently break existing requirements.
6. README/setup/backlog describe actual behaviour. Evidence identifies the reviewed revision or files, commands/results, reviewer and limitations.

## 8. Risks and Next Decisions

| Risk | Response and next evidence | Accountable lead |
|---|---|---|
| Ambiance tags become inconsistent | Enforce a controlled vocabulary (6 distinct vibes) with database-level checks or enum values | Backend / Anuj |
| Food highlights become stale | Keep food tags to broad specialties (e.g. In-house Bakery, Sourdough) rather than whole volatile menus | Curator / Backend |
| Public review spam or pay-to-win | Hard architectural boundary: Only curated/verified friends' reviews allowed in "Friends' Take"; no anonymous public submissions | Root / Architecture |
| Hostinger shared database drift | Always supply idempotent SQL migration files with explicit column-existence guards | Operations / Backend |

## 9. Related Documents

- [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md): epics, story criteria, ownership and status.
- [AGENTS.md](AGENTS.md): operating rules for concurrent implementation.
- [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md): architecture, tech stack, and deployment guide.
- [DECISIONS.md](DECISIONS.md): confirmed choices, open decisions and changes.
- [DATA_AND_PRIVACY.md](DATA_AND_PRIVACY.md): user privacy principles and data handling.
