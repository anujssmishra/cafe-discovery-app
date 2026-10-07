from django.contrib import admin

from .models import Area, Cafe, CafeOffering


class CafeOfferingInline(admin.TabularInline):
    model = CafeOffering
    extra = 0
    fields = ("drink_type", "brewing_method", "price", "currency", "checked_on", "source")


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
    inlines = (CafeOfferingInline,)
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
