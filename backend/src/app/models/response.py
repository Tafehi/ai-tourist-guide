from pydantic import BaseModel

from app.models.itinerary import Itinerary


class GenerateResponse(BaseModel):
    success: bool
    itinerary: Itinerary | None = None
    error: str | None = None
    cached: bool = False
    model_used: str | None = None
    credits_remaining: int | None = None


class CreditsResponse(BaseModel):
    credits_remaining: int


class HealthResponse(BaseModel):
    status: str
    version: str
