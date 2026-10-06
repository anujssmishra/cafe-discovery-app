# Caffeine Chronicles Feature Adaptation

Reviewed: 2026-10-06. Reference: [Caffeine Chronicles](https://caffeinechronicles.vercel.app/). Status: features added to this project's plan; no application code has been implemented.

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
| F01 | Interactive café map | Pan/zoom and labelled café markers; selected result opens details; the same eligible café IDs appear in the accompanying list; usable fallback when tiles or JavaScript fail | First pilot |
| F02 | Area/city shortcuts | Configured pilot-area buttons move the map and update list scope while preserving preferences; only areas with catalogue data appear; additional cities need verified data | Pilot areas; more cities later |
| F03 | Name search | Case-insensitive partial-name search updates the map and list consistently; clearing restores eligible results; a zero-result state explains active filters | First pilot |
| F04 | Café detail dialog | Name, checked address, offerings, amenities, dates, editorial notes, save and directions actions; keyboard/Escape/close and focus return work; a full detail page is available | First pilot |
| F05 | Separate coffee and experience scores | Optional 1–5 curator scores for coffee and overall experience, with original notes, attribution and visit date; unknown values have no numeric placeholder | First pilot |
| F06 | Trip-value assessment | Optional 1–5 curator opinion about effort worth making to visit, with a visible scale; displayed separately from personalized match order | First pilot |
| F07 | External directions | A deliberate link opens a maps provider for the checked café destination; no user origin coordinates are embedded automatically; unavailable coordinates use a checked address or omit the link | First pilot |
| F08 | Local/small-group collection | A clearly described collection/filter uses sourced brand-location counts and checking dates; unknown eligibility does not receive a verified local badge | First pilot after policy confirmation |
| F09 | Collection story and curator context | An about section explains how entries and opinions are selected, whose opinion is shown, dates, limitations and how corrections are handled | First pilot |

F03 extends existing catalogue search. F04 expands existing café details. All nine features complement personalized taste/purpose matching and private visit logs; they do not replace them with a single public rating.

## 3. Ratings and Editorial Meaning

Keep four concepts separate:

- **Verified facts:** address, offerings, indicative prices, amenities and their checking dates.
- **Curator opinions:** coffee/experience scores, trip value and original visit notes, attributed to an approved public display name.
- **Private member feedback:** that person's own visit assessment, editable/deletable by its owner.
- **Personalized ranking:** the content baseline and any eligible aggregate community signal described in [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md).

Do not present a curator score as a community average, objective quality guarantee or percentage match. Do not add editorial scores to the matching weights without an explicit evaluation and decision. One coffee score cannot capture whether a café suits every drink preference or visit purpose.

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

## 4. Implementation Dependencies

Use the existing Django catalogue and café IDs for map/list/detail data. Leaflet is the proposed map client; choose a licensed tile service and review its usage, attribution, key restrictions, cost and privacy before launch. A map library does not supply a free unlimited basemap service. See [SOURCES.md](SOURCES.md).

Add an area configuration, brand/group provenance fields, an editorial review model, and safe public serialization. Do not expose visits, member IDs, exact member coordinates, private notes or draft editor content through the map data endpoint. Escape review text when rendering dialogs.

The list remains useful without map access. Directions go to an external provider only after a click. Notices need to describe third-party map requests and destinations; precise-location handling needs a separate review before a map centers on the user's coordinates.

## 5. Delivery and Validation

Build catalogue/list search first, then map synchronization and area controls, then details/directions, then original editorial content and the local collection. Check combined filters, empty search, archived cafés, missing coordinates, stale facts, tile failure, keyboard navigation, mobile layout and HTML injection handling. Confirm the directions destination against the checked café address.

These additions increase the effort estimate by a proposed 35–60 hours, plus ongoing original-content work; see [ROADMAP_AND_BUDGET.md](ROADMAP_AND_BUDGET.md). Multi-city coverage remains a later expansion gate, rather than an assumption that the reference's US catalogue is available to this project.

## 6. Related Requirements

Implementation is tracked through P1 and P9–P14 in [PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md). Models and endpoints are in [TECHNICAL_DESIGN.md](TECHNICAL_DESIGN.md); editorial rights and map-provider data flows are in [DATA_AND_PRIVACY.md](DATA_AND_PRIVACY.md). Record final policy/provider choices in [DECISIONS.md](DECISIONS.md).
