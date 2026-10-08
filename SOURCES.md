# Sources and Verification Notes

Last updated: 2026-10-07 (Asia/Kolkata). Original planning references were reviewed on 2026-10-06; Django patch/compatibility and agile framework references were checked again during first-increment integration. Unchanged provider/legal references are not claimed to have been freshly rechecked. Version support, terms, pricing and legal commencement can change; recheck relevant references before purchase or launch.

The product concept, architecture trade-offs, weights, thresholds, cohort sizes, effort and INR allocations are **project proposals**, not facts supplied by these references. No market-demand study, customer result or revenue evidence is claimed.

## S1: Django 5.2 Release and Compatibility

[Official Django 5.2 release notes](https://docs.djangoproject.com/en/5.2/releases/5.2/)

Used to check the LTS release and Python/database compatibility.

[Official Django 5.2.18 release notes](https://docs.djangoproject.com/en/5.2/releases/5.2.18/)

[Official Django 5.2 Python compatibility FAQ](https://docs.djangoproject.com/en/5.2/faq/install/)

Checked during integration on 2026-10-07: application requirements pin Django 5.2.18; Python 3.12 and 3.13 are supported targets. The first local run used Python 3.12.14. Recheck compatibility and maintained patches when updating dependencies; a CI matrix is not evidence that both runtimes were executed.

## S2: Django Version Support

[Official Django downloads and support schedule](https://www.djangoproject.com/download/)

Django 5.2 extended support is scheduled through April 2028. The project uses a pinned maintained patch in the 5.2 line and requires periodic version review.

## S3: Django Project Bootstrap

[Official Django 5.2 tutorial, part 1](https://docs.djangoproject.com/en/5.2/intro/tutorial01/)

Background reference for project/app structure and local development. The project now contains its Django source; [GETTING_STARTED.md](GETTING_STARTED.md) runs that existing application. Do not repeat project/app creation commands over it.

## S4: Django Production Checks

[Official deployment checklist](https://docs.djangoproject.com/en/5.2/howto/deployment/checklist/)

Reference for deployment settings, secret handling, HTTPS and production checks. Hosting configuration still needs provider-specific implementation and validation.

## S5: Django Authentication

[Official authentication documentation](https://docs.djangoproject.com/en/5.2/topics/auth/default/)

Reference for standard users, permissions and authentication flows. Application ownership checks and the proposed member journeys require additional code.

## S6: Django Databases

[Official database documentation](https://docs.djangoproject.com/en/5.2/ref/databases/)

Reference for PostgreSQL/SQLite support and database-driver requirements. Select and test the actual PostgreSQL version and connection configuration before hosting.

## S7: Python Environments

[Official Python 3.13 virtual environment documentation](https://docs.python.org/3.13/library/venv.html)

Reference for isolated environments and platform activation. Using the environment's Python directly is an alternative to activation.

## S8: Profile Model and Authentication Extension

[Official Django authentication customization documentation](https://docs.djangoproject.com/en/5.2/topics/auth/customizing/)

Reference for a profile linked to the default user. The proposal avoids a custom user model for the initial skeleton; future authentication changes need careful migration planning.

## S9: Render Free Service Limits

[Official Render free-service documentation](https://render.com/docs/free)

At review, free web services idle after 15 minutes, local files are ephemeral, and free PostgreSQL expires after 30 days. Used to explain why the pilot needs a durable hosting/database plan. Render is a candidate only.

## S10: Render Pricing

[Official Render pricing page](https://render.com/pricing)

Consult at provider selection for current prices, limits, taxes and plan inclusions. No live vendor amounts are quoted in the budget; its INR figures are internal planning allocations.

## S11: OpenStreetMap Licence

[Official OpenStreetMap copyright and licence information](https://www.openstreetmap.org/copyright)

Reference for ODbL and attribution responsibilities. Review applicable database obligations and separate service usage policies before using OSM or combining datasets.

## S12: India Data Protection Commencement

[MeitY official commencement notification, G.S.R. 843(E), November 2025 (PDF)](https://www.meity.gov.in/static/uploads/2025/11/c56ceae6c383460ca69577428d36828b.pdf)

The notification phases provisions on publication, one year later and eighteen months later. Used to avoid describing the full framework as immediately effective. Determine current applicability against the actual launch date with suitable advice.

[Government PIB explanation of the 2025 Rules](https://www.pib.gov.in/PressReleasePage.aspx?PRID=2190014&lang=2&reg=3)

Government context for the rules and implementation. It does not certify this project's compliance or replace the operative legal text.

## S13: Concept Origin

[Original reel supplied by the project owner](https://www.instagram.com/reel/Dd_XEMNxsW5/)

This is the inspiration link, not technical, legal or market evidence. The café adaptation and complete project plan are original planning work. This repository does not include a verbatim transcript of the reel, and it makes no claim of affiliation with its creator.

## S14: Caffeine Chronicles Feature Reference

[Caffeine Chronicles](https://caffeinechronicles.vercel.app/)

Reviewed in the browser on 2026-10-06 because text retrieval did not expose its interface. [FEATURES_REFERENCE.md](FEATURES_REFERENCE.md) records visible observations and our separate implementation requirements. It is feature inspiration, not a content/data licence or evidence that the backend and every control work. No source code, café records, branding or review text are copied into this project.

## S15: Leaflet Map Client

[Official Leaflet API reference](https://leafletjs.com/reference.html)

Reference for client-side maps, markers, controls and interaction. Choose and record a compatible stable version at implementation. Leaflet does not determine the tile service's licence, pricing or privacy.

## S16: Google Maps URLs

[Official Google Maps URL documentation](https://developers.google.com/maps/documentation/urls/get-started)

Reference for external directions links. Construct and validate the café destination; this project does not automatically include a member origin or implement a routing API.

## S17: OpenStreetMap Tile Service Policy

[Official OSM standard tile-service usage policy](https://operations.osmfoundation.org/policies/tiles/)

Reference for the standard tile service's separate attribution/usage requirements. Select a provider appropriate to real traffic and terms; do not infer unlimited tile access from the open map-data licence.

## S18: Django Fields and Constraints

[Official Django 5.2 model field reference](https://docs.djangoproject.com/en/5.2/ref/models/fields/)

[Official Django 5.2 model constraint reference](https://docs.djangoproject.com/en/5.2/ref/models/constraints/)

Reference for nullable storage, optional form values, controlled choices, defaults and database constraints. Cafe count/ownership fields and selected constraints are present in the initial source; proposed Visit/EditorialReview ratings remain future work. Unanswered ratings must remain null, known scores must be 1–5, and unknown ownership must never become verified independence by default.

## S19: Scrum Framework

[Official Scrum Guide](https://scrumguides.org/scrum-guide.html)

Reference for Product Goal, Product Backlog, Sprint Goal, Sprint Backlog, Increment, accountabilities, events and Definition of Done. The project's two-week cadence proposal, brief event timeboxes, agent file ownership and working limits are team choices documented in [AGILE_DELIVERY.md](AGILE_DELIVERY.md), not additional Scrum requirements. Writing these documents does not establish that a Sprint event occurred or that unfinished work meets the Definition of Done.

## Updating References

Record the date, URL, relevant fact and affected decision when a source changes. Replace broken links with the current authoritative source and revise any dependent instructions. Do not leave a new source beside an outdated factual claim without resolving the discrepancy.
