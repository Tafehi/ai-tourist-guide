import logging

from app.models.itinerary import Itinerary
from app.models.request import TripRequest
from app.services.cache_service import CacheService
from app.services.claude_service import ClaudeService
from app.services.route_optimizer import RouteOptimizerService

logger = logging.getLogger(__name__)


class ItineraryService:
    def __init__(self):
        self.claude = ClaudeService()
        self.cache = CacheService()
        self.route_optimizer = RouteOptimizerService()

    async def generate(self, request: TripRequest) -> tuple[Itinerary, bool, str]:
        cached = await self.cache.get_itinerary(request)
        if cached:
            logger.info("Cache hit for %s", request.destination)
            return cached, True, "cache"

        itinerary, model_used = await self.claude.generate_itinerary(
            destination=request.destination,
            start_date=request.start_date,
            end_date=request.end_date,
            budget=request.budget.value,
            travel_style=request.travel_style.value,
            interests=request.interests,
            dietary_restrictions=request.dietary_restrictions,
            origin=request.origin,
            notes=request.notes,
        )

        itinerary = self._optimize_routes(itinerary, request.destination)

        await self.cache.store_itinerary(request, itinerary)
        return itinerary, False, model_used

    def _optimize_routes(self, itinerary: Itinerary, destination: str) -> Itinerary:
        try:
            optimized_days = []
            for day in itinerary.days:
                activities_dicts = [a.model_dump() for a in day.activities]
                optimized = self.route_optimizer.optimize_day(
                    activities_dicts, destination
                )
                from app.models.itinerary import Activity, DayPlan

                optimized_activities = [Activity.model_validate(a) for a in optimized]
                optimized_days.append(
                    DayPlan(
                        day_number=day.day_number,
                        date=day.date,
                        activities=optimized_activities,
                    )
                )
            return itinerary.model_copy(update={"days": optimized_days})
        except Exception:
            logger.warning(
                "Route optimization failed, returning unoptimized", exc_info=True
            )
            return itinerary
