defmodule Cuisine13.Recipes.RecipeVersion do
  use Ecto.Schema
  import Ecto.Changeset

  schema "recipe_versions" do
    field :version_number, :integer
    field :change_description, :string

    # Recipe data snapshot
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
    field :user_notes, :string

    # JSONB snapshots of related data
    field :ingredients_snapshot, :map
    field :instructions_snapshot, :map
    field :prep_tasks_snapshot, :map

    belongs_to :recipe, Cuisine13.Recipes.Recipe
    belongs_to :household, Cuisine13.Households.Household
    belongs_to :created_by, Cuisine13.Accounts.User

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(recipe_version, attrs) do
    recipe_version
    |> cast(attrs, [
      :recipe_id,
      :household_id,
      :created_by_id,
      :version_number,
      :change_description,
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
      :source_attribution,
      :user_notes,
      :ingredients_snapshot,
      :instructions_snapshot,
      :prep_tasks_snapshot
    ])
    |> validate_required([:recipe_id, :version_number, :title, :servings])
    |> validate_number(:servings, greater_than: 0)
    |> validate_number(:version_number, greater_than_or_equal_to: 1)
    |> validate_inclusion(:difficulty, ["easy", "medium", "hard"])
    |> foreign_key_constraint(:recipe_id)
    |> foreign_key_constraint(:household_id)
    |> foreign_key_constraint(:created_by_id)
  end

  @doc """
  Creates a version from a recipe struct.
  """
  def from_recipe(recipe, attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(
      attrs
      |> Map.put(:recipe_id, recipe.id)
      |> Map.put(:title, recipe.title)
      |> Map.put(:description, recipe.description)
      |> Map.put(:image_url, recipe.image_url)
      |> Map.put(:video_url, recipe.video_url)
      |> Map.put(:thumbnail_url, recipe.thumbnail_url)
      |> Map.put(:prep_time_minutes, recipe.prep_time_minutes)
      |> Map.put(:cook_time_minutes, recipe.cook_time_minutes)
      |> Map.put(:total_time_minutes, recipe.total_time_minutes)
      |> Map.put(:servings, recipe.servings)
      |> Map.put(:difficulty, recipe.difficulty)
      |> Map.put(:source_url, recipe.source_url)
      |> Map.put(:source_attribution, recipe.source_attribution)
      |> Map.put(:user_notes, recipe.user_notes)
      |> Map.put(:ingredients_snapshot, snapshot_ingredients(recipe))
      |> Map.put(:instructions_snapshot, snapshot_instructions(recipe))
      |> Map.put(:prep_tasks_snapshot, snapshot_prep_tasks(recipe))
    )
  end

  defp snapshot_ingredients(%{ingredients: ingredients}) when is_list(ingredients) do
    Enum.map(ingredients, fn ing ->
      %{
        name: ing.name,
        quantity: ing.quantity && Decimal.to_string(ing.quantity),
        unit: ing.unit,
        category: ing.category,
        allergens: ing.allergens,
        notes: ing.notes,
        order: ing.order
      }
    end)
  end

  defp snapshot_ingredients(_), do: []

  defp snapshot_instructions(%{instructions: instructions}) when is_list(instructions) do
    Enum.map(instructions, fn inst ->
      %{
        step_number: inst.step_number,
        description: inst.description,
        duration_minutes: inst.duration_minutes
      }
    end)
  end

  defp snapshot_instructions(_), do: []

  defp snapshot_prep_tasks(%{prep_tasks: tasks}) when is_list(tasks) do
    Enum.map(tasks, fn task ->
      %{
        task_type: task.task_type,
        description: task.description,
        hours_before: task.hours_before,
        duration_minutes: task.duration_minutes
      }
    end)
  end

  defp snapshot_prep_tasks(_), do: []
end
