from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.config import settings

router = APIRouter(tags=["Health"])


@router.get("/health")
async def health_check(session: AsyncSession = Depends(get_db)):
    """Health check endpoint checking application status and database connectivity."""
    db_status = "connected"
    try:
        await session.execute(text("SELECT 1"))
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"

    return {
        "status": "ok" if db_status == "connected" else "degraded",
        "app_name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "database": db_status,
    }
