from decimal import Decimal

from django.contrib.auth import login
from django.contrib.auth.decorators import login_required
from django.http import HttpResponseRedirect
from django.shortcuts import get_object_or_404, redirect, render
from django.views.decorators.http import require_POST

from cafes.models import Cafe

from .forms import CustomUserCreationForm, VisitForm
from .models import TasteProfile, Visit


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
    next_url = request.POST.get("next") or request.META.get("HTTP_REFERER")
    if next_url:
        return HttpResponseRedirect(next_url)
    return redirect("discovery:catalogue")


@login_required
def visit_list(request):
    if request.method == "POST":
        form = VisitForm(request.POST)
        if form.is_valid():
            visit = form.save(commit=False)
            visit.user = request.user
            visit.save()
            return redirect("members:visits")
    else:
        # Pre-fill cafe if provided
        initial = {}
        if request.GET.get("cafe"):
            initial["cafe"] = request.GET.get("cafe")
        form = VisitForm(initial=initial)
        # Limit cafe choices to active cafes
        form.fields["cafe"].queryset = Cafe.objects.filter(is_active=True)

    visits = request.user.visits.all().order_by("-visit_date")
    return render(request, "members/visit_list.html", {"visits": visits, "form": form})


@login_required
def visit_edit(request, visit_id):
    visit = get_object_or_404(Visit, id=visit_id, user=request.user)
    if request.method == "POST":
        form = VisitForm(request.POST, instance=visit)
        if form.is_valid():
            form.save()
            return redirect("members:visits")
    else:
        form = VisitForm(instance=visit)
        form.fields["cafe"].queryset = Cafe.objects.filter(is_active=True)
    return render(request, "members/visit_edit.html", {"form": form, "visit": visit})


@require_POST
@login_required
def visit_delete(request, visit_id):
    visit = get_object_or_404(Visit, id=visit_id, user=request.user)
    visit.delete()
    return redirect("members:visits")


@login_required
def account_data(request):
    # Handle community contribution consent

    from django.contrib.auth import logout
    from django.http import JsonResponse
    from django.utils import timezone

    from .models import ConsentRecord, Visit

    current_consent = (
        ConsentRecord.objects.filter(user=request.user, purpose="community_signal")
        .order_by("-timestamp")
        .first()
    )

    is_contributing = current_consent.choice if current_consent else False

    if request.method == "POST":
        if "update_consent" in request.POST:
            new_choice = request.POST.get("community_contribution") == "on"
            if new_choice != is_contributing:
                ConsentRecord.objects.create(
                    user=request.user,
                    purpose="community_signal",
                    notice_version="1.0",
                    choice=new_choice,
                    withdrawal_time=timezone.now() if not new_choice else None,
                )
                from django.contrib import messages

                messages.success(request, "Your privacy settings have been updated.")
                return redirect("members:account_data")
        elif "export_data" in request.POST:
            # Gather data
            profile = getattr(request.user, "taste_profile", None)
            visits = Visit.objects.filter(user=request.user).order_by("visit_date")
            consents = ConsentRecord.objects.filter(user=request.user).order_by("timestamp")

            data = {
                "user": {
                    "username": request.user.username,
                    "email": request.user.email,
                    "date_joined": request.user.date_joined.isoformat(),
                },
                "profile": {
                    "drink": profile.drink if profile else "",
                    "budget": str(profile.budget) if profile and profile.budget else None,
                    "essential_amenities": profile.essential_amenities if profile else [],
                    "preferred_amenities": profile.preferred_amenities if profile else [],
                    "favourites": [str(c.id) for c in profile.favourites.all()] if profile else [],
                },
                "visits": [
                    {
                        "id": str(v.id),
                        "cafe_id": str(v.cafe_id),
                        "visit_date": v.visit_date.isoformat(),
                        "drink": v.drink,
                        "brewing_method": v.brewing_method,
                        "purpose": v.purpose,
                        "spend_band": v.spend_band,
                        "coffee_rating": v.coffee_rating,
                        "vibe_rating": v.vibe_rating,
                        "would_return": v.would_return,
                    }
                    for v in visits
                ],
                "consents": [
                    {
                        "purpose": c.purpose,
                        "notice_version": c.notice_version,
                        "choice": c.choice,
                        "timestamp": c.timestamp.isoformat(),
                        "withdrawal_time": c.withdrawal_time.isoformat()
                        if c.withdrawal_time
                        else None,
                    }
                    for c in consents
                ],
            }

            response = JsonResponse(data, json_dumps_params={"indent": 2})
            response["Content-Disposition"] = (
                f'attachment; filename="cafediscovery_{request.user.username}_data.json"'
            )
            return response
        elif "delete_account" in request.POST:
            # In a real app we might ask for password confirmation
            user = request.user
            logout(request)
            user.delete()
            # Deletion cascades to profile, visits, and consents.
            from django.contrib import messages

            messages.success(
                request, "Your account and all associated data have been permanently deleted."
            )
            return redirect("discovery:catalogue")

    return render(request, "members/account_data.html", {"is_contributing": is_contributing})
