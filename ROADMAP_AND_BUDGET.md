# Roadmap, Resources and Budget

Last updated: 2026-10-06. All figures and dates below are planning assumptions. No funds have been committed, team hired or milestones completed.

## 1. Planning Basis

Proposed scope: one area, 20–30 checked cafés, mobile web discovery with map/list search and directions, original curator reviews/local collection, content-based matching, private saves/visits, and 30–50 adult pilot participants. Start with a free invited pilot. Community matching is enabled only when sufficient consenting evidence exists; it is not a launch dependency.

A provisional 12–18-week sequence assumes roughly 25 hours per week and accessible café information. The expanded estimate below is 235–365 hours before contingency, or 282–438 hours with 20% contingency. At 10 hours per week, the latter represents roughly 29–44 weeks, plus delays; calculate the calendar target from actual capacity.

The [reference-feature expansion](FEATURES_REFERENCE.md) adds a proposed 35–60 hours to the earlier 200–305-hour baseline. This revision makes map/editorial work visible in the plan instead of assuming it has no scheduling or operating cost.

## 2. Roles and Accountability

| Role | Responsibility | Can initially be combined? |
|---|---|---|
| Product owner | Segment, scope, budget, decisions and outcome review | Yes, with founder |
| Full-stack developer | Models, web experience, matching, tests and deployment | Yes, one capable developer |
| Research/catalogue lead | Interviews, café checks, provenance and corrections | Yes, with founder; reserve field time |
| Designer/usability lead | Mobile flows, accessibility and observed user tests | Can be part-time or combined |
| Operations/data owner | Notices, provider records, support, access and retention | Can be combined, but must be explicitly assigned |
| Specialist reviewers | Security, privacy/legal or particular integration questions | Engage when team experience/context requires |

One person covering several roles still needs time for each responsibility. Contractors require a concrete brief, deliverables, repository access limits and agreement on ownership before work begins.

## 3. Milestones and Exit Gates

| Phase | Provisional window | Deliverable | Gate to proceed |
|---|---|---|---|
| M0: Commit to a test | Start | Chosen area/segment, owner and cash/time ceiling | Open decisions assigned; research plan approved |
| M1: Validate the problem | Weeks 1–2 | 15–20 visitor interviews, 5 manager conversations, summarized evidence | Specific recurring problem and reachable cohort; evidence may justify changing/stopping |
| M2: Check catalogue and manual matching | Weeks 2–3 | 20–30 sourced records, preference form, manual comparison | Enough accurate data; participants can identify useful matches |
| M3: Build foundation | Weeks 3–4 | Django project, models, permissions and catalogue admin | Checked records editable; guest browsing works |
| M4: Build core journeys | Weeks 4–8 | Preferences, explanations, saves, visits, data settings | Product acceptance and ownership/deletion checks pass |
| M4b: Map and editorial experience | Weeks 8–10 | Map/list search, area controls, dialogs, directions, original reviews and collection/about | Same result IDs, safe public content, correct directions and tile-failure fallback |
| M5: Prepare hosted pilot | Weeks 10–11 | PostgreSQL, production configuration, notice, support and restore exercise | Mobile usability, catalogue freshness and operational readiness pass |
| M6: Run and assess pilot | Weeks 12–14 | Invited cohort, measured usage, interviews and error reports | Enough evidence to choose improve, expand or stop |
| M7: Iterate | Weeks 15–18 if justified | Fixes, updated hypothesis and next milestone | Owner reviews outcomes and approves next scope/budget |

Windows overlap and are illustrative. Recruitment, permission checks, limited working hours and technical learning can extend them. Do not enable payments or social sharing merely because a date in this table arrives.

## 4. Effort Estimate

| Work | Proposed hours |
|---|---:|
| Research, decisions and synthesis | 20–35 |
| Café collection and checking | 30–45 |
| User flows and usability design | 15–25 |
| Core implementation | 80–110 |
| Testing, deployment and data operations | 30–50 |
| Pilot support and analysis | 25–40 |
| Map/search/dialog integration | 15–25 |
| Original curator content, ratings and local-collection support | 15–25 |
| Additional map/privacy/accessibility validation | 5–10 |
| **Total before contingency** | **235–365** |

Add approximately 20% planning contingency for rework and uncertainty: about 282–438 hours in total. This is an estimate for the expanded scope, not a contractor quote or promised completion time. Re-estimate after the manual test, foundation work and actual tile-provider selection. Recurring editorial/catalogue maintenance continues after initial delivery.

## 5. Cash Budget

The following INR amounts are **suggested allocations**, not current vendor prices, legal estimates, or authorization to spend. Confirm actual service quotes and taxes before purchasing. Founder labour is separate.

| Category | Planning allocation | Notes |
|---|---:|---|
| Local development | ₹0 incremental with existing laptop/internet | Open-source tools; hardware/connectivity replacement excluded |
| Field research and catalogue checks | ₹0–₹5,000 one time | Travel or optional modest participant incentives; depends on area |
| Web host, persistent database, basic email/monitoring/backups | ₹2,000–₹5,000 per month reserve | Compare complete provider configuration; reserve may be insufficient for particular plans |
| Domain | ₹0 if using provider URL; reserve up to ₹2,000 annually | Optional; verify registration and renewal amounts |
| Map tiles | Reserve ₹0–₹1,000 per month in addition to hosting | ₹0 only if a selected service permits the intended usage within limits; verify prices, attribution, quotas and key restrictions |
| Other paid APIs | ₹0 baseline | No geocoding/routing API needed for manual café coordinates and external directions links |
| Design, development, specialist review | Unpriced until scope and rate agreed | External labour/review can dominate total cost |

An illustrative first three months could allocate ₹5,000 research + ₹15,000 services + ₹3,000 map reserve + ₹2,000 domain = **₹25,000 before labour, taxes and specialist work**. This is a budget scenario, not evidence that a launch will cost that amount. It excludes hardware, events, advertising, app stores, payments and unforeseen work. Editorial fieldwork may require revising the research allocation.

Use this calculation for an actual decision:

```text
Pilot cash = one-time research/domain/setup
           + pilot months × (web + database + storage + email + monitoring + APIs)
           + contracted hours × agreed rate
           + specialist review + taxes + contingency
```

Define a monthly spending cap, account owner and warning thresholds. Verify database durability, backup retention and renewal pricing, not just the initial headline plan. [Provider references](SOURCES.md#s10-render-pricing) are starting points; no provider has been chosen or purchased.

## 6. Initial Implementation Backlog

| Priority | Task | Completion evidence |
|---|---|---|
| First | Create Django foundation and environment instructions | A contributor can reproduce a local skeleton |
| First | Define catalogue schema, tags and provenance | Checked café records can be imported/edited without guessed fields |
| First | Restrict editor permissions | Editor cannot access private member models |
| First | Build mobile catalogue, area filters and details | Guest journey works without GPS |
| Next | Preferences and purpose form | Optional favourites can be skipped |
| Next | Eligibility, scoring and explanations | Cold start and essential constraints pass meaningful checks |
| Next | Authentication and recovery flow | Member can manage their own account; hosted email works |
| Next | Bookmarks and structured visit feedback | Ownership, duplicates, edit/delete and dates handled |
| Next | Contribution choice, export and deletion | End-to-end data flow and derived-signal removal checked |
| Next | Correction queue and freshness flags | Report reaches staff; stale essential data excluded |
| Before pilot | Map/list search, pilot-area shortcuts and detail dialogs | Same eligible IDs, keyboard support and full-page fallback |
| Before pilot | External directions and tile-provider setup | Destination checked; no member origin in URLs; tile failure does not block discovery |
| Before pilot | Original curator reviews, trip scale and local collection/about | Published opinions attributed/dated; unknown scores/counts unbadged; no copied reference content |
| Before pilot | Minimal events, notices and eligibility | Event purposes/denominators agreed and payloads inspected |
| Before pilot | PostgreSQL, deploy and backup restore | Production-equivalent journeys and restore exercise pass |
| Later | Aggregate peer repeat signal | Enough eligible participants and tested withdrawal behaviour |

Turn these into issues when implementation begins. Each issue needs one owner and observable acceptance criteria; the table is not a claim that issues already exist on GitHub.

## 7. What to Measure

Freeze metric definitions and cohort dates before collecting results. Report counts with rates so that small samples are visible.

| Metric | Definition | Proposed interpretation |
|---|---|---|
| Onboarding completion | Completed preference flows / started flows, excluding tests | Identify friction; skippable onboarding should not block browse |
| Recommendation preference | Participants preferring manual personalized suggestions / participants comparing both lists | Exploratory target ≥60% with at least 10 comparisons; directional, not proof |
| Main journey usability | Observed participants completing choose → results → detail/save without assistance / attempts | Proposed target ≥70%; inspect every failure in a small sample |
| Recommendation usefulness | Respondents marking a result useful / respondents answering the prompt | Report response rate; unanswered prompts are not successes |
| Save rate | Eligible unique sessions with a save / eligible result-viewing sessions | Interest signal, not a confirmed visit |
| Voluntary visit feedback | Participants submitting a valid log / participants shown recommendations | Contribution feasibility; self-reported and potentially incomplete |
| 14-day return | Activated participants with another discovery session within 14 days / activated participants with full 14-day observation | Proposed exploratory target 30%, preferably ≥20 eligible participants |
| Catalogue errors/freshness | Confirmed error reports and share of important fields checked in last 30 days | Data-maintenance burden and reliability |
| Map reliability | Failed map-load attempts / deliberate map-load attempts, with list fallback completion | Distinguish provider failure from an empty catalogue; no precise location in event payloads |
| Directions intent | Sessions clicking directions / eligible café-detail sessions | Interest only; not proof of arrival or a completed visit |
| Operating cost | Cash spent and staff hours / reporting period | Determine whether a larger catalogue is sustainable |

For return measurement, define activation as a participant viewing at least one eligible recommendation after selecting preferences/purpose. Exclude staff/test accounts and count each participant once. Minimal guest measurement may require a short-lived pseudonymous session; do not silently introduce persistent cross-site tracking. These targets are project hypotheses, not industry benchmarks or current results.

## 8. Pilot Decision and Longer-Term Work

Expand only if observed value, data accuracy, return use and maintenance effort justify it. If personalization performs no better than basic filters, improve the attributes/segment or simplify the product. If visits are too sparse for peers, keep the content baseline rather than fabricating community evidence.

Later candidates include additional areas, café owner tools, opt-in social features, coffee events, premium discovery and labelled sponsorship. First test a revenue hypothesis through interviews and a small permitted experiment; do not assume a commission model works. Payments, receipts and native apps require new technical and operating scope.

Review this plan weekly during active work. Update actual effort, spending, completed gates, failed assumptions and the next decision in [DECISIONS.md](DECISIONS.md).
