# Product Requirements

Last updated: 2026-10-06. Status: proposed MVP specification; no features are implemented.

## 1. Product Goal

Help an adult café visitor choose a café suited to their drinks, budget, atmosphere, location, and current purpose. A successful first version provides useful recommendations even with few users and makes the basis of each recommendation understandable.

## 2. Scope and Roles

| Role | Allowed activity |
|---|---|
| Guest | Browse the catalogue and try session-based preference filters |
| Member | Maintain preferences, save cafés, record private visits and feedback, manage data choices |
| Catalogue editor | Maintain café records and review corrections; no routine access to private user histories |
| Administrator | Manage authorized staff access and operational support with audit records |

The initial pilot is proposed for adults aged 18 and over. Eligibility handling and notices must be decided before recruitment. Café owner self-service and social connections are later work.

## 3. Main User Journeys

### A. Discover a café

Choose an area or optionally grant location permission, select today's purpose, choose drinks and a spending range, then view a ranked list. Each result shows relevant attributes, indicative prices, the last verification date, and reasons for the match. A member can save a result.

For the first pilot, the budget refers to one selected drink per person, not a full meal or total bill. Label whether the checked price includes taxes/add-ons; unknown extras cannot be guaranteed within a ceiling.

### B. Create a taste profile

Select drink types and atmosphere preferences. Optionally add up to three favourite cafés; skipping this must work. Separate essential requirements from preferences. Allow changes without losing previously saved cafés or visits.

### C. Record a visit

Select a café, enter the visit date and optionally the drink and spending band, then answer short questions about taste, atmosphere, purpose fit, and willingness to return. Clearly label the entry as self-reported. Editing or deleting an entry must update derived signals.

### D. Maintain the catalogue

An authorized editor adds or updates a café, records the source and checking date, and reviews user corrections. Facts, subjective observations, and unverified details must remain distinguishable.

## 4. MVP Feature Requirements

| ID | Feature | Minimum acceptance criteria |
|---|---|---|
| P1 | Catalogue browsing | Search by café name/area; show active records, indicative prices and verification date; closed or archived cafés do not appear as normal recommendations |
| P2 | Preferences and purpose | Store chosen drinks, budget, atmosphere and purpose; onboarding works without favourites or a friend network |
| P3 | Matching | Apply essential filters, rank eligible cafés, explain known matches; a user with no history still gets content-based results |
| P4 | Saved cafés | Members can save and unsave their own cafés; duplicate bookmarks are prevented |
| P5 | Visits and feedback | Members create, edit and delete their own logs; other members cannot read them by changing a URL or record ID |
| P6 | Data choices | Private histories by default; optional community contribution is separate; users can export and request/delete their account data |
| P7 | Catalogue operations | Editors record provenance and checking dates; corrections are queued and resolved without exposing a reporter's private profile |
| P8 | Pilot measurement | Record minimal events with defined purposes; exclude secrets, exact location and free-text feedback from routine analytics payloads |

## 5. Essential Constraints and Unknown Information

An essential requirement, such as confirmed charging availability or a maximum budget, must not be silently relaxed. Unknown information is displayed as unknown. If too few cafés qualify, explain the reason and let the user choose a broader area, different budget, or fewer constraints.

Listed opening hours are informational and timestamped. Live “open now” claims need correct local time, overnight hours and exceptions; defer that filter until those cases are implemented and tested. Do not infer dietary suitability, allergen safety or accessibility from incomplete café data.

## 6. Screens to Design

| Screen | Main purpose |
|---|---|
| Discover | Area, purpose, preferences and ranked results |
| Preference onboarding/edit | Short, skippable profile setup |
| Café detail | Drinks, price estimates, amenities, verification date and explanation |
| Saved cafés | A member's private shortlist |
| Visit feedback | A brief visit log and return feedback |
| Account/data settings | Privacy choices, export, deletion and support |
| Editor dashboard | Catalogue maintenance and correction review |

Prefer a usable mobile layout with readable text, labelled controls, keyboard access and adequate colour contrast. Core forms must work without optional browser location access.

## 7. Recommendations and Trust

“Why this café?” explanations must use actual features or eligible evidence. Never invent friend visits, peer counts, ratings, verification, or percentage match claims. Self-reported visits are not payment-verified visits.

For community recommendations, use only opted-in records, limit each contributor's influence, and apply the aggregation threshold in [DATA_AND_PRIVACY.md](DATA_AND_PRIVACY.md). Until sufficient evidence exists, explain the user's own preference matches instead.

## 8. Excluded from the First Pilot

Native iOS/Android apps, bank or UPI account access, automatic receipt ingestion, background location tracking, social feeds, in-app booking payments, paid memberships, owner dashboards, nationwide coverage, and large-model recommendation systems are deferred. This protects a manageable first scope; each addition needs its own hypothesis, requirements and decision record.

## 9. Measurement and Pilot Exit

Track onboarding completion, recommendation usefulness, saves, voluntary visit feedback, returning participants, reported data errors, and time spent maintaining the catalogue. Define denominators and windows before collecting results; see [ROADMAP_AND_BUDGET.md](ROADMAP_AND_BUDGET.md).

Do not call the MVP ready until the principal journeys work on mobile, authorization and deletion tests pass, café information is sufficiently checked, backups can be restored, and participants receive a clear data notice. These are proposed release criteria, not a claim of legal certification.

## 10. Related Documents

[TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md) specifies the data and matching approach. [GETTING_STARTED.md](GETTING_STARTED.md) gives the starting steps. Changes to scope belong in [DECISIONS.md](DECISIONS.md).
