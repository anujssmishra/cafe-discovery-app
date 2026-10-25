# Food RecSys Mobile (Android) — Flutter

A cross-platform Flutter application for Android that brings the **"Spotify for Food"** recommendation engine directly to mobile. It automatically detects UPI dining payment alerts from incoming SMS, strips PII on-device, and serves personalized restaurant recommendations with transparent, data-grounded explanations.

---

## 🌟 Key Features

1. **Automatic UPI Debit Tracking**:
   - Uses Android background SMS receiver to monitor transactional alerts from Indian banks (HDFC, SBI, ICICI, Axis, Kotak, Paytm, PhonePe, Google Pay).
   - Zero copy-paste friction: dining debits update your taste profile automatically.
2. **On-Device PII Stripping**:
   - Bank account digits (`**1234`), card numbers, available balances, and phone numbers are redacted in memory *before* any network dispatch.
3. **Factual Reasoning & Match Scoring**:
   - Shows match percentage alongside reasons (e.g. *"South Indian is your #1 food preference (88% of your UPI food spending)"*).
4. **Meal Context & Neighborhood Filters**:
   - Filter recommendations by meal time (Breakfast, Lunch, Evening Snack, Dinner) and area (Hazratganj, Gomti Nagar, Aliganj, etc.).
5. **Multi-Persona & Clean Slate**:
   - Easily switch between demo personas or tap **"My Real Profile"** to start fresh with 0 transactions.

---

## 📱 App Architecture

```
lib/
├── main.dart                       # App entry point & provider tree
├── config/
│   ├── constants.dart              # Default API URLs, personas, cuisines, sample SMS
│   └── theme.dart                  # Spotify-dark design system
├── models/
│   ├── restaurant.dart             # Restaurant schema
│   ├── taste_profile.dart          # Aggregated user taste profile
│   └── recommendation.dart         # Recommendations with C/P/N/G score breakdown
├── services/
│   ├── api_service.dart            # HTTP client for Food RecSys FastAPI backend
│   ├── on_device_sms_parser.dart   # Regex-based multi-bank SMS parser & PII redactor
│   └── sms_listener_service.dart   # Android Telephony listener + local notifications
├── providers/
│   ├── taste_provider.dart         # State management for taste profile & user switching
│   └── recs_provider.dart          # State management for recommendations & filters
├── screens/
│   ├── home_screen.dart            # 4-tab bottom navigation scaffold
│   ├── recommendations_tab.dart    # Feed of personalized restaurant picks
│   ├── taste_profile_tab.dart      # Spending intelligence, cuisine bars, price tiers
│   ├── sms_ingest_tab.dart         # Background tracker toggle & manual test simulator
│   └── settings_tab.dart           # API server URL config, profile reset, privacy audit
└── widgets/
    ├── rec_card.dart               # Restaurant card with score badge & verified tag
    ├── cuisine_bar.dart            # Animated horizontal progress bar
    └── persona_chip.dart           # Selectable persona pills
```

---

## 🚀 How to Run

### 1. Prerequisites
- **Flutter SDK** (version `>=3.0.0`)
- **Android Studio** with Android SDK (API 34) & Android Emulator (or a physical Android phone with USB debugging enabled).

### 2. Ensure Backend Server is Running
Make sure the Food RecSys backend is running on port 8000:
```bash
cd food_recsys
source .venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### 3. Install Mobile Dependencies & Run
```bash
cd food_recsys_mobile
flutter pub get
flutter run
```

---

## 🌐 Connecting to the Backend

- **Android Emulator**:
  The app is pre-configured to talk to `http://10.0.2.2:8000` (the Android emulator's loopback alias for the host machine's `localhost:8000`).
- **Physical Android Phone**:
  Open the **Settings** tab inside the app and enter your computer's local Wi-Fi IP address (e.g., `http://192.168.1.15:8000`), then tap **Save & Test Connection**.

---

## 🧪 Testing Automatic UPI Ingestion

### Option A: In-App SMS Simulator
1. Open the **Auto-Ingest** tab.
2. Tap any of the quick sample buttons (`+ HDFC Sample`, `+ SBI Sample`, `+ ICICI Sample`) or paste an SMS.
3. Tap **Parse & Ingest SMS** to watch the taste profile and recommendations instantly refresh.

### Option B: Android Emulator SMS Injection
1. Click the **"..."** (More) button on the Android Emulator sidebar.
2. Select **Phone** -> **SMS**.
3. Set the sender to `HDFCBK` or `SBIUPI` and paste:
   ```text
   Sent Rs.320.00 from HDFC Bank A/C **1234 to ROASTERY COFFEE HOUSE on 24-OCT-26 via UPI Ref 429812456789.
   ```
4. Click **Send Message**.
5. The Android app's background listener will capture the SMS, redact account digits, update your taste intelligence profile, and pop a notification:
   > 🍽️ *Taste Profile Updated! Detected ₹320 at ROASTERY COFFEE HOUSE. Recommendations refreshed.*
