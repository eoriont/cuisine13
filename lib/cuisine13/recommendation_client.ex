defmodule Cuisine13.RecommendationClient do
  @moduledoc """
  HTTP client for interacting with the recommendation engine API.

  Note: Currently returns fallback responses as the recommendation engine
  endpoints are not yet implemented (TODO stubs). This allows the app to
  function using database recipes until the recommendation engine is ready.
  """

  require Logger

  @doc """
  Fetches recipe recommendations from the recommendation engine.
  Returns {:ok, recommendations} or {:error, reason}.

  Currently returns :not_implemented to trigger fallback to database recipes.
  """
  def get_feed_recommendations(_user_id, _mode \\ "discover", _limit \\ 20) do
    Logger.info("Recommendation engine not yet integrated - using database fallback")
    {:error, :not_implemented}
  end

  @doc """
  Records user feedback on a recommendation.
  Currently a no-op until recommendation engine is implemented.
  """
  def record_feedback(_user_id, _recipe_id, _action) do
    :ok
  end
end
