import uuid
from io import StringIO

from django.contrib.auth import get_user_model
from django.core.management import call_command
from django.core.management.base import CommandError
from django.test import TestCase, override_settings

from cafes.management.commands.seed_demo import DEMO_CAFES, DEMO_NAMESPACE
from cafes.models import Area, Cafe, CafeOffering


class DemoSeedTests(TestCase):
    def seed(self):
        call_command("seed_demo", stdout=StringIO())

    def test_requires_both_debug_and_demo_mode(self):
        for debug, demo in [(False, False), (False, True), (True, False)]:
            with (
                self.subTest(debug=debug, demo=demo),
                override_settings(DEBUG=debug, DEMO_MODE=demo),
            ):
                with self.assertRaises(CommandError):
                    self.seed()
        self.assertEqual(Area.objects.count(), 0)
        self.assertEqual(Cafe.objects.count(), 0)

    @override_settings(DEBUG=True, DEMO_MODE=True)
    def test_idempotent_fictional_seed_creates_no_users_or_coordinates(self):
        self.seed()
        first_ids = set(Cafe.objects.values_list("id", flat=True))
        self.seed()
        self.assertEqual(Area.objects.count(), 2)
        self.assertEqual(Cafe.objects.count(), 8)
        self.assertEqual(CafeOffering.objects.count(), 16)
        self.assertEqual(first_ids, set(Cafe.objects.values_list("id", flat=True)))
        self.assertFalse(get_user_model().objects.exists())
        for cafe in Cafe.objects.all():
            self.assertTrue(cafe.is_demo)
            self.assertIn("Demo", cafe.name)
            self.assertIn("Fictional", cafe.address)
            self.assertFalse(cafe.has_coordinates)
            self.assertFalse(cafe.is_verified_independent)
            self.assertFalse(cafe.is_small_group)

    @override_settings(DEBUG=True, DEMO_MODE=True)
    def test_does_not_overwrite_non_demo_data_and_rolls_back(self):
        area = Area.objects.create(name="Real test area", slug="real-test", city="Test")
        cafe_id = uuid.uuid5(DEMO_NAMESPACE, DEMO_CAFES[-1][0])
        cafe = Cafe.objects.create(
            id=cafe_id, name="Existing catalogue entry", area=area, address="Test address"
        )
        with self.assertRaises(CommandError):
            self.seed()
        cafe.refresh_from_db()
        self.assertEqual(cafe.name, "Existing catalogue entry")
        self.assertEqual(Cafe.objects.count(), 1)
        self.assertEqual(Area.objects.count(), 1)
        self.assertEqual(CafeOffering.objects.count(), 0)
