from django.urls import include, path

from . import views

app_name = "members"

urlpatterns = [
    path("register/", views.register, name="register"),
    path("favourite/<uuid:cafe_id>/", views.toggle_favourite, name="toggle_favourite"),
    path("visits/", views.visit_list, name="visits"),
    path("visits/<uuid:visit_id>/edit/", views.visit_edit, name="visit_edit"),
    path("visits/<uuid:visit_id>/delete/", views.visit_delete, name="visit_delete"),
    path("account/data/", views.account_data, name="account_data"),
    path("", include("django.contrib.auth.urls")),
]
