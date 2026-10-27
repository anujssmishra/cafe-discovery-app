# Food RecSys Mobile — Flutter / Android

An Android app for importing dining payment signals and viewing explained restaurant
recommendations from the separate Food RecSys FastAPI backend.

## Run

Start the backend using [its setup instructions](../food_recsys/README.md). With Flutter and
the Android SDK installed, run from this directory:

```bash
flutter pub get
flutter run
```

In Settings, choose a reachable API server. Android emulators normally use
`http://10.0.2.2:8000`; a physical phone needs a reachable local-network address or an existing
USB reverse connection. A saved server stays selected while offline. New addresses are probed
before replacing it. Changing the server resets displayed data and processing consent; pending
captures and scan checkpoints remain tied to the server they belong to.

## Import and review

**Swiggy/Zomato orders:** open Auto-Ingest → Import Swiggy / Zomato. Select a CSV/JSON/TXT file
or paste a receipt, edit the extracted fields, check duplicates and import selected orders.
Possible existing payments require an explicit link/separate decision. Orders retain their
IDs and dishes in the ledger. See [formats and instructions](../SWIGGY_ZOMATO_IMPORT.md).
This is file/text import; account synchronization and PDF/image parsing are not included.

- Grant SMS processing consent before scanning or enabling tracking.
- The app extracts structured amount/merchant/reference/time fields on-device. Raw SMS is
  neither uploaded nor persisted in the import queue.
- Scan history processes all available messages in batches and saves progress. It no longer
  stops after the latest 5,000 messages.
- Counts distinguish inserted, duplicate, rejected, unmatched-branch, and pending records.
  A rejected batch is never counted as imported merely because it was uploaded.
- Foreground captures upload when possible. Android background captures are saved locally;
  queued payments retry when the app opens/resumes or when Retry is selected.
- Pausing tracking guards callbacks. Consent withdrawal stops capture/upload; local erasure
  clears queued captures and invalidates delayed background writes before server erasure.
- Payments with uncertain merchant branches retain an unresolved state. Unknown cuisine/time
  does not become an invented preference or meal.

The dining ledger has Load More pagination and full totals independent of the loaded page.
The profile shows cuisine coverage, meal patterns, named restaurants and neighbourhood counts.
Recommendations use meal-specific history when available and explain the overall fallback
when it is absent. Restaurant details include public catalogue images, offerings, atmosphere,
food highlights, and copyable website/directions links.

## Verify and build

```bash
flutter test --no-pub
flutter analyze --no-pub --no-fatal-infos
flutter build apk --debug --no-pub
```

The analyzer excludes the vendored telephony package's separate example/test projects; those
have their own development dependencies. Existing style/deprecation notices are not suppressed
as app compile errors. See [mapping verification](../MOBILE_MAPPING_VERIFICATION.md) for the
actual tested runtime, outcomes, and remaining device acceptance checks.

The debug APK is generated at `build/app/outputs/flutter-apk/app-debug.apk`. Install it alongside
an updated/restarted backend; this client requires the new `/api/v1/ingest/payments` contract.
