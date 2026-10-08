# Caffeine Chronicles Feature Adaptation

Reference reviewed: 2026-10-06. Document updated: 2026-10-07. Reference: [Caffeine Chronicles](https://caffeinechronicles.vercel.app/). Status: full adaptation plan with the first local catalogue slice under integration review. This update does not claim a new review of the reference website.

Current source provides ordinary list name/area search, list-area chips, full café details, a project about page, and branch-count/ownership data fields. These are foundations for F02–F04/F08/F09. No interactive map, detail overlay, member actions, directions or editorial scores have been built. See [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md) and [QUALITY_REVIEW.md](QUALITY_REVIEW.md) for actual acceptance evidence.

## 1. What Was Observed

| Reference interface | Observation |
|---|---|
| Map | Café markers, zoom controls, Leaflet/Carto attribution |
| City controls | San Francisco, New York and Seattle shortcut buttons |
| Search | Entering part of a café name reduced the displayed markers |
| Detail dialog | Name, address, two commented ratings, a trip-value badge and directions link |
| Editorial note | A personal collection focused on small/local cafés, excluding chains |

Search filtering and opening a marker's detail dialog were checked. City buttons were visible; successful recentering was not established. Basemap tiles displayed a missing-key message during review. Accounts, bookings, owner tools and social features were not established by this review.

The specifications below are **our implementation choices**, including improvements such as accessible list navigation, public detail URLs and explicit provenance. They do not claim the reference implements those improvements. No café records, review text, code, branding or imagery are imported from it.

## 2. Features to Add

| ID | Planned café app feature | Acceptance criteria for our project | Release |
|---|---|---|---|
| F01 | Interactive café map | Large map-first browsing mode after deliberate activation, with an obvious map/list toggle; original coffee-cup pins have accessible café-name labels; pan/zoom and filter changes retain the same eligible café IDs as the list; usable fallback when tiles or JavaScript fail | First pilot |
| F02 | Area/city shortcuts | Floating, labelled area chips move the map and update list scope while preserving preferences; keyboard access and selected state are clear; only areas with catalogue data appear; additional cities need verified data | Pilot areas; more cities later |
| F03 | Name search | Case-insensitive partial-name search updates the map and list consistently; clearing restores eligible results; a zero-result state explains active filters | First pilot |
| F04 | Café detail dialog | Name, checked address, offerings, amenities, dates, editorial notes, save, directions and Log visit actions; Log visit opens a café-prefilled form without creating a record until submission; keyboard/Escape/close and focus return work; a full detail page is available | First pilot |
| F05 | Separate coffee and experience scores | Optional 1–5 curator scores for coffee and overall experience, with original notes, attribution and visit date; unknown values have no numeric placeholder | First pilot |
| F06 | Trip-value assessment | Optional 1–5 curator opinion about effort worth making to visit, with a visible scale; displayed separately from personalized match order | First pilot |
| F07 | External directions | A deliberate link opens a maps provider for the checked café destination; no user origin coordinates are embedded automatically; unavailable coordinates use a checked address or omit the link | First pilot |
| F08 | Local/small-group collection | A clearly described collection/filter uses sourced brand-location counts and checking dates; unknown eligibility does not receive a verified local badge | First pilot after policy confirmation |
| F09 | Collection story and curator context | An about section explains how entries and opinions are selected, whose opinion is shown, dates, limitations and how corrections are handled | First pilot |

F03 extends the first catalogue search with map consistency; F04 expands the current full details into an accessible dialog with the remaining pilot content/actions. All nine features complement planned personalized taste/purpose matching and private visit logs.

## 3. Ratings and Editorial Meaning

Keep four concepts separate:

- **Verified facts:** address, offerings, indicative prices, amenities and their checking dates.
- **Curator opinions:** coffee/experience scores, trip value and original visit notes, attributed to an approved public display name.
- **Private member feedback:** that person's own visit assessment, editable/deletable by its owner.
- **Personalized ranking:** the content baseline and any eligible aggregate community signal described in [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md).

Do not present a curator score as a community average, objective quality guarantee or percentage match. Do not add editorial scores to the matching weights without an explicit evaluation and decision. One coffee score cannot capture whether a café suits every drink preference or visit purpose.

### Member coffee and vibe feedback

Add optional `Visit.coffee_rating` and `Visit.vibe_rating`, each an integer from 1 to 5 or unknown/null, with **no preselected rating and no default of 5**. Ask about the drink actually tried and the experience of that visit, with optional drink/brewing context and visit purpose. A visitor can rate either dimension, both or neither. An overall vibe rating alone does not prove Wi-Fi, charging, a laptop policy or suitability for work.

These fields describe private member feedback. The separate public curator scores remain on `EditorialReview`. Do not average these two sources together, publish private reviews, or silently change the T/P/B/R matching formula. Splitting dimensions is a useful hypothesis to test for clearer feedback and better fit; it is not evidence of improved accuracy by itself. A formal bean-origin/roast/extraction scoring rubric was not established by the reference review; a specialist rubric would be a separately defined editorial choice.

### Proposed trip-value scale

| Score | Original project label |
|---|---|
| 1 | Would choose another option |
| 2 | Consider if already passing |
| 3 | Worth a nearby visit |
| 4 | Worth a planned detour |
| 5 | Worth a special trip |

These are proposed labels for this app, not transcribed labels from the reference. The badge must not override an essential travel radius, budget or amenity requirement.

### Proposed local-collection policy

Start with a small-group criterion of **five or fewer verified locations under the brand**, counted worldwide at the checking date. Store the count, scope, source and date; do not infer independent ownership from a low count. The owner must confirm this definition or revise it before publishing the filter. A collection of cafés actually visited by a curator additionally requires a real visit date; unchecked catalogue entries must not be described as first-person experiences.

Store ownership status separately as unknown, verified independent or verified not independent, with evidence and a checking date. Defaulting `isIndependent` to true would falsely classify unchecked cafés. A future filter called "Independent cafés, up to five locations" must require both verified independent ownership and a known count within the threshold. Until then, label the count-based collection as small-group/local and explain its criterion.

### Later candidate: purpose-specific editorial badges

The initial trip-value labels already explain the effort a curator thinks worthwhile. Additional labels such as "Destination coffee pick", "Work-friendly pick" or "Neighbourhood favourite" could make the reason more specific. Treat these as later candidates, outside the pilot estimate, until their definitions and editorial effort are agreed.

For example, a coffee badge needs an attributed, dated assessment identifying the drink; a work badge needs recent evidence of the stated work amenities and laptop policy, alongside an observation with time/context. Publish the badge's reason and checking date, withdraw it when evidence expires, and keep essential filters authoritative. Do not turn a badge into an unsupported algorithmic confidence claim.

## 4. Implementation Dependencies

Build future map/dialog data on the current Django catalogue and café UUIDs. Leaflet is the proposed map client; choose a licensed tile service and review its usage, attribution, key restrictions, cost and privacy before launch. A map library does not supply a free unlimited basemap service. See [SOURCES.md](SOURCES.md).

Area records and brand/count/ownership provenance fields are present in the first source increment. Map center/bounds, an editorial review model and safe public map serialization remain to be added. Do not expose visits, member IDs, exact member coordinates, private notes or draft editor content through a future map endpoint. Escape review text when rendering dialogs.

Use the current Django `Cafe` and proposed `EditorialReview` and `Visit` entities, with field definitions in [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md#explicit-fields-and-defaults). Keep future curator notes on `EditorialReview` instead of duplicating a mutable `curatorNote` field on `Cafe`. The repository has no implemented `GET /api/cafes`, Prisma `VisitLog`, `S_drink` or `S_atmosphere` system; those names in the supplied review are conceptual examples.

The list remains useful without map access. Directions go to an external provider only after a click. Notices need to describe third-party map requests and destinations; precise-location handling needs a separate review before a map centers on the user's coordinates.

Google Maps directions were observed in the reference. Apple Maps support was not established; offer it only as a later provider option after checking current official URL rules, supported devices and destination tests. Designing our own provider choice does not imply the reference implements it.

## 5. Delivery and Validation

Build catalogue/list search first, then map synchronization and area controls, then details/directions, then original editorial content and the local collection. Check combined filters, empty search, archived cafés, missing coordinates, stale facts, tile failure, keyboard navigation, mobile layout and HTML injection handling. Confirm the directions destination against the checked café address.

Also check that map-first mode remains usable on a small screen, pins have meaningful names, skipped ratings stay null, out-of-range scores are rejected, unknown ownership/counts remain unbadged, and Log visit never records a visit merely because a dialog was opened. A guest who signs in to log a visit should return to the selected café form.

These additions increase the effort estimate by a proposed 35–60 hours, plus ongoing original-content work; see [ROADMAP_AND_BUDGET.md](ROADMAP_AND_BUDGET.md). Multi-city coverage remains a later expansion gate, rather than an assumption that the reference's US catalogue is available to this project.

## 6. Related Requirements

Implementation is tracked through P1 and P9–P14 in [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md). Models and endpoints are in [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md); editorial rights and map-provider data flows are in [DATA_AND_PRIVACY.md](DATA_AND_PRIVACY.md). Record final policy/provider choices in [DECISIONS.md](DECISIONS.md).

## 7. Follow-up Review: Coverage and Refinements

| Suggested feature group | Already in the guide | Refinement from the follow-up |
|---|---|---|
| Map-first discovery and city chips | F01–F03: map/list, live name filtering and area shortcuts | Explicit map-first mode, original coffee-cup pins and accessible floating chips |
| Independent-only, up to five locations | F08: sourced count policy and unknown handling | Separate ownership evidence from location count; no default independent status |
| Coffee versus vibe | F05 plus private visit feedback | Explicit nullable member rating fields with drink/purpose context; specialist rubric remains unverified |
| Descriptive conviction badges | F06: original trip-value scale | Purpose-specific editorial badges proposed for later evaluation |
| Detail overlays and directions | F04/F07: dialog, full detail page and external directions | Explicit Log visit action; Google observed, Apple a later unverified option |

This follow-up table records the 2026-10-06 planning review. Implementation has since begun with the local catalogue foundations described at the top of this file; the full adaptations and later candidates remain subject to their story acceptance criteria. The current authoritative progress record is [PRODUCT_BACKLOG.md](PRODUCT_BACKLOG.md).
