import pytest
from fastapi.testclient import TestClient

from app.main import app


@pytest.fixture
def client():
    return TestClient(app)


@pytest.fixture
def sample_trip_request():
    return {
        "destination": "Tokyo",
        "start_date": "2026-06-01",
        "end_date": "2026-06-03",
        "budget": "mid_range",
        "travel_style": "moderate",
        "interests": ["food", "history", "nature"],
    }


@pytest.fixture
def sample_itinerary_json():
    return {
        "destination": "Tokyo",
        "duration_days": 3,
        "budget_level": "mid_range",
        "summary": "A 3-day exploration of Tokyo blending traditional temples with modern food culture.",
        "hotels": [
            {
                "name": "Hotel Gracery Shinjuku",
                "area": "Shinjuku",
                "price_range": "$120-180/night",
            }
        ],
        "days": [
            {
                "day_number": 1,
                "date": "2026-06-01",
                "activities": [
                    {
                        "time": "09:00",
                        "title": "Senso-ji Temple",
                        "description": "Visit Tokyo's oldest temple",
                        "location": "Asakusa",
                        "duration_minutes": 120,
                        "cost_estimate": "Free",
                    },
                    {
                        "time": "13:00",
                        "title": "Ueno Park & National Museum",
                        "description": "Explore the park and museum",
                        "location": "Ueno",
                        "duration_minutes": 180,
                        "cost_estimate": "¥1000",
                    },
                    {
                        "time": "18:00",
                        "title": "Ramen Street at Tokyo Station",
                        "description": "Try regional ramen styles",
                        "location": "Tokyo Station",
                        "duration_minutes": 90,
                        "cost_estimate": "¥1200",
                    },
                ],
            },
            {
                "day_number": 2,
                "date": "2026-06-02",
                "activities": [
                    {
                        "time": "08:00",
                        "title": "Tsukiji Outer Market",
                        "description": "Fresh sushi and street food",
                        "location": "Tsukiji",
                        "duration_minutes": 120,
                        "cost_estimate": "¥2000",
                    },
                    {
                        "time": "13:00",
                        "title": "Meiji Shrine & Harajuku",
                        "description": "Shrine visit then Takeshita Street",
                        "location": "Harajuku",
                        "duration_minutes": 180,
                        "cost_estimate": "Free",
                    },
                    {
                        "time": "18:00",
                        "title": "Shibuya Crossing & Dinner",
                        "description": "Famous crossing then dinner",
                        "location": "Shibuya",
                        "duration_minutes": 120,
                        "cost_estimate": "¥3000",
                    },
                ],
            },
            {
                "day_number": 3,
                "date": "2026-06-03",
                "activities": [
                    {
                        "time": "09:00",
                        "title": "Shinjuku Gyoen Garden",
                        "description": "Beautiful Japanese garden",
                        "location": "Shinjuku",
                        "duration_minutes": 120,
                        "cost_estimate": "¥500",
                    },
                    {
                        "time": "13:00",
                        "title": "Akihabara & Anime Culture",
                        "description": "Electronics and anime shops",
                        "location": "Akihabara",
                        "duration_minutes": 150,
                        "cost_estimate": "Variable",
                    },
                    {
                        "time": "18:00",
                        "title": "Izakaya Dinner in Shinjuku",
                        "description": "Traditional Japanese pub",
                        "location": "Shinjuku",
                        "duration_minutes": 120,
                        "cost_estimate": "¥4000",
                    },
                ],
            },
        ],
        "packing_tips": [
            "Bring an umbrella (rainy season)",
            "Comfortable walking shoes",
        ],
        "estimated_total_cost": "$800 - $1200 total (excluding flights)",
    }
