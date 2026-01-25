defmodule Cuisine13.Recipes.Recipe do
  use Ecto.Schema
  import Ecto.Changeset

  schema "recipes" do
    field :title, :string
    field :description, :string
    field :image_url, :string
    field :video_url, :string
    field :thumbnail_url, :string
    field :prep_time_minutes, :integer
    field :cook_time_minutes, :integer
    field :total_time_minutes, :integer
    field :servings, :integer
    field :difficulty, :string
    field :source_url, :string
    field :source_attribution, :string

    has_many :ingredients, Cuisine13.Recipes.Ingredient
    has_many :instructions, Cuisine13.Recipes.Instruction
    has_many :prep_tasks, Cuisine13.Recipes.PrepTask
    has_many :recipe_likes, Cuisine13.Recipes.RecipeLike
    has_many :planned_meals, Cuisine13.Planning.PlannedMeal

    timestamps()
  end

  @doc false
  def changeset(recipe, attrs) do
    recipe
    |> cast(attrs, [
      :title,
      :description,
      :image_url,
      :video_url,
      :thumbnail_url,
      :prep_time_minutes,
      :cook_time_minutes,
      :total_time_minutes,
      :servings,
      :difficulty,
      :source_url,
      :source_attribution
    ])
    |> validate_required([:title, :servings])
    |> validate_number(:servings, greater_than: 0)
    |> validate_number(:prep_time_minutes, greater_than_or_equal_to: 0)
    |> validate_number(:cook_time_minutes, greater_than_or_equal_to: 0)
    |> validate_number(:total_time_minutes, greater_than_or_equal_to: 0)
    |> validate_inclusion(:difficulty, ["easy", "medium", "hard"])
  end
end
