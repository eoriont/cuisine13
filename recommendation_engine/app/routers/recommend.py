from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from typing import Optional
from enum import Enum
import os
import asyncpg

from ..services.yelp import YelpService, get_yelp_service

router = APIRouter()


class FeedMode(str, Enum):
    normal = "normal"
    steal = "steal"
    trending = "trending"


class FeedRequest(BaseModel):
    user_id: int
    mode: FeedMode = FeedMode.normal
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    limit: int = 20


class FeedResponse(BaseModel):
    mode: FeedMode
    recipes: list[int]  # List of recipe IDs
    steal_dishes: Optional[list[dict]] = None


class FeedbackRequest(BaseModel):
    user_id: int
    recipe_id: int
    action: str  # 'like', 'cook', 'skip'


async def get_db_pool():
    """Get database connection pool."""
    database_url = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@db:5432/cuisine13_dev")
    return await asyncpg.create_pool(database_url)


@router.post("/feed", response_model=FeedResponse)
async def get_personalized_feed(request: FeedRequest):
    """
    Get personalized recipe recommendations for a user.
    In normal mode: returns recipes from database sorted by preference match.
    In steal mode: returns restaurant dishes from Yelp.
    In trending mode: returns trending local dishes.
    """
    try:
        pool = await get_db_pool()
        async with pool.acquire() as conn:
            # Get recipe IDs from database
            # For now, simple ordering by recent + liked count
            # TODO: Add ML-based personalization
            rows = await conn.fetch(
                """
                SELECT r.id
                FROM recipes r
                LEFT JOIN recipe_likes rl ON r.id = rl.recipe_id
                GROUP BY r.id
                ORDER BY COUNT(rl.id) DESC, r.inserted_at DESC
                LIMIT $1
                """,
                request.limit
            )
            recipe_ids = [row["id"] for row in rows]
        await pool.close()
    except Exception as e:
        print(f"Database error: {e}")
        recipe_ids = []

    steal_dishes = None

    # If steal mode, also fetch restaurant dishes
    if request.mode == FeedMode.steal and request.latitude and request.longitude:
        try:
            yelp = get_yelp_service()
            steal_dishes = await yelp.get_nearby_dishes(
                latitude=request.latitude,
                longitude=request.longitude,
                limit=request.limit,
            )
        except Exception as e:
            print(f"Yelp error: {e}")
            steal_dishes = []

    return FeedResponse(
        mode=request.mode,
        recipes=recipe_ids,
        steal_dishes=steal_dishes
    )


@router.post("/feedback")
async def record_feedback(request: FeedbackRequest):
    """
    Record user feedback on a recipe (like, cook, skip).
    Used to improve future recommendations.
    """
    # TODO: Store feedback in user_preferences table
    return {"status": "recorded", "user_id": request.user_id, "recipe_id": request.recipe_id}


class TrendingRequest(BaseModel):
    latitude: float
    longitude: float
    radius_miles: float = 5.0


class TrendingDish(BaseModel):
    dish_name: str
    restaurant_name: str
    restaurant_logo: Optional[str]
    image_url: Optional[str]
    rating: float
    distance_miles: float


class TrendingResponse(BaseModel):
    location: str
    dishes: list[TrendingDish]


@router.post("/trending", response_model=TrendingResponse)
async def get_trending_nearby(request: TrendingRequest):
    """
    Get trending dishes from restaurants near the user's location.
    Uses Yelp API to find popular items.
    """
    try:
        yelp = get_yelp_service()
        dishes = await yelp.get_nearby_dishes(
            latitude=request.latitude,
            longitude=request.longitude,
            radius_meters=int(request.radius_miles * 1609.34),
        )
        return TrendingResponse(
            location="Your Area",
            dishes=[
                TrendingDish(
                    dish_name=d["dish_name"],
                    restaurant_name=d["restaurant_name"],
                    restaurant_logo=d.get("restaurant_logo"),
                    image_url=d.get("dish_image"),
                    rating=d.get("rating", 0),
                    distance_miles=d.get("distance_miles", 0),
                )
                for d in dishes
            ]
        )
    except Exception as e:
        print(f"Trending error: {e}")
        return TrendingResponse(location="Your Area", dishes=[])
