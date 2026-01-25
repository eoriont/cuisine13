defmodule Cuisine13.Households do
  @moduledoc """
  The Households context.
  """

  import Ecto.Query, warn: false
  alias Cuisine13.Repo

  alias Cuisine13.Households.{Household, HouseholdMembership}

  @doc """
  Returns the list of households for a user.
  """
  def list_households_for_user(user_id) do
    Repo.all(
      from h in Household,
        join: hm in HouseholdMembership,
        on: hm.household_id == h.id,
        where: hm.user_id == ^user_id,
        preload: [:household_memberships, :users]
    )
  end

  @doc """
  Gets a single household.
  """
  def get_household!(id), do: Repo.get!(Household, id)

  @doc """
  Creates a household.
  """
  def create_household(attrs \\ %{}) do
    %Household{}
    |> Household.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a household.
  """
  def update_household(%Household{} = household, attrs) do
    household
    |> Household.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a household.
  """
  def delete_household(%Household{} = household) do
    Repo.delete(household)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking household changes.
  """
  def change_household(%Household{} = household, attrs \\ %{}) do
    Household.changeset(household, attrs)
  end

  @doc """
  Adds a user to a household.
  """
  def add_member(household_id, user_id, role \\ "member") do
    %HouseholdMembership{}
    |> HouseholdMembership.changeset(%{
      household_id: household_id,
      user_id: user_id,
      role: role
    })
    |> Repo.insert()
  end

  @doc """
  Removes a user from a household.
  """
  def remove_member(household_id, user_id) do
    from(hm in HouseholdMembership,
      where: hm.household_id == ^household_id and hm.user_id == ^user_id
    )
    |> Repo.delete_all()
  end

  @doc """
  Checks if a user is a member of a household.
  """
  def member?(household_id, user_id) do
    Repo.exists?(
      from hm in HouseholdMembership,
        where: hm.household_id == ^household_id and hm.user_id == ^user_id
    )
  end

  @doc """
  Checks if a user is an admin of a household.
  """
  def admin?(household_id, user_id) do
    Repo.exists?(
      from hm in HouseholdMembership,
        where: hm.household_id == ^household_id and hm.user_id == ^user_id and hm.role == "admin"
    )
  end
end
