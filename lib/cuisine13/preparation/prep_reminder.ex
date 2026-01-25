defmodule Cuisine13.Preparation.PrepReminder do
  use Ecto.Schema
  import Ecto.Changeset

  schema "prep_reminders" do
    field :due_at, :naive_datetime
    field :is_completed, :boolean, default: false
    field :completed_at, :naive_datetime

    belongs_to :planned_meal, Cuisine13.Planning.PlannedMeal
    belongs_to :prep_task, Cuisine13.Recipes.PrepTask
    belongs_to :household, Cuisine13.Households.Household
    belongs_to :completed_by, Cuisine13.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(prep_reminder, attrs) do
    prep_reminder
    |> cast(attrs, [
      :due_at,
      :is_completed,
      :completed_at,
      :planned_meal_id,
      :prep_task_id,
      :household_id,
      :completed_by_id
    ])
    |> validate_required([:due_at, :planned_meal_id, :prep_task_id, :household_id])
  end
end
