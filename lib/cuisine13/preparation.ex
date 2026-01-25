defmodule Cuisine13.Preparation do
  @moduledoc """
  The Preparation context.
  """

  import Ecto.Query, warn: false
  alias Cuisine13.Repo

  alias Cuisine13.Preparation.PrepReminder
  alias Cuisine13.Planning
  alias Cuisine13.Recipes

  @doc """
  Returns the list of prep reminders for a household.
  """
  def list_prep_reminders(household_id) do
    from(pr in PrepReminder,
      where: pr.household_id == ^household_id,
      order_by: [asc: pr.due_at],
      preload: [:planned_meal, :prep_task]
    )
    |> Repo.all()
  end

  @doc """
  Returns upcoming prep reminders for a household (not completed, due in the future).
  """
  def list_upcoming_prep_reminders(household_id) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    from(pr in PrepReminder,
      where: pr.household_id == ^household_id and pr.is_completed == false and pr.due_at >= ^now,
      order_by: [asc: pr.due_at],
      preload: [:planned_meal, :prep_task]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single prep reminder.
  """
  def get_prep_reminder!(id) do
    Repo.get!(PrepReminder, id)
    |> Repo.preload([:planned_meal, :prep_task, :household])
  end

  @doc """
  Creates a prep reminder.
  """
  def create_prep_reminder(attrs \\ %{}) do
    %PrepReminder{}
    |> PrepReminder.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a prep reminder.
  """
  def update_prep_reminder(%PrepReminder{} = prep_reminder, attrs) do
    prep_reminder
    |> PrepReminder.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a prep reminder.
  """
  def delete_prep_reminder(%PrepReminder{} = prep_reminder) do
    Repo.delete(prep_reminder)
  end

  @doc """
  Marks a prep reminder as completed.
  """
  def mark_completed(prep_reminder_id, user_id) do
    prep_reminder = get_prep_reminder!(prep_reminder_id)

    update_prep_reminder(prep_reminder, %{
      is_completed: true,
      completed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      completed_by_id: user_id
    })
  end

  @doc """
  Marks a prep reminder as not completed.
  """
  def mark_uncompleted(prep_reminder_id) do
    prep_reminder = get_prep_reminder!(prep_reminder_id)

    update_prep_reminder(prep_reminder, %{
      is_completed: false,
      completed_at: nil,
      completed_by_id: nil
    })
  end

  @doc """
  Generates prep reminders for a planned meal.
  """
  def generate_for_planned_meal(planned_meal_id) do
    planned_meal = Planning.get_planned_meal!(planned_meal_id)
    recipe = Recipes.get_recipe!(planned_meal.recipe_id)

    # Calculate meal datetime (assume dinner at 6pm, lunch at 12pm, breakfast at 8am, snack at 3pm)
    meal_time =
      case planned_meal.meal_type do
        "breakfast" -> ~T[08:00:00]
        "lunch" -> ~T[12:00:00]
        "dinner" -> ~T[18:00:00]
        "snack" -> ~T[15:00:00]
        _ -> ~T[18:00:00]
      end

    meal_datetime = NaiveDateTime.new!(planned_meal.scheduled_date, meal_time)

    # Create prep reminders for each prep task
    Enum.each(recipe.prep_tasks, fn prep_task ->
      due_at = NaiveDateTime.add(meal_datetime, -prep_task.hours_before * 3600, :second)

      create_prep_reminder(%{
        planned_meal_id: planned_meal.id,
        prep_task_id: prep_task.id,
        household_id: planned_meal.household_id,
        due_at: due_at
      })
    end)

    {:ok, list_prep_reminders(planned_meal.household_id)}
  end
end
