from decimal import Decimal

from django.core.management.base import BaseCommand
from django.utils import timezone

from cafes.models import Area, Cafe, CafeOffering


class Command(BaseCommand):
    help = "Seeds selected specialty cafes in Lucknow for pilot testing."

    def handle(self, *args, **options):
        # 1. Ensure Lucknow areas exist
        gomti_nagar, _ = Area.objects.get_or_create(
            slug="gomti-nagar", defaults={"name": "Gomti Nagar", "city": "Lucknow"}
        )
        hazratganj, _ = Area.objects.get_or_create(
            slug="hazratganj", defaults={"name": "Hazratganj", "city": "Lucknow"}
        )
        golf_city, _ = Area.objects.get_or_create(
            slug="sushant-golf-city", defaults={"name": "Sushant Golf City", "city": "Lucknow"}
        )
        aliganj, _ = Area.objects.get_or_create(
            slug="aliganj", defaults={"name": "Aliganj", "city": "Lucknow"}
        )
        mahanagar, _ = Area.objects.get_or_create(
            slug="mahanagar", defaults={"name": "Mahanagar", "city": "Lucknow"}
        )
        ashiyana, _ = Area.objects.get_or_create(
            slug="ashiyana", defaults={"name": "Ashiyana", "city": "Lucknow"}
        )

        lucknow_cafes_data = [
            {
                "name": "Roastery Coffee House",
                "area": gomti_nagar,
                "address": "Bungalow No 4, Gomti Nagar",
                "lat": Decimal("26.8467"),
                "lon": Decimal("80.9462"),
                "is_active": True,
                "is_verified_independent": False,
                "worldwide_locations_count": 8,
                "drink": "espresso",
                "price": Decimal("180"),
            },
            {
                "name": "Overflow Coffee",
                "area": golf_city,
                "address": "Sushant Golf City",
                "lat": Decimal("26.7820"),
                "lon": Decimal("81.0125"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "filter",
                "price": Decimal("220"),
            },
            {
                "name": "The Hazelnut Factory",
                "area": hazratganj,
                "address": "Ashok Marg, Hazratganj",
                "lat": Decimal("26.8512"),
                "lon": Decimal("80.9405"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 5,
                "drink": "espresso",
                "price": Decimal("190"),
            },
            {
                "name": "The Fresh Factory",
                "area": gomti_nagar,
                "address": "Gomti Nagar",
                "lat": Decimal("26.8480"),
                "lon": Decimal("80.9900"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "cold_brew",
                "price": Decimal("200"),
            },
            {
                "name": "The Cherry Tree Bakery & Cafe",
                "area": hazratganj,
                "address": "Hazratganj",
                "lat": Decimal("26.8504"),
                "lon": Decimal("80.9395"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 3,
                "drink": "tea",
                "price": Decimal("120"),
            },
            {
                "name": "Chacoco Cafe",
                "area": mahanagar,
                "address": "Mahanagar",
                "lat": Decimal("26.8780"),
                "lon": Decimal("80.9480"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "espresso",
                "price": Decimal("210"),
            },
            {
                "name": "Let's Bake Stories",
                "area": gomti_nagar,
                "address": "Gomti Nagar",
                "lat": Decimal("26.8490"),
                "lon": Decimal("80.9910"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "espresso",
                "price": Decimal("190"),
            },
            {
                "name": "HoNS (House of No Sugar)",
                "area": gomti_nagar,
                "address": "Gomti Nagar",
                "lat": Decimal("26.8500"),
                "lon": Decimal("80.9920"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "filter",
                "price": Decimal("170"),
            },
            {
                "name": "Cappuccino Blast",
                "area": hazratganj,
                "address": "Mall Avenue",
                "lat": Decimal("26.8390"),
                "lon": Decimal("80.9450"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 3,
                "drink": "espresso",
                "price": Decimal("160"),
            },
            {
                "name": "Mocha Cafe & Bar",
                "area": gomti_nagar,
                "address": "Gomti Nagar",
                "lat": Decimal("26.8475"),
                "lon": Decimal("80.9950"),
                "is_active": True,
                "is_verified_independent": False,
                "worldwide_locations_count": 15,
                "drink": "espresso",
                "price": Decimal("250"),
            },
            {
                "name": "Sidewalk Bakehouse & Cafe",
                "area": gomti_nagar,
                "address": "Gomti Nagar",
                "lat": Decimal("26.8485"),
                "lon": Decimal("80.9960"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "espresso",
                "price": Decimal("180"),
            },
            {
                "name": "Melting Point",
                "area": gomti_nagar,
                "address": "Gomti Nagar",
                "lat": Decimal("26.8495"),
                "lon": Decimal("80.9970"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "milk",
                "price": Decimal("190"),
            },
            {
                "name": "Sassy Canteen",
                "area": gomti_nagar,
                "address": "Gomti Nagar",
                "lat": Decimal("26.8505"),
                "lon": Decimal("80.9980"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "espresso",
                "price": Decimal("220"),
            },
            {
                "name": "Chihiro",
                "area": mahanagar,
                "address": "Mahanagar",
                "lat": Decimal("26.8790"),
                "lon": Decimal("80.9490"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "matcha",
                "price": Decimal("240"),
            },
            {
                "name": "Talllk",
                "area": gomti_nagar,
                "address": "Gomti Nagar",
                "lat": Decimal("26.8510"),
                "lon": Decimal("80.9990"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "espresso",
                "price": Decimal("180"),
            },
            {
                "name": "The Comma",
                "area": hazratganj,
                "address": "Hazratganj",
                "lat": Decimal("26.8490"),
                "lon": Decimal("80.9400"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "cold_brew",
                "price": Decimal("210"),
            },
            {
                "name": "Criolo",
                "area": mahanagar,
                "address": "Mahanagar",
                "lat": Decimal("26.8770"),
                "lon": Decimal("80.9470"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "espresso",
                "price": Decimal("190"),
            },
            {
                "name": "NBC (Nothing Before Coffee)",
                "area": gomti_nagar,
                "address": "Gomti Nagar",
                "lat": Decimal("26.8480"),
                "lon": Decimal("80.9950"),
                "is_active": True,
                "is_verified_independent": False,
                "worldwide_locations_count": 45,
                "drink": "espresso",
                "price": Decimal("150"),
            },
            {
                "name": "TWC (The White Cafe)",
                "area": gomti_nagar,
                "address": "Gomti Nagar",
                "lat": Decimal("26.8470"),
                "lon": Decimal("80.9940"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "espresso",
                "price": Decimal("200"),
            },
        ]

        now = timezone.now()
        created_cafes = 0

        for cd in lucknow_cafes_data:
            indep_status = (
                "verified_independent"
                if cd["is_verified_independent"]
                else "verified_not_independent"
            )
            cafe, created = Cafe.objects.get_or_create(
                name=cd["name"],
                area=cd["area"],
                defaults={
                    "address": cd["address"],
                    "latitude": cd["lat"],
                    "longitude": cd["lon"],
                    "is_active": cd["is_active"],
                    "is_demo": True,
                    "independence_status": indep_status,
                    "brand_location_count": cd["worldwide_locations_count"],
                    "brand_count_scope": "worldwide",
                    "brand_count_source": "Staff confirmation",
                    "brand_count_checked_on": now.date(),
                    "independence_source": "Staff confirmation"
                    if cd["is_verified_independent"]
                    else "Chain check",
                    "independence_checked_on": now.date(),
                    "source": "Web Research",
                    "checked_on": now.date(),
                },
            )

            if created:
                created_cafes += 1
                CafeOffering.objects.create(
                    cafe=cafe,
                    drink_type=cd["drink"],
                    price=cd["price"],
                    currency="INR",
                    source="Menu",
                    checked_on=now.date(),
                )

        self.stdout.write(self.style.SUCCESS(f"Successfully seeded {created_cafes} Lucknow cafes!"))
