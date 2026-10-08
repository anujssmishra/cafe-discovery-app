from decimal import Decimal

from django.contrib.auth.signals import user_logged_in
from django.dispatch import receiver

from .models import TasteProfile


@receiver(user_logged_in)
def sync_preferences_on_login(sender, user, request, **kwargs):
    prefs = request.session.get("preferences")
    profile, created = TasteProfile.objects.get_or_create(user=user)

    if prefs:
        # Session has preferences, transfer to profile (deliberate transfer)
        if "drink" in prefs:
            profile.drink = prefs["drink"]
        if "budget" in prefs:
            try:
                profile.budget = Decimal(str(prefs["budget"])) if prefs["budget"] else None
            except Exception:
                pass
        if "essential_amenities" in prefs:
            profile.essential_amenities = prefs["essential_amenities"]
        if "preferred_amenities" in prefs:
            profile.preferred_amenities = prefs["preferred_amenities"]
        profile.save()
        if "favourites" in prefs and prefs["favourites"]:
            profile.favourites.set(prefs["favourites"])
    else:
        # No session preferences, load from profile to session
        request.session["preferences"] = {
            "drink": profile.drink,
            "budget": str(profile.budget) if profile.budget is not None else "",
            "essential_amenities": profile.essential_amenities,
            "preferred_amenities": profile.preferred_amenities,
            "favourites": [str(f.id) for f in profile.favourites.all()],
        }
