import asyncio
import json
import logging
import re
from datetime import date

import anthropic

from app.config import get_settings
from app.models.itinerary import Itinerary
from app.prompts.templates import SYSTEM_PROMPT, build_itinerary_prompt

logger = logging.getLogger(__name__)

_bedrock_semaphore = asyncio.Semaphore(3)


def _extract_json(text: str) -> str:
    text = text.strip()
    match = re.search(r"```(?:json)?\s*([\s\S]*?)```", text)
    if match:
        return match.group(1).strip()
    return text


class ClaudeService:
    def __init__(self):
        settings = get_settings()
        self.client = anthropic.AnthropicBedrock(aws_region=settings.aws_region)
        self.model_simple = settings.claude_model_simple
        self.model_complex = settings.claude_model_complex

    def _select_model(self, duration_days: int, interests: list[str]) -> str:
        if duration_days <= 2 and len(interests) <= 2:
            return self.model_simple
        return self.model_complex

    async def generate_itinerary(
        self,
        destination: str,
        start_date: str,
        end_date: str,
        budget: str,
        travel_style: str,
        interests: list[str],
        dietary_restrictions: list[str] | None = None,
        origin: str | None = None,
        notes: str | None = None,
    ) -> tuple[Itinerary, str]:
        start = date.fromisoformat(start_date)
        end = date.fromisoformat(end_date)
        duration_days = (end - start).days + 1

        model = self._select_model(duration_days, interests)
        user_prompt = build_itinerary_prompt(
            destination=destination,
            start_date=start_date,
            end_date=end_date,
            duration_days=duration_days,
            budget=budget,
            travel_style=travel_style,
            interests=interests,
            dietary_restrictions=dietary_restrictions,
            origin=origin,
            notes=notes,
        )

        try:
            async with _bedrock_semaphore:
                response = self.client.messages.create(
                    model=model,
                    max_tokens=4096,
                    system=[
                        {
                            "type": "text",
                            "text": SYSTEM_PROMPT,
                            "cache_control": {"type": "ephemeral"},
                        }
                    ],
                    messages=[{"role": "user", "content": user_prompt}],
                )
        except anthropic.APIStatusError as e:
            logger.error(
                "Bedrock API error: status=%d model=%s region=%s message=%s",
                e.status_code,
                model,
                get_settings().aws_region,
                e.message,
            )
            raise

        raw_text = response.content[0].text
        logger.info(
            "Claude response: model=%s input_tokens=%d output_tokens=%d stop_reason=%s",
            model,
            response.usage.input_tokens,
            response.usage.output_tokens,
            response.stop_reason,
        )

        if response.stop_reason == "max_tokens":
            logger.error(
                "Response truncated (hit max_tokens), raw_text_tail=%s", raw_text[-200:]
            )
            raise ValueError("LLM response was truncated")

        json_text = _extract_json(raw_text)
        if not json_text:
            logger.error("Empty response from Claude, raw_text=%s", raw_text[:500])
            raise ValueError("Empty response from LLM")

        itinerary_data = json.loads(json_text)
        itinerary = Itinerary.model_validate(itinerary_data)
        return itinerary, model
