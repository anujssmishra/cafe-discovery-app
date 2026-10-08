# Pilot Measurement Plan

This document outlines the minimal measurement approach for the Café Discovery pilot (CAFE-030).

## 1. Principles
- **No Third-Party Trackers**: To protect privacy, we do not embed Google Analytics or similar third-party scripts.
- **Anonymous Metrics**: We track aggregate events, not individual user journeys.
- **Distinguish Intent from Reality**: Clicking a directions link is "directions interest," not a confirmed physical arrival. A logged visit is a "self-report," not a "verified transaction."

## 2. Denominators and Windows
- **Active Window**: The pilot will run for an initial 14-day window.
- **Denominators**: 
  - Total Unique Sessions (estimated via server logs without identifying cookies).
  - Total Authenticated Users.
  - Total Fictional/Synthetic Records (excluded from all business metrics).

## 3. Metrics to Collect
We will rely on standard server access logs (via WhiteNoise/Gunicorn) to extract the following:
1. **Engagement**: Number of visits to `/cafes/` (catalogue views).
2. **Detail Interest**: Number of visits to `/cafes/<uuid>/` (detail views).
3. **Directions Interest**: 
   - Currently, directions links point directly to Google Maps. 
   - If measurement of outbound clicks is strictly needed, we can implement an interstitial `/outbound/directions/<uuid>/` redirect, or rely on client-side log reporting. For the initial pilot, we will assume detail page views are a sufficient proxy for intent, keeping data collection strictly server-side.
4. **Correction Submissions**: Count of `POST` requests to `/cafes/<uuid>/correction/`.
5. **Errors / Failures**: 404s, 500s, and unexpected form validation failures captured in `django` logger.

## 4. Exclusion of Sensitive Payloads
- Passwords, form data (e.g. specific correction text), and session cookies are excluded from access logs.
- Test/Synthetic records (demo mode data) will not be counted in final pilot reporting.

## 5. Reviewing the Data
At the end of the 14-day window, the Product Owner (Anuj) will aggregate log counts to evaluate usefulness and error rates before planning the next sprint (CAFE-031).
