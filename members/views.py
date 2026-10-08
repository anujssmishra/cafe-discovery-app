from decimal import Decimal
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import login
from django.contrib.auth.decorators import login_required
from django.views.decorators.http import require_POST
from django.http import HttpResponseRedirect
from cafes.models import Cafe
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

@require_POST
@login_required
def toggle_favourite(request, cafe_id):
    cafe = get_object_or_404(Cafe, id=cafe_id, is_active=True)
    profile, _ = TasteProfile.objects.get_or_create(user=request.user)
    
    if profile.favourites.filter(id=cafe.id).exists():
        profile.favourites.remove(cafe)
    else:
        if profile.favourites.count() >= 3:
            # Maybe show an error message using messages framework, but for now just don't add
            from django.contrib import messages
            messages.error(request, "You can only save up to 3 cafés to your shortlist.")
        else:
            profile.favourites.add(cafe)
        
    # Also update the session to keep it in sync for the matching engine
    prefs = request.session.get("preferences", {})
    prefs["favourites"] = [str(f.id) for f in profile.favourites.all()]
    request.session["preferences"] = prefs
    
    # Redirect back to where the user came from, or catalogue
    next_url = request.POST.get("next") or request.META.get('HTTP_REFERER')
    if next_url:
        return HttpResponseRedirect(next_url)
    return redirect("discovery:catalogue")
