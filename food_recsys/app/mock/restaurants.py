"""Restaurant seed data: 32 Lucknow pilot cafes + 48 diverse multi-cuisine restaurants."""

import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.restaurant import Restaurant

# Shared UUIDs and public details are generated from the PHP catalogue seed.
# The JSON snapshot travels with standalone/Docker builds; live exports use the same sync.
import json
from app.catalogue.sync import SNAPSHOT, sync_public_catalogue, insert_restaurant_if_absent

CAFE_APP_SEEDS = json.loads(SNAPSHOT.read_text())["restaurants"]

# 48 Additional diverse restaurants across South Indian, Biryani, Mughlai, Street Food, Asian, Fine Dining
ADDITIONAL_RESTAURANTS = [
    # --- SOUTH INDIAN ---
    {"name": "Sagar Ratna (Hazratganj)", "city": "Lucknow", "area": "Hazratganj", "address": "15, Ashok Marg, Hazratganj", "cuisines": ["south_indian", "breakfast"], "price_band": "budget", "avg_rating": 4.5},
    {"name": "Sagar Ratna (Gomti Nagar)", "city": "Lucknow", "area": "Gomti Nagar", "address": "TCG 1/1, Vibhuti Khand, Gomti Nagar", "cuisines": ["south_indian", "breakfast"], "price_band": "budget", "avg_rating": 4.4},
    {"name": "Curry Leaf (South Indian Flavours)", "city": "Lucknow", "area": "Hazratganj", "address": "Shop 4, Habibullah Estate, Hazratganj", "cuisines": ["south_indian", "tea_coffee"], "price_band": "budget", "avg_rating": 4.6},
    {"name": "Dakshin Udupi Cafe", "city": "Lucknow", "area": "Aliganj", "address": "Sector Q, Aliganj Main Rd", "cuisines": ["south_indian", "breakfast"], "price_band": "budget", "avg_rating": 4.3},
    {"name": "Swami Dosa Corner", "city": "Lucknow", "area": "Indira Nagar", "address": "Near Munshi Pulia Chauraha, Indira Nagar", "cuisines": ["south_indian", "street_food"], "price_band": "budget", "avg_rating": 4.2},
    {"name": "Saravana Delights", "city": "Lucknow", "area": "Gomti Nagar", "address": "Patrakarpuram, Gomti Nagar", "cuisines": ["south_indian", "breakfast"], "price_band": "budget", "avg_rating": 4.4},
    {"name": "Naivedyam Express", "city": "Lucknow", "area": "Hazratganj", "address": "MG Marg, Hazratganj", "cuisines": ["south_indian", "tea_coffee"], "price_band": "moderate", "avg_rating": 4.5},
    {"name": "Madras Tiffin Room", "city": "Lucknow", "area": "Badshahnagar", "address": "Metro Commercial Complex, Badshahnagar", "cuisines": ["south_indian", "breakfast"], "price_band": "budget", "avg_rating": 4.3},

    # --- BIRYANI & MUGHLAI ---
    {"name": "Idris Biryani", "city": "Lucknow", "area": "Chowk", "address": "Opposite Pata Nala, Raja Bazar, Chowk", "cuisines": ["biryani", "mughlai"], "price_band": "budget", "avg_rating": 4.7},
    {"name": "Tundey Kababi (Aminabad)", "city": "Lucknow", "area": "Aminabad", "address": "168/6, Naaz Cinema Road, Aminabad", "cuisines": ["mughlai", "biryani"], "price_band": "budget", "avg_rating": 4.8},
    {"name": "Tundey Kababi (Gomti Nagar)", "city": "Lucknow", "area": "Gomti Nagar", "address": "Kapoor Market, Patrakarpuram, Gomti Nagar", "cuisines": ["mughlai", "biryani"], "price_band": "budget", "avg_rating": 4.6},
    {"name": "Dastarkhwan (Tulsi Theatre)", "city": "Lucknow", "area": "Hazratganj", "address": "Near Tulsi Theatre, Lalbagh, Hazratganj", "cuisines": ["biryani", "mughlai", "north_indian_curry"], "price_band": "moderate", "avg_rating": 4.6},
    {"name": "Dastarkhwan (Gomti Nagar)", "city": "Lucknow", "area": "Gomti Nagar", "address": "Bhavya Corporate Tower, Vibhuti Khand", "cuisines": ["biryani", "mughlai"], "price_band": "moderate", "avg_rating": 4.5},
    {"name": "Wahid Biryani", "city": "Lucknow", "area": "Aminabad", "address": "Old Naz Cinema Road, Aminabad", "cuisines": ["biryani", "mughlai"], "price_band": "budget", "avg_rating": 4.4},
    {"name": "Naushijaan Awadhi Flavours", "city": "Lucknow", "area": "Hazratganj", "address": "Press Club, Near DM Residence, Hazratganj", "cuisines": ["mughlai", "biryani"], "price_band": "moderate", "avg_rating": 4.6},
    {"name": "Behrouz Biryani (Cloud Kitchen)", "city": "Lucknow", "area": "Gomti Nagar", "address": "Vibhuti Khand, Gomti Nagar", "cuisines": ["biryani"], "price_band": "moderate", "avg_rating": 4.3},

    # --- NORTH INDIAN & DHABA ---
    {"name": "Royal Cafe (Hazratganj)", "city": "Lucknow", "area": "Hazratganj", "address": "51, MG Marg, Hazratganj", "cuisines": ["north_indian_curry", "street_food", "mughlai"], "price_band": "moderate", "avg_rating": 4.6},
    {"name": "Moti Mahal Deluxe", "city": "Lucknow", "area": "Hazratganj", "address": "75, MG Marg, Hazratganj", "cuisines": ["north_indian_curry", "mughlai"], "price_band": "moderate", "avg_rating": 4.4},
    {"name": "Pind Balluchi", "city": "Lucknow", "area": "Gomti Nagar", "address": "Riverside Mall, Vipin Khand, Gomti Nagar", "cuisines": ["north_indian_curry", "mughlai"], "price_band": "moderate", "avg_rating": 4.3},
    {"name": "Punjabi Chulha", "city": "Lucknow", "area": "Aliganj", "address": "Kapoorthala Chauraha, Aliganj", "cuisines": ["north_indian_curry", "street_food"], "price_band": "budget", "avg_rating": 4.2},
    {"name": "Kava at Fairfield by Marriott", "city": "Lucknow", "area": "Gomti Nagar", "address": "Vibhuti Khand, Gomti Nagar", "cuisines": ["north_indian_curry", "continental"], "price_band": "premium", "avg_rating": 4.6},
    {"name": "Falak Numa (Hotel Clarks Avadh)", "city": "Lucknow", "area": "Hazratganj", "address": "8, MG Marg, Hazratganj", "cuisines": ["mughlai", "north_indian_curry"], "price_band": "luxury", "avg_rating": 4.7},

    # --- STREET FOOD, CHAAT & CHAI ---
    {"name": "Sharma Tea Stall", "city": "Lucknow", "area": "Hazratganj", "address": "1, Nawal Kishore Road, Lalbagh, Hazratganj", "cuisines": ["tea_coffee", "street_food"], "price_band": "budget", "avg_rating": 4.6},
    {"name": "King of Chaat", "city": "Lucknow", "area": "Hazratganj", "address": "MG Marg, Hazratganj", "cuisines": ["street_food"], "price_band": "budget", "avg_rating": 4.5},
    {"name": "Royal Cafe Basket Chaat", "city": "Lucknow", "area": "Hazratganj", "address": "Hazratganj Chauraha", "cuisines": ["street_food"], "price_band": "budget", "avg_rating": 4.7},
    {"name": "Netram Sweets & Kachori", "city": "Lucknow", "area": "Aminabad", "address": "Mohan Market, Aminabad", "cuisines": ["street_food", "breakfast", "dessert"], "price_band": "budget", "avg_rating": 4.6},
    {"name": "Ratti Ke Khaste", "city": "Lucknow", "area": "Hazratganj", "address": "Rani Laxmi Bai Marg, Hazratganj", "cuisines": ["street_food", "breakfast"], "price_band": "budget", "avg_rating": 4.5},
    {"name": "Chai Point", "city": "Lucknow", "area": "Gomti Nagar", "address": "One Awadh Center Mall, Vibhuti Khand", "cuisines": ["tea_coffee", "street_food"], "price_band": "budget", "avg_rating": 4.3},
    {"name": "Chaayos", "city": "Lucknow", "area": "Gomti Nagar", "address": "Phoenix United / DLF MyPad", "cuisines": ["tea_coffee", "street_food"], "price_band": "budget", "avg_rating": 4.4},
    {"name": "RollsKing", "city": "Lucknow", "area": "Indira Nagar", "address": "Bhootnath Market, Indira Nagar", "cuisines": ["street_food", "burger"], "price_band": "budget", "avg_rating": 4.1},

    # --- CHINESE, ASIAN & MOMOS ---
    {"name": "Mainland China", "city": "Lucknow", "area": "Gomti Nagar", "address": "Riverside Mall, Vipin Khand, Gomti Nagar", "cuisines": ["chinese_indo"], "price_band": "premium", "avg_rating": 4.5},
    {"name": "Berco's (Garden Galleria)", "city": "Lucknow", "area": "Gomti Nagar", "address": "Ground Floor, Cyber Heights, Vibhuti Khand", "cuisines": ["chinese_indo"], "price_band": "moderate", "avg_rating": 4.4},
    {"name": "Nainital Momos (Gomti Nagar)", "city": "Lucknow", "area": "Gomti Nagar", "address": "Patrakarpuram Chauraha, Gomti Nagar", "cuisines": ["street_food", "chinese_indo"], "price_band": "budget", "avg_rating": 4.3},
    {"name": "Nainital Momos (Hazratganj)", "city": "Lucknow", "area": "Hazratganj", "address": "Janpath Market, Hazratganj", "cuisines": ["street_food", "chinese_indo"], "price_band": "budget", "avg_rating": 4.3},
    {"name": "Wok to Walk", "city": "Lucknow", "area": "Sushant Golf City", "address": "Phoenix Palassio, Food Court", "cuisines": ["chinese_indo"], "price_band": "budget", "avg_rating": 4.2},
    {"name": "Chung Fa Chinese Restaurant", "city": "Lucknow", "area": "Hazratganj", "address": "57, Gokhale Marg, Hazratganj", "cuisines": ["chinese_indo"], "price_band": "moderate", "avg_rating": 4.4},

    # --- PIZZA, BURGER & FAST FOOD ---
    {"name": "Domino's Pizza (Hazratganj)", "city": "Lucknow", "area": "Hazratganj", "address": "Mayfair Building, Hazratganj", "cuisines": ["pizza"], "price_band": "budget", "avg_rating": 4.2},
    {"name": "Domino's Pizza (Gomti Nagar)", "city": "Lucknow", "area": "Gomti Nagar", "address": "Patrakarpuram, Gomti Nagar", "cuisines": ["pizza"], "price_band": "budget", "avg_rating": 4.3},
    {"name": "Pizza Hut (Phoenix Palassio)", "city": "Lucknow", "area": "Sushant Golf City", "address": "Phoenix Palassio Mall, Amar Shaheed Path", "cuisines": ["pizza"], "price_band": "moderate", "avg_rating": 4.1},
    {"name": "Burger King (Hazratganj)", "city": "Lucknow", "area": "Hazratganj", "address": "MG Marg, Hazratganj", "cuisines": ["burger"], "price_band": "budget", "avg_rating": 4.3},
    {"name": "McDonald's (Riverside Mall)", "city": "Lucknow", "area": "Gomti Nagar", "address": "Riverside Mall, Vipin Khand, Gomti Nagar", "cuisines": ["burger"], "price_band": "budget", "avg_rating": 4.4},
    {"name": "La Pino'z Pizza (Aliganj)", "city": "Lucknow", "area": "Aliganj", "address": "Kapoorthala Chauraha, Aliganj", "cuisines": ["pizza"], "price_band": "budget", "avg_rating": 4.2},

    # --- DESSERT & HEALTHY ---
    {"name": "Nirula's Ice Cream & Shakes", "city": "Lucknow", "area": "Hazratganj", "address": "Habibullah Estate, Hazratganj", "cuisines": ["dessert"], "price_band": "budget", "avg_rating": 4.3},
    {"name": "Natural Ice Cream (Gomti Nagar)", "city": "Lucknow", "area": "Gomti Nagar", "address": "Vivek Khand 1, Near Neelkanth Sweets", "cuisines": ["dessert"], "price_band": "budget", "avg_rating": 4.7},
    {"name": "Baskin Robbins (Hazratganj)", "city": "Lucknow", "area": "Hazratganj", "address": "Shop 12, Janpath, Hazratganj", "cuisines": ["dessert"], "price_band": "budget", "avg_rating": 4.4},
    {"name": "The Belgian Waffle Co.", "city": "Lucknow", "area": "Gomti Nagar", "address": "Patrakarpuram Chauraha, Gomti Nagar", "cuisines": ["dessert", "bakery"], "price_band": "budget", "avg_rating": 4.5},
    {"name": "Subway (One Awadh Center)", "city": "Lucknow", "area": "Gomti Nagar", "address": "Vibhuti Khand, Gomti Nagar", "cuisines": ["healthy", "burger"], "price_band": "budget", "avg_rating": 4.2},
    {"name": "Salad Days Express", "city": "Lucknow", "area": "Gomti Nagar", "address": "DLF MyPad, Vibhuti Khand", "cuisines": ["healthy"], "price_band": "moderate", "avg_rating": 4.4},
]


async def seed_restaurants(session: AsyncSession) -> int:
    """Add missing seed rows safely across workers; preserve live/manual enrichment."""
    count = await sync_public_catalogue(
        session, {"schema_version": 1, "restaurants": CAFE_APP_SEEDS}, origin="bundle",
    )
    # Retain legacy random-UUID seed records by name, without modifying manual rows.
    for seed in sorted(ADDITIONAL_RESTAURANTS, key=lambda row: row["name"].casefold()):
        existing = (await session.execute(
            select(Restaurant.id).where(Restaurant.name == seed["name"]).limit(1)
        )).scalar_one_or_none()
        if existing is not None:
            continue
        restaurant_id = str(uuid.uuid5(uuid.NAMESPACE_URL, f"food-recsys:seed-restaurant:{seed['name'].casefold()}"))
        count += int(await insert_restaurant_if_absent(session, {
            **seed, "id": restaurant_id, "source": "manual", "is_active": True,
        }))
    await session.commit()
    return count
