from unittest.mock import MagicMock, patch

from app.prompts.templates import build_itinerary_prompt
from app.services.claude_service import ClaudeService


def test_build_prompt_basic():
    prompt = build_itinerary_prompt(
        destination="Paris",
        start_date="2026-07-01",
        end_date="2026-07-03",
        duration_days=3,
        budget="mid_range",
        travel_style="moderate",
        interests=["art", "food"],
    )
    assert "Paris" in prompt
    assert "3-day" in prompt
    assert "mid_range" in prompt
    assert "art, food" in prompt


def test_build_prompt_with_all_options():
    prompt = build_itinerary_prompt(
        destination="Tokyo",
        start_date="2026-06-01",
        end_date="2026-06-05",
        duration_days=5,
        budget="luxury",
        travel_style="relaxed",
        interests=["history"],
        dietary_restrictions=["vegetarian"],
        origin="London",
        notes="First time visiting Japan",
    )
    assert "vegetarian" in prompt
    assert "London" in prompt
    assert "First time visiting Japan" in prompt


@patch("app.services.claude_service.get_settings")
def test_model_selection_simple(mock_settings):
    mock_settings.return_value = MagicMock(
        aws_region="eu-west-1",
        claude_model_simple="eu.anthropic.claude-haiku-4-5-20251001-v1:0",
        claude_model_complex="eu.anthropic.claude-haiku-4-5-20251001-v1:0",
    )
    service = ClaudeService()
    assert (
        service._select_model(2, ["food"])
        == "eu.anthropic.claude-haiku-4-5-20251001-v1:0"
    )


@patch("app.services.claude_service.get_settings")
def test_model_selection_complex(mock_settings):
    mock_settings.return_value = MagicMock(
        aws_region="eu-west-1",
        claude_model_simple="eu.anthropic.claude-haiku-4-5-20251001-v1:0",
        claude_model_complex="eu.anthropic.claude-haiku-4-5-20251001-v1:0",
    )
    service = ClaudeService()
    assert (
        service._select_model(7, ["food", "history", "nature"])
        == "eu.anthropic.claude-haiku-4-5-20251001-v1:0"
    )
