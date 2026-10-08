from io import StringIO

from django.contrib.auth import get_user_model
from django.contrib.auth.models import Group, Permission
from django.core.management import call_command
from django.test import TestCase
from django.urls import reverse

from cafes.management.commands.setup_catalogue_editors import GROUP_NAME


class CatalogueEditorPermissionsTests(TestCase):
    def setUp(self):
        call_command("setup_catalogue_editors", stdout=StringIO())
        self.group = Group.objects.get(name=GROUP_NAME)
        self.editor = get_user_model().objects.create_user(
            username="test-editor", password="test-only-password", is_staff=True
        )
        self.editor.groups.add(self.group)

    def test_role_contains_only_catalogue_permissions(self):
        self.assertEqual(self.group.permissions.count(), 20)
        self.assertEqual(
            set(self.group.permissions.values_list("content_type__app_label", flat=True)), {"cafes"}
        )
        self.assertFalse(self.editor.is_superuser)

    def test_setup_is_idempotent_and_removes_unrelated_grants(self):
        self.group.permissions.add(
            Permission.objects.get(codename="view_user", content_type__app_label="auth")
        )
        call_command("setup_catalogue_editors", stdout=StringIO())
        self.assertEqual(Group.objects.filter(name=GROUP_NAME).count(), 1)
        self.assertEqual(self.group.permissions.count(), 20)
        self.assertFalse(self.group.permissions.filter(content_type__app_label="auth").exists())

    def test_editor_can_open_catalogue_but_not_auth_administration(self):
        self.client.force_login(self.editor)
        for model in ("area", "cafe", "cafeoffering", "correctionreport"):
            with self.subTest(model=model):
                self.assertEqual(
                    self.client.get(reverse(f"admin:cafes_{model}_changelist")).status_code, 200
                )
        for model in ("user", "group"):
            with self.subTest(model=model):
                self.assertEqual(
                    self.client.get(reverse(f"admin:auth_{model}_changelist")).status_code, 403
                )

    def test_staff_flag_without_permissions_does_not_allow_catalogue_edits(self):
        self.editor.groups.clear()
        self.client.force_login(self.editor)
        response = self.client.get(reverse("admin:cafes_cafe_add"))
        self.assertEqual(response.status_code, 403)
