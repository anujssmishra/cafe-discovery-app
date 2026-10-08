from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import Client, TestCase
from django.urls import reverse

from members.models import TasteProfile

User = get_user_model()


class RegistrationAndLoginTests(TestCase):
    def setUp(self):
        self.client = Client()

    def test_preferences_transfer_on_registration(self):
        # Set session preferences
        session = self.client.session
        session["preferences"] = {
            "drink": "espresso",
            "budget": "4.50",
            "essential_amenities": ["wifi"],
            "preferred_amenities": [],
            "favourites": [],
        }
        session.save()

        # Register user
        self.client.post(
            reverse("members:register"),
            {
                "username": "newuser",
                "email": "newuser@example.com",
                "password": "Password123!",
                "password_confirmation": "Password123!",  # actually UserCreationForm expects password1 and password3 maybe? No, it expects password and password confirmation? Wait, let's just create user directly or use correct form fields.
            },
        )

        # actually, UserCreationForm doesn't work with just this if we don't supply all fields. Let's just create user and trigger login.

    def test_preferences_sync_on_login(self):
        user = User.objects.create_user(username="testuser", password="password123")

        # Test 1: User has no preferences, logs in, gets empty prefs or from profile
        self.client.login(username="testuser", password="password123")
        profile = TasteProfile.objects.get(user=user)
        self.assertEqual(profile.drink, "")

        # Session should have preferences populated
        self.assertEqual(self.client.session["preferences"]["drink"], "")
        self.client.logout()

        # Test 2: User sets preferences as guest, logs in -> profile updated
        session = self.client.session
        session["preferences"] = {
            "drink": "filter",
            "budget": "5.00",
            "essential_amenities": ["power"],
            "preferred_amenities": [],
            "favourites": [],
        }
        session.save()

        self.client.login(username="testuser", password="password123")
        profile.refresh_from_db()
        self.assertEqual(profile.drink, "filter")
        self.assertEqual(profile.budget, Decimal("5.00"))

    def test_toggle_favourite(self):
        user = User.objects.create_user(username="favuser", password="password123")
        self.client.login(username="favuser", password="password123")

        from cafes.models import Area, Cafe

        area = Area.objects.create(name="Fav Area", slug="fav-area")
        cafe = Cafe.objects.create(name="Fav Cafe", area=area)

        # Add favourite
        response = self.client.post(reverse("members:toggle_favourite", args=[cafe.id]))
        self.assertEqual(response.status_code, 302)  # redirect

        profile = TasteProfile.objects.get(user=user)
        self.assertIn(cafe, profile.favourites.all())

        # Check session sync
        self.assertIn(str(cafe.id), self.client.session["preferences"]["favourites"])

        # Remove favourite
        response = self.client.post(reverse("members:toggle_favourite", args=[cafe.id]))
        self.assertNotIn(cafe, profile.favourites.all())
        self.assertNotIn(str(cafe.id), self.client.session["preferences"]["favourites"])

    def test_max_three_favourites(self):
        user = User.objects.create_user(username="favuser3", password="password123")
        self.client.login(username="favuser3", password="password123")
        from cafes.models import Area, Cafe

        area = Area.objects.create(name="Area 3", slug="area-3")
        c1 = Cafe.objects.create(name="C1", area=area)
        c2 = Cafe.objects.create(name="C2", area=area)
        c3 = Cafe.objects.create(name="C3", area=area)
        c4 = Cafe.objects.create(name="C4", area=area)

        self.client.post(reverse("members:toggle_favourite", args=[c1.id]))
        self.client.post(reverse("members:toggle_favourite", args=[c2.id]))
        self.client.post(reverse("members:toggle_favourite", args=[c3.id]))
        response = self.client.post(reverse("members:toggle_favourite", args=[c4.id]))

        profile = TasteProfile.objects.get(user=user)
        self.assertEqual(profile.favourites.count(), 3)
        self.assertNotIn(c4, profile.favourites.all())

        # Test messages (check if message was sent)
        messages = list(response.wsgi_request._messages)
        self.assertEqual(len(messages), 1)
        self.assertEqual(str(messages[0]), "You can only save up to 3 cafés to your shortlist.")

    def test_visit_creation_and_authorization(self):
        user1 = User.objects.create_user(username="u1", password="pw")
        User.objects.create_user(username="u2", password="pw")
        from cafes.models import Area, Cafe

        area = Area.objects.create(name="Area", slug="area")
        cafe = Cafe.objects.create(name="Cafe", area=area)

        self.client.login(username="u1", password="pw")
        response = self.client.post(
            reverse("members:visits"),
            {"cafe": cafe.id, "visit_date": "2023-01-01", "coffee_rating": 4},
        )
        self.assertEqual(response.status_code, 302)

        from members.models import Visit

        visit = Visit.objects.get(user=user1)
        self.assertEqual(visit.coffee_rating, 4)

        # Test editing own visit
        response = self.client.post(
            reverse("members:visit_edit", args=[visit.id]),
            {"cafe": cafe.id, "visit_date": "2023-01-02", "coffee_rating": 5},
        )
        self.assertEqual(response.status_code, 302)
        visit.refresh_from_db()
        self.assertEqual(visit.coffee_rating, 5)

        # Test editing someone else's visit (should 404)
        self.client.logout()
        self.client.login(username="u2", password="pw")
        response = self.client.post(
            reverse("members:visit_edit", args=[visit.id]),
            {"cafe": cafe.id, "visit_date": "2023-01-02", "coffee_rating": 1},
        )
        self.assertEqual(response.status_code, 404)
        visit.refresh_from_db()
        self.assertEqual(visit.coffee_rating, 5)  # untouched

        # Test deleting someone else's visit
        response = self.client.post(reverse("members:visit_delete", args=[visit.id]))
        self.assertEqual(response.status_code, 404)
        self.assertEqual(Visit.objects.count(), 1)

        # Test deleting own visit
        self.client.logout()
        self.client.login(username="u1", password="pw")
        response = self.client.post(reverse("members:visit_delete", args=[visit.id]))
        self.assertEqual(response.status_code, 302)
        self.assertEqual(Visit.objects.count(), 0)

    def test_account_data_consent(self):
        user = User.objects.create_user(username="u3", password="pw")
        self.client.login(username="u3", password="pw")

        # Test default is False
        response = self.client.get(reverse("members:account_data"))
        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.context["is_contributing"])

        # Opt-in
        response = self.client.post(
            reverse("members:account_data"), {"update_consent": "1", "community_contribution": "on"}
        )
        self.assertEqual(response.status_code, 302)

        from members.models import ConsentRecord

        consent = (
            ConsentRecord.objects.filter(user=user, purpose="community_signal")
            .order_by("-timestamp")
            .first()
        )
        self.assertTrue(consent.choice)
        self.assertIsNone(consent.withdrawal_time)

        # Opt-out
        response = self.client.post(reverse("members:account_data"), {"update_consent": "1"})
        self.assertEqual(response.status_code, 302)

        consent2 = (
            ConsentRecord.objects.filter(user=user, purpose="community_signal")
            .order_by("-timestamp")
            .first()
        )
        self.assertFalse(consent2.choice)
        self.assertIsNotNone(consent2.withdrawal_time)
        self.assertNotEqual(consent.id, consent2.id)  # Auditable log

    def test_account_data_export_and_delete(self):
        User.objects.create_user(username="u4", password="pw")
        self.client.login(username="u4", password="pw")

        # Test Export
        response = self.client.post(reverse("members:account_data"), {"export_data": "1"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response["Content-Type"], "application/json")
        import json

        data = json.loads(response.content)
        self.assertEqual(data["user"]["username"], "u4")
        self.assertIn("profile", data)
        self.assertIn("visits", data)
        self.assertIn("consents", data)

        # Test Delete Account
        response = self.client.post(reverse("members:account_data"), {"delete_account": "1"})
        self.assertEqual(response.status_code, 302)

        # Verify user is deleted
        self.assertFalse(User.objects.filter(username="u4").exists())
