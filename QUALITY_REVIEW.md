# Quality Review: First Catalogue Increment

Review date: 2026-10-07. Scope: local Django catalogue foundation and guest browsing. Reviewer role: independent QA agent, with implementation owned by separate developers.

## Acceptance scope

The independent suite in `tests/test_catalogue_acceptance.py` exercises real Django HTTP responses and database-backed fixtures. It covers:

- Active café and area visibility, including detail URLs and demo exclusion.
- Trimmed, case-insensitive name search combined with area selection.
- Invalid, inactive and empty areas, overlong queries and no-result behavior.
- Explicit synthetic labels and unknown price/evidence presentation.
- Escaped catalogue/query text and rejection of unsafe external link schemes.
- Twelve-result pagination with filter preservation and malformed page inputs.
- The public about page.
- Read-only HTTP methods, unknown/malformed café identifiers and external-link suppression for fictional entries.
- Ownership evidence at the 30-day boundary, and imported future dates or whitespace-only sources.
- Price evidence labels at 0, 30 and 31 days, plus invalid future dates, while preserving the recorded price.

`tests/test_editor_acceptance.py` independently checks that catalogue permissions do not grant staff access, editors cannot create users/groups, admin writes require a CSRF token, and a reserved demo-area collision rolls back without replacing existing content. `tests/test_configuration_acceptance.py` loads settings in isolated processes to check missing/short secrets, explicit production hosts, wildcard rejection, strict boolean parsing and the development-only demo boundary.

The independent suite contains 32 tests and uses synthetic fixtures only. It does not contact external café websites. Model/database constraints, ownership evidence, editor permission-set contents and seed idempotence also have developer-owned coverage under `cafes/tests/`.

## Findings and disposition

| Finding | Evidence and required disposition |
|---|---|
| Evidence freshness was enforced by model properties but not public presentation. | Initial source review found detail ownership accepted any non-future checking date and a truthy source; cards accepted future dates and whitespace sources as checked. Root fixed presentation to use current/stale/incomplete evidence and the 30-day boundary. Independent HTTP regressions pass, including stale/future offering evidence. |
| Public URL handling defends against dirty imported values. | Source review found an HTTP/HTTPS allowlist plus rejection of embedded credentials, backslashes and whitespace/control characters. Tests include these cases; no external destination is opened. |
| Visibility uses one shared public queryset. | Both list and UUID detail select active cafés in active areas and suppress demo entries unless demo mode is enabled. Acceptance tests exercise direct URL access as well as browsing. |
| Catalogue editing is restricted to a dedicated role. | The setup command grants catalogue model permissions only and creates no account or staff status. HTTP tests cover permission boundaries and CSRF; hosting-level access controls remain outside this increment. |

## Execution evidence

Environment: Python **3.12.14**, Django **5.2.18**, SQLite's isolated in-memory test database. Tests received an ephemeral generated secret of at least 50 characters, `DJANGO_DEBUG=true`, `DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,testserver` and `DJANGO_DEMO_MODE=true`. Individual cases override settings to exercise hidden demo content and invalid configuration.

| Command/check | Observed result |
|---|---|
| Python AST parsing of the independent test modules | Passed. |
| `.venv/bin/python manage.py test tests --verbosity 2` | Initial 31-test independent suite passed in 0.908 seconds, exit 0. Django applied the initial catalogue migration in the temporary database and reported no system-check issues. |
| `.venv/bin/python manage.py test tests --verbosity 1` | Final **32-test** independent suite passed in **0.826 seconds**, exit 0, after the price-evidence regression and formatting. System check reported no issues. |
| `.venv/bin/python -m ruff check --fix tests` | Passed with no lint fixes required after root repaired the Ruff installation. |
| `.venv/bin/python -m ruff format tests` | Reformatted two files; two were already formatted. |
| `.venv/bin/python -m ruff check tests` and `.venv/bin/python -m ruff format --check tests` | Both passed, exit 0; all four files are formatted. Ruff version is 0.16.10. Earlier code-139 invocations were an executable installation failure, resolved before these passing checks. |

Root subsequently ran the complete integrated suite: **49 tests passed in 1.372 seconds**, exit 0. Django checks and migration drift checks were clean; full-repository Ruff lint and formatting checks passed. The setup sequence migrated the local database and seeded twice without duplicates. Root owns CI configuration and publication evidence. These local QA results do not establish a successful remote CI run. No unresolved functional defect was found in the selected catalogue acceptance scope after the evidence-presentation fix.

## Release boundary

This increment is a local development milestone. It does not establish production readiness or verify the later member, recommendation, map, editorial, consent, deletion, backup/restore or pilot workflows. Real-device/mobile and browser accessibility checks must be recorded separately if performed; this review will not infer them from server-side tests.
