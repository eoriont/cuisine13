from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # Database
    database_url: str = "postgresql://postgres:postgres@db:5432/cuisine13_dev"

    # API Keys
    anthropic_api_key: str = ""
    yelp_api_key: str = ""
    google_places_api_key: str = ""

    # Cache settings
    cache_ttl_restaurants: int = 86400  # 24 hours
    cache_ttl_facts: int = 604800  # 7 days

    # Service settings
    debug: bool = True

    class Config:
        env_file = ".env"
        extra = "ignore"


@lru_cache()
def get_settings() -> Settings:
    return Settings()
