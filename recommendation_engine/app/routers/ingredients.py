from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional

from ..services.claude import ClaudeService, get_claude_service

router = APIRouter()


class NormalizeRequest(BaseModel):
    text: str


class NormalizeResponse(BaseModel):
    original: str
    corrected: str
    was_corrected: bool
    confidence: float


class BatchNormalizeRequest(BaseModel):
    ingredients: list[str]


class BatchNormalizeResponse(BaseModel):
    results: list[NormalizeResponse]


@router.post("/normalize", response_model=NormalizeResponse)
async def normalize_ingredient(
    request: NormalizeRequest,
    claude: ClaudeService = Depends(get_claude_service),
):
    """
    Normalize and spell-check a single ingredient.
    Uses Claude Haiku for fast, cheap processing.
    """
    result = await claude.normalize_ingredient(request.text)
    return result


@router.post("/normalize/batch", response_model=BatchNormalizeResponse)
async def normalize_ingredients_batch(
    request: BatchNormalizeRequest,
    claude: ClaudeService = Depends(get_claude_service),
):
    """
    Normalize and spell-check multiple ingredients at once.
    More efficient than calling normalize multiple times.
    """
    results = await claude.normalize_ingredients_batch(request.ingredients)
    return BatchNormalizeResponse(results=results)
