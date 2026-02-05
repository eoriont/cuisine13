defmodule Cuisine13.RecipeGenerator do
  @moduledoc """
  Background recipe generation using Claude AI.
  Generates new recipes periodically and adds them to the database.
  """

  require Logger
  alias Cuisine13.{Recipes, Households, RecommendationClient}

  @doc """
  Generates recipes for all households that have an Anthropic API key configured.
  Returns a summary of recipes created.
  """
  def generate_for_all_households(count_per_household \\ 3) do
    # Get all households with API keys
    households = Households.list_households_with_api_keys()

    results =
      Enum.map(households, fn household ->
        generate_for_household(household.id, count_per_household)
      end)

    success_count = Enum.count(results, fn {status, _} -> status == :ok end)
    total_recipes = Enum.reduce(results, 0, fn
      {:ok, recipes}, acc -> acc + length(recipes)
      _, acc -> acc
    end)

    Logger.info("Recipe generation complete: #{success_count}/#{length(households)} households, #{total_recipes} new recipes")

    {:ok, %{households_processed: length(households), recipes_created: total_recipes}}
  end

  @doc """
  Generates recipes for a specific household.
  Returns {:ok, recipes} or {:error, reason}.
  """
  def generate_for_household(household_id, count \\ 3) do
    Logger.info("Generating #{count} recipes for household #{household_id}")

    case RecommendationClient.generate_recipes(household_id, count) do
      {:ok, recipes_data} ->
        # Save each recipe to the database
        saved_recipes =
          Enum.map(recipes_data, fn recipe_data ->
            case Recipes.create_recipe_with_details(recipe_data) do
              {:ok, recipe} ->
                Logger.info("Created recipe: #{recipe.title} (ID: #{recipe.id})")
                {:ok, recipe}

              {:error, changeset} ->
                Logger.error("Failed to create recipe: #{inspect(changeset.errors)}")
                {:error, changeset}
            end
          end)

        # Filter out errors
        successful_recipes =
          saved_recipes
          |> Enum.filter(fn {status, _} -> status == :ok end)
          |> Enum.map(fn {:ok, recipe} -> recipe end)

        {:ok, successful_recipes}

      {:error, :no_api_key} ->
        Logger.warning("Household #{household_id} has no API key configured")
        {:error, :no_api_key}

      {:error, reason} ->
        Logger.error("Failed to generate recipes for household #{household_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
