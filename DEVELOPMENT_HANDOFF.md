# Café Discovery — Development Handoff

Updated: 2026-10-12. Transfer context through source and evidence, not credentials or live agent sessions.

## 1. Verified Live Checkpoint

- **Live Production URL:** `https://myfanverse.in` (Hostinger Single Web Hosting, account `u493193058`, PHP 8.3 + LiteSpeed + MariaDB).
- **Domain Isolation:** Sibling subdomains (`sitascanvas.myfanverse.in` and `anujssmishra.myfanverse.in`) remain untouched in their respective subdirectories.
- **Active Tech Stack:** Native PHP 8.2+ with MariaDB (InnoDB, utf8mb4), PDO prepared statements, vanilla semantic HTML5 & responsive CSS (`site.css?v=sprint5.1`). Zero build step, zero client framework overhead.
- **Security Posture:** Dedicated `config/local.php` private configuration loader (`includes/config.php`), strictly isolated outside public git history, supporting server-level fallbacks.
- **Live Pilot Dataset:** 32 verified specialty café locations across 9 Lucknow neighbourhoods (Gomti Nagar, Hazratganj, Sushant Golf City, Mall Avenue, Cantonment, Badshahnagar, Aliganj, Nirala Nagar, Indira Nagar).
- **Visual Ambiance & Media:** Real-world interior, garden, and seating ambiance photos and hero banners populated across all 32 cafés (verified from local publications and field research).
- **Live Features Verified:**
  - Debounced instant live search (250ms fetch + DOMParser + URL history sync)
  - 9-neighbourhood area filter dropdown & mood/vibe filter dropdown
  - Card-level photo thumbnails and detail-level hero banners
  - Side-by-side **`[📍 Maps ↗]`** and **`[🌐 Website ↗]`** action buttons with clean, uncrowded titles
  - Spend tiers (`₹`, `₹₹`, `₹₹₹`) and signature food & bakery highlights on every card
  - **Friends' Take (Private Circle Notes)** hero placement at the top of café details with verified must-orders and food quality verdicts
  - Circle pick indicator badges on catalogue cards
  - `/circles/` hub with WhatsApp invite sharing and on-demand Google review import
  - Mobile optimizations: 16px form controls (no iOS auto-zoom), momentum touch scroll, responsive cards
  - Full UUID detail views (`/cafes/{uuid}/`) with drink offerings and provenance
  - Friendly 404 / 503 error handling with operator diagnostic mode (`?diag=lucknow`)

---

## 2. Active Increment: Sprint 5 (Interactive Map & In-Context Notes)

**Sprint 5 Goal:** Enable geographic exploration via an interactive Leaflet map layer, and allow circle friends to contribute quick recommendations directly from café detail pages.

### Selected User Stories:
1. **CAFE-112: Interactive Leaflet Map Toggle (`[📋 List] | [🗺️ Map]`):**
   - Toggle view on the main catalogue between the existing card grid and a responsive Leaflet.js OpenStreetMap layer.
   - Plot all 32 cafés using their already-stored GPS coordinates.
   - Tapping a pin opens a popup with café thumbnail, name, area, spend tier, and directions link.
   - Parity with area and vibe filters. Zero API billing (OpenStreetMap + Leaflet CDN).
2. **CAFE-113: In-Context Circle Notes on Detail Pages:**
   - Add a lightweight `+ Add your note / Must-try recommendation` form directly on `/cafes/{uuid}/`.
   - Allows circle members to leave a quick 2-line note or dish pick without navigating away to `/circles/`.
3. **CAFE-114: "Find My Café Today" Quick Recommendation Flow:**
   - 3-step quick matcher (Purpose: Work / Social / Date; Area; Budget) surfacing top 3 best-fit cafés with explanation reasons.
4. **CAFE-115: Live Pilot Cohort Testing & Measurement:**
   - Distribute `https://myfanverse.in` to a cohort of 10–15 Lucknow friends and capture real usage observations.

---

## 3. Work Packages and Ownership

| Work package | Lead | Files Owned |
|---|---|---|
| **W1: Interactive Leaflet Map Layer** | Frontend | `php_app/templates/catalogue.php`, `php_app/public/static/site.css` |
| **W2: In-Context Circle Note Submission** | Backend + Frontend | `php_app/includes/circles.php`, `php_app/templates/cafe_detail.php` |
| **W3: Quick Recommendation Matcher** | Frontend + Backend | `php_app/templates/catalogue.php`, `php_app/includes/catalogue.php` |
| **W4: Hostinger Deployment & Verification** | Operations / Root | `C:\Users\anujs\Downloads\hostinger_update.zip`, Hostinger File Manager |
| **W5: Delivery Plan & Backlog Sync** | Planning | `AGILE_DELIVERY.md`, `PRODUCT_BACKLOG.md`, `RELEASE_CHECKLIST.md` |

---

## 4. Next Implementation Actions

1. Implement Leaflet.js map layer toggle in `php_app/templates/catalogue.php` using stored GPS coordinates.
2. Add in-context note submission form to `php_app/templates/cafe_detail.php`.
3. Package and verify updates for Hostinger deployment.
