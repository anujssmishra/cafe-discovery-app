from decimal import Decimal

from django.test import TestCase
from django.urls import reverse

from cafes.models import Area, Cafe


class PreferencesTests(TestCase):
    def setUp(self):
        self.area = Area.objects.create(name="Test area", slug="test-area", city="Test city")
        self.cafe1 = Cafe.objects.create(name="Cafe 1", area=self.area, address="Address 1")
        self.cafe2 = Cafe.objects.create(name="Cafe 2", area=self.area, address="Address 2")
        self.cafe3 = Cafe.objects.create(name="Cafe 3", area=self.area, address="Address 3")
        self.cafe4 = Cafe.objects.create(name="Cafe 4", area=self.area, address="Address 4")
        self.url = reverse("discovery:preferences")

    def test_get_preferences_renders_form(self):
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Your Preferences")

    def test_post_valid_preferences_saves_to_session(self):
        data = {
            "drink": "espresso",
            "budget": "5.50",
            "atmosphere": "quiet, cozy",
            "purpose": "work",
            "essential_amenities": ["wifi", "power"],
            "favourites": [self.cafe1.id, self.cafe2.id],
            "action": "save",
        }
        response = self.client.post(self.url, data)
        self.assertRedirects(response, self.url)
        prefs = self.client.session.get("preferences")
        self.assertIsNotNone(prefs)
        self.assertEqual(prefs["drink"], "espresso")
        self.assertEqual(prefs["budget"], "5.50")
        self.assertEqual(prefs["atmosphere"], "quiet,cozy")
        self.assertEqual(prefs["purpose"], "work")
        self.assertEqual(prefs["essential_amenities"], ["wifi", "power"])
        self.assertEqual(len(prefs["favourites"]), 2)

    def test_post_skip_redirects_to_catalogue(self):
        data = {"action": "skip"}
        response = self.client.post(self.url, data)
        self.assertRedirects(response, reverse("discovery:catalogue"))
        self.assertIn("preferences", self.client.session)

    def test_favourites_limited_to_three(self):
        data = {
            "favourites": [self.cafe1.id, self.cafe2.id, self.cafe3.id, self.cafe4.id],
            "action": "save",
        }
        response = self.client.post(self.url, data)
        self.assertEqual(response.status_code, 200)
        self.assertFormError(response, "form", "favourites", "You can select up to 3 favourite cafés.")

    def test_invalid_atmosphere_tags_rejected(self):
        data = {
            "atmosphere": "good-vibes! 100%",
            "action": "save",
        }
        response = self.client.post(self.url, data)
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.context["form"].errors["atmosphere"])

    def test_empty_catalogue_shows_unmet_constraints(self):
        # Set impossible budget
        session = self.client.session
        session["preferences"] = {"drink": "espresso", "budget": "0.10"}
        session.save()
        
        response = self.client.get(reverse("discovery:catalogue"))
        self.assertContains(response, "The following essential constraints excluded the matches:")
        self.assertContains(response, "Missing price or drink not available")
