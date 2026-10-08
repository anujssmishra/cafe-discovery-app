from django.conf import settings
from django.db import models

class TasteProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="taste_profile")
    drink = models.CharField(max_length=20, blank=True)
    budget = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    essential_amenities = models.JSONField(default=list, blank=True)
    preferred_amenities = models.JSONField(default=list, blank=True)
    favourites = models.ManyToManyField("cafes.Cafe", blank=True, related_name="favourited_by")

    def __str__(self):
        return f"Taste profile for {self.user.username}"
