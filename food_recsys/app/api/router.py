from fastapi import APIRouter
from app.api.health import router as health_router
from app.api.restaurants import router as restaurants_router
from app.api.ingest import router as ingest_router
from app.api.profile import router as profile_router
from app.api.recommend import router as recommend_router

api_router = APIRouter()

api_router.include_router(health_router)
api_router.include_router(restaurants_router, prefix="/api/v1")
api_router.include_router(ingest_router, prefix="/api/v1")
api_router.include_router(profile_router, prefix="/api/v1")
api_router.include_router(recommend_router, prefix="/api/v1")
