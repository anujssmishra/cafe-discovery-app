# Café Discovery — Development Handoff

Updated: 2026-10-12. Transfer context through source and evidence, not credentials or live agent sessions.

## 1. Verified Live Checkpoint

- **Live Production URL:** `https://myfanverse.in` (Hostinger Single Web Hosting, account `u493193058`, PHP 8.3 + LiteSpeed + MariaDB).
- **Domain Isolation:** Sibling subdomains (`sitascanvas.myfanverse.in` and `anujssmishra.myfanverse.in`) remain untouched in their respective subdirectories.
- **Active Tech Stack:** Native PHP 8.2+ with MariaDB (InnoDB, utf8mb4), PDO prepared statements, vanilla semantic HTML5 & responsive CSS (`site.css?v=sprint5.2`). Zero build step, zero client framework overhead.
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
  - Mobile optimizations: 16px form controls (no iOS auto-zoom), momentum touch scroll, responsive cards, and clean mobile offerings card list replacing cramped tables on small screens (commit `54eb82b`)
  - Full UUID detail views (`/cafes/{uuid}/`) with drink offerings and provenance
  - Friendly 404 / 503 error handling with operator diagnostic mode (`?diag=lucknow`)

---

## 2. Active Increment: Sprint 5 (Interactive Map & In-Context Notes)

**Sprint 5 Goal:** Enable geographic exploration via an interactive Leaflet map layer, allow circle friends to contribute quick recommendations directly from café detail pages, and consolidate multi-branch chains into single brand cards.

### Delivered User Stories:
1. **CAFE-112: Interactive Leaflet Map Toggle (`[📋 List] | [🗺️ Map]`):**
   - Toggle view on the main catalogue between card grid and responsive Leaflet.js OpenStreetMap layer.
   - Plots all 32 cafés using database GPS coordinates with interactive popups and directions links.
2. **CAFE-113: In-Context Circle Notes on Detail Pages:**
   - Lightweight `+ Add your note / Must-try recommendation` inline form on `/cafes/{uuid}/` inserting directly into Friends' Take.
3. **CAFE-114: "Find My Café Today" Quick Recommendation Flow:**
   - 3-step quick matcher (Purpose, Area, Budget) surfacing top 3 best-fit cafés with factual explanation tags.
4. **CAFE-121: 1 Card Per Café Brand & Branch Selector Dropdown:**
   - Multi-branch chains grouped into 1 brand card in the catalogue, with branch selection dropdown on `/cafes/{uuid}/`.
5. **CAFE-115: Live Pilot Cohort Testing & Measurement:**
   - Deployment bundle packaged; cohort distribution ready.

---

## 3. Work Packages and Ownership

| Work package | Lead | Files Owned / Artifact | Status |
|---|---|---|---|
| **W1: Interactive Leaflet Map Layer (CAFE-112)** | Frontend | `php_app/templates/catalogue.php`, `site.css` | Done |
| **W2: In-Context Circle Note Submission (CAFE-113)** | Backend + Frontend | `php_app/includes/circles.php`, `cafe_detail.php` | Done |
| **W3: Quick Recommendation Matcher (CAFE-114)** | Frontend + Backend | `php_app/templates/catalogue.php`, `catalogue.php` | Done |
| **W4: Multi-Branch Consolidation (CAFE-121)** | Backend + Frontend | `php_app/public/index.php`, `catalogue.php` | Done |
| **W5: Hostinger Release Packaging** | Ops / Root | `~/Downloads/hostinger_update.zip` & `localdata/releases/` | Packaged |
| **W6: Pilot Usability Testing (CAFE-115)** | Anuj (PO) + Planning | `PILOT_MEASUREMENT.md`, `myfanverse.in` | Ready |

---

## 4. Next Implementation Actions

1. In Hostinger File Manager for `myfanverse.in`: Upload and extract `hostinger_update.zip` (available in `~/Downloads/`).
2. Verify live site functionality at `https://myfanverse.in` (map toggle, branch dropdown selector, and note submissions).
3. Distribute pilot invite link to the 10–15 friend cohort to measure engagement and collect feedback.
