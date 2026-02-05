defmodule Cuisine13.RecommendationClient do
  @moduledoc """
  HTTP client for interacting with the recommendation engine API.
  """

  require Logger

  defp recommendation_engine_url do
    System.get_env("RECOMMENDATION_ENGINE_URL") || "http://localhost:8000"
  end

  @doc """
  Fetches recipe recommendations from the recommendation engine.
  Returns {:ok, recommendations} or {:error, reason}.
  """
  def get_feed_recommendations(user_id, household_id, mode \\ "normal", limit \\ 20) do
    url = "#{recommendation_engine_url()}/api/recommend/feed"

    body =
      Jason.encode!(%{
        user_id: user_id,
        household_id: household_id,
        mode: mode,
        limit: limit
      })

    headers = [{'Content-Type', 'application/json'}]

    case :httpc.request(:post, {String.to_charlist(url), headers, 'application/json', String.to_charlist(body)}, [], []) do
      {:ok, {{_, 200, _}, _, response_body}} ->
        case Jason.decode(to_string(response_body)) do
          {:ok, %{"recommendations" => recommendations}} ->
            {:ok, recommendations}

          error ->
            Logger.error("Failed to parse recommendation response: #{inspect(error)}")
            {:error, :parse_error}
        end

      {:ok, {{_, status_code, _}, _, _}} ->
        Logger.error("Recommendation engine returned status #{status_code}")
        {:error, :http_error}

      {:error, reason} ->
        Logger.error("Failed to connect to recommendation engine: #{inspect(reason)}")
        {:error, :connection_error}
    end
  end

  @doc """
  Records user feedback on a recommendation.
  """
  def record_feedback(user_id, recipe_id, action) do
    url = "#{recommendation_engine_url()}/api/recommend/feedback"

    body =
      Jason.encode!(%{
        user_id: user_id,
        recipe_id: recipe_id,
        action: action
      })

    headers = [{'Content-Type', 'application/json'}]

    case :httpc.request(:post, {String.to_charlist(url), headers, 'application/json', String.to_charlist(body)}, [], []) do
      {:ok, {{_, 200, _}, _, _}} ->
        :ok

      _error ->
        Logger.warning("Failed to record feedback, continuing anyway")
        :ok
    end
  end

  @doc """
  Generates new recipes using Claude AI.
  Returns {:ok, recipes} or {:error, reason}.
  """
  def generate_recipes(household_id, count \\ 3, preferences \\ nil) do
    url = "#{recommendation_engine_url()}/api/generate/recipes"

    body =
      Jason.encode!(%{
        household_id: household_id,
        count: count,
        preferences: preferences
      })

    headers = [{'Content-Type', 'application/json'}]

    case :httpc.request(:post, {String.to_charlist(url), headers, 'application/json', String.to_charlist(body)}, [], [{:timeout, 60_000}]) do
      {:ok, {{_, 200, _}, _, response_body}} ->
        case Jason.decode(to_string(response_body)) do
          {:ok, %{"success" => true, "recipes" => recipes}} ->
            {:ok, recipes}

          {:ok, response} ->
            Logger.error("Unexpected response structure: #{inspect(response)}")
            {:error, :parse_error}

          error ->
            Logger.error("Failed to parse generation response: #{inspect(error)}")
            {:error, :parse_error}
        end

      {:ok, {{_, 400, _}, _, response_body}} ->
        Logger.error("Bad request: #{to_string(response_body)}")
        {:error, :no_api_key}

      {:ok, {{_, status_code, _}, _, response_body}} ->
        Logger.error("Generation failed with status #{status_code}: #{to_string(response_body)}")
        {:error, :generation_error}

      {:error, reason} ->
        Logger.error("Failed to connect to recommendation engine: #{inspect(reason)}")
        {:error, :connection_error}
    end
  end
end
