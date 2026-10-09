# PHP Catalogue Release Checklist

Updated: 2026-10-09. This checklist applies to the PHP/MariaDB catalogue intended for myfanverse.in on Hostinger. It records release acceptance, not planned features or historical Django capabilities. Items remain unchecked until the release owner records the corresponding evidence. Local results belong in [QUALITY_REVIEW.md](QUALITY_REVIEW.md); setup and hosting procedures are in [GETTING_STARTED.md](GETTING_STARTED.md) and [HOSTINGER_DEPLOYMENT.md](HOSTINGER_DEPLOYMENT.md).

## Release record

| Item | Evidence for this release |
|---|---|
| Revision / package and release.json | Local codex/hostinger-mariadb; localdata/releases/hostinger-myfanverse.in.zip, SHA256 in QUALITY_REVIEW |
| Responsible owner / release date | To record |
| Actual host PHP / MariaDB versions | To verify |
| Local test commands / results | [Executed local matrix and ZIP-layout evidence](QUALITY_REVIEW.md) |
| Remote CI run for this revision | To verify |
| Staging / live URLs and smoke results | To verify |
| Backup location / successful restore rehearsal | To verify |
| Rollback package and decision | To verify |

## Source and local verification

- [x] Scope and available routes match the current catalogue; future admin/accounts/matching/maps/ratings/editorial features are clearly identified as future work.
- [x] PHP lint fails on invalid files; lint, unit, private-config, package and disposable MariaDB integration checks pass for the release revision with exact runtime/results recorded.
- [x] Schema setup/upgrade and constraints are checked on supported MariaDB, with InnoDB, utf8mb4 and enabled foreign-key/CHECK settings.
- [x] Repeat seeding preserves counts, IDs, unrelated records, edited/historical evidence and inactive flags; injected failures roll back.
- [x] Catalogue/detail tests cover combined filters, pagination, malformed/array input, empty results, active visibility, escaping, 404s and generic visitor errors.
- [x] The allowlisted ZIP and manifest are inspected; private config, seeds, tests, exports, Git and legacy source are excluded.
- [x] The ZIP-layout Apache rehearsal verifies public_html routing and private-file configuration.
- [ ] A successful remote CI run is linked for the exact release revision.
- [ ] Actual browser acceptance verifies keyboard navigation, visible focus, labelled controls, narrow layouts, empty/error states and table scrolling.

## Hostinger and domain acceptance

- [ ] Existing myfanverse.in site/files/database are preserved before replacement, where applicable.
- [ ] The account's actual PHP runtime/extensions and MariaDB version are verified against the supported release.
- [ ] Only public_html is served; includes/templates/config/scripts/schema remain outside it, and hidden .htaccess is uploaded.
- [ ] Production uses private readable config/local.php, APP_ENV=production, DEMO_MODE=false and empty APP_BASE_PATH at the domain root.
- [ ] Unintended process-environment/APP_CONFIG_FILE overrides are removed or deliberately documented; no credential is stored in the public directory, Git or ZIP.
- [ ] Initial schema installation or additive upgrade is rehearsed on staging, backed up and applied using the reviewed production acknowledgement/fresh-import procedure.
- [ ] The actual hPanel DNS values connect myfanverse.in to the intended website; optional www behaviour is verified, and email MX/SPF/DKIM/DMARC records are preserved.
- [ ] SSL is valid for the selected domain/alias; HTTP redirects to the intended HTTPS URL without loops.
- [ ] Real staging and live smoke checks pass for catalogue, details where data exists, about, CSS, malformed inputs, missing records and private-file denial.
- [ ] Private server logs and PHP error settings are verified; visitor responses contain no internal traces or database credentials.

## Catalogue content and privacy

- [ ] A fresh empty catalogue is accepted as such, or permitted real records have been reviewed before public use; no development/test fixtures were imported as real content.
- [ ] Café sources, historical dates, independence/count evidence and prices are factually reviewed; missing evidence remains unknown.
- [ ] Existing café UUIDs/URLs are preserved and inactive café/area visibility is checked on the actual data.
- [ ] Original/permitted text and content rights are confirmed; copied third-party review collections and private participant records are excluded.
- [ ] The owner records an appropriate support/correction contact for real-data operation. No correction-submission UI or privacy/account route is claimed unless separately implemented and accepted.
- [ ] The release accurately describes its actual data flows. Any future accounts, preferences, visits, maps, analytics or personal-data features receive their own privacy/consent/deletion/provider review before launch.

## Backup, restore and release decision

- [ ] The actual backup availability/schedule, protected storage, retention and responsible owner are recorded.
- [ ] File/private-config/database backups are available for this release and kept outside the public directory and repository.
- [ ] Restoration into an isolated database is rehearsed and verified for schema, rows/UUIDs, historical evidence and catalogue/detail behaviour.
- [ ] The previous compatible package/configuration and schema recovery plan are available; nontransactional DDL and newer data are accounted for.
- [ ] Remaining issues and any accepted limitations are recorded with an owner and disposition.
- [ ] The release owner approves the concrete package, observed host checks and rollback plan before live cutover.

[RUNBOOK.md](RUNBOOK.md) describes recovery. Local test passes, CI configuration, a generated ZIP and an agent handoff do not establish a successful Hostinger deployment, DNS/SSL configuration, backup schedule or restore drill.
