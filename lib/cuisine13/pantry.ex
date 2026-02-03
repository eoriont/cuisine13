defmodule Cuisine13.Pantry do
  @moduledoc """
  The Pantry context for tracking household inventory.
  """

  import Ecto.Query, warn: false
  alias Cuisine13.Repo
  alias Cuisine13.Pantry.PantryItem

  @doc """
  Returns the list of pantry items for a household.
  """
  def list_pantry_items(household_id) do
    from(pi in PantryItem,
      where: pi.household_id == ^household_id,
      order_by: [asc: pi.category, asc: pi.name]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single pantry item.
  """
  def get_pantry_item!(id), do: Repo.get!(PantryItem, id)

  @doc """
  Creates a pantry item.
  """
  def create_pantry_item(attrs \\ %{}) do
    %PantryItem{}
    |> PantryItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a pantry item.
  """
  def update_pantry_item(%PantryItem{} = pantry_item, attrs) do
    pantry_item
    |> PantryItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a pantry item.
  """
  def delete_pantry_item(%PantryItem{} = pantry_item) do
    Repo.delete(pantry_item)
  end

  @doc """
  Adds a grocery item to the pantry.
  Creates or updates existing pantry item with the same name and unit.
  """
  def add_from_grocery_item(grocery_item, user_id) do
    household_id = grocery_item.household_id

    # Check if this item already exists in pantry
    existing =
      from(pi in PantryItem,
        where:
          pi.household_id == ^household_id and
            fragment("LOWER(?)", pi.name) == ^String.downcase(grocery_item.name) and
            pi.unit == ^grocery_item.unit
      )
      |> Repo.one()

    case existing do
      nil ->
        # Create new pantry item
        create_pantry_item(%{
          household_id: household_id,
          name: grocery_item.name,
          quantity: grocery_item.quantity,
          unit: grocery_item.unit,
          category: grocery_item.category,
          added_by_id: user_id
        })

      existing_item ->
        # Add to existing quantity
        new_quantity =
          if existing_item.quantity && grocery_item.quantity do
            Decimal.add(existing_item.quantity, grocery_item.quantity)
          else
            existing_item.quantity || grocery_item.quantity
          end

        update_pantry_item(existing_item, %{quantity: new_quantity})
    end
  end

  @doc """
  Deducts ingredients from pantry items.
  Matches by ingredient name (case-insensitive) and unit.
  Only deducts if there's a matching pantry item with sufficient quantity.
  """
  def deduct_ingredients_from_pantry(household_id, ingredients) do
    Enum.each(ingredients, fn ingredient ->
      # Skip if no quantity specified
      if ingredient.quantity do
        # Find matching pantry item (case-insensitive name match and same unit)
        existing =
          from(pi in PantryItem,
            where:
              pi.household_id == ^household_id and
                fragment("LOWER(?)", pi.name) == ^String.downcase(ingredient.name) and
                pi.unit == ^ingredient.unit
          )
          |> Repo.one()

        case existing do
          nil ->
            # No matching pantry item, skip
            :ok

          existing_item ->
            # Deduct from existing quantity
            if existing_item.quantity do
              new_quantity = Decimal.sub(existing_item.quantity, ingredient.quantity)

              # If quantity becomes zero or negative, delete the item
              if Decimal.compare(new_quantity, Decimal.new(0)) != :gt do
                delete_pantry_item(existing_item)
              else
                update_pantry_item(existing_item, %{quantity: new_quantity})
              end
            end
        end
      end
    end)

    :ok
  end
end
