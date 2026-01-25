defmodule Cuisine13.Households.HouseholdMembership do
  use Ecto.Schema
  import Ecto.Changeset

  schema "household_memberships" do
    field :role, :string, default: "member"

    belongs_to :user, Cuisine13.Accounts.User
    belongs_to :household, Cuisine13.Households.Household

    timestamps()
  end

  @doc false
  def changeset(household_membership, attrs) do
    household_membership
    |> cast(attrs, [:role, :user_id, :household_id])
    |> validate_required([:role, :user_id, :household_id])
    |> validate_inclusion(:role, ["admin", "member"])
    |> unique_constraint([:user_id, :household_id])
  end
end
