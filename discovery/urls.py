from django.urls import path

from . import views

app_name = "discovery"

urlpatterns = [
    path("", views.catalogue, name="catalogue"),
    path("cafes/<uuid:pk>/", views.cafe_detail, name="cafe_detail"),
    path("about/", views.about, name="about"),
]
