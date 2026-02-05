defmodule Cuisine13Web.RecipeFeedLive do
  use Cuisine13Web, :live_view

  alias Cuisine13.{Recipes, Households, Planning, RecommendationClient, RecipeGenerator}
  require Logger

  on_mount {Cuisine13Web.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    household = Households.get_or_create_default_household(current_user)

    # Try to get recommendations from the recommendation engine
    household_id = if household, do: household.id, else: nil
    recipes =
      case RecommendationClient.get_feed_recommendations(current_user.id, household_id, "normal", 20) do
        {:ok, [_ | _] = recommendations} ->
          # Convert recommendation IDs to full recipe objects
          recipe_ids = Enum.map(recommendations, & &1["recipe_id"])
          load_recipes_by_ids(recipe_ids)

        _ ->
          # Fallback to database recipes if recommendation engine fails or returns empty
          Logger.info("Using fallback recipes from database")
          Recipes.list_recipes(limit: 20, offset: 0)
      end

    # Get liked recipe IDs for this household
    liked_recipe_ids = get_liked_recipe_ids(household)

    socket =
      socket
      |> assign(:recipes, recipes)
      |> assign(:current_index, 0)
      |> assign(:page_title, "Discover Recipes")
      |> assign(:household, household)
      |> assign(:show_calendar_modal, false)
      |> assign(:selected_recipe_id, nil)
      |> assign(:liked_recipe_ids, liked_recipe_ids)
      |> assign(:generating_recipes, false)
      |> assign(:search_query, "")
      |> assign(:sort_by, "newest")
      |> assign(:difficulty_filter, "all")

    {:ok, socket}
  end

  defp get_liked_recipe_ids(household) do
    liked_recipes = Recipes.list_household_liked_recipes(household.id)
    MapSet.new(liked_recipes, & &1.id)
  end

  @impl true
  def handle_event("open_calendar_modal", %{"recipe-id" => recipe_id}, socket) do
    case Integer.parse(recipe_id) do
      {id, ""} ->
        {:noreply,
         socket
         |> assign(:show_calendar_modal, true)
         |> assign(:selected_recipe_id, id)}

      _ ->
        {:noreply, put_flash(socket, :error, "Invalid recipe ID")}
    end
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
    case Integer.parse(recipe_id_str) do
      {recipe_id, ""} ->
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

      _ ->
        {:noreply, put_flash(socket, :error, "Invalid recipe ID")}
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

  @impl true
  def handle_event("generate_recipes", _params, socket) do
    household = socket.assigns.household

    if household && household.anthropic_api_key do
      # Start generation in background
      parent = self()

      Task.start(fn ->
        case RecipeGenerator.generate_for_household(household.id, 5) do
          {:ok, new_recipes} ->
            send(parent, {:recipes_generated, new_recipes})

          {:error, reason} ->
            send(parent, {:generation_failed, reason})
        end
      end)

      {:noreply,
       socket
       |> assign(:generating_recipes, true)
       |> put_flash(:info, "Generating 5 new recipes with AI... This may take 30-60 seconds.")}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Please configure your Claude API key in settings first.")
       |> push_navigate(to: "/settings/api")}
    end
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    recipes = load_filtered_recipes(query, socket.assigns.sort_by, socket.assigns.difficulty_filter)
    {:noreply, assign(socket, search_query: query, recipes: recipes)}
  end

  @impl true
  def handle_event("sort", %{"sort_by" => sort_by}, socket) do
    recipes = load_filtered_recipes(socket.assigns.search_query, sort_by, socket.assigns.difficulty_filter)
    {:noreply, assign(socket, sort_by: sort_by, recipes: recipes)}
  end

  @impl true
  def handle_event("filter_difficulty", %{"difficulty" => difficulty}, socket) do
    recipes = load_filtered_recipes(socket.assigns.search_query, socket.assigns.sort_by, difficulty)
    {:noreply, assign(socket, difficulty_filter: difficulty, recipes: recipes)}
  end

  @impl true
  def handle_info({:recipes_generated, new_recipes}, socket) do
    # Reload all recipes to include the new ones
    all_recipes = Recipes.list_recipes(limit: 50, offset: 0)

    {:noreply,
     socket
     |> assign(:recipes, all_recipes)
     |> assign(:generating_recipes, false)
     |> put_flash(:info, "Successfully generated #{length(new_recipes)} new recipes! Scroll down to see them.")}
  end

  @impl true
  def handle_info({:generation_failed, reason}, socket) do
    error_message = case reason do
      :no_api_key -> "No Claude API key configured. Please add one in settings."
      :connection_error -> "Could not connect to AI service. Please try again."
      _ -> "Failed to generate recipes. Please try again."
    end

    {:noreply,
     socket
     |> assign(:generating_recipes, false)
     |> put_flash(:error, error_message)}
  end

  defp load_filtered_recipes(search_query, sort_by, difficulty_filter) do
    opts = [
      search: search_query,
      sort_by: sort_by,
      difficulty: (if difficulty_filter == "all", do: nil, else: difficulty_filter),
      limit: 50
    ]

    Recipes.list_recipes(opts)
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

  defp load_recipes_by_ids(recipe_ids) do
    # Load recipes by IDs while preserving the order from recommendations
    recipe_map =
      recipe_ids
      |> Enum.uniq()
      |> Enum.map(&Recipes.get_recipe/1)
      |> Enum.filter(&(&1 != nil))
      |> Map.new(&{&1.id, &1})

    # Return recipes in the order specified by recipe_ids
    Enum.map(recipe_ids, &Map.get(recipe_map, &1))
    |> Enum.filter(&(&1 != nil))
  end
end
