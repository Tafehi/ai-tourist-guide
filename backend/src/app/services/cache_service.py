import hashlib
import json
import logging
import time

import boto3
from botocore.exceptions import ClientError

from app.config import get_settings
from app.models.itinerary import Itinerary
from app.models.request import TripRequest

logger = logging.getLogger(__name__)


class CacheService:
    def __init__(self):
        settings = get_settings()
        self.dynamodb = boto3.resource("dynamodb", region_name=settings.aws_region)
        self.table = self.dynamodb.Table(settings.dynamodb_table_itineraries)

    def _cache_key(self, request: TripRequest) -> str:
        key_parts = {
            "destination": request.destination.lower().strip(),
            "start_date": request.start_date,
            "end_date": request.end_date,
            "budget": request.budget.value,
            "travel_style": request.travel_style.value,
            "interests": sorted(request.interests),
        }
        key_str = json.dumps(key_parts, sort_keys=True)
        return hashlib.sha256(key_str.encode()).hexdigest()[:16]

    async def get_itinerary(self, request: TripRequest) -> Itinerary | None:
        cache_key = self._cache_key(request)
        try:
            response = self.table.get_item(
                Key={"pk": f"CACHE#{cache_key}", "sk": "itinerary"}
            )
            item = response.get("Item")
            if not item:
                return None

            if item.get("expires_at", 0) < int(time.time()):
                return None

            return Itinerary.model_validate_json(item["data"])
        except ClientError:
            logger.warning("DynamoDB cache read failed", exc_info=True)
            return None

    async def store_itinerary(self, request: TripRequest, itinerary: Itinerary) -> None:
        cache_key = self._cache_key(request)
        ttl = int(time.time()) + 86400  # 24 hours
        try:
            self.table.put_item(
                Item={
                    "pk": f"CACHE#{cache_key}",
                    "sk": "itinerary",
                    "data": itinerary.model_dump_json(),
                    "destination": request.destination,
                    "created_at": int(time.time()),
                    "expires_at": ttl,
                }
            )
        except ClientError:
            logger.warning("DynamoDB cache write failed", exc_info=True)
