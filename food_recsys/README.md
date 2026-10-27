# Food RecSys — UPI Payment-Based Food Recommendation Engine

**26 October 2026 mapping update:** mobile imports now use the versioned structured payment
endpoint, with duplicate-safe identities and explicit per-record outcomes. See
[verification and upgrade notes](../MOBILE_MAPPING_VERIFICATION.md).

> **"Spotify for Food"** — A personalized recommendation engine that learns what you actually eat from UPI payment history and recommends restaurants you'll love with transparent reasoning.

---

## 1. Differentiator

Traditional recommendation tools rely on public 5-star ratings or paid sponsorships. **Food RecSys** uses your **actual UPI spending behavior**:
- Which cuisines you spend money on regularly (e.g. South Indian breakfast vs. late-night Biryani).
- What your typical spending band is (Budget ≤₹150, Moderate ₹151–400, Premium ₹401–800, Luxury >₹800).
- When you eat out (weekday lunch vs. weekend dinner patterns).
- Factual, data-backed reasoning: *"South Indian accounts for 88% of your food spending"*, *"Fits your budget tier (avg ₹187/meal)"*.

---

## 2. Architecture & Modules

```
food_recsys/
├── app/
│   ├── api/                     # REST API Endpoints (FastAPI)
│   │   ├── health.py            # GET /health
│   │   ├── ingest.py            # POST /api/v1/ingest, POST /api/v1/ingest/mock/generate
│   │   ├── profile.py           # GET /api/v1/profile/{user_id}, POST /api/v1/profile/{user_id}/rebuild
│   │   ├── recommend.py         # GET /api/v1/recommend/{user_id} (top-N with reasons)
│   │   ├── restaurants.py       # GET /api/v1/restaurants (catalogue search & filter)
│   │   └── router.py            # API Router aggregator
│   ├── db/
│   │   └── session.py           # Async SQLAlchemy session factory (SQLite & Postgres)
│   ├── ingestion/               # Ingestion pipeline
│   │   ├── mcc_classifier.py    # Food vs non-food MCC code detection (5812, 5814, 5462, etc.)
│   │   ├── merchant_resolver.py # Merchant cleaning, cuisine inference, meal type, price band
│   │   └── pipeline.py          # Batch ingestion & FoodPurchase classification
│   ├── mock/                    # Synthetic data generators
│   │   ├── restaurants.py       # 80 restaurants (32 from Lucknow cafe-discovery-app + 48 diverse spots)
│   │   └── transactions.py      # 90-day UPI transaction generator for 3 personas
│   ├── models/                  # SQLAlchemy 2.0 ORM models
│   │   ├── base.py
│   │   ├── profile.py           # TasteProfile (affinities, price dist, meal patterns)
│   │   ├── recommendation.py   # RecommendationLog (audit & analytics)
│   │   ├── restaurant.py        # Restaurant catalogue
│   │   └── transaction.py       # UpiTransaction & FoodPurchase
│   ├── profile/
│   │   └── builder.py           # Taste Profile computation & versioning
│   ├── recsys/                  # Recommendation engine
│   │   ├── engine.py            # Candidate retrieval, scoring & ranking
│   │   ├── explainer.py         # Human-readable reasoning generator
│   │   └── scoring.py           # C/P/N/G affinity scoring formula
│   ├── schemas/                 # Pydantic schemas (type safety & validation)
│   ├── templates/
│   │   └── index.html           # Interactive demo dashboard (Jinja2)
│   ├── config.py                # Pydantic BaseSettings
│   └── main.py                  # FastAPI application entrypoint & lifespan seeder
├── tests/                       # Complete automated test suite (13 tests)
│   ├── conftest.py
│   ├── test_api.py
│   ├── test_ingestion.py
│   ├── test_profile.py
│   └── test_recsys.py
├── cli.py                       # Command-line runner for instant terminal testing
├── Dockerfile                   # Production Python 3.12 image
├── docker-compose.yml           # App + PostgreSQL 16 multi-container setup
├── requirements.txt             # Dependencies
└── README.md
```

---

## 3. Quickstart

### Option A: Local Run (Zero-Config SQLite)

```bash
cd food_recsys

# 1. Activate virtual environment
source .venv/bin/activate  # or create one: python3 -m venv .venv && source .venv/bin/activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Start the application
uvicorn app.main:app --reload --port 8000
```

- Open the **Interactive Demo Dashboard**: [http://localhost:8000](http://localhost:8000)
- Open the **Swagger API Docs**: [http://localhost:8000/docs](http://localhost:8000/docs)

### Option B: Docker Compose (PostgreSQL 16)

```bash
cd food_recsys
docker compose up --build
```

### Option C: CLI Runner

Test recommendations instantly in your terminal for any persona:

```bash
# South Indian persona
python cli.py --persona south_indian_regular -n 3

# Cafe hopper persona
python cli.py --persona cafe_hopper -n 3

# Budget student persona
python cli.py --persona budget_student -n 3
```

---

## 4. Personas in the MVP

| Persona Key | User ID | Spending Profile | Top Recommendations |
|---|---|---|---|
| `south_indian_regular` | `user_south_indian` | 88% South Indian, avg ₹187/meal, morning breakfast peaks | Naivedyam Express, Sagar Ratna, Saravana Delights |
| `cafe_hopper` | `user_cafe_hopper` | 88% Café & Coffee, avg ₹550/meal, premium spending tier | The Hazelnut Factory, Mocha Cafe, Roastery Coffee House |
| `budget_student` | `user_budget_student` | 84% Street food, avg ₹111/meal, evening & late-night bites | King of Chaat, Ratti Ke Khaste, Nainital Momos |

---

## 5. API Reference

### 1. Recommendations
```http
GET /api/v1/recommend/{user_id}?n=5&meal=dinner&area=Hazratganj
```
Returns top-N restaurants scored with transparent reasons:
```json
{
  "user_id": "user_south_indian",
  "meal_context": "dinner",
  "algorithm": "cpng_v1_content_affinity",
  "count": 5,
  "recommendations": [
    {
      "rank": 1,
      "restaurant": {
        "id": "...",
        "name": "Naivedyam Express",
        "city": "Lucknow",
        "area": "Hazratganj",
        "cuisines": ["south_indian", "tea_coffee"],
        "price_band": "moderate"
      },
      "score": 0.85,
      "reasons": [
        "South Indian is your #1 food preference (88% of your UPI food spending)",
        "Fits your typical moderate spending band (66% of your meals, avg ₹187/order)",
        "New discovery — you haven't paid at this spot yet"
      ],
      "score_breakdown": {
        "cuisine_score": 0.88,
        "price_score": 0.79,
        "novelty_score": 1.0,
        "geo_score": 0.5,
        "total_score": 0.85
      }
    }
  ]
}
```

### 2. User Taste Profile
```http
GET /api/v1/profile/{user_id}
POST /api/v1/profile/{user_id}/rebuild
```

### 3. Ingest Transactions (Batch, SMS, or Bank Statement)

#### A. Direct Batch Ingest
```http
POST /api/v1/ingest
```
Upload structured batch of transactions with `mcc_code`, `merchant_name`, `amount`, `transaction_time`.

#### B. Real-World Bank / UPI SMS Ingest
```http
POST /api/v1/ingest/sms
Content-Type: application/json

{
  "user_id": "user_123",
  "sms_text": "Sent Rs.340.00 from HDFC Bank A/C **1234 to ROASTERY COFFEE HOUSE on 24-OCT-26 via UPI Ref 429812456789."
}
```
*Supports alerts from HDFC, SBI, ICICI, Axis, Kotak, Google Pay, PhonePe, and Paytm.*

#### C. Bank Statement CSV Upload
```http
POST /api/v1/ingest/statement
Content-Type: multipart/form-data

user_id="user_123"
file=@statement.csv
```
*Parses CSV statement exports from HDFC, SBI, ICICI, and Axis net banking, automatically extracting dining debits and filtering out salaries, investments, and ATM withdrawals.*

### 4. Generate Mock Data
```http
POST /api/v1/ingest/mock/generate?persona=cafe_hopper&days=90
```

---

## 6. Running Tests

```bash
cd food_recsys
pytest -v
```
The suite covers ingestion, profile aggregation, recommendation scoring, API contracts,
concurrent imports, ledger pagination, and catalogue synchronization. Record actual results
from the command rather than assuming an earlier test count still applies.

## 7. Structured mobile imports and public catalogue sync

`POST /api/v1/ingest/payments` accepts `schema_version: 1`, `user_id`, and `payments`.
Each payment contains a stable `source_id`, `merchant_name`, `amount`, and optional
`transaction_time`, `timezone`, `upi_ref`, `payment_app`, `cuisine`, and `dish_names`.
Raw SMS fields are rejected. The response includes `ingested_count`, `duplicate_count`,
`rejected_count`, `unresolved_count`, and an `outcomes` list echoing each `source_id`.
Unresolved is a subset of inserted payments without a specific restaurant branch.
The legacy SMS, statement, and direct-order endpoints remain available.

`GET /api/v1/profile/{user_id}/transactions?limit=100&cursor=...` returns whole-ledger
`total_count`/`total_spent`, the current page, `has_more`, and `next_cursor`. Unknown purchase
times remain unknown. Repeated legacy UPI references are reconciled in ledger/profile views
without deleting the underlying records. Records without a shared reliable identifier are
not speculatively merged.

The bundled 32-café public snapshot is generated from `php_app/schema/lucknow_cafes.sql`:

```bash
python scripts/export_seed_catalogue.py
python scripts/export_seed_catalogue.py --check
```

To transfer current catalogue edits/closures from an existing PHP database, run its read-only
public-field exporter in the PHP environment, then import the resulting JSON in Food RecSys:

```bash
php php_app/scripts/export_catalogue.php > public-catalogue.json
# From food_recsys/:
python -m app.catalogue.sync ../public-catalogue.json
```

Exports include explicit inactive flags and exclude circle notes and personal histories.
Imports preserve stable UUIDs, cuisine enrichment when omitted by PHP, and unrelated manual
records. A live export takes precedence over the bundled snapshot on restart. This is an
explicit synchronization step; changing the hosted database does not automatically contact
this separate backend. The mobile metadata endpoint supplies current areas/cuisines/meal options.
