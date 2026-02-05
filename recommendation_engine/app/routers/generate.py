from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
import anthropic
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
import json

from ..database import get_db

router = APIRouter()


async def get_household_api_key(db: AsyncSession, household_id: int):
    """Fetch Anthropic API key for a household."""
    query = text("""
        SELECT anthropic_api_key
        FROM households
        WHERE id = :household_id
    """)

    result = await db.execute(query, {"household_id": household_id})
    row = result.fetchone()

    if row and row.anthropic_api_key:
        return row.anthropic_api_key
    return None


class GenerateRecipesRequest(BaseModel):
    household_id: int
    count: int = 3
    preferences: Optional[str] = None
    dietary_restrictions: Optional[list[str]] = None


class RecipeData(BaseModel):
    title: str
    description: str
    image_url: Optional[str] = None
    image_search: Optional[str] = None  # Search term for finding the right image
    prep_time_minutes: Optional[int] = None
    cook_time_minutes: Optional[int] = None
    total_time_minutes: Optional[int] = None
    servings: Optional[int] = 4
    difficulty: Optional[str] = "medium"
    calories_per_serving: Optional[int] = None
    ingredients: list[dict]  # [{name, amount, unit}]
    instructions: list[str]  # List of step-by-step instructions


class GenerateRecipesResponse(BaseModel):
    success: bool
    recipes: list[RecipeData]
    message: Optional[str] = None


@router.post("/recipes", response_model=GenerateRecipesResponse)
async def generate_recipes(
    request: GenerateRecipesRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Generate new recipe ideas using Claude AI.
    Uses the household's Anthropic API key to generate creative,
    personalized recipe suggestions.
    """
    # Get the API key for this household
    api_key = await get_household_api_key(db, request.household_id)

    if not api_key:
        raise HTTPException(
            status_code=400,
            detail="No Anthropic API key configured for this household. Please add one in settings."
        )

    # Build the prompt
    dietary_info = ""
    if request.dietary_restrictions:
        dietary_info = f"\nDietary restrictions: {', '.join(request.dietary_restrictions)}"

    preferences_info = ""
    if request.preferences:
        preferences_info = f"\nUser preferences: {request.preferences}"

    prompt = f"""Generate {request.count} unique, creative recipe ideas. {dietary_info}{preferences_info}

For each recipe, provide:
1. A catchy, descriptive title
2. A brief description (2-3 sentences) that makes it sound delicious
3. Prep time, cook time, and total time in minutes
4. Number of servings (default to 4)
5. Difficulty level (easy, medium, or hard)
6. Estimated calories per serving
7. A detailed ingredient list with amounts and units
8. Step-by-step cooking instructions
9. A specific Unsplash search query (2-4 words) that would find a photo of THIS EXACT dish

Return the recipes as a JSON array. Each recipe should follow this exact structure:
{{
  "title": "Recipe Name",
  "description": "Brief description...",
  "prep_time_minutes": 15,
  "cook_time_minutes": 30,
  "total_time_minutes": 45,
  "servings": 4,
  "difficulty": "medium",
  "calories_per_serving": 350,
  "image_search": "specific dish name",
  "ingredients": [
    {{"name": "ingredient name", "amount": "1", "unit": "cup"}},
    {{"name": "another ingredient", "amount": "2", "unit": "tablespoons"}}
  ],
  "instructions": [
    "Step 1 description",
    "Step 2 description"
  ]
}}

IMPORTANT for image_search:
- Use the specific dish name (e.g., "chicken tikka masala", "carbonara pasta", "chocolate chip cookies")
- Be specific to the exact dish type, not generic (e.g., "pad thai noodles" not just "asian food")
- Include the main protein or key ingredient if it helps (e.g., "grilled salmon teriyaki")

Make the recipes interesting, achievable, and delicious. Focus on popular cuisines and comfort foods with visual appeal."""

    try:
        # Call Claude API
        client = anthropic.Anthropic(api_key=api_key)

        message = client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=4000,
            messages=[{
                "role": "user",
                "content": prompt
            }]
        )

        # Parse the response
        response_text = message.content[0].text

        # Extract JSON from the response (Claude might wrap it in markdown)
        if "```json" in response_text:
            json_start = response_text.find("```json") + 7
            json_end = response_text.find("```", json_start)
            response_text = response_text[json_start:json_end].strip()
        elif "```" in response_text:
            json_start = response_text.find("```") + 3
            json_end = response_text.find("```", json_start)
            response_text = response_text[json_start:json_end].strip()

        recipes_data = json.loads(response_text)

        # Convert to RecipeData objects
        recipes = []
        for recipe_dict in recipes_data:
            # Use the image_search term to create a specific Unsplash URL
            search_term = recipe_dict.pop("image_search", "food dish").replace(" ", "-")
            recipe_dict["image_url"] = f"https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80&fit=crop&crop=entropy&cs=tinysrgb&fm=jpg&ixid=MnwxfDB8MXxyYW5kb218MHx8{search_term}||en|0|fDB8fHx8fA"
            recipes.append(RecipeData(**recipe_dict))

        return GenerateRecipesResponse(
            success=True,
            recipes=recipes,
            message=f"Successfully generated {len(recipes)} recipes"
        )

    except json.JSONDecodeError as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to parse recipe data from AI response: {str(e)}"
        )
    except anthropic.APIError as e:
        raise HTTPException(
            status_code=500,
            detail=f"Anthropic API error: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate recipes: {str(e)}"
        )
