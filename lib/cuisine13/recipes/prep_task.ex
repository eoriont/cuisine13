defmodule Cuisine13.Recipes.PrepTask do
  use Ecto.Schema
  import Ecto.Changeset

  schema "prep_tasks" do
    field :task_type, :string
    field :description, :string
    field :hours_before, :integer
    field :duration_minutes, :integer

    belongs_to :recipe, Cuisine13.Recipes.Recipe
    has_many :prep_reminders, Cuisine13.Preparation.PrepReminder

    timestamps()
  end

  @doc false
  def changeset(prep_task, attrs) do
    prep_task
    |> cast(attrs, [:task_type, :description, :hours_before, :duration_minutes, :recipe_id])
    |> validate_required([:task_type, :description, :hours_before, :recipe_id])
    |> validate_inclusion(:task_type, [
      "thaw",
      "marinate",
      "make_component",
      "soak",
      "chill",
      "rest"
    ])
    |> validate_number(:hours_before, greater_than: 0)
    |> validate_number(:duration_minutes, greater_than_or_equal_to: 0)
  end
end
