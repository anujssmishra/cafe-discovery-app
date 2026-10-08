from django import forms
from django.core.exceptions import ValidationError

from cafes.models import Cafe, CafeObservation, CafeOffering


class PreferencesForm(forms.Form):
    PURPOSE_CHOICES = [
        ("", "No specific purpose"),
        ("work", "Working / Study"),
        ("social", "Social / Meeting friends"),
        ("date", "Date"),
        ("reading", "Reading / Relaxing"),
        ("quick", "Quick stop"),
    ]

    drink = forms.ChoiceField(
        choices=[("", "No preference")] + CafeOffering.DrinkType.choices,
        required=False,
        label="Preferred drink",
    )
    budget = forms.DecimalField(
        min_value=0,
        max_digits=8,
        decimal_places=2,
        required=False,
        label="Budget per drink (max)",
    )
    atmosphere = forms.CharField(
        required=False,
        help_text="Comma-separated tags (e.g., quiet, lively, cozy)",
        label="Atmosphere tags",
    )
    purpose = forms.ChoiceField(
        choices=PURPOSE_CHOICES,
        required=False,
        label="Today's purpose",
    )
    essential_amenities = forms.MultipleChoiceField(
        choices=CafeObservation.Attribute.choices,
        required=False,
        widget=forms.CheckboxSelectMultiple,
        label="Essential amenities",
    )
    favourites = forms.ModelMultipleChoiceField(
        queryset=Cafe.objects.filter(is_active=True),
        required=False,
        widget=forms.SelectMultiple,
        label="Favourite cafés (up to 3)",
    )

    def clean_favourites(self):
        favs = self.cleaned_data.get("favourites")
        if favs and favs.count() > 3:
            raise ValidationError("You can select up to 3 favourite cafés.")
        return favs

    def clean_atmosphere(self):
        val = self.cleaned_data.get("atmosphere", "")
        tags = [t.strip().lower() for t in val.split(",") if t.strip()]
        for t in tags:
            if not t.isalnum():
                raise ValidationError(f"Tag '{t}' is invalid. Use letters and numbers only.")
        return ",".join(tags)
