defmodule Cuisine13.Planning do
  @moduledoc """
  The Planning context.
  """

  import Ecto.Query, warn: false
  alias Cuisine13.Repo

  alias Cuisine13.Planning.PlannedMeal

  @doc """
  Returns the list of planned meals for a household in a date range.
  """
  def list_planned_meals(household_id, start_date, end_date) do
    from(pm in PlannedMeal,
      where:
        pm.household_id == ^household_id and
          pm.scheduled_date >= ^start_date and
          pm.scheduled_date <= ^end_date,
      order_by: [asc: pm.scheduled_date, asc: pm.meal_type],
      preload: [:recipe, :added_by]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of planned meals for a household on a specific date.
  """
  def list_planned_meals_by_date(household_id, date) do
    from(pm in PlannedMeal,
      where: pm.household_id == ^household_id and pm.scheduled_date == ^date,
      order_by: [asc: pm.meal_type],
      preload: [:recipe, :added_by]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single planned meal.
  """
  def get_planned_meal!(id) do
    Repo.get!(PlannedMeal, id)
    |> Repo.preload([:recipe, :added_by, :household])
  end

  @doc """
  Creates a planned meal.
  """
  def create_planned_meal(attrs \\ %{}) do
    %PlannedMeal{}
    |> PlannedMeal.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a planned meal.
  """
  def update_planned_meal(%PlannedMeal{} = planned_meal, attrs) do
    planned_meal
    |> PlannedMeal.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a planned meal.
  """
  def delete_planned_meal(%PlannedMeal{} = planned_meal) do
    Repo.delete(planned_meal)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking planned meal changes.
  """
  def change_planned_meal(%PlannedMeal{} = planned_meal, attrs \\ %{}) do
    PlannedMeal.changeset(planned_meal, attrs)
  end

  @doc """
  Scales ingredient quantities based on serving size difference.
  """
  def scale_ingredients(ingredients, original_servings, target_servings) do
    scale_factor = Decimal.div(Decimal.new(target_servings), Decimal.new(original_servings))

    Enum.map(ingredients, fn ingredient ->
      scaled_quantity =
        if ingredient.quantity do
          Decimal.mult(ingredient.quantity, scale_factor)
        else
          nil
        end

      %{ingredient | quantity: scaled_quantity}
    end)
  end

  @doc """
  Marks a planned meal as prepared and deducts ingredients from pantry.
  Returns {:ok, planned_meal} or {:error, changeset}.
  """
  def mark_meal_as_prepared(planned_meal_id, user_id) do
    planned_meal = get_planned_meal!(planned_meal_id)

    # Load recipe with ingredients
    recipe = Cuisine13.Repo.preload(planned_meal.recipe, :ingredients)

    # Scale ingredients based on servings
    scaled_ingredients =
      scale_ingredients(recipe.ingredients, recipe.servings, planned_meal.servings)

    # Deduct from pantry
    Cuisine13.Pantry.deduct_ingredients_from_pantry(
      planned_meal.household_id,
      scaled_ingredients
    )

    # Mark as prepared
    update_planned_meal(planned_meal, %{
      is_prepared: true,
      prepared_at: NaiveDateTime.utc_now(),
      prepared_by_id: user_id
    })
  end

  @doc """
  Unmarks a planned meal as prepared (in case of mistake).
  """
  def unmark_meal_as_prepared(planned_meal_id) do
    planned_meal = get_planned_meal!(planned_meal_id)

    update_planned_meal(planned_meal, %{
      is_prepared: false,
      prepared_at: nil,
      prepared_by_id: nil
    })
  end
end
