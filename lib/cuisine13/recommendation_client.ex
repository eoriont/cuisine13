defmodule Cuisine13.RecommendationClient do
  @moduledoc """
  HTTP client for interacting with the recommendation engine API.
  """

  require Logger

  @doc """
  Fetches recipe recommendations from the recommendation engine.
  Returns {:ok, recommendations} or {:error, reason}.
  """
  def get_feed_recommendations(user_id, mode \\ "discover", limit \\ 20) do
    url = recommendation_engine_url() <> "/api/recommend/feed"

    body = %{
      user_id: user_id,
      mode: mode,
      limit: limit
    }

    client = build_client()

    case Tesla.post(client, url, body) do
      {:ok, %Tesla.Env{status: 200, body: data}} ->
        recommendations = Map.get(data, "recommendations", [])
        {:ok, recommendations}

      {:ok, %Tesla.Env{status: status_code}} ->
        Logger.error("Recommendation engine returned status #{status_code}")
        {:error, {:http_error, status_code}}

      {:error, reason} ->
        Logger.error("Failed to connect to recommendation engine: #{inspect(reason)}")
        {:error, {:connection_error, reason}}
    end
  end

  @doc """
  Records user feedback on a recommendation.
  """
  def record_feedback(user_id, recipe_id, action) do
    url = recommendation_engine_url() <> "/api/recommend/feedback"

    body = %{
      user_id: user_id,
      recipe_id: recipe_id,
      action: action
    }

    client = build_client()

    case Tesla.post(client, url, body) do
      {:ok, %Tesla.Env{status: 200}} ->
        :ok

      {:ok, %Tesla.Env{status: status_code}} ->
        Logger.warning("Feedback recording returned status #{status_code}")
        {:error, {:http_error, status_code}}

      {:error, reason} ->
        Logger.warning("Failed to record feedback: #{inspect(reason)}")
        {:error, {:connection_error, reason}}
    end
  end

  defp build_client do
    middleware = [
      {Tesla.Middleware.BaseUrl, recommendation_engine_url()},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"accept", "application/json"}]},
      {Tesla.Middleware.Timeout, timeout: 5_000}
    ]

    Tesla.client(middleware, Tesla.Adapter.Hackney)
  end

  defp recommendation_engine_url do
    System.get_env("RECOMMENDATION_ENGINE_URL") || "http://localhost:8000"
  end
end
