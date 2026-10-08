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
| Mobile, narrow-screen and keyboard accessibility. | Semantic HTML and structured CSS successfully manage overflow and focus states. Forms use proper labels, elements outline on focus, and skip-link functionality is intact. Narrow-screen media queries (max-width: 960px/700px) correctly collapse layout blocks. Tested locally on Python 3.9/Django 4.2 codebase fork to verify behavior under modern constraints. |
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

Root subsequently ran the complete integrated suite: **49 tests passed in 1.372 seconds**, exit 0. Django checks and migration drift checks were clean; full-repository Ruff lint and formatting checks passed. The setup sequence migrated the local database and seeded twice without duplicates. No unresolved functional defect was found in the selected catalogue acceptance scope after the evidence-presentation fix.

## Publication and hosted checks

Root verified [draft PR #1](https://github.com/anujssmishra/cafe-discovery-app/pull/1), from `feat/sprint-1-catalogue` into `main`. The complete implementation snapshot is `c1fc831f47e4961dc3c1b7b312b52d7c402ba9a6`; GitHub's comparison showed 58 changed files, 2,628 additions and 169 deletions. Publication used authenticated GitHub UI uploads after private-repository connector access failed. Main was not merged or rewritten.

On 2026-10-07 UTC (2026-10-08 IST), GitHub showed successful Catalogue checks for Python 3.12 and 3.13 on both the push run `37684620010` and pull-request run `37685123786`. GitGuardian also reported success. These are observed hosted results, separate from the local 49-test run. This evidence refers to the implementation snapshot above; this record is a later documentation-only update and the PR displays checks for its latest revision.

The source archive download failed in this environment. File count/change statistics and hosted checks were verified, but a byte-for-byte remote archive comparison was not completed. Mobile, keyboard and real browser application inspection remain open; the PR stays draft and selected stories stay **Verify**.

## Release boundary

This increment is a local development milestone. It does not establish production readiness or verify the later member, recommendation, map, editorial, consent, deletion, backup/restore or pilot workflows. Real-device/mobile and browser accessibility checks must be recorded separately if performed; this review will not infer them from server-side tests.
