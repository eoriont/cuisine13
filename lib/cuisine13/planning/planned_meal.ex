defmodule Cuisine13.Planning.PlannedMeal do
  use Ecto.Schema
  import Ecto.Changeset

  schema "planned_meals" do
    field :scheduled_date, :date
    field :meal_type, :string
    field :servings, :integer
    field :notes, :string
    field :is_leftover, :boolean, default: false

    belongs_to :household, Cuisine13.Households.Household
    belongs_to :recipe, Cuisine13.Recipes.Recipe
    belongs_to :added_by, Cuisine13.Accounts.User
    belongs_to :leftover_from, Cuisine13.Planning.PlannedMeal

    has_many :prep_reminders, Cuisine13.Preparation.PrepReminder

    timestamps()
  end

  @doc false
  def changeset(planned_meal, attrs) do
    planned_meal
    |> cast(attrs, [
      :scheduled_date,
      :meal_type,
      :servings,
      :notes,
      :is_leftover,
      :household_id,
      :recipe_id,
      :added_by_id,
      :leftover_from_id
    ])
    |> validate_required([:scheduled_date, :meal_type, :servings, :household_id, :recipe_id])
    |> validate_inclusion(:meal_type, ["breakfast", "lunch", "dinner", "snack"])
    |> validate_number(:servings, greater_than: 0)
  end
end
