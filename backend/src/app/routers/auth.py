import logging
import re
import secrets
import time

import boto3
from botocore.exceptions import ClientError
from fastapi import APIRouter, Header, HTTPException
from pydantic import BaseModel, Field

from app.config import get_settings
from app.services.auth_service import AuthService

logger = logging.getLogger(__name__)
router = APIRouter()

DEVICE_ID_PATTERN = re.compile(r"^[a-zA-Z0-9\-_]{8,64}$")
_CHALLENGE_TTL_SECONDS = 300


class AttestRequest(BaseModel):
    attestation: str = Field(min_length=1, max_length=10000)


class ChallengeResponse(BaseModel):
    challenge: str


class TokenResponse(BaseModel):
    device_token: str


def _get_table():
    settings = get_settings()
    dynamodb = boto3.resource("dynamodb", region_name=settings.aws_region)
    return dynamodb.Table(settings.dynamodb_table_credits)


@router.get("/challenge", response_model=ChallengeResponse)
async def get_challenge(
    x_device_id: str = Header(description="Unique device identifier"),
):
    if not DEVICE_ID_PATTERN.match(x_device_id):
        raise HTTPException(status_code=400, detail="Invalid device ID")

    challenge = secrets.token_urlsafe(32)
    now = int(time.time())

    table = _get_table()
    table.put_item(
        Item={
            "pk": f"CHALLENGE#{x_device_id}",
            "sk": "PENDING",
            "challenge": challenge,
            "created_at": now,
            "expires_at": now + _CHALLENGE_TTL_SECONDS,
        }
    )

    return ChallengeResponse(challenge=challenge)


@router.post("/attest", response_model=TokenResponse)
async def attest_device(
    request: AttestRequest,
    x_device_id: str = Header(description="Unique device identifier"),
):
    if not DEVICE_ID_PATTERN.match(x_device_id):
        raise HTTPException(status_code=400, detail="Invalid device ID")

    table = _get_table()
    now = int(time.time())

    try:
        response = table.delete_item(
            Key={"pk": f"CHALLENGE#{x_device_id}", "sk": "PENDING"},
            ConditionExpression="attribute_exists(pk) AND created_at > :min_time",
            ExpressionAttributeValues={":min_time": now - _CHALLENGE_TTL_SECONDS},
            ReturnValues="ALL_OLD",
        )
    except ClientError as e:
        if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
            raise HTTPException(
                status_code=400,
                detail="No valid challenge found. Request /auth/challenge first.",
            )
        raise

    old_item = response.get("Attributes")
    if not old_item:
        raise HTTPException(
            status_code=400,
            detail="No valid challenge found. Request /auth/challenge first.",
        )

    challenge = old_item["challenge"]
    auth_service = AuthService()

    try:
        token = await auth_service.register_device(
            device_id=x_device_id,
            attestation=request.attestation,
            challenge=challenge,
        )
        return TokenResponse(device_token=token)
    except ValueError as e:
        raise HTTPException(status_code=403, detail=str(e))
