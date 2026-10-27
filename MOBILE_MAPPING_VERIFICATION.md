# Mobile data mapping — implementation and verification

Updated: 2026-10-27. This checkpoint covers the separate Food RecSys backend and Flutter Android app. It does not establish production deployment or validation against private dining history.

## Implemented behaviour

- Mobile extraction sends a versioned structured payment contract, preserving merchant, amount, source identity, reference, time and timezone when known. Import results distinguish inserted, duplicate, rejected, unresolved-branch and pending records. Unknown cuisine, branch or meal time remains unknown.
- Stable payment identities prevent repeat imports. Background captures persist extracted fields locally and retry when the app opens/resumes or the user selects Retry. Historical scanning saves progress and processes the available history in batches rather than truncating it at 5,000 messages. Confirmed duplicate acknowledgements also refresh the displayed profile.
- Pending captures and scan checkpoints belong to their API server. A saved server remains selected while offline; new addresses are checked before selection. Changing the server invalidates displayed data, tracking and consent. Request guards prevent earlier responses from replacing the current selection. Persisted erasure epochs invalidate delayed captures across queue instances.
- Profile failures preserve the last valid same-server profile and show an unavailable/stale state. Cuisine coverage, meal patterns, named restaurants and neighbourhood counts are visible; neighbourhoods are ranked by payment count.
- The ledger supports cursor pagination, with whole-ledger count/spend independent of loaded pages. It displays classification and time precision, and converts known timestamps to the device's local timezone. Meal-specific recommendations use recorded preferences and explain the overall-history fallback when that meal has no history. Explanations distinguish transaction frequency from spending share.
- Current catalogue metadata supplies areas, cuisines and meal options, including late night. Restaurant details expose public photos, offerings, atmosphere, food highlights, provenance and copyable website/directions links. Inactive restaurants are excluded from public detail and discovery responses; catalogue filters apply before pagination.

## Existing data and upgrade contract

The additive `PaymentIdentity` (`payment_identities`) and `RestaurantMetadata` (`restaurant_metadata`) tables support import identity and public catalogue details without dropping existing purchase/restaurant tables. Startup creates missing tables through the existing schema initialization. Back up the configured database before upgrading; no production database was inspected or migrated during this work.

[Legacy record reconciliation](food_recsys/app/profile/records.py) counts repeated non-empty UPI references once per user in profile and ledger views while retaining the underlying rows. Records without a shared reliable reference remain separate. Existing histories are not destructively deduplicated or speculatively merged; corrected views may therefore show a lower count than older inflated totals.

Upgrade/restart the backend and install a newly built mobile app together. The client requires `POST /api/v1/ingest/payments` and the updated metadata, detail, profile and paginated-ledger contracts. The final debug APK was rebuilt after the integrated source changes and phone-layout correction.

## Public catalogue synchronization

The bundled JSON snapshot is generated from the repository's PHP seed; it is not a live connection to the hosted catalogue. From `food_recsys/`:

```bash
python scripts/export_seed_catalogue.py
python scripts/export_seed_catalogue.py --check
```

The second command detects a stale bundled snapshot. To transfer current PHP database edits and inactive flags, explicitly run the read-only public-field exporter in the configured PHP environment, then import its JSON:

```bash
# From the repository root, in the PHP environment:
php php_app/scripts/export_catalogue.php > public-catalogue.json
# From food_recsys/, using its configured backend environment:
python -m app.catalogue.sync ../public-catalogue.json
```

Sync preserves UUIDs, unrelated manual records and existing cuisine enrichment when the PHP export omits it. Explicit closures propagate. A live export takes precedence over the bundled snapshot on subsequent backend starts. The exporter excludes private circle notes and personal histories. See [backend setup and contracts](food_recsys/README.md) and [mobile setup](food_recsys_mobile/README.md).

## Verification checkpoint

Tested toolchain: Python **3.12.6**, Flutter **3.47.8**, Dart **3.13.7**. Results below record the final integrated local checks; remaining environment/device checks are separate.

| Check | Recorded outcome |
| --- | --- |
| Backend regression suite | **93 passed**, reported by root on 2026-10-27; isolated test databases and synthetic fixtures. Coverage includes identity/retry mapping, legacy reference reconciliation, ledger totals/pages/user scope, catalogue sync/concurrency, metadata and meal-context behaviour. |
| Final Flutter test suite | **55 passed** with `flutter test --no-pub`, including all four tabs at a 390 × 844 phone viewport, import queues, provider state, ledger paging and restaurant details. |
| Final Flutter analysis | `flutter analyze --no-pub --no-fatal-infos` exited **0** with **0 errors and 0 warnings**. 229 informational style/deprecation notices remain, including vendored telephony code. |
| Final debug APK rebuild | **Passed:** `flutter build apk --debug --no-pub`; `food_recsys_mobile/build/app/outputs/flutter-apk/app-debug.apk` (200,812,986 bytes). |
| Bundled snapshot stale check | **Passed:** `scripts/export_seed_catalogue.py --check`. Changed/new Python syntax checks (30 files) and `git diff --check` also passed. |
| PHP exporter syntax/runtime and MySQL integration | **Not run:** no PHP runtime; Docker daemon unavailable. The explicit exporter still needs validation in its intended environment. |
| PostgreSQL concurrency | **Not run.** Passing isolated backend tests do not establish PostgreSQL concurrency behaviour. |
| Real Android background/offline/restart flow | **Not verified on a physical device.** Automated service/queue tests do not establish OS delivery, permission or process-restart behaviour. |
| Actual private history and deployed service | **Not inspected or validated.** No claim that every real payment has been mapped correctly. |

Physical-device acceptance should include a historical scan and repeat scan, upload interruption followed by duplicate acknowledgement, background capture followed by resume, process restart, consent withdrawal/erasure during capture, server switching with pending records, and reconciliation of displayed ledger/profile totals. Verify only with an authorized device and dataset.

Final APK SHA-256: `eb7a262955704320a7f9e7f545790da6a605c3b5a77873c2e579440e2e756be1`.
