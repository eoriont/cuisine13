defmodule Cuisine13.Households.Household do
  use Ecto.Schema
  import Ecto.Changeset

  schema "households" do
    field :name, :string

    has_many :household_memberships, Cuisine13.Households.HouseholdMembership
    has_many :users, through: [:household_memberships, :user]
    has_many :planned_meals, Cuisine13.Planning.PlannedMeal
    has_many :grocery_items, Cuisine13.Groceries.GroceryItem
    has_many :prep_reminders, Cuisine13.Preparation.PrepReminder

    timestamps()
  end

  @doc false
  def changeset(household, attrs) do
    household
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 255)
  end
end
