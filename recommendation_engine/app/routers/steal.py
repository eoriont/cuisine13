from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from pydantic import BaseModel
from typing import Optional
import base64

from ..services.claude import ClaudeService, get_claude_service
from ..services.yelp import YelpService, get_yelp_service

router = APIRouter()


class RestaurantDish(BaseModel):
    yelp_business_id: str
    restaurant_name: str
    restaurant_logo: Optional[str]
    dish_name: str
    dish_image: Optional[str]
    rating: float
    distance_miles: float
    price_level: Optional[str]  # '$', '$$', '$$$', '$$$$'


class StealFeedRequest(BaseModel):
    latitude: float
    longitude: float
    user_id: int
    limit: int = 20


class StealFeedResponse(BaseModel):
    dishes: list[RestaurantDish]


class StealFromTextRequest(BaseModel):
    user_id: int
    query: str  # e.g., "Orange Chicken from Panda Express"


class StealFromImageRequest(BaseModel):
    user_id: int
    image_base64: str


class GeneratedRecipe(BaseModel):
    title: str
    description: str
    ingredients: list[dict]  # {name, quantity, unit}
    instructions: list[str]
    prep_time_minutes: int
    cook_time_minutes: int
    servings: int
    source_restaurant: Optional[str]
    source_dish: Optional[str]


class StealResponse(BaseModel):
    success: bool
    recipe: Optional[GeneratedRecipe]
    error: Optional[str]


@router.post("/feed", response_model=StealFeedResponse)
async def get_steal_feed(
    request: StealFeedRequest,
    yelp: YelpService = Depends(get_yelp_service),
):
    """
    Get a feed of dishes from local restaurants for Steal Mode.
    Returns dishes sorted by user preference match + distance.
    """
    dishes = await yelp.get_nearby_dishes(
        latitude=request.latitude,
        longitude=request.longitude,
        limit=request.limit,
    )
    return StealFeedResponse(dishes=dishes)


@router.post("/from-text", response_model=StealResponse)
async def steal_from_text(
    request: StealFromTextRequest,
    claude: ClaudeService = Depends(get_claude_service),
    yelp: YelpService = Depends(get_yelp_service),
):
    """
    Generate a recipe from a text description of a restaurant dish.
    E.g., "Orange Chicken from Panda Express"
    """
    try:
        # Parse the query to extract dish and restaurant
        parsed = claude.parse_dish_query(request.query)

        # Try to find restaurant info from Yelp
        restaurant_info = None
        if parsed.get("restaurant"):
            restaurant_info = await yelp.search_restaurant(parsed["restaurant"])

        # Generate the recipe
        recipe = claude.generate_recipe_from_dish(
            dish_name=parsed.get("dish", request.query),
            restaurant_name=parsed.get("restaurant"),
            restaurant_info=restaurant_info,
        )

        return StealResponse(success=True, recipe=recipe, error=None)
    except Exception as e:
        return StealResponse(success=False, recipe=None, error=str(e))


@router.post("/from-image", response_model=StealResponse)
async def steal_from_image(
    request: StealFromImageRequest,
    claude: ClaudeService = Depends(get_claude_service),
):
    """
    Generate a recipe from a photo of a dish.
    Uses Claude Vision to identify the dish.
    """
    try:
        # Identify the dish from the image
        identification = claude.identify_dish_from_image(request.image_base64)

        # Generate the recipe
        recipe = claude.generate_recipe_from_dish(
            dish_name=identification.get("dish_name", "Unknown Dish"),
            restaurant_name=identification.get("restaurant"),
            cuisine=identification.get("cuisine"),
        )

        return StealResponse(success=True, recipe=recipe, error=None)
    except Exception as e:
        return StealResponse(success=False, recipe=None, error=str(e))


@router.post("/from-restaurant")
async def steal_from_restaurant_menu(
    yelp_business_id: str,
    dish_name: str,
    user_id: int,
    claude: ClaudeService = Depends(get_claude_service),
    yelp: YelpService = Depends(get_yelp_service),
):
    """
    Generate a recipe from a specific restaurant's dish.
    Used when user selects a dish from the Steal Mode feed.
    """
    try:
        # Get restaurant details
        restaurant = await yelp.get_business_details(yelp_business_id)

        # Generate the recipe
        recipe = claude.generate_recipe_from_dish(
            dish_name=dish_name,
            restaurant_name=restaurant.get("name"),
            restaurant_info=restaurant,
        )

        return StealResponse(success=True, recipe=recipe, error=None)
    except Exception as e:
        return StealResponse(success=False, recipe=None, error=str(e))
