from unittest.mock import AsyncMock, MagicMock, patch

import pytest


@pytest.fixture(autouse=True)
def _bypass_auth_and_rate_limiter():
    mock_settings = MagicMock(
        unlimited_test_credits=True,
        api_key_secret_name="",
        aws_region="eu-west-1",
        dynamodb_table_credits="test-credits",
    )
    with (
        patch("app.routers.itinerary.get_settings", return_value=mock_settings),
        patch("app.middleware.get_settings", return_value=mock_settings),
        patch("app.middleware.get_api_key", return_value=""),
    ):
        yield


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["version"] == "0.1.0"


@patch("app.routers.itinerary.CreditsService")
@patch("app.services.itinerary_service.CacheService")
@patch("app.services.itinerary_service.ClaudeService")
def test_generate_itinerary_success(
    mock_claude_cls,
    mock_cache_cls,
    mock_credits_cls,
    client,
    sample_trip_request,
    sample_itinerary_json,
):
    from app.models.itinerary import Itinerary

    mock_credits = MagicMock()
    mock_credits.has_credits = AsyncMock(return_value=True)
    mock_credits.consume_credit = AsyncMock(return_value=2)
    mock_credits.get_credits = AsyncMock(return_value=3)
    mock_credits_cls.return_value = mock_credits

    mock_cache = MagicMock()
    mock_cache.get_itinerary = AsyncMock(return_value=None)
    mock_cache.store_itinerary = AsyncMock(return_value=None)
    mock_cache_cls.return_value = mock_cache

    itinerary = Itinerary.model_validate(sample_itinerary_json)
    mock_claude = MagicMock()
    mock_claude.generate_itinerary = AsyncMock(
        return_value=(itinerary, "claude-sonnet-4-6-20250514")
    )
    mock_claude_cls.return_value = mock_claude

    response = client.post(
        "/itinerary/generate",
        json=sample_trip_request,
        headers={"X-Device-ID": "test-device-12345678"},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["itinerary"]["destination"] == "Tokyo"
    assert data["itinerary"]["duration_days"] == 3
    assert len(data["itinerary"]["days"]) == 3
    assert data["cached"] is False
    assert data["credits_remaining"] == 2


def test_generate_itinerary_missing_device_id(client, sample_trip_request):
    response = client.post(
        "/itinerary/generate",
        json=sample_trip_request,
    )
    assert response.status_code == 422


def test_generate_itinerary_invalid_device_id(client, sample_trip_request):
    response = client.post(
        "/itinerary/generate",
        json=sample_trip_request,
        headers={"X-Device-ID": "short"},
    )
    assert response.status_code == 400


@patch("app.routers.itinerary.CreditsService")
def test_generate_itinerary_no_credits(mock_credits_cls, client, sample_trip_request):
    mock_credits = MagicMock()
    mock_credits.has_credits = AsyncMock(return_value=False)
    mock_credits_cls.return_value = mock_credits

    response = client.post(
        "/itinerary/generate",
        json=sample_trip_request,
        headers={"X-Device-ID": "test-device-12345678"},
    )

    assert response.status_code == 402
    assert "No trip credits" in response.json()["detail"]


@patch("app.routers.itinerary.CreditsService")
@patch("app.services.itinerary_service.CacheService")
@patch("app.services.itinerary_service.ClaudeService")
def test_generate_itinerary_cache_hit_no_credit_consumed(
    mock_claude_cls,
    mock_cache_cls,
    mock_credits_cls,
    client,
    sample_trip_request,
    sample_itinerary_json,
):
    from app.models.itinerary import Itinerary

    mock_credits = MagicMock()
    mock_credits.has_credits = AsyncMock(return_value=True)
    mock_credits.get_credits = AsyncMock(return_value=3)
    mock_credits_cls.return_value = mock_credits

    itinerary = Itinerary.model_validate(sample_itinerary_json)
    mock_cache = MagicMock()
    mock_cache.get_itinerary = AsyncMock(return_value=itinerary)
    mock_cache_cls.return_value = mock_cache
    mock_claude_cls.return_value = MagicMock()

    response = client.post(
        "/itinerary/generate",
        json=sample_trip_request,
        headers={"X-Device-ID": "test-device-12345678"},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["cached"] is True
    assert data["credits_remaining"] == 3
    mock_credits.consume_credit.assert_not_called()
