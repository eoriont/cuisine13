from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from typing import Optional
from enum import Enum
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from ..database import get_db

router = APIRouter()


async def get_household_api_keys(db: AsyncSession, household_id: Optional[int]):
    """
    Fetch API keys for a household from the database.
    Returns a dict with api keys or None values if household_id is None or keys don't exist.
    """
    if not household_id:
        return {
            "anthropic_api_key": None,
            "yelp_api_key": None,
            "google_places_api_key": None
        }

    query = text("""
        SELECT anthropic_api_key, yelp_api_key, google_places_api_key
        FROM households
        WHERE id = :household_id
    """)

    result = await db.execute(query, {"household_id": household_id})
    row = result.fetchone()

    if row:
        return {
            "anthropic_api_key": row.anthropic_api_key,
            "yelp_api_key": row.yelp_api_key,
            "google_places_api_key": row.google_places_api_key
        }

    return {
        "anthropic_api_key": None,
        "yelp_api_key": None,
        "google_places_api_key": None
    }


class FeedMode(str, Enum):
    normal = "normal"
    steal = "steal"


class FeedRequest(BaseModel):
    user_id: int
    household_id: Optional[int] = None
    mode: FeedMode = FeedMode.normal
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    limit: int = 20


class RecipeRecommendation(BaseModel):
    recipe_id: int
    title: str
    image_url: Optional[str]
    match_score: float  # 0.0 to 1.0
    reason: str  # Why this was recommended


class FeedResponse(BaseModel):
    mode: FeedMode
    recommendations: list[RecipeRecommendation]


class FeedbackRequest(BaseModel):
    user_id: int
    recipe_id: int
    action: str  # 'like', 'cook', 'skip'


@router.post("/feed", response_model=FeedResponse)
async def get_personalized_feed(
    request: FeedRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Get personalized recipe recommendations for a user.
    In normal mode: returns recipes from database sorted by preference match.
    In steal mode: returns restaurant dishes from Yelp (handled by steal router).

    Basic implementation: Returns recent recipes with simple scoring.
    """
    # Fetch household API keys (will be used for AI-powered features)
    api_keys = await get_household_api_keys(db, request.household_id)
    # Note: API keys are available in api_keys dict but not used in basic recommendations yet
    # They will be used for: Claude AI recipe generation, Yelp integration, Google Places, etc.

    # Query for recent recipes
    query = text("""
        SELECT id, title, image_url, inserted_at
        FROM recipes
        ORDER BY inserted_at DESC
        LIMIT :limit
    """)

    result = await db.execute(query, {"limit": request.limit})
    recipes = result.fetchall()

    # Convert to recommendations with basic scoring
    recommendations = []
    for idx, recipe in enumerate(recipes):
        # Simple scoring: newer recipes get higher scores
        match_score = 1.0 - (idx * 0.05)  # Decreases by 0.05 for each position
        match_score = max(0.5, match_score)  # Minimum score of 0.5

        recommendations.append(RecipeRecommendation(
            recipe_id=recipe.id,
            title=recipe.title,
            image_url=recipe.image_url,
            match_score=match_score,
            reason="Recently added recipe"
        ))

    return FeedResponse(mode=request.mode, recommendations=recommendations)


@router.post("/feedback")
async def record_feedback(request: FeedbackRequest):
    """
    Record user feedback on a recipe (like, cook, skip).
    Used to improve future recommendations.
    """
    # TODO: Store feedback in user_preferences table for future ML improvements
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
    # TODO: Implement Yelp API integration
    return TrendingResponse(location="Your Area", dishes=[])
