defmodule Cuisine13Web.RecipeFeedLive do
  use Cuisine13Web, :live_view

  alias Cuisine13.{Recipes, Households, Planning}
  alias Cuisine13.Recommendation.Client, as: RecommendationClient

  on_mount {Cuisine13Web.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    household = get_or_create_household(current_user)

    # Get liked recipe IDs for this household
    liked_recipe_ids = get_liked_recipe_ids(household)

    # Try to get recommendations from the engine, fallback to direct DB query
    {recipes, steal_dishes} = fetch_feed_data(current_user.id, "normal")

    socket =
      socket
      |> assign(:recipes, recipes)
      |> assign(:steal_dishes, steal_dishes)
      |> assign(:feed_mode, "normal")
      |> assign(:current_index, 0)
      |> assign(:page_title, "Discover Recipes")
      |> assign(:household, household)
      |> assign(:show_calendar_modal, false)
      |> assign(:selected_recipe_id, nil)
      |> assign(:liked_recipe_ids, liked_recipe_ids)
      |> assign(:recommendation_available, recommendation_engine_available?())
      |> assign(:show_steal_modal, false)
      |> assign(:generated_recipe, nil)

    {:ok, socket}
  end

  defp fetch_feed_data(user_id, mode) do
    case RecommendationClient.get_feed(user_id, mode) do
      {:ok, %{"recipes" => recipe_ids, "steal_dishes" => steal_dishes}} when is_list(recipe_ids) ->
        # Fetch full recipe objects from DB using recommended IDs
        recipes = if Enum.empty?(recipe_ids) do
          Recipes.list_recipes(limit: 20, offset: 0)
        else
          Recipes.get_recipes_by_ids(recipe_ids)
        end
        {recipes, steal_dishes || []}

      {:ok, %{"recipes" => recipe_ids}} when is_list(recipe_ids) ->
        recipes = if Enum.empty?(recipe_ids) do
          Recipes.list_recipes(limit: 20, offset: 0)
        else
          Recipes.get_recipes_by_ids(recipe_ids)
        end
        {recipes, []}

      _ ->
        # Fallback to direct DB query if recommendation engine is unavailable
        {Recipes.list_recipes(limit: 20, offset: 0), []}
    end
  end

  defp recommendation_engine_available? do
    case RecommendationClient.health_check() do
      :ok -> true
      _ -> false
    end
  end

  defp get_liked_recipe_ids(household) do
    liked_recipes = Recipes.list_household_liked_recipes(household.id)
    MapSet.new(liked_recipes, & &1.id)
  end

  @impl true
  def handle_event("open_calendar_modal", %{"recipe-id" => recipe_id}, socket) do
    {:noreply,
     socket
     |> assign(:show_calendar_modal, true)
     |> assign(:selected_recipe_id, String.to_integer(recipe_id))}
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
         |> put_flash(:info, "Added to calendar!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to add to calendar")}
    end
  end

  @impl true
  def handle_event("toggle_like", %{"recipe-id" => recipe_id_str}, socket) do
    recipe_id = String.to_integer(recipe_id_str)
    current_user = socket.assigns.current_user
    household = socket.assigns.household
    liked_recipe_ids = socket.assigns.liked_recipe_ids

    is_liked = MapSet.member?(liked_recipe_ids, recipe_id)

    new_liked_ids =
      if is_liked do
        Recipes.unlike_recipe_for_household(recipe_id, household.id)
        MapSet.delete(liked_recipe_ids, recipe_id)
      else
        Recipes.like_recipe_for_household(recipe_id, current_user.id, household.id)
        MapSet.put(liked_recipe_ids, recipe_id)
      end

    {:noreply, assign(socket, :liked_recipe_ids, new_liked_ids)}
  end

  @impl true
  def handle_event("switch_feed_mode", %{"mode" => mode}, socket) do
    current_user = socket.assigns.current_user
    {recipes, steal_dishes} = fetch_feed_data(current_user.id, mode)

    {:noreply,
     socket
     |> assign(:feed_mode, mode)
     |> assign(:recipes, recipes)
     |> assign(:steal_dishes, steal_dishes)}
  end

  @impl true
  def handle_event("steal_dish", %{"dish-name" => dish_name, "restaurant" => restaurant}, socket) do
    current_user = socket.assigns.current_user
    query = "#{dish_name} from #{restaurant}"

    case RecommendationClient.steal_from_text(current_user.id, query) do
      {:ok, recipe_data} ->
        {:noreply,
         socket
         |> assign(:generated_recipe, recipe_data)
         |> assign(:show_steal_modal, true)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to generate recipe: #{reason}")}
    end
  end

  @impl true
  def handle_event("close_steal_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_steal_modal, false)
     |> assign(:generated_recipe, nil)}
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

  defp recipe_liked?(recipe, liked_recipe_ids) do
    MapSet.member?(liked_recipe_ids, recipe.id)
  end
end
