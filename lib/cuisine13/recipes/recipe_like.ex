defmodule Cuisine13.Recipes.RecipeLike do
  use Ecto.Schema
  import Ecto.Changeset

  schema "recipe_likes" do
    belongs_to :user, Cuisine13.Accounts.User
    belongs_to :recipe, Cuisine13.Recipes.Recipe

    timestamps()
  end

  @doc false
  def changeset(recipe_like, attrs) do
    recipe_like
    |> cast(attrs, [:user_id, :recipe_id])
    |> validate_required([:user_id, :recipe_id])
    |> unique_constraint([:user_id, :recipe_id])
  end
end
