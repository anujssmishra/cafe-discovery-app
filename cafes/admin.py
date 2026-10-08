from django.contrib import admin

from .models import Area, Cafe, CafeOffering, CafeObservation, CorrectionReport, EditorialReview


class CafeOfferingInline(admin.TabularInline):
    model = CafeOffering
    extra = 0
    fields = ("drink_type", "brewing_method", "price", "currency", "checked_on", "source")


class CafeObservationInline(admin.TabularInline):
    model = CafeObservation
    extra = 0
    fields = ("attribute", "value", "checked_on", "source", "notes")


@admin.register(Area)
class AreaAdmin(admin.ModelAdmin):
    list_display = ("name", "city", "is_active", "display_order")
    list_filter = ("is_active", "city")
    search_fields = ("name", "city")
    prepopulated_fields = {"slug": ("name",)}


@admin.register(Cafe)
class CafeAdmin(admin.ModelAdmin):
    list_display = ("name", "area", "is_active", "is_demo", "checked_on", "independence_status")
    list_filter = ("is_active", "is_demo", "area", "independence_status")
    search_fields = ("name", "address", "area__name", "area__city")
    list_select_related = ("area",)
    autocomplete_fields = ("area",)
    readonly_fields = ("id",)
    inlines = (CafeOfferingInline, CafeObservationInline)
    fieldsets = (
        ("Public identity", {"fields": ("id", "name", "area", "address", "summary", "website")}),
        ("Publication and source", {"fields": ("is_active", "is_demo", "source", "checked_on")}),
        ("Coordinates (optional pair)", {"fields": ("latitude", "longitude")}),
        (
            "Brand count (does not establish ownership)",
            {
                "fields": (
                    "brand_location_count",
                    "brand_count_scope",
                    "brand_count_source",
                    "brand_count_checked_on",
                )
            },
        ),
        (
            "Independent ownership evidence",
            {"fields": ("independence_status", "independence_source", "independence_checked_on")},
        ),
    )


@admin.register(CafeOffering)
class CafeOfferingAdmin(admin.ModelAdmin):
    list_display = ("cafe", "drink_type", "brewing_method", "price", "currency", "checked_on")
    list_filter = ("drink_type", "currency")
    search_fields = ("cafe__name", "brewing_method")
    list_select_related = ("cafe",)
    autocomplete_fields = ("cafe",)


@admin.register(CorrectionReport)
class CorrectionReportAdmin(admin.ModelAdmin):
    list_display = ("cafe", "disputed_field", "status", "submitted_on")
    list_filter = ("status", "submitted_on")
    search_fields = ("cafe__name", "disputed_field", "proposed_correction", "contact")
    list_select_related = ("cafe",)
    autocomplete_fields = ("cafe",)
    readonly_fields = ("submitted_on",)

@admin.register(EditorialReview)
class EditorialReviewAdmin(admin.ModelAdmin):
    list_display = ("cafe", "curator", "is_published", "visit_date", "publication_date")
    list_filter = ("is_published", "has_permission", "publication_date")
    search_fields = ("cafe__name", "curator__username", "display_name", "notes")
    list_select_related = ("cafe", "curator")
    autocomplete_fields = ("cafe", "curator")
