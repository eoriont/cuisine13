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
  Returns all households that have an Anthropic API key configured.
  """
  def list_households_with_api_keys do
    Repo.all(
      from h in Household,
        where: not is_nil(h.anthropic_api_key) and h.anthropic_api_key != ""
    )
  end

  @doc """
  Gets a single household.
  """
  def get_household!(id),
    do: Repo.get!(Household, id) |> Repo.preload([:users, :household_memberships])

  @doc """
  Gets a household by invite code.
  """
  def get_household_by_invite_code(invite_code) do
    Repo.get_by(Household, invite_code: invite_code)
    |> case do
      nil -> nil
      household -> Repo.preload(household, [:users, :household_memberships])
    end
  end

  @doc """
  Gets a household by calendar feed token.
  """
  def get_household_by_feed_token(token) when is_binary(token) do
    Repo.get_by(Household, calendar_feed_token: token)
  end

  def get_household_by_feed_token(_), do: nil

  @doc """
  Creates a household with an auto-generated invite code and calendar feed token.
  """
  def create_household(attrs \\ %{}) do
    invite_code = Household.generate_invite_code()
    calendar_feed_token = Household.generate_calendar_feed_token()

    %Household{}
    |> Household.changeset(
      attrs
      |> Map.put(:invite_code, invite_code)
      |> Map.put(:calendar_feed_token, calendar_feed_token)
    )
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
  Updates API keys for a household.
  """
  def update_api_keys(%Household{} = household, attrs) do
    household
    |> Household.api_keys_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns a changeset for tracking API keys changes.
  """
  def change_api_keys(%Household{} = household, attrs \\ %{}) do
    Household.api_keys_changeset(household, attrs)
  end

  @doc """
  Regenerates the invite code for a household.
  """
  def regenerate_invite_code(%Household{} = household) do
    new_code = Household.generate_invite_code()
    update_household(household, %{invite_code: new_code})
  end

  @doc """
  Regenerates the calendar feed token for a household.
  This invalidates any existing calendar subscriptions.
  """
  def regenerate_calendar_feed_token(%Household{} = household) do
    new_token = Household.generate_calendar_feed_token()
    update_household(household, %{calendar_feed_token: new_token})
  end

  @doc """
  Ensures a household has a calendar feed token, generating one if missing.
  """
  def ensure_calendar_feed_token(%Household{calendar_feed_token: nil} = household) do
    regenerate_calendar_feed_token(household)
  end

  def ensure_calendar_feed_token(%Household{} = household), do: {:ok, household}

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

  @doc """
  Joins a household using an invite code.
  Returns {:ok, membership} if successful, {:error, reason} otherwise.
  """
  def join_household_by_code(invite_code, user_id) do
    case get_household_by_invite_code(invite_code) do
      nil ->
        {:error, :invalid_code}

      household ->
        if member?(household.id, user_id) do
          {:error, :already_member}
        else
          add_member(household.id, user_id, "member")
        end
    end
  end

  @doc """
  Leaves a household. Cannot leave if user is the only admin.
  """
  def leave_household(household_id, user_id) do
    membership =
      Repo.one(
        from hm in HouseholdMembership,
          where: hm.household_id == ^household_id and hm.user_id == ^user_id
      )

    cond do
      is_nil(membership) ->
        {:error, :not_member}

      membership.role == "admin" && count_admins(household_id) == 1 ->
        {:error, :last_admin}

      true ->
        Repo.delete(membership)
    end
  end

  defp count_admins(household_id) do
    Repo.aggregate(
      from(hm in HouseholdMembership,
        where: hm.household_id == ^household_id and hm.role == "admin"
      ),
      :count
    )
  end

  @doc """
  Gets the membership for a user in a household.
  """
  def get_membership(household_id, user_id) do
    Repo.one(
      from hm in HouseholdMembership,
        where: hm.household_id == ^household_id and hm.user_id == ^user_id
    )
  end

  @doc """
  Gets the first household for a user, or creates a default one if none exists.
  This is used to ensure users always have a household when accessing the app.
  """
  def get_or_create_default_household(user) do
    case list_households_for_user(user.id) do
      [] ->
        {:ok, household} = create_household(%{name: "#{user.email}'s Household"})
        {:ok, _membership} = add_member(household.id, user.id, "admin")
        household

      [household | _] ->
        household
    end
  end
end
