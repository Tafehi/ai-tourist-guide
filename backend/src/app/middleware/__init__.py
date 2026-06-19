import hashlib
import hmac

import boto3
from botocore.exceptions import ClientError
from fastapi import Request
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware

from app.config import get_api_key, get_settings

EXEMPT_PATHS = {"/health", "/auth/challenge", "/auth/attest"}


class ApiKeyMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if request.url.path in EXEMPT_PATHS:
            return await call_next(request)

        settings = get_settings()

        # Check Bearer token first (App Attest device token)
        auth_header = request.headers.get("authorization") or ""
        if auth_header.startswith("Bearer "):
            token = auth_header[7:]
            device_id = request.headers.get("x-device-id") or ""
            if device_id and await self._validate_device_token(device_id, token):
                return await call_next(request)

        # Fallback: API key validation (for Insomnia/testing)
        expected_key = get_api_key()
        if not expected_key:
            if settings.unlimited_test_credits:
                return await call_next(request)
            return JSONResponse(
                status_code=401,
                content={"detail": "Authentication required"},
            )

        api_key = request.headers.get("x-api-key") or ""
        if hmac.compare_digest(api_key, expected_key):
            return await call_next(request)

        return JSONResponse(
            status_code=401,
            content={"detail": "Invalid or missing authentication"},
        )

    async def _validate_device_token(self, device_id: str, token: str) -> bool:
        token_hash = hashlib.sha256(token.encode()).hexdigest()
        max_token_age = 86400 * 90  # 90 days
        try:
            settings = get_settings()
            dynamodb = boto3.resource("dynamodb", region_name=settings.aws_region)
            table = dynamodb.Table(settings.dynamodb_table_credits)
            response = table.get_item(Key={"pk": f"DEVICE#{device_id}", "sk": "AUTH"})
            item = response.get("Item")
            if not item:
                return False
            if item.get("token_hash") != token_hash:
                return False
            if not item.get("attested", False):
                return False
            import time

            created_at = item.get("created_at", 0)
            if time.time() - created_at > max_token_age:
                return False
            return True
        except ClientError:
            return False
