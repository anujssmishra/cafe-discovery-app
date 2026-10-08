"""Create the catalogue role without creating accounts or granting staff access."""

from django.contrib.auth.models import Group, Permission
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

GROUP_NAME = "Catalogue editors"
CATALOGUE_MODELS = ("area", "cafe", "cafeoffering", "cafeobservation", "correctionreport")


class Command(BaseCommand):
    help = "Create/reset the Catalogue editors group's catalogue-only permissions."

    @transaction.atomic
    def handle(self, *args, **options):
        permissions = Permission.objects.filter(
            content_type__app_label="cafes", content_type__model__in=CATALOGUE_MODELS
        )
        expected = {
            f"{action}_{model}"
            for action in ("add", "change", "delete", "view")
            for model in CATALOGUE_MODELS
        }
        permissions = permissions.filter(codename__in=expected)
        if set(permissions.values_list("codename", flat=True)) != expected:
            raise CommandError("Catalogue permissions are missing. Run migrate first.")
        group, _ = Group.objects.get_or_create(name=GROUP_NAME)
        group.permissions.set(permissions)
        self.stdout.write(
            self.style.SUCCESS(
                f"Catalogue editors has {len(expected)} catalogue permissions. No accounts or staff access were created."
            )
        )
