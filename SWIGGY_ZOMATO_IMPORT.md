# Android Swiggy and Zomato import

Implemented 27 October 2026 in the Flutter/FastAPI subsystem. This does not change the
separate hosted PHP catalogue. No personal order history was read or imported during development.

## Use it

1. Install the updated Android APK from the private GitHub release. Keep the selected API
   server reachable and update/restart that backend with this source revision first.
2. Open **Auto-Ingest → Import Swiggy / Zomato** and choose the order app.
3. Select a UTF-8 `.csv`, `.json` or `.txt` file, or paste plain-text receipt/email content.
   Files are limited to 5 MiB and imports to 1,000 rows. PDF/image extraction is not included;
   copy the receipt text instead.
4. Review and edit the order ID, restaurant, final amount paid, completion status, currency,
   date/time, dishes and any optional payment reference. Required unknown fields block import.
   Missing dates or dishes can remain unknown after explicit review. Cancelled, refunded and
   unrecognized statuses are excluded.
5. Select **Check duplicates**. For a possible payment match, explicitly choose **Link existing
   payment** or **Import as separate order**. Check the selected rows, then import.
6. Open the dining ledger from Taste to see saved order IDs and dishes. If disconnected during
   upload, use **Retry pending** in Auto-Ingest when the selected server is reachable again.

This is a user-selected file/text import. It does not sign in to either service or synchronize
accounts. The in-app templates and [CSV](food_recsys_mobile/examples/orders.csv) /
[JSON](food_recsys_mobile/examples/orders.json) examples are this app's formats, with fictional
data. They are not asserted to be native Swiggy or Zomato export formats. Other exports may
need reshaping or correction in the review screen. Plain-text receipt parsing requires explicit
fields and supports one receipt per paste; ambiguous totals remain unset for correction.

## Data contract and mapping

CSV fields: `platform,order_id,restaurant_name,amount,order_time,dish_names,status,currency`.
`platform` may use the selected app when omitted; explicit per-row platforms take precedence.
Use `|` between dish names in CSV. JSON accepts an array or `{ "orders": [...] }`, with dishes
as a string array. Optional fields: `timezone`, `cuisine`, `upi_ref`. Exact timestamps include
an offset, for example `2026-10-26T19:30:00+05:30`. A date such as `2026-10-26` stays date-only.
The Android importer supports `Asia/Kolkata`, `Asia/Calcutta`, `UTC`, `GMT` and `Etc/UTC`.
Naive timestamps in the default `Asia/Kolkata` timezone are interpreted there. Unknown times
stay unknown in meal patterns. An order must have a positive final INR amount at most ₹100,000,
a Swiggy/Zomato platform, a 1–64 character order ID containing letters/digits/underscore/hyphen,
and completed, delivered or paid status. Up to 20 dish names of 120 characters each are accepted.

The parser and Android document picker operate locally. Only reviewed fields go to
`POST /api/v1/ingest/food-orders/preview`, then the consent-gated retry queue sends them through
the existing versioned `/api/v1/ingest/payments` endpoint. Raw files, receipt/email text,
addresses and account contents are not uploaded or saved in the retry queue. Import does not
request SMS or broad file-storage permission. Server selection, consent withdrawal and erasure
invalidate stale requests; offline rows remain bound to the original selected server.

Canonical source IDs are `order:swiggy:<order_id>` or `order:zomato:<order_id>`. Order IDs and
UPI references provide exact duplicate identities scoped to the profile. Matching an amount,
restaurant or time alone only produces review candidates. A confirmed link checks profile
ownership, amount and identity conflicts. Re-imports enrich the same purchase rather than
adding spend twice; different orders cannot share a payment. Partial
retries retain previously known details. The additive `order_details` table stores safe order
context; ledger responses include it and profile erasure deletes it.

The backend remains the existing development API with profile IDs; this change does not add
multi-user authentication or production account synchronization.

## Verification

Verified against the final implementation on 27 October 2026:

- Python 3.12.6: `.venv/bin/python -m pytest -q` — **111 passed**. Includes identity conflicts,
  concurrent linking, existing import compatibility, preview privacy, enrichment, ledger and erasure.
- Flutter 3.47.8 / Dart 3.13.7: `flutter test --no-pub` — **92 passed**. Includes 21 parser cases,
  nine import-screen cases at 390 pixels, native-channel file validation/cancellation, offline
  retries and navigation from the complete app.
- `flutter analyze --no-pub --no-fatal-infos` — exit 0, **zero errors or warnings**;
  234 informational style/deprecation notices remain across the application and vendored code.
- `flutter build apk --debug --no-pub` — succeeded. Android package
  `com.foodrecsys.food_recsys_mobile`, version **1.0.1**, version code **2**, minimum Android API 24.
- Live local-server synthetic check passed for both platforms: possible-match preview, explicit
  bank-payment linking, repeat import skipping, ledger dishes, date-only meal precision and
  erasure. Existing user profiles were not queried or modified by this synthetic check.
- The existing local API server was restarted with this source and its database preserved.

APK SHA-256: `a3f122d289b6b5ecf6662f04a993d7fee002f5fdef4e67768e5459116f202c2c`.
Source branch: `codex/swiggy-zomato-import`. Download the APK and checksum from the
[private GitHub release](https://github.com/anujssmishra/cafe-discovery-app/releases/tag/android-order-import-2026-10-27).

A successful APK build verifies Android compilation. Native document-provider selection and
installation of this APK still need a physical Android device check; no device is connected
to ADB in this workspace. No remote CI result or production deployment is claimed.
