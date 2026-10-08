import uuid

from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone


class TasteProfile(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="taste_profile"
    )
    drink = models.CharField(max_length=20, blank=True)
    budget = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    essential_amenities = models.JSONField(default=list, blank=True)
    preferred_amenities = models.JSONField(default=list, blank=True)
    favourites = models.ManyToManyField("cafes.Cafe", blank=True, related_name="favourited_by")

    def __str__(self):
        return f"Taste profile for {self.user.username}"


class Visit(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="visits"
    )
    cafe = models.ForeignKey("cafes.Cafe", on_delete=models.CASCADE, related_name="visits")
    visit_date = models.DateField()
    drink = models.CharField(max_length=50, blank=True)
    brewing_method = models.CharField(max_length=50, blank=True)
    purpose = models.CharField(max_length=50, blank=True)
    spend_band = models.CharField(max_length=50, blank=True)

    coffee_rating = models.IntegerField(null=True, blank=True)
    vibe_rating = models.IntegerField(null=True, blank=True)
    would_return = models.BooleanField(null=True, blank=True)

    def clean(self):
        if self.visit_date and self.visit_date > timezone.now().date():
            raise ValidationError({"visit_date": "Visit date cannot be in the future."})

    class Meta:
        constraints = [
            models.CheckConstraint(
                check=models.Q(coffee_rating__isnull=True)
                | models.Q(coffee_rating__gte=1, coffee_rating__lte=5),
                name="valid_coffee_rating",
            ),
            models.CheckConstraint(
                check=models.Q(vibe_rating__isnull=True)
                | models.Q(vibe_rating__gte=1, vibe_rating__lte=5),
                name="valid_vibe_rating",
            ),
        ]

    def __str__(self):
        return f"{self.user.username} visited {self.cafe.name} on {self.visit_date}"


class ConsentRecord(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="consents"
    )
    purpose = models.CharField(max_length=100)
    notice_version = models.CharField(max_length=50)
    choice = models.BooleanField(default=False)
    timestamp = models.DateTimeField(auto_now_add=True)
    withdrawal_time = models.DateTimeField(null=True, blank=True)

    class Meta:
        pass

    def __str__(self):
        return f"{self.user.username} - {self.purpose} (v{self.notice_version}): {self.choice}"
