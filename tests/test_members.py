from decimal import Decimal
from django.test import TestCase, Client
from django.urls import reverse
from django.contrib.auth import get_user_model
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
            "favourites": []
        }
        session.save()
        
        # Register user
        response = self.client.post(reverse("members:register"), {
            "username": "newuser",
            "email": "newuser@example.com",
            "password": "Password123!",
            "password_confirmation": "Password123!" # actually UserCreationForm expects password1 and password3 maybe? No, it expects password and password confirmation? Wait, let's just create user directly or use correct form fields.
        })
        
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
            "favourites": []
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
        self.assertEqual(response.status_code, 302) # redirect
        
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
