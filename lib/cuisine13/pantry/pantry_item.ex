defmodule Cuisine13.Pantry.PantryItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pantry_items" do
    field :name, :string
    field :quantity, :decimal
    field :unit, :string
    field :category, :string

    belongs_to :household, Cuisine13.Households.Household
    belongs_to :added_by, Cuisine13.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(pantry_item, attrs) do
    pantry_item
    |> cast(attrs, [
      :name,
      :quantity,
      :unit,
      :category,
      :household_id,
      :added_by_id
    ])
    |> validate_required([:name, :household_id])
    |> validate_number(:quantity, greater_than: 0)
  end
end
