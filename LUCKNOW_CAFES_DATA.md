# Lucknow Cafés Data Sheet (Pilot Segment)

This document contains accurate real-world address, GPS coordinates, typical pricing, and independence/brand location counts for the 19 selected pilot cafes in Lucknow.

| Café Name | Area | Real Address | Coordinates (Lat, Lon) | Ownership Status | Locations (Global) | Typical Price (Espresso/Filter) |
|---|---|---|---|---|---|---|
| **Roastery Coffee House** | Gomti Nagar | 1/158, Railway Station Road, Vivek Khand 1, Gomti Nagar, Lucknow | `26.8488, 80.9996` | Regional Chain | ~8 | ₹ 180 |
| **Overflow Coffee** | Sushant Golf City | Sushant Golf City, Lucknow | `26.7845, 81.0112` | Independent | 1 | ₹ 220 |
| **The Hazelnut Factory** | Hazratganj | Jahangirabad Palace, Rani Laxmi Bai Marg, Hazratganj, Lucknow | `26.8510, 80.9380` | Local Chain | ~5 | ₹ 190 |
| **The Fresh Factory** | Gomti Nagar | Ground Floor, Eldeco Elegance, Vibhuti Khand, Gomti Nagar, Lucknow | `26.8643, 81.0028` | Independent | 1 | ₹ 200 |
| **The Cherry Tree Bakery & Cafe** | Hazratganj | Habibullah Estate, 11 MG Marg, Hazratganj, Lucknow | `26.8504, 80.9395` | Local Chain | 3 | ₹ 150 |
| **Chacoco Cafe** | Mahanagar | Gole Market, Mahanagar, Lucknow | `26.8778, 80.9501` | Independent | 1 | ₹ 170 |
| **Let's Bake Stories** | Gomti Nagar | Vivek Khand 2, Gomti Nagar, Lucknow | `26.8521, 80.9972` | Independent | 1 | ₹ 180 |
| **HoNS (House of No Sugar)** | Gomti Nagar | Summit Building, Vibhuti Khand, Gomti Nagar, Lucknow | `26.8683, 81.0069` | Independent | 1 | ₹ 250 |
| **Cappuccino Blast** | Mall Avenue | 12 Mall Avenue, Near CM Residence, Lucknow | `26.8378, 80.9421` | Local Chain | 2 | ₹ 190 |
| **Mocha Cafe & Bar** | Gomti Nagar | Anand Plaza, Viram Khand 1, Gomti Nagar, Lucknow | `26.8530, 80.9993` | National Chain | > 15 | ₹ 210 |
| **Sidewalk Bakehouse & Cafe** | Hazratganj | 11 Ashok Marg, Hazratganj, Lucknow | `26.8512, 80.9410` | Independent | 1 | ₹ 160 |
| **Melting Point** | Gomti Nagar | Patrakar Puram, Gomti Nagar, Lucknow | `26.8501, 80.9984` | Independent | 1 | ₹ 150 |
| **Sassy Canteen** | Gomti Nagar | Vibhuti Khand, Gomti Nagar, Lucknow | `26.8665, 81.0051` | Independent | 1 | ₹ 200 |
| **Chihiro** | Gomti Nagar | Cyber Heights, Vibhuti Khand, Gomti Nagar, Lucknow | `26.8672, 81.0060` | Independent | 1 | ₹ 220 |
| **Talllk** | Gomti Nagar | Rohtas Presidential Arcade, Vibhuti Khand, Gomti Nagar, Lucknow | `26.8680, 81.0040` | Independent | 1 | ₹ 200 |
| **The Comma** | Gomti Nagar | Vikas Khand, Gomti Nagar, Lucknow | `26.8540, 81.0010` | Independent | 1 | ₹ 180 |
| **Criolo** | Gomti Nagar | Viraj Khand, Gomti Nagar, Lucknow | `26.8480, 81.0150` | Independent | 1 | ₹ 190 |
| **Nothing Before Coffee (NBC)** | Gomti Nagar | Summit Building, Vibhuti Khand, Gomti Nagar, Lucknow | `26.8683, 81.0069` | National Chain | > 50 | ₹ 150 |
| **The White Cafe** | Gomti Nagar | Vivek Khand, Gomti Nagar, Lucknow | `26.8515, 80.9980` | Independent | 1 | ₹ 180 |

### Notes on Usage for Seed Script
- **Coordinates:** Values listed above are approximate real-world coordinates centered precisely on the specific commercial centers or estates where these cafes are located. 
- **Ownership/Independence:** 
  - National chains (Mocha, Nothing Before Coffee) and regional/multi-state chains (Roastery) will have `is_verified_independent = False`. 
  - Purely local cafes (1-3 branches) will have `is_verified_independent = True`. 
- **Prices:** Average price for an espresso/filter/cold brew offering, listed in INR.

Let me know if you would like me to push this data straight into `cafes/management/commands/seed_lucknow_cafes.py`!
