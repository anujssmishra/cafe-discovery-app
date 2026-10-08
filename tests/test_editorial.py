from datetime import timedelta
from django.test import TestCase
from django.core.exceptions import ValidationError
from django.db.utils import IntegrityError
from django.utils import timezone
from django.contrib.auth.models import User

from cafes.models import Area, Cafe, EditorialReview

class EditorialReviewTests(TestCase):
    @classmethod
    def setUpTestData(cls):
        cls.curator = User.objects.create_user(username="curator")
        cls.area = Area.objects.create(name="Editorial Area", slug="ed-area", is_active=True)
        cls.cafe = Cafe.objects.create(name="Editorial Cafe", area=cls.area, is_active=True)
        cls.today = timezone.localdate()
        cls.tomorrow = cls.today + timedelta(days=1)
        cls.yesterday = cls.today - timedelta(days=1)

    def test_draft_review_creation(self):
        review = EditorialReview.objects.create(
            cafe=self.cafe,
            curator=self.curator,
            display_name="Expert",
            visit_date=self.yesterday,
            notes="Good coffee",
            is_published=False,
        )
        review.full_clean()
        self.assertEqual(review.is_published, False)

    def test_published_review_requires_permission(self):
        review = EditorialReview(
            cafe=self.cafe,
            curator=self.curator,
            display_name="Expert",
            visit_date=self.yesterday,
            publication_date=self.today,
            notes="Good coffee",
            is_published=True,
            has_permission=False,
        )
        with self.assertRaises(ValidationError) as ctx:
            review.full_clean()
        self.assertIn("has_permission", ctx.exception.message_dict)

    def test_published_review_requires_publication_date(self):
        review = EditorialReview(
            cafe=self.cafe,
            curator=self.curator,
            display_name="Expert",
            visit_date=self.yesterday,
            notes="Good coffee",
            is_published=True,
            has_permission=True,
        )
        with self.assertRaises(ValidationError) as ctx:
            review.full_clean()
        self.assertIn("publication_date", ctx.exception.message_dict)

    def test_future_visit_date_is_invalid(self):
        review = EditorialReview(
            cafe=self.cafe,
            curator=self.curator,
            display_name="Expert",
            visit_date=self.tomorrow,
            notes="Good coffee",
        )
        with self.assertRaises(ValidationError) as ctx:
            review.full_clean()
        self.assertIn("visit_date", ctx.exception.message_dict)

    def test_invalid_ratings_caught_by_constraints(self):
        review = EditorialReview(
            cafe=self.cafe,
            curator=self.curator,
            display_name="Expert",
            visit_date=self.yesterday,
            coffee_rating=6,
        )
        with self.assertRaises(ValidationError):
            review.full_clean()
            
        review.coffee_rating = 0
        with self.assertRaises(ValidationError):
            review.full_clean()

    def test_view_displays_published_reviews(self):
        review = EditorialReview.objects.create(
            cafe=self.cafe,
            curator=self.curator,
            display_name="Expert",
            visit_date=self.yesterday,
            publication_date=self.today,
            notes="Good coffee",
            coffee_rating=4,
            is_published=True,
            has_permission=True,
        )
        response = self.client.get(f"/cafes/{self.cafe.id}/")
        self.assertContains(response, "Review by Expert")
        self.assertContains(response, "Good coffee")
        self.assertContains(response, "Coffee:</strong> 4/5")

    def test_view_hides_draft_reviews(self):
        review = EditorialReview.objects.create(
            cafe=self.cafe,
            curator=self.curator,
            display_name="Secret Expert",
            visit_date=self.yesterday,
            notes="Bad coffee",
            is_published=False,
        )
        response = self.client.get(f"/cafes/{self.cafe.id}/")
        self.assertNotContains(response, "Review by Secret Expert")
        self.assertNotContains(response, "Bad coffee")
