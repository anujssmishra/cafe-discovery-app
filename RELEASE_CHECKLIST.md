# Pilot Release Checklist

This document captures the final review of privacy, data rights, and operational readiness before the Café Discovery pilot.

## 1. Privacy & Participant Notice
- [x] **Adult Eligibility**: Confirmed pilot is restricted to adults (18+). This is communicated in the Privacy Notice and on the signup/login pages.
- [x] **Privacy Notice**: Published at `/privacy/`. It covers:
  - Identity & Contact: (Anuj / Data Owner).
  - Purposes: Matching preferences to cafés.
  - Retention: Profile kept while active; pilot logs kept up to 90 days.
  - Export/Deletion: Working routes available in account settings.
- [x] **Consent & Withdrawal**: Preferences and visits are explicitly optional.

## 2. Third-Party Data Flows
- [x] **Map Requests (Leaflet/OSM)**: 
  - Validated that we use standard OSM tiles.
  - Confirmed no user coordinates, profiles, or identifying queries are sent to OSM.
  - Map only centers on generic areas or fixed café coordinates.
- [x] **Directions Links**:
  - Validated that `https://www.google.com/maps/dir/?api=1&destination=...` is used without passing any `origin` or user session data.
  - Directions are launched securely in a new tab (`noopener noreferrer nofollow`).

## 3. Data Rights & Content
- [x] **Catalogue Facts vs Opinions**: Clear separation exists between objective data (address, offerings) and subjective opinions (curator reviews, user feedback).
- [x] **Original Text & Permissions**: All editorial reviews use original text or have explicit permission. No scraped third-party reviews.
- [x] **Corrections Route**: The "Suggest a correction" feature is live.

## 4. Outstanding Issues & Disposition
| Issue | Risk | Disposition / Mitigation |
|---|---|---|
| Inactive account automated cleanup | Low for 30-day pilot | Handled manually post-pilot if needed. Defer automated job to Sprint 7. |
| Detailed tracking/analytics | Medium | We have chosen *not* to embed third-party analytics scripts in the pilot to minimize data footprint. |
| Production Database Backups | High | Configured via `pg_dump` in RUNBOOK, must verify cron schedule on target infrastructure during deployment. |
