defmodule Cuisine13.Recipes.RecipeLike do
  use Ecto.Schema
  import Ecto.Changeset

  schema "recipe_likes" do
    belongs_to :user, Cuisine13.Accounts.User
    belongs_to :recipe, Cuisine13.Recipes.Recipe
    belongs_to :household, Cuisine13.Households.Household

    timestamps()
  end

  @doc false
  def changeset(recipe_like, attrs) do
    recipe_like
    |> cast(attrs, [:user_id, :recipe_id, :household_id])
    |> validate_required([:user_id, :recipe_id])
    |> unique_constraint([:user_id, :recipe_id])
    |> unique_constraint([:household_id, :recipe_id], name: :recipe_likes_household_recipe_index)
  end
end
