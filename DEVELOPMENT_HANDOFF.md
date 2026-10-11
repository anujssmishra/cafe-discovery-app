# Café Discovery — Development Handoff

Updated: 2026-10-11. Transfer context through source and evidence, not credentials or live agent sessions.

## 1. Verified Live Checkpoint

- **Live Production URL:** `https://myfanverse.in` (Hostinger Single Web Hosting, account `u493193058`).
- **Domain Isolation:** Sibling subdomains (`sitascanvas.myfanverse.in` and `anujssmishra.myfanverse.in`) remain untouched in their respective subdirectories.
- **Active Tech Stack:** Native PHP 8.2+ with MariaDB (InnoDB, utf8mb4), PDO prepared statements, vanilla semantic HTML5 & responsive CSS (`site.css`). No node_modules, no build step, minimal overhead.
- **Security Posture:** Enterprise-grade config loader (`includes/config.php`) strictly enforcing credentials via `.htaccess` `SetEnv` or private server environment, rejecting public credential files.
- **Live Pilot Dataset:** 19 verified specialty cafés across 6 Lucknow neighbourhoods (Gomti Nagar, Hazratganj, Sushant Golf City, Mall Avenue, Cantonment, Badshahnagar) seeded with coordinates, drink prices, and verified independence status.
- **Live Features:**
  - Debounced instant live search (250ms fetch + DOMParser + URL history sync)
  - Area filter dropdown
  - Clickable address with Google Maps directions link and mini `[📍 Maps ↗]` action button
  - Context-aware Open Graph, Twitter Cards, and SEO meta tags
  - Full UUID detail views (`/cafes/{uuid}`) with drink offerings and provenance
  - Friendly 404 / 503 error handling

---

## 2. Active Increment: Sprint 3 (Friend-Informed Discovery)

Sprint 3 directly incorporates real user research collected by Product Owner Anuj from his cohort of friends regarding what they must know before visiting a café:
1. **Food Quality & Variety:** Specialty baking, sourdough, desserts, vegan/brunch options.
2. **Ambiance & Aesthetics:** Work-friendly, cozy/aesthetic, garden/outdoor, minimalist, lively hangout.
3. **Price Band:** Quick `₹` / `₹₹` / `₹₹₹` spend band per person.
4. **Location:** Clickable address navigation (delivered in Sprint 2).
5. **Reviews by Friends, Not Public:** Trusted private circle reviews and must-try recommendations, explicitly rejecting public/commercial star review aggregators.

---

## 3. Work Packages and Ownership

| Work package | Lead | Files Owned |
|---|---|---|
| **W1: Schema & DB Migration** | Backend / Ops | `php_app/schema/migration_sprint3_vibes_and_friends.sql` |
| **W2: Catalogue Queries** | Backend | `php_app/includes/catalogue.php` |
| **W3: Discovery & Detail UI** | Frontend | `php_app/templates/catalogue.php`, `php_app/templates/cafe_detail.php`, `php_app/public/static/site.css` |
| **W4: Pilot Data Enrichment** | Anuj (Curator) | Lucknow vibe tags, food specialties, and trusted friend notes |
| **W5: Hostinger Deployment** | Root / User | File uploads to Hostinger `public_html/` and phpMyAdmin SQL execution |

---

## 4. Next Implementation Steps

1. **Database Migration:**
   - Execute `php_app/schema/migration_sprint3_vibes_and_friends.sql` via phpMyAdmin on Hostinger.
   - Adds `vibe_tags`, `food_highlights`, `price_band` to `cafe` table.
   - Creates `friend_review` table with friend name, visit context, must-order recommendation, and review notes.
2. **Backend Query Updates:**
   - Update `catalogue_page()` in `php_app/includes/catalogue.php` to accept an optional `vibe` filter parameter and return vibe tags & price bands.
   - Update `catalogue_detail()` to query joined `friend_review` records ordered by date.
3. **Template Updates:**
   - Add vibe badges and price pill to `templates/catalogue.php`.
   - Add "Friends' Take" review cards and food highlights section to `templates/cafe_detail.php`.
4. **Styles:**
   - Add CSS for `.vibe-badge`, `.price-band`, and `.friend-review-card` in `public/static/site.css`.
5. **Hostinger Upload:**
   - Upload modified PHP and CSS files to Hostinger File Manager under `public_html/`.
