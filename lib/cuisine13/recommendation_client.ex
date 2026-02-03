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

    case HTTPoison.post(url, Jason.encode!(body), headers(), recv_timeout: 5000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, data} ->
            recommendations = Map.get(data, "recommendations", [])
            {:ok, recommendations}

          {:error, _} = error ->
            Logger.error("Failed to decode recommendation response: #{inspect(error)}")
            {:error, :decode_error}
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        Logger.error("Recommendation engine returned status #{status_code}")
        {:error, {:http_error, status_code}}

      {:error, %HTTPoison.Error{reason: reason}} ->
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

    case HTTPoison.post(url, Jason.encode!(body), headers(), recv_timeout: 5000) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        :ok

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        Logger.warning("Feedback recording returned status #{status_code}")
        {:error, {:http_error, status_code}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.warning("Failed to record feedback: #{inspect(reason)}")
        {:error, {:connection_error, reason}}
    end
  end

  defp recommendation_engine_url do
    System.get_env("RECOMMENDATION_ENGINE_URL") || "http://localhost:8000"
  end

  defp headers do
    [
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ]
  end
end
