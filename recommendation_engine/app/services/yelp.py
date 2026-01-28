import httpx
from typing import Optional

from ..config import get_settings


class YelpService:
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.base_url = "https://api.yelp.com/v3"
        self.headers = {"Authorization": f"Bearer {api_key}"}

    async def get_nearby_dishes(
        self,
        latitude: float,
        longitude: float,
        limit: int = 20,
        radius_meters: int = 8000,  # ~5 miles
    ) -> list[dict]:
        """
        Get dishes from nearby restaurants for Steal Mode feed.
        """
        async with httpx.AsyncClient() as client:
            # Search for restaurants
            response = await client.get(
                f"{self.base_url}/businesses/search",
                headers=self.headers,
                params={
                    "latitude": latitude,
                    "longitude": longitude,
                    "radius": radius_meters,
                    "categories": "restaurants,food",
                    "sort_by": "rating",
                    "limit": limit,
                },
            )

            if response.status_code != 200:
                return []

            data = response.json()
            businesses = data.get("businesses", [])

            dishes = []
            for biz in businesses:
                # For each restaurant, create a dish entry
                # In a real implementation, we'd get actual menu items
                # For now, we use the restaurant's top categories as dish types
                dish = {
                    "yelp_business_id": biz.get("id"),
                    "restaurant_name": biz.get("name"),
                    "restaurant_logo": biz.get("image_url"),
                    "dish_name": self._generate_dish_name(biz),
                    "dish_image": biz.get("image_url"),
                    "rating": biz.get("rating", 0),
                    "distance_miles": round(biz.get("distance", 0) / 1609.34, 1),
                    "price_level": biz.get("price"),
                }
                dishes.append(dish)

            return dishes

    def _generate_dish_name(self, business: dict) -> str:
        """
        Generate a representative dish name from restaurant categories.
        In production, this would come from actual menu data.
        """
        categories = business.get("categories", [])
        if categories:
            category = categories[0].get("title", "Special")
            return f"{business.get('name', 'Restaurant')} {category}"
        return f"{business.get('name', 'Restaurant')} Special"

    async def search_restaurant(self, name: str, location: Optional[str] = None) -> Optional[dict]:
        """
        Search for a restaurant by name.
        """
        async with httpx.AsyncClient() as client:
            params = {"term": name, "categories": "restaurants", "limit": 1}

            if location:
                params["location"] = location
            else:
                # Default to a broad search (would need user location in production)
                params["location"] = "United States"

            response = await client.get(
                f"{self.base_url}/businesses/search",
                headers=self.headers,
                params=params,
            )

            if response.status_code != 200:
                return None

            data = response.json()
            businesses = data.get("businesses", [])

            if businesses:
                return businesses[0]
            return None

    async def get_business_details(self, business_id: str) -> Optional[dict]:
        """
        Get detailed information about a specific business.
        """
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/businesses/{business_id}",
                headers=self.headers,
            )

            if response.status_code != 200:
                return None

            return response.json()


# Dependency injection
def get_yelp_service() -> YelpService:
    settings = get_settings()
    if not settings.yelp_api_key:
        # Return a mock service that returns empty results
        return MockYelpService()
    return YelpService(settings.yelp_api_key)


class MockYelpService:
    """Mock Yelp service when API key is not configured."""

    async def get_nearby_dishes(self, **kwargs) -> list[dict]:
        return []

    async def search_restaurant(self, name: str, location: str = None) -> dict | None:
        return None

    async def get_business_details(self, business_id: str) -> dict | None:
        return None
