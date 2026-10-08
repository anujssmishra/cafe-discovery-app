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
            slug="sushant-golf-city",
            defaults={"name": "Sushant Golf City", "city": "Lucknow"},
        )
        aliganj, _ = Area.objects.get_or_create(
            slug="aliganj", defaults={"name": "Aliganj", "city": "Lucknow"}
        )
        mall_avenue, _ = Area.objects.get_or_create(
            slug="mall-avenue",
            defaults={"name": "Mall Avenue", "city": "Lucknow"},
        )
        cantonment, _ = Area.objects.get_or_create(
            slug="cantonment",
            defaults={"name": "Cantonment", "city": "Lucknow"},
        )
        badshahnagar, _ = Area.objects.get_or_create(
            slug="badshahnagar",
            defaults={"name": "Badshahnagar", "city": "Lucknow"},
        )

        lucknow_cafes_data = [
            {
                "name": "Roastery Coffee House",
                "area": gomti_nagar,
                "address": "1/158, Railway Station Road, Vivek Khand 1, Gomti Nagar",
                "lat": Decimal("26.8580"),
                "lon": Decimal("81.0028"),
                "is_active": True,
                "is_verified_independent": False,
                "worldwide_locations_count": 18,
                "drink": "espresso",
                "price": Decimal("165"),
            },
            {
                "name": "Overflow Coffee",
                "area": golf_city,
                "address": (
                    "Ground Floor, Click Collection Hotel, Sector A,"
                    " Amar Shaheed Path, Sushant Golf City"
                ),
                "lat": Decimal("26.8042"),
                "lon": Decimal("81.0182"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "filter",
                "price": Decimal("200"),
            },
            {
                "name": "The Hazelnut Factory",
                "area": hazratganj,
                "address": ("Commercial Space 06, Hazratganj Metro Station, MG Marg, Hazratganj"),
                "lat": Decimal("26.8528"),
                "lon": Decimal("80.9465"),
                "is_active": True,
                "is_verified_independent": False,
                "worldwide_locations_count": 12,
                "drink": "espresso",
                "price": Decimal("150"),
            },
            {
                "name": "The Fresh Factory",
                "area": gomti_nagar,
                "address": "Kisan Bazar, Vibhuti Khand, Gomti Nagar",
                "lat": Decimal("26.8712"),
                "lon": Decimal("81.0065"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "cold_brew",
                "price": Decimal("180"),
            },
            {
                "name": "The Cherry Tree Bakery & Cafe",
                "area": hazratganj,
                "address": "11, Habibullah Estate Road, Hazratganj",
                "lat": Decimal("26.8519"),
                "lon": Decimal("80.9461"),
                "is_active": True,
                "is_verified_independent": False,
                "worldwide_locations_count": 3,
                "drink": "tea",
                "price": Decimal("150"),
            },
            {
                "name": "Chacoco Cafe",
                "area": gomti_nagar,
                "address": ("B4/186, Opposite LDA Market, Vishal Khand 4, Gomti Nagar"),
                "lat": Decimal("26.8504"),
                "lon": Decimal("80.9982"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "espresso",
                "price": Decimal("150"),
            },
            {
                "name": "Let's Bake Stories",
                "area": mall_avenue,
                "address": ("Rudraksh Complex, 17/17A Havelock Road, Near Mall Avenue"),
                "lat": Decimal("26.8373"),
                "lon": Decimal("80.9472"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "espresso",
                "price": Decimal("180"),
            },
            {
                "name": "HoNS (House of No Sugar)",
                "area": gomti_nagar,
                "address": ("Shop A-9, Kisan Bazar, Vibhuti Khand, Gomti Nagar"),
                "lat": Decimal("26.8530"),
                "lon": Decimal("80.9985"),
                "is_active": True,
                "is_verified_independent": False,
                "worldwide_locations_count": 3,
                "drink": "filter",
                "price": Decimal("160"),
            },
            {
                "name": "Cappuccino Blast",
                "area": hazratganj,
                "address": ("12 Mall Avenue Rd, The Mall Avenue, Hazratganj"),
                "lat": Decimal("26.8376"),
                "lon": Decimal("80.9469"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "espresso",
                "price": Decimal("150"),
            },
            {
                "name": "Mocha Cafe & Bar",
                "area": gomti_nagar,
                "address": ("CP-1, 2nd Floor, Anand Plaza, Viram Khand 1, Gomti Nagar"),
                "lat": Decimal("26.8488"),
                "lon": Decimal("80.9997"),
                "is_active": True,
                "is_verified_independent": False,
                "worldwide_locations_count": 25,
                "drink": "espresso",
                "price": Decimal("175"),
            },
            {
                "name": "Sidewalk Bakehouse & Cafe",
                "area": gomti_nagar,
                "address": ("4/492, Vivek Khand 2, Near Patrakarpuram, Gomti Nagar"),
                "lat": Decimal("26.8450"),
                "lon": Decimal("81.0100"),
                "is_active": True,
                "is_verified_independent": False,
                "worldwide_locations_count": 4,
                "drink": "espresso",
                "price": Decimal("200"),
            },
            {
                "name": "Melting Point",
                "area": gomti_nagar,
                "address": ("Hotel Dayal Paradise, Vipul Khand 5, Gomti Nagar"),
                "lat": Decimal("26.8458"),
                "lon": Decimal("80.9998"),
                "is_active": True,
                "is_verified_independent": False,
                "worldwide_locations_count": 3,
                "drink": "milk",
                "price": Decimal("200"),
            },
            {
                "name": "Sassy Canteen",
                "area": badshahnagar,
                "address": ("Sapphire Building, Metro City Centre, Badshahnagar"),
                "lat": Decimal("26.8700"),
                "lon": Decimal("80.9600"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "espresso",
                "price": Decimal("180"),
            },
            {
                "name": "Chihiro",
                "area": cantonment,
                "address": "3, MG Marg, Sadar Bazaar, Cantonment",
                "lat": Decimal("26.8170"),
                "lon": Decimal("80.9400"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "matcha",
                "price": Decimal("190"),
            },
            {
                "name": "Talllk",
                "area": gomti_nagar,
                "address": ("Shop 26, B-1, DLF MyPad, Vibhuti Khand, Gomti Nagar"),
                "lat": Decimal("26.8639"),
                "lon": Decimal("80.9999"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "espresso",
                "price": Decimal("160"),
            },
            {
                "name": "The Comma",
                "area": hazratganj,
                "address": "Le Press, 29 Nawal Kishore Road, Hazratganj",
                "lat": Decimal("26.8530"),
                "lon": Decimal("80.9450"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "cold_brew",
                "price": Decimal("200"),
            },
            {
                "name": "Criolo",
                "area": hazratganj,
                "address": "Le Press, 29 Nawal Kishore Road, Hazratganj",
                "lat": Decimal("26.8530"),
                "lon": Decimal("80.9450"),
                "is_active": True,
                "is_verified_independent": False,
                "worldwide_locations_count": 5,
                "drink": "espresso",
                "price": Decimal("150"),
            },
            {
                "name": "NBC (Nothing Before Coffee)",
                "area": gomti_nagar,
                "address": ("Shop 4, Experio at Experion Capital, Vibhuti Khand, Gomti Nagar"),
                "lat": Decimal("26.8650"),
                "lon": Decimal("81.0020"),
                "is_active": True,
                "is_verified_independent": False,
                "worldwide_locations_count": 60,
                "drink": "espresso",
                "price": Decimal("90"),
            },
            {
                "name": "TWC (The White Cafe)",
                "area": gomti_nagar,
                "address": "Vivek Khand, Gomti Nagar",
                "lat": Decimal("26.8515"),
                "lon": Decimal("80.9980"),
                "is_active": True,
                "is_verified_independent": True,
                "worldwide_locations_count": 1,
                "drink": "espresso",
                "price": Decimal("180"),
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
                    "brand_count_source": "Web research",
                    "brand_count_checked_on": now.date(),
                    "independence_source": "Web research",
                    "independence_checked_on": now.date(),
                    "source": "Web research",
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
