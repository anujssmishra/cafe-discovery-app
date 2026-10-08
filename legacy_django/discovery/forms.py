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
    preferred_amenities = forms.MultipleChoiceField(
        choices=CafeObservation.Attribute.choices,
        required=False,
        widget=forms.CheckboxSelectMultiple,
        label="Preferred amenities",
    )
    favourites = forms.ModelMultipleChoiceField(
        queryset=Cafe.objects.filter(is_active=True),
        required=False,
        widget=forms.SelectMultiple,
        label="Favourite cafés (up to 3)",
    )

    def clean(self):
        cleaned_data = super().clean()
        essentials = set(cleaned_data.get("essential_amenities") or [])
        preferred = set(cleaned_data.get("preferred_amenities") or [])
        if essentials & preferred:
            self.add_error(
                "preferred_amenities", "An amenity cannot be both essential and preferred."
            )
        return cleaned_data

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


class CorrectionReportForm(forms.ModelForm):
    class Meta:
        from cafes.models import CorrectionReport

        model = CorrectionReport
        fields = ["disputed_field", "proposed_correction", "contact"]
        widgets = {
            "proposed_correction": forms.Textarea(attrs={"rows": 4}),
            "contact": forms.TextInput(attrs={"placeholder": "Optional email or username"}),
        }
        labels = {
            "disputed_field": "What is incorrect or missing?",
            "proposed_correction": "What should it be?",
            "contact": "Contact info (optional)",
        }
