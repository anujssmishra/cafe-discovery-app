"""Repeatable, clearly fictional local fixtures; never a pilot café dataset."""

import uuid
from decimal import Decimal

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.utils import timezone

from cafes.models import Area, Cafe, CafeOffering

DEMO_NAMESPACE = uuid.UUID("b1d8af90-9a1d-47f5-bb2d-4db3fb7aa935")
DEMO_SOURCE = "Synthetic development fixture; no real café or checked menu is represented."
DEMO_AREAS = (
    ("demo-paper-quarter", "Demo Paper Quarter", "Fictional Demo City"),
    ("demo-cloud-gardens", "Demo Cloud Gardens", "Fictional Demo City"),
)
DEMO_CAFES = (
    (
        "paper-lantern",
        "Demo Paper Lantern Café",
        0,
        "filter",
        "Pour-over",
        "180.00",
        "tea",
        "90.00",
    ),
    ("ink-cup", "Demo Ink Cup Café", 0, "espresso", "Espresso machine", "120.00", "milk", "170.00"),
    (
        "chapter-eight",
        "Demo Chapter Eight Café",
        0,
        "milk",
        "Espresso machine",
        "160.00",
        "cold_brew",
        "190.00",
    ),
    ("pencil-perch", "Demo Pencil Perch Café", 0, "tea", "Steeped", "100.00", "matcha", "220.00"),
    (
        "cloud-kettle",
        "Demo Cloud Kettle Café",
        1,
        "filter",
        "Immersion",
        "150.00",
        "espresso",
        "110.00",
    ),
    (
        "rainbow-roast",
        "Demo Rainbow Roast Café",
        1,
        "cold_brew",
        "Cold steep",
        "200.00",
        "milk",
        "180.00",
    ),
    ("pocket-meadow", "Demo Pocket Meadow Café", 1, "matcha", "Whisked", "240.00", "tea", "120.00"),
    (
        "moon-saucer",
        "Demo Moon Saucer Café",
        1,
        "espresso",
        "Espresso machine",
        "130.00",
        "filter",
        "210.00",
    ),
)


class Command(BaseCommand):
    help = "Seed eight fictional cafés; requires both DEBUG and DEMO_MODE."

    @transaction.atomic
    def handle(self, *args, **options):
        if not settings.DEBUG or not getattr(settings, "DEMO_MODE", False):
            raise CommandError("seed_demo requires DEBUG=True and DEMO_MODE=True.")
        today = timezone.localdate()
        areas = []
        for index, (slug, name, city) in enumerate(DEMO_AREAS):
            existing = Area.objects.filter(slug=slug).first()
            if existing and (existing.name != name or existing.city != city):
                raise CommandError(f"Reserved demo area {slug!r} already contains other data.")
            area, _ = Area.objects.update_or_create(
                slug=slug,
                defaults={"name": name, "city": city, "is_active": True, "display_order": index},
            )
            areas.append(area)
        for number, row in enumerate(DEMO_CAFES, start=1):
            key, name, area_index, drink, method, price, second_drink, second_price = row
            cafe_id = uuid.uuid5(DEMO_NAMESPACE, key)
            if Cafe.objects.filter(pk=cafe_id, is_demo=False).exists():
                raise CommandError(
                    f"Reserved demo identifier for {name!r} contains a non-demo café."
                )
            cafe, _ = Cafe.objects.update_or_create(
                pk=cafe_id,
                defaults={
                    "name": name,
                    "area": areas[area_index],
                    "address": f"Fictional address {number}, {areas[area_index].name}; not a real destination.",
                    "summary": "Fictional demonstration café with synthetic drink prices. Use it to explore the app; do not travel here.",
                    "latitude": None,
                    "longitude": None,
                    "website": "",
                    "is_active": True,
                    "is_demo": True,
                    "checked_on": today,
                    "source": DEMO_SOURCE,
                    "brand_location_count": None,
                    "brand_count_scope": "worldwide",
                    "brand_count_source": "",
                    "brand_count_checked_on": None,
                    "independence_status": Cafe.IndependenceStatus.UNKNOWN,
                    "independence_source": "",
                    "independence_checked_on": None,
                },
            )
            cafe.full_clean()
            for drink_type, brewing_method, amount in (
                (drink, method, price),
                (second_drink, "", second_price),
            ):
                offering, _ = CafeOffering.objects.update_or_create(
                    cafe=cafe,
                    drink_type=drink_type,
                    brewing_method=brewing_method,
                    defaults={
                        "price": Decimal(amount),
                        "currency": "INR",
                        "checked_on": today,
                        "source": DEMO_SOURCE,
                    },
                )
                offering.full_clean()
        self.stdout.write(
            self.style.SUCCESS(
                "Seeded 8 fictional demo cafés and 16 synthetic offerings in 2 fictional areas. No users created."
            )
        )
