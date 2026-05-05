from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    anthropic_api_key: str = ""
    database_url: str = "postgresql+asyncpg://localhost:5432/locallore"
    database_ssl: bool = True
    database_pool_size: int = 5
    database_max_overflow: int = 10
    database_pool_recycle: int = 300
    r2_bucket_url: str = ""
    free_tier_daily_limit: int = 10
    environment: str = "development"

    model_config = {"env_file": ".env"}


settings = Settings()
