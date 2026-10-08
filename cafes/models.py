"""Public catalogue facts. Member activity does not belong in these models."""

import uuid
from decimal import Decimal

from django.core.exceptions import ValidationError
from django.core.validators import MaxValueValidator, MinValueValidator, RegexValidator
from django.db import models
from django.db.models import Q
from django.utils import timezone

CATALOGUE_FRESHNESS_DAYS = 30


def evidence_is_current(checked_on):
    if checked_on is None:
        return False
    age = (timezone.localdate() - checked_on).days
    return 0 <= age <= CATALOGUE_FRESHNESS_DAYS


def evidence_status(checked_on, source):
    """Keep stale evidence distinct from missing or invalid provenance."""
    if not source.strip() or checked_on is None or checked_on > timezone.localdate():
        return "incomplete"
    return "current" if evidence_is_current(checked_on) else "stale"


def validate_checking_dates(instance, field_names):
    today = timezone.localdate()
    errors = {
        name: "A checking date cannot be in the future."
        for name in field_names
        if getattr(instance, name) is not None and getattr(instance, name) > today
    }
    if errors:
        raise ValidationError(errors)


class Area(models.Model):
    name = models.CharField(max_length=120)
    slug = models.SlugField(max_length=140, unique=True)
    city = models.CharField(max_length=120)
    is_active = models.BooleanField(default=True)
    display_order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ("display_order", "name", "pk")

    def __str__(self):
        return f"{self.name}, {self.city}"


class Cafe(models.Model):
    class IndependenceStatus(models.TextChoices):
        UNKNOWN = "unknown", "Ownership not verified"
        VERIFIED_INDEPENDENT = "verified_independent", "Verified independent ownership"
        VERIFIED_NOT_INDEPENDENT = (
            "verified_not_independent",
            "Verified not independently owned",
        )

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=180)
    area = models.ForeignKey(Area, on_delete=models.PROTECT, related_name="cafes")
    address = models.TextField()
    summary = models.TextField(blank=True)
    latitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal("-90")), MaxValueValidator(Decimal("90"))],
    )
    longitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal("-180")), MaxValueValidator(Decimal("180"))],
    )
    website = models.URLField(blank=True)
    is_active = models.BooleanField(default=True)
    is_demo = models.BooleanField(default=False)
    checked_on = models.DateField(null=True, blank=True)
    source = models.TextField(blank=True)
    brand_location_count = models.PositiveIntegerField(
        null=True, blank=True, validators=[MinValueValidator(1)]
    )
    brand_count_scope = models.CharField(max_length=40, default="worldwide")
    brand_count_source = models.TextField(blank=True)
    brand_count_checked_on = models.DateField(null=True, blank=True)
    independence_status = models.CharField(
        max_length=32,
        choices=IndependenceStatus.choices,
        default=IndependenceStatus.UNKNOWN,
    )
    independence_source = models.TextField(blank=True)
    independence_checked_on = models.DateField(null=True, blank=True)

    class Meta:
        ordering = ("name", "id")
        constraints = [
            models.CheckConstraint(
                check=(Q(latitude__isnull=True) & Q(longitude__isnull=True))
                | (Q(latitude__isnull=False) & Q(longitude__isnull=False)),
                name="cafe_coordinate_pair",
            ),
            models.CheckConstraint(
                check=Q(latitude__isnull=True) | Q(latitude__gte=-90, latitude__lte=90),
                name="cafe_latitude_range",
            ),
            models.CheckConstraint(
                check=Q(longitude__isnull=True) | Q(longitude__gte=-180, longitude__lte=180),
                name="cafe_longitude_range",
            ),
            models.CheckConstraint(
                check=Q(brand_location_count__isnull=True) | Q(brand_location_count__gte=1),
                name="cafe_positive_location_count",
            ),
            models.CheckConstraint(
                check=Q(
                    independence_status__in=[
                        "unknown",
                        "verified_independent",
                        "verified_not_independent",
                    ]
                ),
                name="cafe_valid_ownership_status",
            ),
            models.CheckConstraint(
                check=Q(independence_status="unknown")
                | (Q(independence_checked_on__isnull=False) & ~Q(independence_source="")),
                name="cafe_verified_ownership_evidence",
            ),
        ]

    def __str__(self):
        return self.name

    def clean(self):
        super().clean()
        self.brand_count_scope = self.brand_count_scope.strip().lower()
        self.source = self.source.strip()
        self.brand_count_source = self.brand_count_source.strip()
        self.independence_source = self.independence_source.strip()
        errors = {}
        if (self.latitude is None) != (self.longitude is None):
            errors["latitude"] = "Provide both latitude and longitude, or leave both empty."
            errors["longitude"] = "Provide both latitude and longitude, or leave both empty."
        if self.independence_status != self.IndependenceStatus.UNKNOWN:
            if not self.independence_source:
                errors["independence_source"] = "Verified ownership requires its own evidence."
            if self.independence_checked_on is None:
                errors["independence_checked_on"] = "Record when ownership was checked."
        try:
            validate_checking_dates(
                self, ("checked_on", "brand_count_checked_on", "independence_checked_on")
            )
        except ValidationError as exc:
            errors.update(exc.message_dict)
        if errors:
            raise ValidationError(errors)

    @property
    def has_coordinates(self):
        return self.latitude is not None and self.longitude is not None

    @property
    def is_current(self):
        return bool(self.source.strip()) and evidence_is_current(self.checked_on)

    @property
    def evidence_status(self):
        return evidence_status(self.checked_on, self.source)

    @property
    def is_small_group(self):
        """Checked worldwide count, never a claim about independent ownership."""
        return (
            self.brand_location_count is not None
            and 1 <= self.brand_location_count <= 5
            and self.brand_count_scope == "worldwide"
            and bool(self.brand_count_source.strip())
            and evidence_is_current(self.brand_count_checked_on)
        )

    @property
    def is_verified_independent(self):
        return (
            self.independence_status == self.IndependenceStatus.VERIFIED_INDEPENDENT
            and bool(self.independence_source.strip())
            and evidence_is_current(self.independence_checked_on)
        )


class CafeOffering(models.Model):
    class DrinkType(models.TextChoices):
        ESPRESSO = "espresso", "Espresso"
        FILTER = "filter", "Filter coffee"
        MILK = "milk", "Milk coffee"
        COLD_BREW = "cold_brew", "Cold brew"
        TEA = "tea", "Tea"
        MATCHA = "matcha", "Matcha"

    cafe = models.ForeignKey(Cafe, on_delete=models.CASCADE, related_name="offerings")
    drink_type = models.CharField(max_length=20, choices=DrinkType.choices)
    brewing_method = models.CharField(max_length=100, blank=True)
    price = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal("0"))],
    )
    currency = models.CharField(
        max_length=3,
        default="INR",
        validators=[RegexValidator(r"^[A-Z]{3}$", "Use a three-letter currency code.")],
    )
    checked_on = models.DateField(null=True, blank=True)
    source = models.TextField(blank=True)

    class Meta:
        ordering = ("drink_type", "brewing_method", "pk")
        constraints = [
            models.CheckConstraint(
                check=Q(price__isnull=True) | Q(price__gte=0),
                name="offering_nonnegative_price",
            ),
            models.CheckConstraint(
                check=Q(
                    drink_type__in=["espresso", "filter", "milk", "cold_brew", "tea", "matcha"]
                ),
                name="offering_valid_drink_type",
            ),
        ]

    def __str__(self):
        return f"{self.cafe}: {self.get_drink_type_display()}"

    def clean(self):
        super().clean()
        self.source = self.source.strip()
        validate_checking_dates(self, ("checked_on",))

    @property
    def is_current(self):
        return bool(self.source.strip()) and evidence_is_current(self.checked_on)

    @property
    def evidence_status(self):
        return evidence_status(self.checked_on, self.source)


class CafeObservation(models.Model):
    class Attribute(models.TextChoices):
        WIFI = "wifi", "Wi-Fi available"
        POWER = "power", "Power outlets"
        ACCESSIBLE = "accessible", "Accessible entrance"
        ROASTERY = "roastery", "Roastery on site"
        FOOD = "food", "Substantial food"

    class Value(models.TextChoices):
        YES = "yes", "Yes"
        NO = "no", "No"
        UNKNOWN = "unknown", "Unknown"

    cafe = models.ForeignKey(Cafe, on_delete=models.CASCADE, related_name="observations")
    attribute = models.CharField(max_length=40, choices=Attribute.choices)
    value = models.CharField(max_length=20, choices=Value.choices, default=Value.UNKNOWN)
    source = models.TextField(blank=True)
    checked_on = models.DateField(null=True, blank=True)
    notes = models.TextField(blank=True)

    class Meta:
        ordering = ("cafe", "attribute")
        constraints = [
            models.UniqueConstraint(
                fields=["cafe", "attribute"], name="unique_cafe_observation"
            ),
            models.CheckConstraint(
                check=Q(value__in=["yes", "no", "unknown"]),
                name="observation_valid_value",
            ),
            models.CheckConstraint(
                check=Q(attribute__in=["wifi", "power", "accessible", "roastery", "food"]),
                name="observation_valid_attribute",
            ),
        ]

    def __str__(self):
        return f"{self.cafe}: {self.get_attribute_display()} - {self.get_value_display()}"

    def clean(self):
        super().clean()
        self.source = self.source.strip()
        validate_checking_dates(self, ("checked_on",))

    @property
    def is_current(self):
        return bool(self.source.strip()) and evidence_is_current(self.checked_on)

    @property
    def evidence_status(self):
        return evidence_status(self.checked_on, self.source)


class CorrectionReport(models.Model):
    class Status(models.TextChoices):
        NEW = "new", "New"
        IN_PROGRESS = "in_progress", "In progress"
        RESOLVED = "resolved", "Resolved"
        REJECTED = "rejected", "Rejected"

    cafe = models.ForeignKey(Cafe, on_delete=models.CASCADE, related_name="correction_reports")
    disputed_field = models.CharField(max_length=100)
    proposed_correction = models.TextField()
    contact = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.NEW)
    submitted_on = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("-submitted_on", "pk")
        constraints = [
            models.CheckConstraint(
                check=Q(status__in=["new", "in_progress", "resolved", "rejected"]),
                name="correction_valid_status",
            ),
        ]

    def __str__(self):
        return f"Correction for {self.cafe} ({self.get_status_display()})"
