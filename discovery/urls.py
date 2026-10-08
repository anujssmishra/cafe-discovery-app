from django.urls import path

from . import views

app_name = "discovery"

urlpatterns = [
    path("", views.catalogue, name="catalogue"),
    path("cafes/map-data/", views.map_data, name="map_data"),
    path("cafes/<uuid:pk>/", views.cafe_detail, name="cafe_detail"),
    path("cafes/<uuid:pk>/correction/", views.cafe_correction, name="cafe_correction"),
    path("about/", views.about, name="about"),
    path("preferences/", views.preferences, name="preferences"),
]
