import os
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    APP_NAME: str = "Food RecSys (UPI Taste Intelligence)"
    APP_VERSION: str = "0.1.0"
    DEBUG: bool = True
    
    # Database: defaults to async SQLite for instant local zero-config runs,
    # or override with PostgreSQL e.g. postgresql+asyncpg://user:pass@localhost:5432/food_recsys
    DATABASE_URL: str = "sqlite+aiosqlite:///./food_recsys.db"
    
    # Recommendation weights
    WEIGHT_CUISINE: float = 0.45
    WEIGHT_PRICE: float = 0.30
    WEIGHT_NOVELTY: float = 0.15
    WEIGHT_GEO: float = 0.10
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )


settings = Settings()
