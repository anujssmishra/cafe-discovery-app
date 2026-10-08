from django.conf import settings


def app_context(request):
    return {"demo_mode": settings.DEMO_MODE}
