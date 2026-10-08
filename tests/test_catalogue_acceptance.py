"""Independent HTTP acceptance checks for the first catalogue increment."""

from datetime import timedelta
from html.parser import HTMLParser
from urllib.parse import parse_qs, urlsplit

from django.test import TestCase, override_settings
from django.urls import reverse
from django.utils import timezone

from cafes.models import Area, Cafe, CafeOffering


class Links(HTMLParser):
    """Inspect rendered links without depending on a CSS framework."""

    def __init__(self, html):
        super().__init__()
        self.items = []
        self.feed(html)

    def handle_starttag(self, tag, attrs):
        if tag == "a":
            attributes = dict(attrs)
            if "href" in attributes:
                self.items.append(attributes)


@override_settings(DEMO_MODE=False)
class CatalogueAcceptanceTests(TestCase):
    @classmethod
    def setUpTestData(cls):
        cls.central = Area.objects.create(
            name="Central Quarter", slug="central-quarter", city="Test City"
        )
        cls.riverside = Area.objects.create(
            name="Riverside Quarter", slug="riverside-quarter", city="Test City"
        )
        cls.archived_area = Area.objects.create(
            name="Archived Quarter", slug="archived-quarter", city="Test City", is_active=False
        )
        cls.empty_area = Area.objects.create(
            name="Empty Quarter", slug="empty-quarter", city="Test City"
        )
        cls.central_cafe = Cafe.objects.create(
            name="Amber Coffee House", area=cls.central, address="1 Test Lane"
        )
        cls.riverside_cafe = Cafe.objects.create(
            name="Amber Riverside", area=cls.riverside, address="2 Test Lane"
        )
        cls.other_cafe = Cafe.objects.create(
            name="Juniper Tea Room", area=cls.central, address="3 Test Lane"
        )
        cls.archived_cafe = Cafe.objects.create(
            name="Archived Cafe Record", area=cls.central, is_active=False
        )
        cls.hidden_area_cafe = Cafe.objects.create(
            name="Archived Area Record", area=cls.archived_area
        )
        cls.demo_cafe = Cafe.objects.create(
            name="Synthetic Example Cafe", area=cls.central, is_demo=True
        )

    def catalogue(self, params=None):
        return self.client.get(reverse("discovery:catalogue"), params or {})

    def detail(self, cafe):
        return self.client.get(reverse("discovery:cafe_detail", kwargs={"pk": cafe.pk}))

    def test_public_catalogue_excludes_hidden_and_demo_records(self):
        response = self.catalogue()
        self.assertContains(response, self.central_cafe.name)
        self.assertContains(response, self.riverside_cafe.name)
        self.assertContains(response, self.other_cafe.name)
        for cafe in (self.archived_cafe, self.hidden_area_cafe, self.demo_cafe):
            with self.subTest(cafe=cafe.name):
                self.assertNotContains(response, cafe.name)

    def test_hidden_records_cannot_be_opened_by_guessing_detail_uuid(self):
        for cafe in (self.archived_cafe, self.hidden_area_cafe, self.demo_cafe):
            with self.subTest(cafe=cafe.name):
                self.assertEqual(self.detail(cafe).status_code, 404)
        self.assertEqual(self.detail(self.central_cafe).status_code, 200)

    def test_partial_name_search_trims_input_and_ignores_case(self):
        response = self.catalogue({"q": "   aMbEr   "})
        self.assertContains(response, self.central_cafe.name)
        self.assertContains(response, self.riverside_cafe.name)
        self.assertNotContains(response, self.other_cafe.name)
        self.assertEqual(response.context["q"], "aMbEr")

    def test_name_and_area_are_intersected_without_broadening(self):
        response = self.catalogue({"q": "Amber", "area": self.central.slug})
        self.assertContains(response, self.central_cafe.name)
        self.assertNotContains(response, self.riverside_cafe.name)
        self.assertNotContains(response, self.other_cafe.name)
        self.assertEqual(response.context["result_count"], 1)

    def test_invalid_inactive_and_empty_areas_do_not_fall_back_to_all_cafes(self):
        for area in ("does-not-exist", self.archived_area.slug, self.empty_area.slug):
            with self.subTest(area=area):
                response = self.catalogue({"area": area})
                self.assertEqual(response.status_code, 200)
                self.assertEqual(response.context["result_count"], 0)
                self.assertTrue(response.context["errors"])
                self.assertNotContains(response, self.central_cafe.name)

    def test_search_larger_than_limit_does_not_silently_browse_everything(self):
        response = self.catalogue({"q": "x" * 101})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.context["result_count"], 0)
        self.assertTrue(response.context["errors"])
        self.assertNotContains(response, self.central_cafe.name)

    def test_empty_search_is_valid_and_unmatched_search_has_zero_results(self):
        blank = self.catalogue({"q": "  "})
        self.assertContains(blank, self.central_cafe.name)
        no_match = self.catalogue({"q": "no-cafe-has-this-name"})
        self.assertEqual(no_match.status_code, 200)
        self.assertEqual(no_match.context["result_count"], 0)
        self.assertNotContains(no_match, self.central_cafe.name)

    def test_demo_mode_exposes_only_active_demo_records_with_explicit_label(self):
        with override_settings(DEMO_MODE=True):
            response = self.catalogue({"q": self.demo_cafe.name})
            self.assertContains(response, self.demo_cafe.name)
            self.assertRegex(
                response.content.decode().lower(), r"synthetic|fictional|demonstration"
            )
            detail = self.detail(self.demo_cafe)
            self.assertContains(detail, self.demo_cafe.name)
            self.assertRegex(detail.content.decode().lower(), r"synthetic|fictional|demonstration")
            self.assertEqual(self.detail(self.hidden_area_cafe).status_code, 404)
            self.assertEqual(self.detail(self.archived_cafe).status_code, 404)

    def test_missing_price_and_evidence_are_visible_unknowns(self):
        CafeOffering.objects.create(
            cafe=self.central_cafe, drink_type="espresso", brewing_method="espresso", price=None
        )
        response = self.detail(self.central_cafe)
        self.assertEqual(response.status_code, 200)
        html = response.content.decode().lower()
        self.assertRegex(
            html,
            r"price[^<]*(?:unknown|not checked|not recorded|unavailable)|(?:unknown|not checked|not recorded|unavailable)[^<]*price",
        )
        self.assertRegex(html, r"unknown|not checked|not recorded|unverified")
        self.assertNotIn("verified independent", html)
        self.assertNotIn("5/5", html)
        self.assertNotIn("₹0", html)

    def test_catalogue_text_is_escaped_in_list_and_detail(self):
        self.central_cafe.name = '<script>alert("catalogue")</script>'
        self.central_cafe.summary = '<img src=x onerror="alert(1)">'
        self.central_cafe.source = '<svg onload="alert(2)">'
        self.central_cafe.save()
        for response in (self.catalogue(), self.detail(self.central_cafe)):
            with self.subTest(path=response.request["PATH_INFO"]):
                self.assertEqual(response.status_code, 200)
                self.assertNotContains(response, '<script>alert("catalogue")</script>')
                self.assertNotContains(response, '<img src=x onerror="alert(1)">')
                self.assertNotContains(response, '<svg onload="alert(2)">')
                self.assertContains(response, "&lt;script&gt;")

    def test_unsafe_catalogue_website_values_never_become_links(self):
        for value in (
            "javascript:alert(1)",
            "data:text/html,<script>alert(1)</script>",
            "//evil.example",
            "ftp://evil.example",
            "https://",
            "https://user:password@cafe.example/",
            "https://cafe.example\\@other.example/",
            "https://cafe.example/\nmenu",
        ):
            with self.subTest(value=value):
                self.central_cafe.website = value
                self.central_cafe.save()
                for response in (self.catalogue(), self.detail(self.central_cafe)):
                    links = Links(response.content.decode()).items
                    self.assertNotIn(value, [link["href"] for link in links])
                    for link in links:
                        scheme = urlsplit(link["href"]).scheme.lower()
                        self.assertNotIn(scheme, ("javascript", "data", "ftp"))

    def test_valid_external_website_is_available_without_opening_it(self):
        self.central_cafe.website = "https://cafe.example/menu?section=coffee&lang=en"
        self.central_cafe.save()
        response = self.detail(self.central_cafe)
        links = Links(response.content.decode()).items
        matching = [item for item in links if item["href"] == self.central_cafe.website]
        self.assertTrue(matching)
        for link in matching:
            if link.get("target") == "_blank":
                self.assertIn("noopener", link.get("rel", "").split())

    def test_query_text_is_not_interpreted_as_markup(self):
        value = '"><script>alert("query")</script>'
        response = self.catalogue({"q": value})
        self.assertEqual(response.status_code, 200)
        self.assertNotContains(response, '<script>alert("query")</script>')

    def test_pagination_limits_results_and_preserves_filter_intersection(self):
        for number in range(14):
            Cafe.objects.create(name=f"Pagination Coffee {number:02d}", area=self.central)
        Cafe.objects.create(name="Pagination Coffee Outside", area=self.riverside)
        response = self.catalogue({"q": "Pagination Coffee", "area": self.central.slug})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.context["result_count"], 14)
        self.assertEqual(len(response.context["cafes"]), 12)
        next_page_links = []
        for link in Links(response.content.decode()).items:
            query = parse_qs(urlsplit(link["href"]).query)
            if query.get("page") == ["2"]:
                next_page_links.append((link["href"], query))
        self.assertTrue(next_page_links)
        for href, query in next_page_links:
            self.assertEqual(query.get("q"), ["Pagination Coffee"])
            self.assertEqual(query.get("area"), [self.central.slug])
        page_two = self.client.get(next_page_links[0][0])
        self.assertEqual(page_two.status_code, 200)
        self.assertEqual(len(page_two.context["cafes"]), 2)
        first_ids = {cafe.pk for cafe in response.context["cafes"]}
        second_ids = {cafe.pk for cafe in page_two.context["cafes"]}
        self.assertFalse(first_ids & second_ids)
        self.assertNotContains(page_two, "Pagination Coffee Outside")

    def test_malformed_pages_cannot_error_or_bypass_visibility(self):
        for page in ("garbage", "-1", "0", "999999999999999999999999999999999"):
            with self.subTest(page=page):
                response = self.catalogue({"page": page})
                self.assertEqual(response.status_code, 200)
                self.assertNotContains(response, self.demo_cafe.name)
                self.assertNotContains(response, self.archived_cafe.name)

    def test_about_page_explains_current_catalogue_limits(self):
        response = self.client.get(reverse("discovery:about"))
        self.assertEqual(response.status_code, 200)
        self.assertRegex(response.content.decode().lower(), r"catalogue|catalog")

    def test_public_pages_allow_reads_and_reject_mutation_methods(self):
        paths = (
            reverse("discovery:catalogue"),
            reverse("discovery:cafe_detail", kwargs={"pk": self.central_cafe.pk}),
            reverse("discovery:about"),
        )
        for path in paths:
            with self.subTest(path=path):
                self.assertEqual(self.client.head(path).status_code, 200)
                self.assertEqual(self.client.post(path).status_code, 405)
                self.assertEqual(self.client.delete(path).status_code, 405)

    def test_unknown_or_malformed_cafe_identifier_returns_404(self):
        for value in ("00000000-0000-0000-0000-000000000000", "not-a-uuid"):
            with self.subTest(value=value):
                self.assertEqual(self.client.get(f"/cafes/{value}/").status_code, 404)

    def test_demo_detail_never_links_to_external_destination(self):
        self.demo_cafe.website = "https://cafe.example/"
        self.demo_cafe.save()
        with override_settings(DEMO_MODE=True):
            response = self.detail(self.demo_cafe)
        self.assertEqual(response.status_code, 200)
        links = Links(response.content.decode()).items
        self.assertNotIn(self.demo_cafe.website, [item["href"] for item in links])

    def test_ownership_claim_requires_current_nonblank_evidence(self):
        self.central_cafe.independence_status = "verified_independent"
        self.central_cafe.independence_source = "Synthetic ownership evidence"
        for days_ago, confirmed in ((0, True), (30, True), (31, False), (-1, False)):
            with self.subTest(days_ago=days_ago):
                self.central_cafe.independence_checked_on = timezone.localdate() - timedelta(
                    days=days_ago
                )
                # Direct save deliberately simulates an import bypassing full_clean.
                self.central_cafe.save()
                response = self.detail(self.central_cafe)
                if confirmed:
                    self.assertContains(response, "Recorded as independently owned")
                else:
                    self.assertEqual(response.context["ownership_label"], "Ownership not verified")
        self.central_cafe.independence_checked_on = timezone.localdate()
        self.central_cafe.independence_source = "   "
        self.central_cafe.save()
        response = self.detail(self.central_cafe)
        self.assertEqual(response.context["ownership_label"], "Ownership not verified")

    def test_future_or_blank_source_cannot_be_presented_as_checked(self):
        for checked_on, source in (
            (timezone.localdate() + timedelta(days=1), "Synthetic fixture evidence"),
            (timezone.localdate(), "   "),
        ):
            with self.subTest(checked_on=checked_on, source=source):
                self.central_cafe.checked_on = checked_on
                self.central_cafe.source = source
                self.central_cafe.save()
                response = self.catalogue({"q": self.central_cafe.name})
                self.assertNotContains(response, "Catalogue checked")

    def test_offering_price_keeps_its_evidence_age_visible(self):
        offering = CafeOffering.objects.create(
            cafe=self.central_cafe,
            drink_type="filter",
            price="180.00",
            source="Synthetic price evidence",
        )
        for days_ago, label in (
            (0, "Checked within 30 days"),
            (30, "Checked within 30 days"),
            (31, "Recheck needed — evidence is older than 30 days"),
            (-1, "Verification incomplete"),
        ):
            with self.subTest(days_ago=days_ago):
                offering.checked_on = timezone.localdate() - timedelta(days=days_ago)
                offering.save()
                response = self.detail(self.central_cafe)
                self.assertContains(response, "INR 180.00")
                self.assertContains(response, f"<strong>{label}</strong>", html=True)
                if days_ago not in (0, 30):
                    self.assertNotContains(response, "Checked within 30 days")

    def test_map_data_endpoint(self):
        a = Area.objects.create(name="Map Area", slug="map-area", is_active=True)
        c1 = Cafe.objects.create(name="Map Cafe 1", area=a, is_active=True, latitude=51.5074, longitude=-0.1278)
        
        response = self.client.get(reverse("discovery:map_data") + "?area=map-area")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response["Content-Type"], "application/json")
        
        import json
        data = json.loads(response.content)
        self.assertEqual(data["type"], "FeatureCollection")
        self.assertEqual(data["count"], 1)
        self.assertEqual(len(data["features"]), 1)
        
        # Verify pagination coordinates
        self.assertEqual(data["features"][0]["geometry"]["coordinates"], [-0.1278, 51.5074])
        self.assertEqual(data["features"][0]["properties"]["name"], "Map Cafe 1")
