defmodule Cuisine13Web.CalendarLive do
  use Cuisine13Web, :live_view

  alias Cuisine13.{Groceries, Households, Planning, Recipes}

  on_mount {Cuisine13Web.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    household = get_or_create_household(current_user)

    today = Date.utc_today()
    week_start = Date.beginning_of_week(today, :monday)
    week_end = Date.add(week_start, 6)

    planned_meals = Planning.list_planned_meals(household.id, week_start, week_end)
    saved_recipes = Recipes.list_liked_recipes(current_user.id)

    socket =
      socket
      |> assign(:page_title, "Meal Calendar")
      |> assign(:household, household)
      |> assign(:week_start, week_start)
      |> assign(:week_end, week_end)
      |> assign(:planned_meals, planned_meals)
      |> assign(:saved_recipes, saved_recipes)
      |> assign(:show_add_modal, false)
      |> assign(:selected_date, nil)
      |> assign(:selected_meal_type, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("prev_week", _params, socket) do
    new_week_start = Date.add(socket.assigns.week_start, -7)
    new_week_end = Date.add(socket.assigns.week_end, -7)

    planned_meals = Planning.list_planned_meals(socket.assigns.household.id, new_week_start, new_week_end)

    {:noreply,
     socket
     |> assign(:week_start, new_week_start)
     |> assign(:week_end, new_week_end)
     |> assign(:planned_meals, planned_meals)
    }
  end

  @impl true
  def handle_event("next_week", _params, socket) do
    new_week_start = Date.add(socket.assigns.week_start, 7)
    new_week_end = Date.add(socket.assigns.week_end, 7)

    planned_meals = Planning.list_planned_meals(socket.assigns.household.id, new_week_start, new_week_end)

    {:noreply,
     socket
     |> assign(:week_start, new_week_start)
     |> assign(:week_end, new_week_end)
     |> assign(:planned_meals, planned_meals)
    }
  end

  @impl true
  def handle_event("open_add_modal", %{"date" => date_str, "meal-type" => meal_type}, socket) do
    {:ok, date} = Date.from_iso8601(date_str)

    {:noreply,
     socket
     |> assign(:show_add_modal, true)
     |> assign(:selected_date, date)
     |> assign(:selected_meal_type, meal_type)
    }
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :show_add_modal, false)}
  end

  @impl true
  def handle_event("add_recipe", %{"recipe-id" => recipe_id}, socket) do
    attrs = %{
      scheduled_date: socket.assigns.selected_date,
      meal_type: socket.assigns.selected_meal_type,
      household_id: socket.assigns.household.id,
      recipe_id: String.to_integer(recipe_id),
      added_by_id: socket.assigns.current_user.id,
      servings: 2
    }

    case Planning.create_planned_meal(attrs) do
      {:ok, _planned_meal} ->
        planned_meals = Planning.list_planned_meals(
          socket.assigns.household.id,
          socket.assigns.week_start,
          socket.assigns.week_end
        )

        # Auto-regenerate grocery list for upcoming meals
        Groceries.auto_generate_for_upcoming_meals(socket.assigns.household.id, 14)

        {:noreply,
         socket
         |> assign(:planned_meals, planned_meals)
         |> assign(:show_add_modal, false)
        }

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("remove_meal", %{"id" => id}, socket) do
    planned_meal = Planning.get_planned_meal!(id)
    {:ok, _} = Planning.delete_planned_meal(planned_meal)

    planned_meals = Planning.list_planned_meals(
      socket.assigns.household.id,
      socket.assigns.week_start,
      socket.assigns.week_end
    )

    # Auto-regenerate grocery list for upcoming meals
    Groceries.auto_generate_for_upcoming_meals(socket.assigns.household.id, 14)

    {:noreply, assign(socket, :planned_meals, planned_meals)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-950 text-white pb-20">
      <!-- Header -->
      <header class="sticky top-0 z-20 bg-gray-900/95 backdrop-blur-sm border-b border-gray-800">
        <div class="max-w-7xl mx-auto px-4 py-4">
          <div class="flex items-center justify-between">
            <h1 class="text-2xl font-bold bg-gradient-to-r from-purple-400 to-pink-500 bg-clip-text text-transparent">
              Meal Calendar
            </h1>
          </div>
        </div>
      </header>

      <main class="max-w-7xl mx-auto px-4 py-6">
        <!-- Week Navigation -->
        <div class="flex items-center justify-between mb-6">
          <button
            phx-click="prev_week"
            class="p-2 hover:bg-gray-800 rounded-lg transition-colors"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
            </svg>
          </button>

          <div class="text-center">
            <p class="text-lg font-semibold">
              <%= Calendar.strftime(@week_start, "%B %d") %> - <%= Calendar.strftime(@week_end, "%B %d, %Y") %>
            </p>
          </div>

          <button
            phx-click="next_week"
            class="p-2 hover:bg-gray-800 rounded-lg transition-colors"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
            </svg>
          </button>
        </div>

        <!-- Week At A Glance -->
        <div class="bg-gray-900 rounded-xl border border-gray-800 overflow-hidden">
          <!-- Days Header -->
          <div class="grid grid-cols-7 border-b border-gray-800">
            <%= for day_offset <- 0..6 do %>
              <% date = Date.add(@week_start, day_offset) %>
              <% is_today = date == Date.utc_today() %>
              <div class={"text-center py-3 border-r border-gray-800 last:border-r-0 #{if is_today, do: "bg-purple-600", else: "bg-gray-800"}"}>
                <div class="text-xs font-medium uppercase text-gray-400">
                  <%= Calendar.strftime(date, "%a") %>
                </div>
                <div class={"text-xl font-bold #{if is_today, do: "text-white", else: "text-purple-400"}"}>
                  <%= Calendar.strftime(date, "%d") %>
                </div>
              </div>
            <% end %>
          </div>

          <!-- Meals Grid -->
          <%= for meal_type <- ["breakfast", "lunch", "dinner"] do %>
            <div class="grid grid-cols-7 border-b border-gray-800 last:border-b-0">
              <div class="flex items-center justify-center bg-gray-800/50 py-3 px-2 border-r border-gray-800">
                <span class="text-sm font-semibold text-gray-400 capitalize"><%= meal_type %></span>
              </div>
              <%= for day_offset <- 0..6 do %>
                <% date = Date.add(@week_start, day_offset) %>
                <% meals = get_meals_for_date_and_type(@planned_meals, date, meal_type) %>
                <% is_today = date == Date.utc_today() %>

                <div class={"py-2 px-1 border-r border-gray-800 last:border-r-0 min-h-[60px] #{if is_today, do: "bg-purple-900/20", else: ""}"}>
                  <%= if Enum.empty?(meals) do %>
                    <button
                      phx-click="open_add_modal"
                      phx-value-date={Date.to_iso8601(date)}
                      phx-value-meal-type={meal_type}
                      class="w-full h-full flex items-center justify-center text-gray-600 hover:text-purple-400 transition-colors"
                    >
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                      </svg>
                    </button>
                  <% else %>
                    <div class="space-y-1">
                      <%= for meal <- meals do %>
                        <div class="group relative bg-gray-700/50 rounded px-2 py-1 hover:bg-gray-700 transition-colors">
                          <div class="text-xs text-white line-clamp-1 pr-4">
                            <%= meal.recipe.title %>
                          </div>
                          <button
                            phx-click="remove_meal"
                            phx-value-id={meal.id}
                            class="absolute top-0.5 right-0.5 opacity-0 group-hover:opacity-100 transition-opacity p-0.5 hover:bg-red-500 rounded"
                          >
                            <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                            </svg>
                          </button>
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>

        <!-- View Full Calendar Link -->
        <div class="mt-6 text-center">
          <%= live_redirect to: "/calendar/full", class: "inline-flex items-center gap-2 px-6 py-3 bg-gray-800 hover:bg-gray-700 text-white font-semibold rounded-lg transition-colors border border-gray-700" do %>
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
            </svg>
            <span>View Full Calendar</span>
          <% end %>
        </div>
      </main>

      <%= if @show_add_modal do %>
        <!-- Modal Backdrop -->
        <div
          class="fixed inset-0 bg-black/80 z-40"
          phx-click="close_modal"
        ></div>

        <!-- Modal -->
        <div class="fixed inset-x-4 top-1/2 -translate-y-1/2 md:inset-x-auto md:left-1/2 md:-translate-x-1/2 md:w-full md:max-w-lg z-50">
          <div class="bg-gray-900 rounded-2xl shadow-2xl border border-gray-800 max-h-[80vh] flex flex-col">
            <!-- Modal Header -->
            <div class="px-6 py-4 border-b border-gray-800 flex items-center justify-between">
              <h3 class="text-xl font-bold">
                Add <%= String.capitalize(@selected_meal_type || "") %> - <%= Calendar.strftime(@selected_date || Date.utc_today(), "%B %d") %>
              </h3>
              <button
                phx-click="close_modal"
                class="p-2 hover:bg-gray-800 rounded-lg transition-colors"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                </svg>
              </button>
            </div>

            <!-- Modal Body -->
            <div class="flex-1 overflow-y-auto p-6">
              <%= if Enum.empty?(@saved_recipes) do %>
                <div class="text-center py-8">
                  <p class="text-gray-400 mb-4">No saved recipes yet</p>
                  <%= live_redirect to: "/", class: "text-purple-400 hover:text-purple-300" do %>
                    Browse recipes →
                  <% end %>
                </div>
              <% else %>
                <div class="space-y-3">
                  <%= for recipe <- @saved_recipes do %>
                    <button
                      phx-click="add_recipe"
                      phx-value-recipe-id={recipe.id}
                      class="w-full flex items-center gap-4 p-3 bg-gray-800 hover:bg-gray-700 rounded-xl transition-colors text-left"
                    >
                      <%= if recipe.image_url do %>
                        <img src={recipe.image_url} alt={recipe.title} class="w-16 h-16 object-cover rounded-lg" />
                      <% else %>
                        <div class="w-16 h-16 bg-gradient-to-br from-purple-600 to-pink-600 rounded-lg flex items-center justify-center text-2xl">
                          🍽️
                        </div>
                      <% end %>
                      <div class="flex-1">
                        <div class="font-semibold text-white"><%= recipe.title %></div>
                        <div class="text-sm text-gray-400">
                          <%= if recipe.total_time_minutes, do: "#{recipe.total_time_minutes} min", else: "" %>
                        </div>
                      </div>
                      <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                      </svg>
                    </button>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>

      <%= render_nav(assigns) %>
    </div>
    """
  end

  defp get_or_create_household(user) do
    case Households.list_households_for_user(user.id) do
      [] ->
        # Create a default household for the user
        {:ok, household} = Households.create_household(%{name: "#{user.email}'s Household"})
        {:ok, _membership} = Households.add_member(household.id, user.id, "admin")
        household

      [household | _] ->
        household
    end
  end

  defp get_meals_for_date_and_type(planned_meals, date, meal_type) do
    Enum.filter(planned_meals, fn meal ->
      Date.compare(meal.scheduled_date, date) == :eq && meal.meal_type == meal_type
    end)
  end

  defp render_nav(assigns) do
    ~H"""
    <nav class="fixed bottom-0 left-0 right-0 z-30 bg-gray-900/95 backdrop-blur-lg border-t border-gray-800">
      <div class="max-w-7xl mx-auto px-4">
        <div class="flex items-center justify-around py-3">
          <%= live_redirect to: "/", class: "flex flex-col items-center gap-1 text-gray-400 hover:text-white transition-colors" do %>
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
            </svg>
            <span class="text-xs font-medium">Feed</span>
          <% end %>
          <%= live_redirect to: "/recipes/saved", class: "flex flex-col items-center gap-1 text-gray-400 hover:text-white transition-colors" do %>
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/>
            </svg>
            <span class="text-xs font-medium">Saved</span>
          <% end %>
          <a href="/calendar" class="flex flex-col items-center gap-1 text-purple-400 transition-colors">
            <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clip-rule="evenodd"/>
            </svg>
            <span class="text-xs font-medium">Calendar</span>
          </a>
          <%= live_redirect to: "/groceries", class: "flex flex-col items-center gap-1 text-gray-400 hover:text-white transition-colors" do %>
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"/>
            </svg>
            <span class="text-xs font-medium">Groceries</span>
          <% end %>
          <%= live_redirect to: "/users/settings", class: "flex flex-col items-center gap-1 text-gray-400 hover:text-white transition-colors" do %>
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
            </svg>
            <span class="text-xs font-medium">Profile</span>
          <% end %>
        </div>
      </div>
    </nav>
    """
  end
end
