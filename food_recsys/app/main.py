import logging
from contextlib import asynccontextmanager
from pathlib import Path
from fastapi import FastAPI, Request, Response
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from jinja2 import Environment, FileSystemLoader

from app.config import settings
from app.db.session import engine, AsyncSessionLocal
from app.models.base import Base
from app.api.router import api_router
from app.mock.restaurants import seed_restaurants
from app.profile.builder import build_taste_profile

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("food_recsys")

TEMPLATES_DIR = Path(__file__).parent / "templates"
jinja_env = Environment(loader=FileSystemLoader(str(TEMPLATES_DIR)), autoescape=True)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup & shutdown events."""
    logger.info("Initializing database schema...")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # 2. Seed restaurant catalogue if empty
    async with AsyncSessionLocal() as session:
        seeded_count = await seed_restaurants(session)
        if seeded_count > 0:
            logger.info("Seeded %d restaurants into catalogue", seeded_count)

        # 3. Ensure active user taste profile is ready
        await build_taste_profile(session, "user_my_real_data")
        logger.info("Initialized real user taste intelligence profile 'user_my_real_data'")

    yield

    # Clean shutdown
    logger.info("Closing database connections...")
    await engine.dispose()


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="A Spotify-style recommendation engine that learns user dining preferences from UPI payment history.",
    lifespan=lifespan,
)


# Security Headers Middleware (OWASP A05)
@app.middleware("http")
async def security_headers_middleware(request: Request, call_next):
    """Inject strict security headers into every HTTP response."""
    response: Response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"
    return response


# Global Exception Handler (OWASP A05 - Prevent stack trace & SQL leakage)
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Catch unhandled exceptions and return safe JSON without leaking internal details."""
    logger.exception("Unhandled server exception on %s %s: %s", request.method, request.url.path, exc)
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal Server Error",
            "message": "An unexpected error occurred while processing your request.",
        },
    )


# CORS middleware for open client access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include all API endpoints
app.include_router(api_router)


@app.get("/", response_class=HTMLResponse, tags=["Dashboard"])
async def dashboard(request: Request):
    """Interactive demo dashboard."""
    template = jinja_env.get_template("index.html")
    return template.render()
