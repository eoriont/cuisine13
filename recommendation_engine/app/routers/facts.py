from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional

from ..services.claude import ClaudeService, get_claude_service

router = APIRouter()


class RecipeFactsRequest(BaseModel):
    recipe_id: int
    title: str
    ingredients: list[str]
    cuisine: Optional[str] = None


class RecipeFact(BaseModel):
    fact_type: str  # 'history', 'nutrition', 'tip', 'fun_fact'
    content: str


class RecipeFactsResponse(BaseModel):
    recipe_id: int
    facts: list[RecipeFact]


@router.post("/generate", response_model=RecipeFactsResponse)
async def generate_recipe_facts(
    request: RecipeFactsRequest,
    claude: ClaudeService = Depends(get_claude_service),
):
    """
    Generate interesting facts about a recipe.
    Uses Claude Haiku for fast generation.
    Facts are cached after first generation.
    """
    facts = await claude.generate_recipe_facts(
        title=request.title,
        ingredients=request.ingredients,
        cuisine=request.cuisine,
    )
    return RecipeFactsResponse(recipe_id=request.recipe_id, facts=facts)
