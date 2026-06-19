from pydantic import BaseModel, Field, field_validator
from enum import Enum


class BudgetLevel(str, Enum):
    BUDGET = "budget"
    MID_RANGE = "mid_range"
    LUXURY = "luxury"


class TravelStyle(str, Enum):
    RELAXED = "relaxed"
    MODERATE = "moderate"
    PACKED = "packed"


class TripRequest(BaseModel):
    destination: str = Field(
        min_length=1, max_length=200, description="City or region to visit"
    )
    origin: str | None = Field(
        default=None,
        max_length=200,
        description="Departure city for flight suggestions",
    )
    start_date: str = Field(
        min_length=10, max_length=10, description="Trip start date (YYYY-MM-DD)"
    )
    end_date: str = Field(
        min_length=10, max_length=10, description="Trip end date (YYYY-MM-DD)"
    )
    budget: BudgetLevel = Field(default=BudgetLevel.MID_RANGE)
    travel_style: TravelStyle = Field(default=TravelStyle.MODERATE)
    interests: list[str] = Field(
        default_factory=list,
        max_length=20,
        description="E.g. history, food, nature, nightlife, art, shopping",
    )
    dietary_restrictions: list[str] = Field(default_factory=list, max_length=10)
    notes: str | None = Field(
        default=None,
        max_length=500,
        description="Additional preferences or constraints",
    )

    @field_validator("interests", "dietary_restrictions", mode="before")
    @classmethod
    def validate_list_item_length(cls, v: list[str]) -> list[str]:
        if v:
            return [item[:100] for item in v]
        return v
