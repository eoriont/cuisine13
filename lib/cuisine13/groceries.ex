defmodule Cuisine13.Groceries do
  @moduledoc """
  The Groceries context.
  """

  import Ecto.Query, warn: false
  alias Cuisine13.Repo

  alias Cuisine13.Groceries.GroceryItem
  alias Cuisine13.Planning
  alias Cuisine13.Recipes

  @doc """
  Returns the list of grocery items for a household.
  """
  def list_grocery_items(household_id) do
    from(gi in GroceryItem,
      where: gi.household_id == ^household_id,
      order_by: [asc: gi.category, asc: gi.name]
    )
    |> Repo.all()
  end

  @doc """
  Returns grocery items grouped by category.
  """
  def list_grocery_items_by_category(household_id) do
    list_grocery_items(household_id)
    |> Enum.group_by(& &1.category)
  end

  @doc """
  Returns only upcoming grocery items (for today and future dates).
  Excludes items from past meals.
  """
  def list_upcoming_grocery_items(household_id) do
    today = Date.utc_today()

    from(gi in GroceryItem,
      where: gi.household_id == ^household_id,
      where: is_nil(gi.needed_by_date) or gi.needed_by_date >= ^today,
      order_by: [asc: gi.category, asc: gi.name]
    )
    |> Repo.all()
  end

  @doc """
  Returns upcoming grocery items grouped by category.
  """
  def list_upcoming_items_by_category(household_id) do
    list_upcoming_grocery_items(household_id)
    |> Enum.group_by(& &1.category)
  end

  @doc """
  Deletes all purchased grocery items for a household.
  """
  def clear_purchased_items(household_id) do
    from(gi in GroceryItem,
      where: gi.household_id == ^household_id and gi.is_purchased == true
    )
    |> Repo.delete_all()
  end

  @doc """
  Auto-generates grocery items for upcoming planned meals.
  Clears old auto-generated items and regenerates for the specified period ahead.
  """
  def auto_generate_for_upcoming_meals(household_id, days_ahead \\ 14) do
    today = Date.utc_today()
    end_date = Date.add(today, days_ahead)

    # Delete old auto-generated items from the past
    from(gi in GroceryItem,
      where:
        gi.household_id == ^household_id and
          not is_nil(gi.ingredient_id) and
          gi.needed_by_date < ^today
    )
    |> Repo.delete_all()

    # Generate items for upcoming meals
    generate_from_planned_meals(household_id, today, end_date)
  end

  @doc """
  Gets a single grocery item.
  """
  def get_grocery_item!(id), do: Repo.get!(GroceryItem, id)

  @doc """
  Creates a grocery item.
  """
  def create_grocery_item(attrs \\ %{}) do
    %GroceryItem{}
    |> GroceryItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a grocery item.
  """
  def update_grocery_item(%GroceryItem{} = grocery_item, attrs) do
    grocery_item
    |> GroceryItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a grocery item.
  """
  def delete_grocery_item(%GroceryItem{} = grocery_item) do
    Repo.delete(grocery_item)
  end

  @doc """
  Marks a grocery item as purchased.
  """
  def mark_purchased(grocery_item_id, user_id) do
    grocery_item = get_grocery_item!(grocery_item_id)

    update_grocery_item(grocery_item, %{
      is_purchased: true,
      purchased_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      purchased_by_id: user_id
    })
  end

  @doc """
  Marks a grocery item as unpurchased.
  """
  def mark_unpurchased(grocery_item_id) do
    grocery_item = get_grocery_item!(grocery_item_id)

    update_grocery_item(grocery_item, %{
      is_purchased: false,
      purchased_at: nil,
      purchased_by_id: nil
    })
  end

  @doc """
  Generates grocery items from planned meals in a date range.
  """
  def generate_from_planned_meals(household_id, start_date, end_date) do
    planned_meals = Planning.list_planned_meals(household_id, start_date, end_date)

    # Delete existing auto-generated items for this date range
    from(gi in GroceryItem,
      where:
        gi.household_id == ^household_id and
          gi.needed_by_date >= ^start_date and
          gi.needed_by_date <= ^end_date and
          not is_nil(gi.ingredient_id)
    )
    |> Repo.delete_all()

    # Generate new items from planned meals (excluding leftovers)
    planned_meals
    |> Enum.reject(& &1.is_leftover)
    |> Enum.flat_map(fn planned_meal ->
      recipe = Recipes.get_recipe!(planned_meal.recipe_id)

      scaled_ingredients =
        Planning.scale_ingredients(
          recipe.ingredients,
          recipe.servings,
          planned_meal.servings
        )

      Enum.map(scaled_ingredients, fn ingredient ->
        %{
          household_id: household_id,
          ingredient_id: ingredient.id,
          name: ingredient.name,
          quantity: ingredient.quantity,
          unit: ingredient.unit,
          category: ingredient.category,
          needed_by_date: planned_meal.scheduled_date,
          inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
          updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        }
      end)
    end)
    |> then(fn items ->
      if Enum.empty?(items) do
        {:ok, []}
      else
        Repo.insert_all(GroceryItem, items)
        {:ok, list_grocery_items(household_id)}
      end
    end)
  end
end
