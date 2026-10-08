from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("members/", include("members.urls")),
    path("", include("discovery.urls")),
]

admin.site.site_header = "Café Discovery catalogue"
admin.site.site_title = "Café Discovery"
admin.site.index_title = "Catalogue administration"
