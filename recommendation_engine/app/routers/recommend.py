from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from typing import Optional
from enum import Enum

router = APIRouter()


class FeedMode(str, Enum):
    normal = "normal"
    steal = "steal"


class FeedRequest(BaseModel):
    user_id: int
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
async def get_personalized_feed(request: FeedRequest):
    """
    Get personalized recipe recommendations for a user.
    In normal mode: returns recipes from database sorted by preference match.
    In steal mode: returns restaurant dishes from Yelp (handled by steal router).
    """
    # TODO: Implement recommendation logic
    # For now, return empty list
    return FeedResponse(mode=request.mode, recommendations=[])


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
    # TODO: Implement Yelp API integration
    return TrendingResponse(location="Your Area", dishes=[])
