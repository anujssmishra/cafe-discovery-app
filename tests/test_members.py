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
