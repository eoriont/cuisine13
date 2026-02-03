import anthropic
from typing import Optional
import json

from ..config import get_settings


class ClaudeService:
    def __init__(self, api_key: str):
        self.client = anthropic.Anthropic(api_key=api_key)
        self.haiku_model = "claude-3-haiku-20240307"
        self.sonnet_model = "claude-sonnet-4-20250514"

    def normalize_ingredient(self, text: str) -> dict:
        """
        Normalize and spell-check a single ingredient using Claude Haiku.
        """
        prompt = f"""You are an ingredient spell-checker and normalizer.
Given an ingredient text, correct any spelling errors and normalize the format.

Input: "{text}"

Respond with JSON only:
{{
    "original": "{text}",
    "corrected": "<corrected ingredient name>",
    "was_corrected": <true if changed, false if same>,
    "confidence": <0.0 to 1.0>
}}

Rules:
- Fix spelling errors (chiken -> chicken)
- Standardize format (2% milk -> milk, 2%)
- Keep quantities if present
- Return was_corrected: false if no changes needed"""

        response = self.client.messages.create(
            model=self.haiku_model,
            max_tokens=150,
            messages=[{"role": "user", "content": prompt}],
        )

        try:
            result = json.loads(response.content[0].text)
            return result
        except json.JSONDecodeError:
            return {
                "original": text,
                "corrected": text,
                "was_corrected": False,
                "confidence": 1.0,
            }

    def normalize_ingredients_batch(self, ingredients: list[str]) -> list[dict]:
        """
        Normalize multiple ingredients at once (more efficient).
        """
        if not ingredients:
            return []

        ingredients_list = "\n".join(f"- {ing}" for ing in ingredients)

        prompt = f"""You are an ingredient spell-checker and normalizer.
Given a list of ingredients, correct spelling errors and normalize formats.

Ingredients:
{ingredients_list}

Respond with JSON array only:
[
    {{"original": "...", "corrected": "...", "was_corrected": true/false, "confidence": 0.0-1.0}},
    ...
]

Rules:
- Fix spelling errors (chiken -> chicken)
- Standardize format (2% milk -> milk, 2%)
- Keep quantities if present
- Return was_corrected: false if no changes needed
- Return results in same order as input"""

        response = self.client.messages.create(
            model=self.haiku_model,
            max_tokens=1000,
            messages=[{"role": "user", "content": prompt}],
        )

        try:
            results = json.loads(response.content[0].text)
            return results
        except json.JSONDecodeError:
            # Fallback: return unchanged
            return [
                {"original": ing, "corrected": ing, "was_corrected": False, "confidence": 1.0}
                for ing in ingredients
            ]

    def generate_recipe_facts(
        self,
        title: str,
        ingredients: list[str],
        cuisine: Optional[str] = None,
    ) -> list[dict]:
        """
        Generate interesting facts about a recipe using Claude Haiku.
        """
        ingredients_str = ", ".join(ingredients[:10])  # Limit to first 10
        cuisine_str = f" ({cuisine} cuisine)" if cuisine else ""

        prompt = f"""Generate 2-3 interesting, short facts about this dish.

Dish: {title}{cuisine_str}
Key ingredients: {ingredients_str}

Respond with JSON array only:
[
    {{"fact_type": "history|nutrition|tip|fun_fact", "content": "<one sentence, max 100 chars>"}},
    ...
]

Guidelines:
- Keep each fact to ONE short sentence
- Be specific and interesting, not generic
- Include at least one nutrition fact if possible
- Make it feel like Uber's clean, compact UI style"""

        response = self.client.messages.create(
            model=self.haiku_model,
            max_tokens=400,
            messages=[{"role": "user", "content": prompt}],
        )

        try:
            facts = json.loads(response.content[0].text)
            return facts
        except json.JSONDecodeError:
            return []

    def parse_dish_query(self, query: str) -> dict:
        """
        Parse a natural language query to extract dish name and restaurant.
        E.g., "Orange Chicken from Panda Express" -> {"dish": "Orange Chicken", "restaurant": "Panda Express"}
        """
        prompt = f"""Parse this food query to extract the dish name and restaurant (if mentioned).

Query: "{query}"

Respond with JSON only:
{{
    "dish": "<dish name>",
    "restaurant": "<restaurant name or null if not mentioned>",
    "cuisine": "<detected cuisine type or null>"
}}"""

        response = self.client.messages.create(
            model=self.haiku_model,
            max_tokens=150,
            messages=[{"role": "user", "content": prompt}],
        )

        try:
            return json.loads(response.content[0].text)
        except json.JSONDecodeError:
            return {"dish": query, "restaurant": None, "cuisine": None}

    def generate_recipe_from_dish(
        self,
        dish_name: str,
        restaurant_name: Optional[str] = None,
        restaurant_info: Optional[dict] = None,
        cuisine: Optional[str] = None,
    ) -> dict:
        """
        Generate a homemade recipe based on a restaurant dish.
        Uses Claude Sonnet for higher quality output.
        """
        context = f"Dish: {dish_name}"
        if restaurant_name:
            context += f"\nFrom: {restaurant_name}"
        if cuisine:
            context += f"\nCuisine: {cuisine}"
        if restaurant_info:
            if restaurant_info.get("categories"):
                context += f"\nRestaurant type: {', '.join(c.get('title', '') for c in restaurant_info['categories'][:3])}"

        prompt = f"""Create a homemade recipe that recreates this restaurant dish.

{context}

Respond with JSON only:
{{
    "title": "<recipe title>",
    "description": "<2-3 sentence description>",
    "ingredients": [
        {{"name": "<ingredient>", "quantity": "<amount>", "unit": "<unit or null>"}}
    ],
    "instructions": ["<step 1>", "<step 2>", ...],
    "prep_time_minutes": <number>,
    "cook_time_minutes": <number>,
    "servings": <number>,
    "source_restaurant": "{restaurant_name or ''}",
    "source_dish": "{dish_name}"
}}

Guidelines:
- Make it achievable for home cooks
- Use common ingredients (suggest substitutes for hard-to-find items)
- Include tips to get restaurant-quality results
- Be specific with quantities and techniques"""

        response = self.client.messages.create(
            model=self.sonnet_model,
            max_tokens=2000,
            messages=[{"role": "user", "content": prompt}],
        )

        try:
            return json.loads(response.content[0].text)
        except json.JSONDecodeError:
            raise ValueError("Failed to generate recipe")

    def identify_dish_from_image(self, image_base64: str) -> dict:
        """
        Identify a dish from a photo using Claude Vision.
        """
        prompt = """Identify this dish from the photo.

Respond with JSON only:
{
    "dish_name": "<name of the dish>",
    "restaurant": "<restaurant name if visible, or null>",
    "cuisine": "<cuisine type>",
    "confidence": <0.0 to 1.0>
}"""

        response = self.client.messages.create(
            model=self.sonnet_model,
            max_tokens=200,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": image_base64,
                            },
                        },
                        {"type": "text", "text": prompt},
                    ],
                }
            ],
        )

        try:
            return json.loads(response.content[0].text)
        except json.JSONDecodeError:
            return {"dish_name": "Unknown Dish", "restaurant": None, "cuisine": None, "confidence": 0.0}


# Dependency injection
def get_claude_service() -> ClaudeService:
    settings = get_settings()
    if not settings.anthropic_api_key:
        raise ValueError("ANTHROPIC_API_KEY not configured")
    return ClaudeService(settings.anthropic_api_key)
