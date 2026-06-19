import time

import boto3
from pydantic_settings import BaseSettings
from functools import lru_cache

_api_key_cache: dict[str, tuple[str, float]] = {}
_CACHE_TTL_SECONDS = 300


class Settings(BaseSettings):
    aws_region: str = "eu-west-1"
    api_key_secret_name: str = ""
    dynamodb_table_itineraries: str = "tripcraft-ai-Itineraries"
    dynamodb_table_credits: str = "tripcraft-ai-Credits"
    environment: str = "development"
    free_credits: int = 1
    unlimited_test_credits: bool = False
    google_maps_secret_name: str = ""
    claude_model_simple: str = "eu.anthropic.claude-haiku-4-5-20251001-v1:0"
    claude_model_complex: str = "eu.anthropic.claude-haiku-4-5-20251001-v1:0"

    model_config = {"env_file": ".env", "env_prefix": "APP_"}


@lru_cache
def get_settings() -> Settings:
    return Settings()


def get_api_key() -> str:
    settings = get_settings()
    if not settings.api_key_secret_name:
        return ""

    now = time.time()
    cached = _api_key_cache.get("key")
    if cached and (now - cached[1]) < _CACHE_TTL_SECONDS:
        return cached[0]

    client = boto3.client("secretsmanager", region_name=settings.aws_region)
    response = client.get_secret_value(SecretId=settings.api_key_secret_name)
    value = response["SecretString"]
    _api_key_cache["key"] = (value, now)
    return value
