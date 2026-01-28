defmodule Cuisine13.Recommendation.Client do
  @moduledoc """
  HTTP client for communicating with the recommendation engine (FastAPI).
  """

  @default_timeout 30_000

  defp base_url do
    System.get_env("RECOMMENDATION_ENGINE_URL", "http://localhost:8000")
  end

  @doc """
  Check if the recommendation engine is healthy.
  """
  def health_check do
    case HTTPoison.get("#{base_url()}/health", [], timeout: 5_000, recv_timeout: 5_000) do
      {:ok, %{status_code: 200}} -> :ok
      _ -> :error
    end
  end

  @doc """
  Normalize/spell-check an ingredient.
  """
  def normalize_ingredient(text) do
    body = Jason.encode!(%{text: text})

    case post("/api/ingredients/normalize", body) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Normalize multiple ingredients at once.
  """
  def normalize_ingredients_batch(ingredients) when is_list(ingredients) do
    body = Jason.encode!(%{ingredients: ingredients})

    case post("/api/ingredients/normalize/batch", body) do
      {:ok, %{"results" => results}} -> {:ok, results}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Generate facts about a recipe.
  """
  def generate_recipe_facts(recipe_id, title, ingredients, cuisine \\ nil) do
    body =
      Jason.encode!(%{
        recipe_id: recipe_id,
        title: title,
        ingredients: ingredients,
        cuisine: cuisine
      })

    case post("/api/facts/generate", body) do
      {:ok, %{"facts" => facts}} -> {:ok, facts}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get personalized feed recommendations.
  """
  def get_feed(user_id, mode \\ "normal", opts \\ []) do
    body =
      Jason.encode!(%{
        user_id: user_id,
        mode: mode,
        latitude: Keyword.get(opts, :latitude),
        longitude: Keyword.get(opts, :longitude),
        limit: Keyword.get(opts, :limit, 20)
      })

    case post("/api/recommend/feed", body) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get steal mode feed (local restaurant dishes).
  """
  def get_steal_feed(user_id, latitude, longitude, limit \\ 20) do
    body =
      Jason.encode!(%{
        user_id: user_id,
        latitude: latitude,
        longitude: longitude,
        limit: limit
      })

    case post("/api/steal/feed", body) do
      {:ok, %{"dishes" => dishes}} -> {:ok, dishes}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Steal a recipe from text description.
  E.g., "Orange Chicken from Panda Express"
  """
  def steal_from_text(user_id, query) do
    body = Jason.encode!(%{user_id: user_id, query: query})

    case post("/api/steal/from-text", body) do
      {:ok, %{"success" => true, "recipe" => recipe}} -> {:ok, recipe}
      {:ok, %{"success" => false, "error" => error}} -> {:error, error}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Steal a recipe from an image.
  """
  def steal_from_image(user_id, image_base64) do
    body = Jason.encode!(%{user_id: user_id, image_base64: image_base64})

    case post("/api/steal/from-image", body) do
      {:ok, %{"success" => true, "recipe" => recipe}} -> {:ok, recipe}
      {:ok, %{"success" => false, "error" => error}} -> {:error, error}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get trending dishes nearby.
  """
  def get_trending(latitude, longitude, radius_miles \\ 5.0) do
    body =
      Jason.encode!(%{
        latitude: latitude,
        longitude: longitude,
        radius_miles: radius_miles
      })

    case post("/api/recommend/trending", body) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end

  # Private helpers

  defp post(path, body) do
    headers = [{"Content-Type", "application/json"}]

    case HTTPoison.post("#{base_url()}#{path}", body, headers,
           timeout: @default_timeout,
           recv_timeout: @default_timeout
         ) do
      {:ok, %{status_code: 200, body: response_body}} ->
        {:ok, Jason.decode!(response_body)}

      {:ok, %{status_code: status, body: response_body}} ->
        {:error, "HTTP #{status}: #{response_body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end
end
