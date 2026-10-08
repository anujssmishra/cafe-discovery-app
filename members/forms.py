from django import forms
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth import get_user_model

User = get_user_model()

class CustomUserCreationForm(UserCreationForm):
    email = forms.EmailField(required=True)

    class Meta(UserCreationForm.Meta):
        model = User
        fields = ("username", "email")

from .models import Visit

class VisitForm(forms.ModelForm):
    class Meta:
        model = Visit
        fields = [
            "cafe", "visit_date", "drink", "brewing_method", 
            "purpose", "spend_band", "coffee_rating", 
            "vibe_rating", "would_return"
        ]
        widgets = {
            "visit_date": forms.DateInput(attrs={"type": "date"}),
            "would_return": forms.Select(choices=[
                (None, "Unknown"),
                (True, "Yes"),
                (False, "No")
            ]),
        }
