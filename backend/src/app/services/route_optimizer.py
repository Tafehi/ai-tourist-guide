import logging
from typing import Any

import boto3
import requests

from app.config import get_settings

logger = logging.getLogger(__name__)


class RouteOptimizerService:
    def __init__(self):
        self.api_key = self._get_google_api_key()

    def _get_google_api_key(self) -> str:
        settings = get_settings()
        if not settings.google_maps_secret_name:
            return ""
        client = boto3.client("secretsmanager", region_name=settings.aws_region)
        response = client.get_secret_value(SecretId=settings.google_maps_secret_name)
        return response["SecretString"]

    def optimize_day(
        self, activities: list[dict[str, Any]], city: str
    ) -> list[dict[str, Any]]:
        if not self.api_key or len(activities) <= 2:
            return activities

        meal_indices = []
        non_meal_activities = []

        for i, activity in enumerate(activities):
            title_lower = activity.get("title", "").lower()
            if any(
                word in title_lower
                for word in ["lunch", "dinner", "breakfast", "brunch"]
            ):
                meal_indices.append(i)
            else:
                non_meal_activities.append(activity)

        if len(non_meal_activities) <= 1:
            return activities

        coords = self._geocode_activities(non_meal_activities, city)
        if not coords or len(coords) < 2:
            return activities

        optimized_order = self._get_optimized_order(coords)
        if not optimized_order:
            return activities

        reordered = [non_meal_activities[i] for i in optimized_order]
        return self._reinsert_meals(reordered, activities, meal_indices)

    def _geocode_activities(
        self, activities: list[dict[str, Any]], city: str
    ) -> list[dict[str, float] | None]:
        coords: list[dict[str, float] | None] = []
        for activity in activities:
            location = activity.get("location", "")
            query = f"{location}, {city}"
            try:
                resp = requests.get(
                    "https://maps.googleapis.com/maps/api/geocode/json",
                    params={"address": query, "key": self.api_key},
                    timeout=5,
                )
                data = resp.json()
                if data.get("results"):
                    loc = data["results"][0]["geometry"]["location"]
                    coords.append({"lat": loc["lat"], "lng": loc["lng"]})
                else:
                    coords.append(None)
            except Exception:
                logger.warning("Geocoding failed for: %s", query)
                coords.append(None)
        return coords

    def _get_optimized_order(
        self, coords: list[dict[str, float] | None]
    ) -> list[int] | None:
        valid_coords = [(i, c) for i, c in enumerate(coords) if c is not None]
        if len(valid_coords) < 2:
            return None

        origin = valid_coords[0][1]
        destination = valid_coords[-1][1]
        intermediates = [c for _, c in valid_coords[1:-1]]

        body: dict[str, Any] = {
            "origin": {
                "location": {
                    "latLng": {"latitude": origin["lat"], "longitude": origin["lng"]}
                }
            },
            "destination": {
                "location": {
                    "latLng": {
                        "latitude": destination["lat"],
                        "longitude": destination["lng"],
                    }
                }
            },
            "intermediates": [
                {"location": {"latLng": {"latitude": c["lat"], "longitude": c["lng"]}}}
                for c in intermediates
            ],
            "travelMode": "WALK",
            "optimizeWaypointOrder": True,
        }

        try:
            resp = requests.post(
                "https://routes.googleapis.com/directions/v2:computeRoutes",
                json=body,
                headers={
                    "X-Goog-Api-Key": self.api_key,
                    "X-Goog-FieldMask": "routes.optimizedIntermediateWaypointIndex",
                },
                timeout=10,
            )
            data = resp.json()
            if "routes" not in data or not data["routes"]:
                return None

            route = data["routes"][0]
            optimized_indices = route.get("optimizedIntermediateWaypointIndex", [])

            original_indices = [i for i, _ in valid_coords]
            result = [original_indices[0]]
            for opt_idx in optimized_indices:
                result.append(original_indices[opt_idx + 1])
            result.append(original_indices[-1])
            return result
        except Exception:
            logger.warning("Route optimization failed", exc_info=True)
            return None

    def _reinsert_meals(
        self,
        reordered: list[dict[str, Any]],
        original: list[dict[str, Any]],
        meal_indices: list[int],
    ) -> list[dict[str, Any]]:
        result = []
        meal_activities = [original[i] for i in meal_indices]

        non_meal_idx = 0
        for orig_activity in original:
            if orig_activity in meal_activities:
                result.append(orig_activity)
            else:
                if non_meal_idx < len(reordered):
                    result.append(reordered[non_meal_idx])
                    non_meal_idx += 1

        while non_meal_idx < len(reordered):
            result.append(reordered[non_meal_idx])
            non_meal_idx += 1

        return result
