defmodule Cuisine13.Recipes.Instruction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "instructions" do
    field :step_number, :integer
    field :description, :string
    field :duration_minutes, :integer

    belongs_to :recipe, Cuisine13.Recipes.Recipe

    timestamps()
  end

  @doc false
  def changeset(instruction, attrs) do
    instruction
    |> cast(attrs, [:step_number, :description, :duration_minutes, :recipe_id])
    |> validate_required([:step_number, :description, :recipe_id])
    |> validate_number(:step_number, greater_than: 0)
    |> validate_number(:duration_minutes, greater_than_or_equal_to: 0)
  end
end
