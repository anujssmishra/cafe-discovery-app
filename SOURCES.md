# Sources and Verification Notes

Last reviewed: 2026-10-06 (Asia/Kolkata). These are primary references checked while writing this planning guide. Version support, provider terms, pricing and legal commencement can change; recheck them before implementation, purchase or launch.

The product concept, architecture trade-offs, weights, thresholds, cohort sizes, effort and INR allocations are **project proposals**, not facts supplied by these references. No market-demand study, customer result or revenue evidence is claimed.

## S1: Django 5.2 Release and Compatibility

[Official Django 5.2 release notes](https://docs.djangoproject.com/en/5.2/releases/5.2/)

Used to check the LTS release and Python/database compatibility. Use a current patch and recheck the compatibility table for the actual dependencies selected.

## S2: Django Version Support

[Official Django downloads and support schedule](https://www.djangoproject.com/download/)

Django 5.2 extended support is scheduled through April 2028. The documentation proposes the maintained 5.2 line, not an indefinitely safe frozen patch.

## S3: Django Project Bootstrap

[Official Django 5.2 tutorial, part 1](https://docs.djangoproject.com/en/5.2/intro/tutorial01/)

Reference for project/app creation and local development workflow. [GETTING_STARTED.md](GETTING_STARTED.md) is a project-specific recipe; it has not created or run the application.

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

## Updating References

Record the date, URL, relevant fact and affected decision when a source changes. Replace broken links with the current authoritative source and revise any dependent instructions. Do not leave a new source beside an outdated factual claim without resolving the discrepancy.
