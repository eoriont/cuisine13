defmodule Cuisine13.Recipes.Ingredient do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ingredients" do
    field :name, :string
    field :quantity, :decimal
    field :unit, :string
    field :category, :string
    field :allergens, {:array, :string}, default: []
    field :notes, :string
    field :order, :integer

    belongs_to :recipe, Cuisine13.Recipes.Recipe
    has_many :grocery_items, Cuisine13.Groceries.GroceryItem

    timestamps()
  end

  @doc false
  def changeset(ingredient, attrs) do
    ingredient
    |> cast(attrs, [:name, :quantity, :unit, :category, :allergens, :notes, :order, :recipe_id])
    |> validate_required([:name, :order, :recipe_id])
    |> validate_number(:quantity, greater_than: 0)
  end
end
