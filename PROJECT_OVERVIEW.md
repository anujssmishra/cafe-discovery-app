# Café Discovery App — Master Project Overview

**Document Version:** 1.0.0  
**Last Updated:** October 2026  
**Status:** Deployed & Active (Pilot Release)  
**Primary Domain:** `myfanverse.in` (Hostinger Shared Web Hosting)

---

## 1. Executive Summary & Purpose

The **Café Discovery App** is an independent, community-focused web platform designed to help coffee lovers discover specialty coffee shops, third-wave roasters, and mindful café spaces.

Unlike massive aggregators (Google Maps, Zomato, Yelp), this application enforces **strict editorial integrity**:
* **No Pay-to-Win:** Listings are never boosted by ad spend.
* **Verified Provenance:** Every listing tracks when details were checked, what source was used, and distinguishes verified independent cafés from regional/national chains.
* **Privacy by Design:** Zero tracking pixels, no invasive geolocation requirements, and guest-first discovery.
* **Lightweight & Accessible:** Fast server-rendered pages that work without JavaScript, on slow mobile connections, and with full keyboard navigation.

---

## 2. Technical Stack

The project transitioned from a Python/Django prototype to a **production PHP/MySQL architecture** specifically optimized for shared hosting constraints (Hostinger) without losing database rigor or security.

```
+-----------------------------------------------------------------------+
|                             CLIENT TIER                               |
|       Any Browser / Mobile Device (Vanilla HTML5 + Responsive CSS)    |
+-----------------------------------------------------------------------+
                                   |
                                   | HTTPS Requests (GET)
                                   v
+-----------------------------------------------------------------------+
|                    WEB SERVER (LiteSpeed / Apache)                    |
|  - Hostinger Shared Web Hosting (`myfanverse.in`)                     |
|  - .htaccess: Enforces single-entry routing & blocks private .php    |
+-----------------------------------------------------------------------+
                                   |
                                   | Executes /public_html/index.php
                                   v
+-----------------------------------------------------------------------+
|                         APPLICATION RUNTIME                           |
|  - PHP 8.2+ (Strict typing enabled, zero heavy framework bloat)      |
|  - Router & Controllers: Lightweight parameter-filtered routing       |
|  - Security: PDO Prepared Statements, htmlspecialchars XSS escaping   |
|  - View Engine: Native PHP Templates (Header / Footer includes)       |
+-----------------------------------------------------------------------+
                                   |
                                   | PDO MySQL Driver
                                   v
+-----------------------------------------------------------------------+
|                          DATABASE ENGINE                              |
|  - MariaDB 10.11+ / MySQL 8.x (InnoDB, utf8mb4_unicode_ci)           |
|  - UUID Primary Keys (`CHAR(36)`)                                     |
|  - Strict FOREIGN KEY cascades and DB-level CHECK constraints         |
+-----------------------------------------------------------------------+
```

### Component Details

| Layer | Technology | Rationale & Responsibility |
|---|---|---|
| **Runtime** | **PHP 8.2+** | Native execution on Hostinger shared servers; fast bootstrap (<15ms), minimal memory footprint (<4MB per request). |
| **Database** | **MariaDB 10.11+ / MySQL 8.x** | Relational InnoDB storage with ACID compliance, foreign key cascades, and check constraints. |
| **DB Layer** | **PDO (`pdo_mysql`)** | Parameterized queries with prepared statements preventing SQL injection; strict exception mode. |
| **Frontend** | **Vanilla HTML5 & CSS** | Semantic, responsive CSS (`site.css`). Fast first-contentful-paint (FCP), zero build step, no npm bloat. |
| **Web Server** | **LiteSpeed / Apache** | Rewrite rules redirect clean URLs to `index.php`; `.htaccess` blocks public access to sensitive files. |
| **CI / Quality** | **GitHub Actions** | Automated CI pipeline verifying PHP syntax (`php -l`) and code integrity on push. |

---

## 3. System Architecture & Request Lifecycle

The application enforces a **clean separation of concerns** and a **two-tier security boundary**.

### Directory Structure

```text
cafe-discovery-app/
├── php_app/
│   ├── includes/                 # Core backend logic (Private)
│   │   ├── config.php            # Environment and credential loader
│   │   ├── db.php                # PDO database connection factory
│   │   ├── catalogue.php         # Catalogue querying and pagination logic
│   │   ├── request.php           # Sanitization and query parameter parsing
│   │   └── web.php               # HTML escape helpers and URL builders
│   ├── templates/                # UI Presentation (Server-rendered HTML)
│   │   ├── header.php            # Top banner, navigation, skip links
│   │   ├── footer.php            # Footer notes and closing markup
│   │   ├── catalogue.php         # Main explore page (grid of cafés + filters)
│   │   ├── cafe_detail.php       # Single café view (menu offerings + provenance)
│   │   ├── about.php             # Editorial methodology and standards
│   │   └── error.php             # Friendly fallback error pages (404/500)
│   ├── public/                   # Publicly served web entrypoint
│   │   ├── index.php             # Central Front Controller / Router
│   │   ├── .htaccess             # Apache rewrite rules and security deny blocks
│   │   └── static/
│   │       └── site.css          # Core stylesheet
│   ├── schema/                   # Database DDL and seed files
│   │   ├── schema.sql            # Table definitions, indices, and constraints
│   │   └── lucknow_cafes.sql     # Initial 19 verified pilot cafés & offerings
│   └── scripts/                  # CLI tools for development
│       ├── seed.php              # Guarded CLI synthetic demo data seeder
│       ├── schema.php            # Automated migration tool
│       └── package.php           # Hostinger ZIP packaging script
├── legacy_django/                # Archived Python prototype for historical reference
└── PROJECT_OVERVIEW.md           # This master architectural reference
```

### Request Flow

1. **Incoming Request:** User navigates to `https://myfanverse.in/` or `https://myfanverse.in/cafes/{uuid}`.
2. **Web Server Layer (`.htaccess`):** If the request matches an existing static asset (e.g. `/static/site.css`), LiteSpeed serves it directly. Otherwise, it forwards the request internally to `index.php`.
3. **Security Check:** `.htaccess` blocks any direct access to hidden files (`.*`) or arbitrary `.php` files inside subfolders.
4. **Router (`index.php`):**
   * Reads and parses `$_SERVER['REQUEST_URI']`.
   * Strips base paths and matches endpoints:
     - `/` or `/index.php` ➔ **Catalogue Action**
     - `/cafes/{uuid}` ➔ **Detail Action**
     - `/about/` ➔ **About Page**
     - Anything else ➔ **404 Error Action**
5. **Controller & Query Execution (`includes/`):**
   * Sanitizes query parameters (`?q=`, `?area=`, `?page=`).
   * Opens a persistent PDO connection via `db.php`.
   * Executes parameterized SQL queries with pagination offsets.
6. **View Rendering (`templates/`):**
   * Controller injects variables (`$cafes`, `$areas`, `$pagination`) into view templates.
   * `header.php` and `footer.php` wrap the page content.
   * Outputs HTML with `Content-Type: text/html; charset=UTF-8` and `X-Content-Type-Options: nosniff`.

---

## 4. Database Schema & Data Models

The relational database is normalized into three core tables with strict integrity rules.

```
+-------------------------------------------------+
|                      AREA                       |
+-------------------------------------------------+
| id            INT AUTO_INCREMENT PRIMARY KEY    |
| name          VARCHAR(120) NOT NULL             |
| slug          VARCHAR(140) NOT NULL UNIQUE      |
| city          VARCHAR(120) NOT NULL             |
| is_active     TINYINT(1) DEFAULT 1              |
| display_order INT DEFAULT 0                     |
+-------------------------------------------------+
                         | 1
                         |
                         | has many
                         v *
+-------------------------------------------------+
|                      CAFE                       |
+-------------------------------------------------+
| id                     CHAR(36) PRIMARY KEY     |  <-- UUID v4
| name                   VARCHAR(180) NOT NULL    |
| area_id                INT NOT NULL             |  <-- FK -> area.id
| address                TEXT NOT NULL            |
| summary                TEXT                     |
| latitude               DECIMAL(9,6) NULL        |
| longitude              DECIMAL(9,6) NULL        |
| website                VARCHAR(255)             |
| is_active              TINYINT(1) DEFAULT 1     |
| is_demo                TINYINT(1) DEFAULT 0     |
| brand_location_count   INT NULL                 |
| brand_count_scope      VARCHAR(40)              |
| brand_count_source     TEXT                     |
| brand_count_checked_on DATE NULL                |
| independence_status    VARCHAR(32)              |  <-- 'unknown' | 'verified_independent' | 'verified_not_independent'
| independence_source    TEXT                     |
| independence_checked_on DATE NULL               |
| source                 TEXT                     |
| checked_on             DATE NULL                |
+-------------------------------------------------+
                         | 1
                         |
                         | has many
                         v *
+-------------------------------------------------+
|                 CAFE_OFFERING                   |
+-------------------------------------------------+
| id             INT AUTO_INCREMENT PRIMARY KEY   |
| cafe_id        CHAR(36) NOT NULL                |  <-- FK -> cafe.id (CASCADE)
| drink_type     VARCHAR(20) NOT NULL             |  <-- 'espresso', 'filter', 'milk', 'cold_brew', 'tea', 'matcha'
| brewing_method VARCHAR(100) DEFAULT ''          |
| price          DECIMAL(8,2) NULL                |
| currency       CHAR(3) DEFAULT 'INR'            |
| checked_on     DATE NULL                        |
| source         TEXT                             |
+-------------------------------------------------+
```

### Key Schema Constraints

* **Paired Coordinates:** `CHECK ((latitude IS NULL AND longitude IS NULL) OR (latitude IS NOT NULL AND longitude IS NOT NULL))` ensures a café cannot have half-coordinates.
* **Coordinate Bounds:** Latitude is constrained between -90 and 90; longitude between -180 and 180.
* **Positive Branch Counts:** `CHECK (brand_location_count >= 1)` prevents zero or negative branch counts.
* **Enumerated Values:** `drink_type` and `independence_status` are restricted to controlled sets.
* **Non-negative Pricing:** `CHECK (price IS NULL OR price >= 0)`.

---

## 5. Pilot Dataset: Lucknow Speciality Cafés

The live pilot catalogue currently covers **19 verified coffee spots** across Lucknow, India, representing a balanced sample of local independent roasteries, specialty brands, and established regional groups.

| Café Name | Neighbourhood | Ownership Status | Primary Offering | Sample Price |
|---|---|---|---|---|
| **Overflow Coffee** | Sushant Golf City | Verified Independent | Filter coffee | ₹180 |
| **Let's Bake Stories** | Mall Avenue | Verified Independent | Espresso | ₹180 |
| **Chacoco Cafe** | Gomti Nagar | Verified Independent | Milk coffee | ₹150 |
| **Cappuccino Blast** | Hazratganj | Verified Independent | Espresso | ₹150 |
| **The Fresh Factory** | Gomti Nagar | Verified Independent | Cold brew | ₹200 |
| **Chihiro** | Cantonment | Verified Independent | Matcha | ₹190 |
| **Talllk** | Gomti Nagar | Verified Independent | Espresso | ₹160 |
| **The Comma** | Hazratganj | Verified Independent | Cold brew | ₹200 |
| **Sassy Canteen** | Badshahnagar | Verified Independent | Espresso | ₹180 |
| **Roastery Coffee House** | Gomti Nagar | Regional Chain (18 locations) | Espresso | ₹195 |
| **Third Wave Coffee** | Gomti Nagar | National Chain (100+ locations) | Espresso | ₹180 |
| **The Hazelnut Factory** | Hazratganj | Regional Chain (12 locations) | Milk coffee | ₹220 |
| **The Cherry Tree Bakery** | Hazratganj | Group (4 locations) | Espresso | ₹180 |
| **Mocha Cafe & Bar** | Gomti Nagar | Chain (25 locations) | Espresso | ₹175 |
| **Sidewalk Bakehouse** | Gomti Nagar | Group (4 locations) | Espresso | ₹200 |
| **Melting Point** | Gomti Nagar | Group (3 locations) | Milk coffee | ₹200 |
| **HoNS (House of No Sugar)**| Gomti Nagar | Group (3 locations) | Filter coffee | ₹160 |
| **Criolo** | Hazratganj | Group (5 locations) | Espresso | ₹150 |
| **Nothing Before Coffee** | Gomti Nagar | National Chain (60 locations) | Espresso | ₹90 |

---

## 6. Security & Hardening Strategy

1. **SQL Injection Defense:** All SQL operations utilize PDO prepared statements with explicit parameter binding (`:name`, `:slug`, `:id`). Raw variable interpolation in queries is strictly prohibited.
2. **Cross-Site Scripting (XSS):** Every dynamic output rendered in templates is wrapped through `htmlspecialchars($val, ENT_QUOTES, 'UTF-8')`.
3. **Directory Traversal Prevention:** The private code (`includes/`, `templates/`) and server credentials can sit above `public_html/`. The root `.htaccess` forbids execution of any `.php` files other than `index.php`.
4. **Credential Isolation:** Database credentials are passed through `.htaccess` environment variables (`SetEnv DB_USER ...`) or an isolated `config/local.php` outside the web root. No plain-text passwords exist in version control.
5. **Safe Failures:** Display of raw PHP error stack traces is disabled in production (`ini_set('display_errors', '0')`). Visitors receive a clean 503 or 404 template; error diagnostics are written only to protected server logs.

---

## 7. Deployment & Hosting Guide (Hostinger)

The application is deployed on **Hostinger Single Web Hosting** serving `myfanverse.in`.

### Deployment Steps Summary

1. **File Placement:**
   * Folders `includes/`, `templates/`, `schema/`, and `static/` reside in `public_html/`.
   * The entry script `index.php` sits directly in `public_html/index.php`.
   * Static stylesheet is reachable at `myfanverse.in/static/site.css`.
2. **Database Provisioning:**
   * MySQL/MariaDB database created in Hostinger hPanel (e.g. `u493193058_cafes`).
   * Structure imported via phpMyAdmin using `schema/schema.sql`.
   * Data populated via phpMyAdmin using `schema/lucknow_cafes.sql`.
3. **Database Configuration:**
   * Credentials configured via `.htaccess` (`SetEnv DB_NAME ...`) or `includes/config.php`.
4. **Subdomain Isolation:**
   * Existing sibling subdomains (`sitascanvas.myfanverse.in` and `anujssmishra.myfanverse.in`) live in independent subdirectories (`public_html/sitascanvas/`) and remain completely untouched.

---

## 8. Current Progression & Roadmap

* **Sprint 2 (Done):** Lightweight PHP/MySQL core architecture, 19 Lucknow cafés seeded, Hostinger deployment (`myfanverse.in`), live search, directions integration, Open Graph SEO.
* **Sprint 3 (Active):** **Friend-Informed Discovery & Private Circles** (Vibe taxonomy, food variety/quality badges, price bands, and "Friends' Take" private circle reviews).
* **Sprint 4 (Planned):** **Interactive Map View:** Optional client-side Leaflet.js map layer with custom coffee cup markers, respecting list fallbacks.
* **Sprint 5 (Planned):** **Member Taste Profiles & Private Saves:** Optional account creation allowing users to save preferred drink types, budget thresholds, and bookmarked venues.
* **Sprint 6 (Planned):** **Community Repeat Signal:** Collaborative recommendation weighting based on repeated visits rather than one-off ratings.

---

## 9. Sprint 3: Friend-Informed Discovery Architecture

Following primary user research conducted by Product Owner Anuj with his cohort, seven essential pre-visit decision factors were identified. Sprint 3 directly translates these insights into database models and user interfaces:

```
+-----------------------------------------------------------------------------------------+
|                                    USER RESEARCH FEEDBACK                               |
|  1. Food Quality   2. Food Variety   3. Ambiance   4. Aesthetics   5. Price   6. Location   |
|                                7. Reviews by friends, not public                        |
+-----------------------------------------------------------------------------------------+
                                             |
                                             v
+-----------------------------------------------------------------------------------------+
|                                  ARCHITECTURAL MAPPING                                  |
|  * Ambiance & Aesthetics   --->  Curated Vibe Tags (`Work & Study`, `Aesthetic / Cozy`)|
|  * Food Quality & Variety  --->  Food Highlights & Badges (`Fresh Bakery`, `Sourdough`)|
|  * Price Band              --->  3-Tier Spend Band (`₹`, `₹₹`, `₹₹₹`)                   |
|  * Location Navigation     --->  Clickable Address + Direct Maps Button [LIVE]          |
|  * Reviews by Friends      --->  "Friends' Take" Private Circle Notes (Zero Public Spam)|
+-----------------------------------------------------------------------------------------+
```

### 9.1 Vibe & Aesthetics Taxonomy

Cafés are tagged with a controlled vocabulary of recognizable ambiance styles:
* `Work & Study` (high table space, charging outlets, reliable Wi-Fi, low distraction)
* `Aesthetic & Cozy` (warm lighting, comfortable seating, visually curated decor, photo-friendly)
* `Garden & Outdoor` (open-air seating, greenery, natural breeze)
* `Minimalist & Quiet` (understated design, low ambient decibels, contemplative space)
* `Lively & Social` (vibrant music, group seating, conversational energy)
* `Date Spot` (intimate seating, mood lighting, refined atmosphere)

### 9.2 Food Quality & Variety Badging

* **Food Highlights:** Tags highlighting culinary specialties: `In-house Bakery`, `Artisan Sourdough`, `Specialty Desserts`, `All-Day Brunch`, `Vegan & Healthy`, `Savory Small Plates`.
* **Detail View Preview:** Dedicated "Food & Bakery" showcase section on café detail pages detailing food craft and provenance.

### 9.3 Price Band Indicator

* **`₹` (Budget):** Typical drink/snack under ₹150 per person.
* **`₹₹` (Moderate):** Typical specialty coffee and food ₹150–₹300 per person.
* **`₹₹₹` (Premium):** Single-origin pour-overs, artisan dining ₹300+ per person.

### 9.4 "Friends' Take" — Private Circle Reviews

Aggregator star reviews (Google Maps, Zomato) suffer from bot inflation, owner manipulation, and conflicting standards. Users explicitly requested **"Reviews by my friends, not public"**.

* **Architecture:**
  * Dedicated `friend_review` table linking trusted individuals to cafés.
  * Fields: `friend_name`, `visit_context` ("Late evening work sprint", "Weekend brunch"), `food_quality_verdict`, `ambiance_rating`, `must_try_item` ("Iced Spanish Latte + Almond Croissant"), `review_text`, `visited_on`.
  * **Zero Public Spam:** Only verified friends' recommendations appear. No public registration for anonymous trolling.

