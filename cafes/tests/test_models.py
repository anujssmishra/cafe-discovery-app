from datetime import timedelta
from decimal import Decimal

from django.core.exceptions import ValidationError
from django.db import IntegrityError, transaction
from django.db.models import ProtectedError
from django.test import TestCase
from django.utils import timezone

from cafes.models import Area, Cafe, CafeOffering


class CatalogueModelTests(TestCase):
    def setUp(self):
        self.area = Area.objects.create(name="Test area", slug="test-area", city="Test city")
        self.cafe = Cafe.objects.create(
            name="Test café", area=self.area, address="Synthetic address"
        )

    def test_unknown_defaults_do_not_invent_evidence(self):
        self.cafe.full_clean()
        self.assertIsNone(self.cafe.brand_location_count)
        self.assertEqual(self.cafe.independence_status, "unknown")
        self.assertFalse(self.cafe.is_small_group)
        self.assertFalse(self.cafe.is_verified_independent)
        self.assertFalse(self.cafe.has_coordinates)
        offering = CafeOffering(cafe=self.cafe, drink_type="filter")
        offering.full_clean()
        self.assertIsNone(offering.price)
        self.assertFalse(offering.is_current)

    def test_coordinates_require_pair_and_valid_ranges(self):
        for lat, lon in [(Decimal("24"), None), (None, Decimal("80")), (91, 80), (24, -181)]:
            with self.subTest(latitude=lat, longitude=lon):
                self.cafe.latitude, self.cafe.longitude = lat, lon
                with self.assertRaises(ValidationError):
                    self.cafe.full_clean()
        self.cafe.latitude, self.cafe.longitude = Decimal("-90"), Decimal("180")
        self.cafe.full_clean()
        self.assertTrue(self.cafe.has_coordinates)

    def test_database_rejects_partial_or_out_of_range_coordinates(self):
        for changes in (
            {"latitude": 20},
            {"latitude": 91, "longitude": 80},
            {"latitude": 20, "longitude": 181},
        ):
            with self.subTest(changes=changes):
                with self.assertRaises(IntegrityError), transaction.atomic():
                    Cafe.objects.filter(pk=self.cafe.pk).update(**changes)

    def test_known_count_does_not_prove_independence(self):
        self.cafe.brand_location_count = 3
        self.assertFalse(self.cafe.is_small_group)
        self.cafe.brand_count_source = "Synthetic count evidence"
        self.cafe.brand_count_checked_on = timezone.localdate()
        self.assertTrue(self.cafe.is_small_group)
        self.assertFalse(self.cafe.is_verified_independent)
        self.cafe.brand_count_scope = "city"
        self.assertFalse(self.cafe.is_small_group)

    def test_badges_require_current_evidence(self):
        self.cafe.brand_location_count = 5
        self.cafe.brand_count_source = "Synthetic count evidence"
        self.cafe.independence_status = "verified_independent"
        self.cafe.independence_source = "Separate synthetic ownership evidence"
        for days_ago, expected in [(0, True), (30, True), (31, False), (-1, False)]:
            with self.subTest(days_ago=days_ago):
                checked = timezone.localdate() - timedelta(days=days_ago)
                self.cafe.brand_count_checked_on = checked
                self.cafe.independence_checked_on = checked
                self.assertEqual(self.cafe.is_small_group, expected)
                self.assertEqual(self.cafe.is_verified_independent, expected)
        self.cafe.brand_location_count = 6
        self.cafe.brand_count_checked_on = timezone.localdate()
        self.assertFalse(self.cafe.is_small_group)

    def test_verified_ownership_requires_separate_source_and_date(self):
        for status in ("verified_independent", "verified_not_independent"):
            with self.subTest(status=status):
                self.cafe.independence_status = status
                self.cafe.independence_source = "  "
                with self.assertRaises(ValidationError):
                    self.cafe.full_clean()
                with self.assertRaises(IntegrityError), transaction.atomic():
                    Cafe.objects.filter(pk=self.cafe.pk).update(independence_status=status)
        self.cafe.independence_source = "Synthetic ownership evidence"
        self.cafe.independence_checked_on = timezone.localdate()
        self.cafe.full_clean()
        self.assertFalse(self.cafe.is_verified_independent)

    def test_invalid_count_status_and_drink_fail_database_constraints(self):
        for changes in ({"brand_location_count": 0}, {"independence_status": "guessed"}):
            with self.subTest(changes=changes):
                with self.assertRaises(IntegrityError), transaction.atomic():
                    Cafe.objects.filter(pk=self.cafe.pk).update(**changes)
        with self.assertRaises(IntegrityError), transaction.atomic():
            CafeOffering.objects.create(cafe=self.cafe, drink_type="invented")

    def test_prices_can_be_unknown_but_not_negative(self):
        offering = CafeOffering(cafe=self.cafe, drink_type="espresso", price=Decimal("-0.01"))
        with self.assertRaises(ValidationError):
            offering.full_clean()
        with self.assertRaises(IntegrityError), transaction.atomic():
            offering.save()
        offering.price = Decimal("0")
        offering.full_clean()

    def test_future_check_dates_are_rejected(self):
        tomorrow = timezone.localdate() + timedelta(days=1)
        self.cafe.checked_on = tomorrow
        with self.assertRaises(ValidationError):
            self.cafe.full_clean()
        offering = CafeOffering(cafe=self.cafe, drink_type="tea", checked_on=tomorrow)
        with self.assertRaises(ValidationError):
            offering.full_clean()

    def test_area_cannot_be_deleted_while_cafe_references_it(self):
        with self.assertRaises(ProtectedError):
            self.area.delete()

    def test_observation_unique_per_attribute_and_enforces_choices(self):
        from cafes.models import CafeObservation
        obs = CafeObservation.objects.create(cafe=self.cafe, attribute="wifi", value="yes")
        with self.assertRaises(IntegrityError), transaction.atomic():
            CafeObservation.objects.create(cafe=self.cafe, attribute="wifi", value="no")
        with self.assertRaises(IntegrityError), transaction.atomic():
            CafeObservation.objects.create(cafe=self.cafe, attribute="fake", value="yes")
        with self.assertRaises(IntegrityError), transaction.atomic():
            CafeObservation.objects.create(cafe=self.cafe, attribute="power", value="fake")

    def test_observation_freshness_rules(self):
        from cafes.models import CafeObservation
        obs = CafeObservation(cafe=self.cafe, attribute="wifi", value="yes")
        self.assertFalse(obs.is_current)
        self.assertEqual(obs.evidence_status, "incomplete")
        obs.checked_on = timezone.localdate()
        obs.source = "Test"
        self.assertTrue(obs.is_current)
        self.assertEqual(obs.evidence_status, "current")
        obs.checked_on = timezone.localdate() - timedelta(days=31)
        self.assertFalse(obs.is_current)
        self.assertEqual(obs.evidence_status, "stale")

    def test_correction_report_enforces_status_choices(self):
        from cafes.models import CorrectionReport
        report = CorrectionReport.objects.create(
            cafe=self.cafe, disputed_field="address", proposed_correction="123 New St"
        )
        self.assertEqual(report.status, "new")
        with self.assertRaises(IntegrityError), transaction.atomic():
            CorrectionReport.objects.filter(pk=report.pk).update(status="fake")
