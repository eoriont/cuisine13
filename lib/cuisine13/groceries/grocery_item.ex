defmodule Cuisine13.Groceries.GroceryItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "grocery_items" do
    field :name, :string
    field :quantity, :decimal
    field :unit, :string
    field :category, :string
    field :needed_by_date, :date
    field :is_purchased, :boolean, default: false
    field :purchased_at, :naive_datetime

    belongs_to :household, Cuisine13.Households.Household
    belongs_to :ingredient, Cuisine13.Recipes.Ingredient
    belongs_to :purchased_by, Cuisine13.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(grocery_item, attrs) do
    grocery_item
    |> cast(attrs, [
      :name,
      :quantity,
      :unit,
      :category,
      :needed_by_date,
      :is_purchased,
      :purchased_at,
      :household_id,
      :ingredient_id,
      :purchased_by_id
    ])
    |> validate_required([:name, :household_id])
    |> validate_number(:quantity, greater_than: 0)
  end
end
