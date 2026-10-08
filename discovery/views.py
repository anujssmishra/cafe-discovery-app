"""Public catalogue views; one visibility rule applies to lists and details."""

from urllib.parse import urlencode, urlsplit

from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.paginator import Paginator
from django.core.validators import URLValidator
from django.db.models.functions import Lower
from django.shortcuts import get_object_or_404, render, redirect
from django.urls import reverse
from django.views.decorators.http import require_safe

from cafes.models import Area, Cafe, evidence_status


def visible_cafes():
    """Keep archived records and non-public demo records out of every view."""
    queryset = Cafe.objects.filter(is_active=True, area__is_active=True)
    if not getattr(settings, "DEMO_MODE", False):
        queryset = queryset.filter(is_demo=False)
    return queryset.select_related("area").prefetch_related("offerings")


def _catalogue_url(q="", area=""):
    params = {key: value for key, value in (("q", q), ("area", area)) if value}
    query = urlencode(params)
    return reverse("discovery:catalogue") + (f"?{query}" if query else "")


def _safe_website(value):
    """Defend the public link even when dirty imports bypass model validation."""
    if not value or any(character.isspace() or ord(character) < 32 for character in value):
        return ""
    try:
        parts = urlsplit(value)
        if parts.username or parts.password or "\\" in value:
            return ""
        URLValidator(schemes=["http", "https"])(value)
    except (ValidationError, ValueError, TypeError):
        return ""
    return value


@require_safe
def catalogue(request):
    queryset = visible_cafes()
    area_records = list(
        Area.objects.filter(is_active=True, pk__in=queryset.values("area_id")).order_by(
            "display_order", "name", "pk"
        )
    )
    raw_q = request.GET.get("q", "").strip()
    q = raw_q[:100]
    raw_area = request.GET.get("area", "").strip()
    selected_area = next((area for area in area_records if area.slug == raw_area), None)
    errors = []

    if len(raw_q) > 100:
        errors.append(
            "Search names can be up to 100 characters. Shorten your search and try again."
        )
    if raw_area and selected_area is None:
        errors.append(
            "That area is not available in the current catalogue. Choose a listed area or clear the filters."
        )
    if errors:
        queryset = queryset.none()
    else:
        if q:
            queryset = queryset.filter(name__icontains=q)
        if selected_area:
            queryset = queryset.filter(area=selected_area)

    preferences = request.session.get("preferences", {})
    from .matching import rank_cafes
    
    # We must prefetch observations for ranking
    queryset = queryset.prefetch_related("observations")
    cafes_list = list(queryset.order_by(Lower("name"), "id"))
    
    has_active_prefs = any(preferences.get(k) for k in ["drink", "budget", "essential_amenities", "preferred_amenities"])
    
    unmet_constraints = None
    if has_active_prefs:
        cafes_list, unmet_summary = rank_cafes(cafes_list, preferences)
        if unmet_summary is not None:
            unmet_constraints = unmet_summary
            errors.append("No cafés match your essential requirements or hard budget. See below for details.")
            
    page = Paginator(cafes_list, 12).get_page(request.GET.get("page"))
    active_params = {key: value for key, value in (("q", q), ("area", raw_area)) if value}
    query_string = urlencode(active_params)
    context = {
        "cafes": page.object_list,
        "page_obj": page,
        "areas": [
            {"area": area, "url": _catalogue_url(q, area.slug), "selected": area == selected_area}
            for area in area_records
        ],
        "all_areas_url": _catalogue_url(q),
        "q": q,
        "selected_area": selected_area,
        "invalid_area": bool(raw_area and selected_area is None),
        "errors": errors,
        "result_count": page.paginator.count,
        "query_string": query_string + "&" if query_string else "",
        "has_filters": bool(raw_q or raw_area),
        "has_preferences": has_active_prefs,
        "unmet_constraints": unmet_constraints,
        "demo_mode": getattr(settings, "DEMO_MODE", False),
    }
    return render(request, "discovery/catalogue.html", context)


@require_safe
def cafe_detail(request, pk):
    cafe = get_object_or_404(visible_cafes(), pk=pk)
    ownership_evidence_status = evidence_status(
        cafe.independence_checked_on, cafe.independence_source
    )
    has_ownership_evidence = ownership_evidence_status == "current"
    ownership_label = "Ownership not verified"
    if has_ownership_evidence:
        ownership_label = {
            "verified_independent": "Recorded as independently owned",
            "verified_not_independent": "Recorded as not independently owned",
        }.get(cafe.independence_status, ownership_label)
    return render(
        request,
        "discovery/cafe_detail.html",
        {
            "cafe": cafe,
            "website_url": _safe_website(cafe.website),
            "ownership_label": ownership_label,
            "ownership_evidence_status": ownership_evidence_status,
            "has_ownership_evidence": has_ownership_evidence
            and cafe.independence_status != "unknown",
            "demo_mode": getattr(settings, "DEMO_MODE", False),
        },
    )


@require_safe
def about(request):
    return render(
        request,
        "discovery/about.html",
        {"demo_mode": getattr(settings, "DEMO_MODE", False)},
    )


def preferences(request):
    """CAFE-012: session-based preferences."""
    from .forms import PreferencesForm

    if request.method == "POST":
        form = PreferencesForm(request.POST)
        if form.is_valid():
            favs = form.cleaned_data.pop("favourites", [])
            form.cleaned_data["budget"] = (
                str(form.cleaned_data["budget"]) if form.cleaned_data["budget"] is not None else ""
            )
            data = form.cleaned_data
            data["favourites"] = [str(f.id) for f in favs]
            request.session["preferences"] = data
            
            if request.user.is_authenticated:
                from members.models import TasteProfile
                from decimal import Decimal
                profile, _ = TasteProfile.objects.get_or_create(user=request.user)
                if "drink" in data: profile.drink = data["drink"]
                if "budget" in data:
                    try: profile.budget = Decimal(str(data["budget"])) if data["budget"] else None
                    except: pass
                if "essential_amenities" in data: profile.essential_amenities = data["essential_amenities"]
                if "preferred_amenities" in data: profile.preferred_amenities = data["preferred_amenities"]
                profile.save()
                profile.favourites.set(favs)
                
            if request.POST.get("action") == "skip":
                return redirect("discovery:catalogue")
            return redirect("discovery:preferences")
    else:
        initial = request.session.get("preferences", {})
        if "favourites" in initial:
            initial["favourites"] = Cafe.objects.filter(id__in=initial["favourites"], is_active=True)
        form = PreferencesForm(initial=initial)

    return render(
        request,
        "discovery/preferences.html",
        {"form": form, "demo_mode": getattr(settings, "DEMO_MODE", False)},
    )
