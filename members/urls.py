from django.urls import path, include
from . import views

app_name = "members"

urlpatterns = [
    path("register/", views.register, name="register"),
    path("favourite/<uuid:cafe_id>/", views.toggle_favourite, name="toggle_favourite"),
    path("", include("django.contrib.auth.urls")),
]
