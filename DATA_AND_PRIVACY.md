# Data, Privacy and Catalogue Operations

Last updated: 2026-10-06. Status: proposed operating policy and implementation requirements. No user data or café dataset has been collected for this repository.

## 1. Data Principles

Use data that is necessary to explain useful café matches. Keep personal taste profiles, saves and visits private by default. Optional contribution to aggregate community matching must be a separate, understandable choice that can be withdrawn. Core discovery works without this choice and without location permission.

Do not collect banking credentials, card details, UPI PINs, government IDs or background location. Do not claim self-reported visits are transaction-verified. Keep interview notes, participant contact lists, credentials and backups outside Git, including a private repository.

The controls, thresholds and retention periods here are **project proposals**, not statements of statutory deadlines. The owner must approve them, ensure they can be implemented, and publish a notice that accurately reflects the deployed system.

## 2. Building the First Café Catalogue

Start with first-party observations, public factual information checked against a café's own material, and information supplied with permission by café staff. Record a source and checking date for each important attribute. User corrections create a review task; they do not automatically overwrite records.

| Field group | Examples | Verification method |
|---|---|---|
| Identity and location | Name, address, area, coordinates, active/closed status | Café's own contact information and direct checking |
| Drinks | Espresso, pour-over, cold brew, tea, matcha, brewing methods | Current menu or staff confirmation |
| Indicative prices | Selected drink price, currency, observation date | Dated menu check; explain possible taxes or changes |
| Amenities | Wi-Fi, charging, outdoor seating, laptop policy | Ask staff or observe; store yes/no/unknown |
| Atmosphere | Noise, crowding, seating suitability | Dated observation with time/context; subjective, not a permanent fact |
| Hours | Listed weekday/weekend hours and source | Staff/current café listing; label informational until live status is implemented |
| Provenance | Source type, source URL where appropriate, permission/licence notes | Editor records during collection |

Do not copy complete third-party review collections, menu photographs, personal reviewer profiles or other protected content without an appropriate right. A public page is not blanket permission to reuse its images or text. Use original descriptions, permitted assets, or no photographs initially. Names and factual attributes still need accuracy and a source.

If OpenStreetMap is used, review its ODbL licence, attribution and any applicable database-sharing obligations. Its data licence is separate from tile/geocoding service usage policies. Do not assume an attribution line alone resolves every dataset or API obligation. [Official licence reference](SOURCES.md#s11-openstreetmap-licence).

### Catalogue workflow

Collect → check source/permission → editor review → publish with date → review corrections → recheck or archive. Maintain stable IDs and a short change audit. Give café staff a correction channel; listing a café does not imply a partnership or endorsement.

Before pilot launch, recheck all included cafés. During the pilot, review reports and high-impact facts weekly. Mark important observations older than 30 days as stale and prioritize their review; this 30-day policy is a proposed operating target. Stale price or amenity information must not satisfy an essential constraint. Preserve an unknown value instead of guessing.

## 3. Personal Data Inventory

| Data | Purpose | Visibility |
|---|---|---|
| Username, email where supplied, password hash | Authentication, recovery and service contact | User and narrowly authorized support; never raw passwords |
| Taste and purpose preferences | Personalized matching | User and matching service |
| Saved cafés | Private shortlist | Owner only |
| Visit date, café, optional drink/spending band and feedback | Personal history and preference learning | Owner only by default |
| Community contribution choice | Control eligible aggregate signals | User and restricted operations |
| Optional temporary coordinates | Nearby results for that request/session | Used transiently; excluded from persistent analytics and routine logs |
| Minimal event metadata | Pilot journey and usefulness measurement | Restricted analysis; pseudonymous where possible |
| Correction/support submissions | Resolve errors or requests | Restricted staff queue |

Prefer a selected area to exact coordinates. If optional browser location is used, avoid writing it to database records, URLs, logs or analytics. Validate what hosting and monitoring services receive; disabling an app field alone does not prove infrastructure collects nothing.

Guest preferences can expire with a short session; propose a maximum 24-hour server-side lifetime and a process to clear expired sessions. State the actual behaviour when implemented.

## 4. Community Matching Controls

- Default contribution off. Explain which structured visit/profile attributes are used, the 90-day matching window, and that other users see aggregate evidence rather than personal histories.
- Only opted-in eligible visits contribute. Require at least five distinct comparable contributors for a café-specific signal; exclude the requesting user and cap each contributor to one vote.
- No names, exact visit dates, contact details or free-text feedback in public explanations.
- Withdrawal and deleted/edited records must invalidate affected scores, caches and explanations.
- Apply rate limits and avoid exposing detailed similarity cohorts that could identify someone through repeated queries.
- Treat small-cohort aggregates as potentially sensitive. The threshold is a safeguard, not a guarantee of anonymity.

The precise scoring rules are in [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md). At the start, most results should use the content baseline because the community evidence does not yet exist.

## 5. Proposed Retention and Deletion

| Data category | Proposed retention | Deletion action |
|---|---|---|
| Member profile, saves and private visits | While account is active, unless user deletes earlier; review inactivity after 12 months | Remove on user deletion; implement an approved inactive-account notice/deletion process |
| Community matching input | Eligible opted-in records from preceding 90 days | Stop use immediately on withdrawal; purge/recompute derived data |
| Pilot event records | Up to 90 days | Delete detailed records; retain only reviewed, non-identifying summaries if justified |
| Security/operational logs | Normally up to 30 days, with documented incident exceptions | Rotate/delete; redact sensitive payloads from collection |
| Raw research recordings/notes | Up to 90 days after analysis, unless a different agreed need exists | Delete raw identifiable material; keep consented/de-identified findings |
| Correction contact details | Up to 30 days after resolution | Remove contact details while keeping safe catalogue change history |
| Database backups | Rolling maximum 30 days, subject to selected provider capability | Expire on schedule; reapply deletion records after any restore |

Aim to complete ordinary account deletion from active systems within seven days of a validated request, with community contribution stopped immediately. This is an internal proposed service target, not a legal deadline. Before publishing it, confirm the team and provider can meet it. Document any necessary, limited exception and the actual backup expiry behaviour.

Export only the requesting person's profile, saves, visits and choices, in a readable machine format. Do not include other people's records. Protect downloads, expire generated exports, and avoid sending an unprotected file to a different address. Require appropriate identity checks without collecting unnecessary documents.

## 6. Staff Access and Incident Handling

Use named staff accounts and least privilege. Catalogue editors should work only with catalogue/correction data. Restrict production database access and record unusual support operations. Keep secrets in deployment configuration, encrypt transport, protect backups, and test authorization and deletion before inviting users.

Before a pilot, assign a support/data contact and write a short incident procedure: contain the problem, preserve necessary evidence, assess affected data, fix the cause, and determine applicable notifications with qualified advice. Configure monitoring to omit passwords, tokens, exact coordinates and private free text.

The repository remains private. That controls repository access; it does not substitute for application authorization, a privacy notice or provider review.

## 7. Launch Notice and Eligibility

The proposed first cohort is 18+. Decide how eligibility is communicated and handled before recruitment; do not assume an age checkbox is sufficient for every legal context. The pilot notice needs the operator's identity/contact, purposes, data categories, providers, retention, contribution choices, location behaviour, export/deletion route and complaint contact. Explain any research use separately.

If launching in India, recheck the Digital Personal Data Protection Act and Rules and all applicable obligations at the actual launch date. The November 2025 commencement notification phases provisions at publication, one year and eighteen months; it does **not** make every operational provision immediately effective. This document is not a compliance certification. Obtain suitable review of the actual service and launch location. [Official notification and government explanation](SOURCES.md#s12-india-data-protection-commencement).

## 8. Before Collecting Participant Data

Assign the responsible person, approve the data inventory and retention choices, select providers, publish accurate notices, implement consent and withdrawal, verify export/deletion/backup behaviour, review catalogue rights, and test restricted staff access. Record completion and unresolved gaps in [DECISIONS.md](DECISIONS.md).
