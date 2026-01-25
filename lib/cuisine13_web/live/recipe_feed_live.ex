defmodule Cuisine13Web.RecipeFeedLive do
  use Cuisine13Web, :live_view

  alias Cuisine13.{Recipes, Households, Planning}

  on_mount {Cuisine13Web.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    recipes = Recipes.list_recipes(limit: 20, offset: 0)
    current_user = socket.assigns.current_user
    household = get_or_create_household(current_user)

    socket =
      socket
      |> assign(:recipes, recipes)
      |> assign(:current_index, 0)
      |> assign(:page_title, "Discover Recipes")
      |> assign(:household, household)
      |> assign(:show_calendar_modal, false)
      |> assign(:selected_recipe_id, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("open_calendar_modal", %{"recipe-id" => recipe_id}, socket) do
    {:noreply,
     socket
     |> assign(:show_calendar_modal, true)
     |> assign(:selected_recipe_id, String.to_integer(recipe_id))
    }
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :show_calendar_modal, false)}
  end

  @impl true
  def handle_event("add_to_calendar", %{"date" => date_str, "meal-type" => meal_type}, socket) do
    {:ok, date} = Date.from_iso8601(date_str)

    attrs = %{
      scheduled_date: date,
      meal_type: meal_type,
      household_id: socket.assigns.household.id,
      recipe_id: socket.assigns.selected_recipe_id,
      added_by_id: socket.assigns.current_user.id,
      servings: 2
    }

    case Planning.create_planned_meal(attrs) do
      {:ok, _planned_meal} ->
        {:noreply,
         socket
         |> assign(:show_calendar_modal, false)
         |> put_flash(:info, "Added to calendar!")
        }

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to add to calendar")}
    end
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    current_recipes = socket.assigns.recipes
    offset = length(current_recipes)

    new_recipes = Recipes.list_recipes(limit: 10, offset: offset)

    socket = assign(socket, :recipes, current_recipes ++ new_recipes)

    {:noreply, socket}
  end

  defp get_or_create_household(user) do
    case Households.list_households_for_user(user.id) do
      [] ->
        {:ok, household} = Households.create_household(%{name: "#{user.email}'s Household"})
        {:ok, _membership} = Households.add_member(household.id, user.id, "admin")
        household

      [household | _] ->
        household
    end
  end

  defp has_allergens?(recipe, user) do
    if user && user.allergies && length(user.allergies) > 0 do
      Recipes.contains_allergens?(recipe.id, user.allergies)
    else
      false
    end
  end

  defp get_matching_allergens(recipe, user) do
    if user && user.allergies && length(user.allergies) > 0 do
      Recipes.get_matching_allergens(recipe.id, user.allergies)
    else
      []
    end
  end

  defp get_next_week_dates do
    today = Date.utc_today()
    Enum.map(0..6, fn offset -> Date.add(today, offset) end)
  end
end
