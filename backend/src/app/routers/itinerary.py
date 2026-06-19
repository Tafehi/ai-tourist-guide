import logging
import re

from fastapi import APIRouter, Header, HTTPException, Query

from app.config import get_settings
from app.models.request import TripRequest
from app.models.response import GenerateResponse, CreditsResponse
from app.services.credits_service import CreditsService
from app.services.itinerary_service import ItineraryService
from app.services.rate_limiter import RateLimiter

logger = logging.getLogger(__name__)
router = APIRouter()

DEVICE_ID_PATTERN = re.compile(r"^[a-zA-Z0-9\-_]{8,128}$")


def _validate_device_id(device_id: str) -> None:
    if not device_id or not DEVICE_ID_PATTERN.match(device_id):
        raise HTTPException(status_code=400, detail="Invalid device ID")


@router.post("/generate", response_model=GenerateResponse)
async def generate_itinerary(
    request: TripRequest,
    x_device_id: str = Header(description="Unique device identifier"),
):
    _validate_device_id(x_device_id)

    if not get_settings().unlimited_test_credits:
        rate_limiter = RateLimiter()
        if not rate_limiter.check_device_rate(x_device_id):
            raise HTTPException(
                status_code=429, detail="Rate limit exceeded. Try again later."
            )

    credits_service = CreditsService()

    if not await credits_service.has_credits(x_device_id):
        raise HTTPException(
            status_code=402,
            detail="No trip credits remaining. Purchase a trip pack to continue.",
        )

    service = ItineraryService()

    try:
        itinerary, cached, model_used = await service.generate(request)

        if not cached:
            remaining = await credits_service.consume_credit(x_device_id)
            if remaining == -1:
                raise HTTPException(
                    status_code=402, detail="No trip credits remaining."
                )
        else:
            remaining = await credits_service.get_credits(x_device_id)

        return GenerateResponse(
            success=True,
            itinerary=itinerary,
            cached=cached,
            model_used=model_used,
            credits_remaining=remaining,
        )
    except HTTPException:
        raise
    except Exception:
        logger.exception("Failed to generate itinerary")
        raise HTTPException(status_code=500, detail="An internal error occurred")


@router.get("/credits", response_model=CreditsResponse)
async def get_credits(
    x_device_id: str = Header(description="Unique device identifier"),
):
    _validate_device_id(x_device_id)

    credits_service = CreditsService()
    balance = await credits_service.get_credits(x_device_id)
    return CreditsResponse(credits_remaining=balance)


@router.post("/credits/purchase", response_model=CreditsResponse)
async def purchase_credits(
    product_id: str = Query(max_length=64),
    transaction_id: str = Query(max_length=128),
    x_device_id: str = Header(description="Unique device identifier"),
):
    _validate_device_id(x_device_id)

    credits_service = CreditsService()

    try:
        balance = await credits_service.add_credits(
            x_device_id, product_id, transaction_id
        )
        return CreditsResponse(credits_remaining=balance)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
