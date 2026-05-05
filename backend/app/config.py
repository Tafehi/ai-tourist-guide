from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    anthropic_api_key: str = ""
    database_url: str = "postgresql+asyncpg://localhost:5432/locallore"
    r2_bucket_url: str = ""
    free_tier_daily_limit: int = 10

    model_config = {"env_file": ".env"}


settings = Settings()
