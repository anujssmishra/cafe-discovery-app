"""Independent tests for staff boundaries and repeatable fixture safeguards."""

from io import StringIO

from django.contrib.auth import get_user_model
from django.contrib.auth.models import Group
from django.core.management import call_command
from django.core.management.base import CommandError
from django.test import Client, TestCase, override_settings
from django.urls import reverse

from cafes.management.commands.seed_demo import DEMO_AREAS
from cafes.management.commands.setup_catalogue_editors import GROUP_NAME
from cafes.models import Area, Cafe


class EditorBoundaryAcceptanceTests(TestCase):
    def setUp(self):
        call_command("setup_catalogue_editors", stdout=StringIO())
        self.editor = get_user_model().objects.create_user(username="qa-editor", is_staff=True)
        self.editor.groups.add(Group.objects.get(name=GROUP_NAME))

    def test_catalogue_group_does_not_automatically_grant_admin_access(self):
        self.editor.is_staff = False
        self.editor.save()
        self.client.force_login(self.editor)
        response = self.client.get(reverse("admin:cafes_cafe_changelist"))
        self.assertEqual(response.status_code, 302)
        self.assertIn(reverse("admin:login"), response.url)

    def test_editor_cannot_post_user_or_group_privilege_changes(self):
        self.client.force_login(self.editor)
        for model in ("user", "group"):
            with self.subTest(model=model):
                response = self.client.post(reverse(f"admin:auth_{model}_add"), {})
                self.assertEqual(response.status_code, 403)

    def test_admin_catalogue_mutations_require_csrf_token(self):
        client = Client(enforce_csrf_checks=True)
        client.force_login(self.editor)
        response = client.post(
            reverse("admin:cafes_area_add"),
            {"name": "Unauthorized fixture", "city": "Test", "slug": "csrf-check"},
        )
        self.assertEqual(response.status_code, 403)
        self.assertFalse(Area.objects.filter(slug="csrf-check").exists())

    @override_settings(DEBUG=True, DEMO_MODE=True)
    def test_seed_area_collision_rolls_back_before_changing_existing_data(self):
        reserved_slug = DEMO_AREAS[-1][0]
        existing = Area.objects.create(
            name="Existing non-demo area", city="Test City", slug=reserved_slug
        )
        with self.assertRaises(CommandError):
            call_command("seed_demo", stdout=StringIO())
        existing.refresh_from_db()
        self.assertEqual(existing.name, "Existing non-demo area")
        self.assertEqual(Area.objects.count(), 1)
        self.assertFalse(Cafe.objects.exists())
