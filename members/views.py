from decimal import Decimal
from django.shortcuts import render, redirect
from django.contrib.auth import login
from django.contrib.auth.decorators import login_required
from .forms import CustomUserCreationForm
from .models import TasteProfile

def transfer_session_preferences(request, user):
    prefs = request.session.get("preferences")
    if not prefs:
        return
        
    profile, created = TasteProfile.objects.get_or_create(user=user)
    
    # Update profile fields from session preferences
    if "drink" in prefs:
        profile.drink = prefs["drink"]
    if "budget" in prefs:
        try:
            profile.budget = Decimal(str(prefs["budget"])) if prefs["budget"] else None
        except:
            pass
    if "essential_amenities" in prefs:
        profile.essential_amenities = prefs["essential_amenities"]
    if "preferred_amenities" in prefs:
        profile.preferred_amenities = prefs["preferred_amenities"]
        
    profile.save()
    
    if "favourites" in prefs and prefs["favourites"]:
        # favourites contains IDs
        profile.favourites.set(prefs["favourites"])
        
    # We deliberately do NOT delete session preferences so guests retain catalogue browsing if they log out? 
    # Actually, once logged in, we rely on the profile. Wait, we should sync profile back to session so the matching algorithm can just read the session! Or we modify the matching algorithm to read from profile if user is authenticated.
    # The requirement: "session preferences transfer deliberately; guests retain catalogue browsing."
    # Let's write preferences to session on login so the existing frontend doesn't need to change much.
    
def register(request):
    if request.method == "POST":
        form = CustomUserCreationForm(request.POST)
        if form.is_valid():
            user = form.save()
            # Log the user in
            login(request, user)
            transfer_session_preferences(request, user)
            return redirect("discovery:catalogue")
    else:
        form = CustomUserCreationForm()
    return render(request, "registration/register.html", {"form": form})
