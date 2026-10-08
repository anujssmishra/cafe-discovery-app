"""Check configuration failure boundaries in isolated Python processes."""

import os
import secrets
import subprocess
import sys
from pathlib import Path

from django.test import SimpleTestCase


class ConfigurationAcceptanceTests(SimpleTestCase):
    def load_settings(self, **overrides):
        env = {name: value for name, value in os.environ.items() if not name.startswith("DJANGO_")}
        generated_key = secrets.token_urlsafe(48)
        env.update(
            {
                "DJANGO_SECRET_KEY": generated_key,
                "DJANGO_DEBUG": "true",
                "DJANGO_ALLOWED_HOSTS": "localhost,127.0.0.1,testserver",
                "DJANGO_DEMO_MODE": "false",
            }
        )
        for name, value in overrides.items():
            if value is None:
                env.pop(name, None)
            else:
                env[name] = value
        result = subprocess.run(
            [sys.executable, "-c", "import config.settings; print('settings loaded')"],
            cwd=Path(__file__).resolve().parent.parent,
            env=env,
            capture_output=True,
            text=True,
            check=False,
            timeout=15,
        )
        self.assertNotIn(generated_key, result.stdout + result.stderr)
        return result

    def test_no_fallback_secret_when_key_is_missing_or_short(self):
        for key in (None, "short-development-key"):
            with self.subTest(key_length=0 if key is None else len(key)):
                result = self.load_settings(DJANGO_SECRET_KEY=key)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("DJANGO_SECRET_KEY", result.stderr)

    def test_non_debug_configuration_requires_explicit_hosts(self):
        result = self.load_settings(DJANGO_DEBUG="false", DJANGO_ALLOWED_HOSTS=None)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("DJANGO_ALLOWED_HOSTS", result.stderr)

    def test_wildcard_hosts_are_rejected(self):
        result = self.load_settings(DJANGO_ALLOWED_HOSTS="localhost,*")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("wildcard", result.stderr)

    def test_demo_data_cannot_be_enabled_outside_debug(self):
        result = self.load_settings(DJANGO_DEBUG="false", DJANGO_DEMO_MODE="true")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Demo", result.stderr)

    def test_misspelled_boolean_does_not_silently_select_a_mode(self):
        for name in ("DJANGO_DEBUG", "DJANGO_DEMO_MODE"):
            with self.subTest(name=name):
                result = self.load_settings(**{name: "tru"})
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(name, result.stderr)

    def test_documented_local_configuration_loads(self):
        result = self.load_settings(DJANGO_DEMO_MODE="true")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "settings loaded")
