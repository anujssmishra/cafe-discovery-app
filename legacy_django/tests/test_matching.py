from decimal import Decimal

from django.test import TestCase
from django.utils import timezone

from cafes.models import Area, Cafe, CafeObservation, CafeOffering
from discovery.matching import rank_cafes


class MatchingAlgorithmTests(TestCase):
    def setUp(self):
        self.area = Area.objects.create(name="Match Area", slug="match-area", city="Test")
        self.cafe1 = Cafe.objects.create(name="Cafe 1", area=self.area)
        self.cafe2 = Cafe.objects.create(name="Cafe 2", area=self.area)
        self.cafe3 = Cafe.objects.create(name="Cafe 3", area=self.area)

        # Cafe 1: Has espresso for 4.0, wifi and power
        CafeOffering.objects.create(
            cafe=self.cafe1,
            drink_type="espresso",
            price=Decimal("4.00"),
            checked_on=timezone.localdate(),
            source="Test",
        )
        CafeObservation.objects.create(
            cafe=self.cafe1,
            attribute="wifi",
            value="yes",
            checked_on=timezone.localdate(),
            source="Test",
        )
        CafeObservation.objects.create(
            cafe=self.cafe1,
            attribute="power",
            value="yes",
            checked_on=timezone.localdate(),
            source="Test",
        )

        # Cafe 2: Has espresso for 5.0 (over budget 4.5 * 1.2 = 5.4, so fits 20% margin), wifi only, explicitly no power
        CafeOffering.objects.create(
            cafe=self.cafe2,
            drink_type="espresso",
            price=Decimal("5.00"),
            checked_on=timezone.localdate(),
            source="Test",
        )
        CafeObservation.objects.create(
            cafe=self.cafe2,
            attribute="wifi",
            value="yes",
            checked_on=timezone.localdate(),
            source="Test",
        )
        CafeObservation.objects.create(
            cafe=self.cafe2,
            attribute="power",
            value="no",
            checked_on=timezone.localdate(),
            source="Test",
        )

        # Cafe 3: Has filter for 3.0, no wifi
        CafeOffering.objects.create(
            cafe=self.cafe3,
            drink_type="filter",
            price=Decimal("3.00"),
            checked_on=timezone.localdate(),
            source="Test",
        )

    def test_essential_amenities_strict_filtering(self):
        # Requires wifi
        preferences = {"essential_amenities": ["wifi"]}
        cafes = Cafe.objects.all().prefetch_related("observations")
        ranked, empty = rank_cafes(list(cafes), preferences)

        self.assertFalse(empty)
        self.assertEqual(len(ranked), 2)
        self.assertNotIn(self.cafe3, ranked)

    def test_hard_budget_ceiling(self):
        # Espresso under 4.0 hard budget? Wait, hard budget is 1.2x. So 4.0 * 1.2 = 4.8.
        # Cafe 1 (4.0) fits, Cafe 2 (5.0) fails hard budget
        preferences = {"drink": "espresso", "budget": "4.00"}
        cafes = Cafe.objects.all().prefetch_related("observations", "offerings")
        ranked, empty = rank_cafes(list(cafes), preferences)

        self.assertEqual(len(ranked), 1)
        self.assertEqual(ranked[0], self.cafe1)
        self.assertNotIn(self.cafe2, ranked)

    def test_scoring_and_ranking(self):
        # Drink: espresso (T)
        # Preferred: power (P)
        # Budget: 4.50 (B)
        # Cafe 1: T=1.0, P=1.0, B=1.0 (4.0 <= 4.5) => Total = (4 + 3 + 2)/9 = 1.0
        # Cafe 2: T=1.0, P=0.0, B=0.5 (5.0 <= 5.4) => Total = (4 + 0 + 1)/9 = 5/9 = 0.55

        preferences = {"drink": "espresso", "budget": "4.50", "preferred_amenities": ["power"]}
        cafes = [self.cafe1, self.cafe2]  # both eligible

        # Needs fresh queryset for prefetching
        cafes_qs = Cafe.objects.filter(id__in=[c.id for c in cafes]).prefetch_related(
            "observations", "offerings"
        )
        ranked, empty = rank_cafes(list(cafes_qs), preferences)

        self.assertEqual(len(ranked), 2)
        self.assertEqual(ranked[0].id, self.cafe1.id)
        self.assertAlmostEqual(ranked[0].match_score, 1.0)

        self.assertEqual(ranked[1].id, self.cafe2.id)
        # P is included and = 0 for Cafe 2 since it has an explicit 'no' for power.
        # Score = (4*1.0 + 3*0 + 2*0.5) / 9 = 5/9
        self.assertAlmostEqual(ranked[1].match_score, 5.0 / 9.0)

    def test_missing_information_renormalization(self):
        # Cafe 3 has no 'power' observation. P score denom should be 0, omit P dimension.
        # Cafe 3 has filter for 3.0. We will set drink="filter", budget="4.50", preferred_amenities=["power"]
        preferences = {"drink": "filter", "budget": "4.50", "preferred_amenities": ["power"]}

        cafes_qs = Cafe.objects.filter(id=self.cafe3.id).prefetch_related(
            "observations", "offerings"
        )
        ranked, empty = rank_cafes(list(cafes_qs), preferences)

        self.assertEqual(len(ranked), 1)
        # T=1.0, B=1.0, P=omitted. Score = (4*1.0 + 2*1.0) / 6 = 6.0/6.0 = 1.0
        self.assertAlmostEqual(ranked[0].match_score, 1.0)
