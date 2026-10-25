#!/usr/bin/env python3
"""CLI utility to generate mock UPI data and print personalized restaurant recommendations."""

import asyncio
import argparse
from app.db.session import engine, AsyncSessionLocal
from app.models.base import Base
from app.mock.restaurants import seed_restaurants
from app.mock.transactions import generate_mock_transactions_for_persona, PERSONA_PROFILES
from app.ingestion.pipeline import ingest_transactions
from app.profile.builder import build_taste_profile
from app.recsys.engine import get_recommendations


async def run_cli(persona: str, n: int, meal: str | None, area: str | None):
    # 1. Initialize tables & seed catalogue
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as session:
        await seed_restaurants(session)

        # 2. Ingest mock transactions for chosen persona
        p = PERSONA_PROFILES[persona]
        user_id = p["user_id"]
        print(f"\n=======================================================")
        print(f"🍽️  FOOD RECSYS — UPI TASTE INTELLIGENCE")
        print(f"=======================================================")
        print(f"Selected Persona : {persona}")
        print(f"User ID          : {user_id}")
        print(f"Profile Bio      : {p['description']}")
        print(f"Generating 90-day UPI spending history...")

        mock_txs = generate_mock_transactions_for_persona(persona, days=90)
        res = await ingest_transactions(session, mock_txs)
        print(f"✓ Ingested {res.classified_food_count} food transactions (skipped {res.skipped_count} non-food)")

        # 3. Build & display taste profile
        profile = await build_taste_profile(session, user_id)
        print(f"\n--- Computed Taste Profile (v{profile.version}) ---")
        print(f"Average Spend : ₹{profile.avg_spend:.0f} per meal")
        print("Top Cuisines  :")
        for c, score in list(profile.cuisine_affinities.items())[:4]:
            print(f"  • {c.replace('_', ' ').title():<22} : {int(score*100)}%")
        print("Price Bands   :")
        for band, score in profile.price_distribution.items():
            print(f"  • {band.capitalize():<12} : {int(score*100)}%")

        # 4. Generate recommendations
        print(f"\n--- Top {n} Restaurant Recommendations ---")
        recs = await get_recommendations(session, user_id, n=n, meal_context=meal, area=area)

        for item in recs.recommendations:
            r = item.restaurant
            print(f"\n#{item.rank} {r.name.upper()} (Affinity: {int(item.score*100)}%)")
            print(f"   📍 {r.area}, {r.city} | Price: {r.price_band} | Cuisines: {', '.join(r.cuisines)}")
            print(f"   Score Breakdown: Cuisine {item.score_breakdown.cuisine_score:.2f} | Price {item.score_breakdown.price_score:.2f} | Novelty {item.score_breakdown.novelty_score:.2f}")
            print(f"   Why you'll like it:")
            for reason in item.reasons:
                print(f"     ✓ {reason}")

        print(f"\n=======================================================\n")

    await engine.dispose()


def main():
    parser = argparse.ArgumentParser(description="Food RecSys CLI Runner")
    parser.add_argument(
        "--persona",
        choices=list(PERSONA_PROFILES.keys()),
        default="south_indian_regular",
        help="Select user persona archetype",
    )
    parser.add_argument("-n", type=int, default=5, help="Number of recommendations")
    parser.add_argument("--meal", type=str, default=None, help="Meal context: breakfast, lunch, snack, dinner")
    parser.add_argument("--area", type=str, default=None, help="Filter by area e.g. Hazratganj, Gomti Nagar")
    args = parser.parse_args()

    asyncio.run(run_cli(args.persona, args.n, args.meal, args.area))


if __name__ == "__main__":
    main()
