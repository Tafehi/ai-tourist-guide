from pydantic import BaseModel


class Activity(BaseModel):
    time: str
    title: str
    description: str
    location: str
    cost_estimate: str | None = None
    duration_minutes: int | None = None


class DayPlan(BaseModel):
    day_number: int
    date: str
    activities: list[Activity]


class HotelSuggestion(BaseModel):
    name: str
    area: str
    price_range: str


class Itinerary(BaseModel):
    destination: str
    duration_days: int
    budget_level: str
    summary: str
    hotels: list[HotelSuggestion] = []
    days: list[DayPlan]
    packing_tips: list[str] = []
    estimated_total_cost: str | None = None
