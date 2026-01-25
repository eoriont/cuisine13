defmodule Cuisine13Web.FullCalendarLive do
  use Cuisine13Web, :live_view

  alias Cuisine13.{Households, Planning, Recipes}

  on_mount {Cuisine13Web.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    household = get_or_create_household(current_user)

    today = Date.utc_today()
    month_start = Date.beginning_of_month(today)
    month_end = Date.end_of_month(today)

    # Get the full calendar range (including days from prev/next month to fill the grid)
    calendar_start = Date.beginning_of_week(month_start, :monday)
    calendar_end = Date.end_of_week(month_end, :sunday)

    planned_meals = Planning.list_planned_meals(household.id, calendar_start, calendar_end)
    saved_recipes = Recipes.list_liked_recipes(current_user.id)

    socket =
      socket
      |> assign(:page_title, "Full Calendar")
      |> assign(:household, household)
      |> assign(:current_month, today)
      |> assign(:month_start, month_start)
      |> assign(:month_end, month_end)
      |> assign(:calendar_start, calendar_start)
      |> assign(:calendar_end, calendar_end)
      |> assign(:planned_meals, planned_meals)
      |> assign(:saved_recipes, saved_recipes)
      |> assign(:show_add_modal, false)
      |> assign(:selected_date, nil)
      |> assign(:selected_meal_type, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("prev_month", _params, socket) do
    new_month = Date.add(socket.assigns.current_month, -30)
    month_start = Date.beginning_of_month(new_month)
    month_end = Date.end_of_month(new_month)
    calendar_start = Date.beginning_of_week(month_start, :monday)
    calendar_end = Date.end_of_week(month_end, :sunday)

    planned_meals =
      Planning.list_planned_meals(socket.assigns.household.id, calendar_start, calendar_end)

    {:noreply,
     socket
     |> assign(:current_month, new_month)
     |> assign(:month_start, month_start)
     |> assign(:month_end, month_end)
     |> assign(:calendar_start, calendar_start)
     |> assign(:calendar_end, calendar_end)
     |> assign(:planned_meals, planned_meals)}
  end

  @impl true
  def handle_event("next_month", _params, socket) do
    new_month = Date.add(socket.assigns.current_month, 30)
    month_start = Date.beginning_of_month(new_month)
    month_end = Date.end_of_month(new_month)
    calendar_start = Date.beginning_of_week(month_start, :monday)
    calendar_end = Date.end_of_week(month_end, :sunday)

    planned_meals =
      Planning.list_planned_meals(socket.assigns.household.id, calendar_start, calendar_end)

    {:noreply,
     socket
     |> assign(:current_month, new_month)
     |> assign(:month_start, month_start)
     |> assign(:month_end, month_end)
     |> assign(:calendar_start, calendar_start)
     |> assign(:calendar_end, calendar_end)
     |> assign(:planned_meals, planned_meals)}
  end

  @impl true
  def handle_event("open_add_modal", %{"date" => date_str, "meal-type" => meal_type}, socket) do
    {:ok, date} = Date.from_iso8601(date_str)

    {:noreply,
     socket
     |> assign(:show_add_modal, true)
     |> assign(:selected_date, date)
     |> assign(:selected_meal_type, meal_type)}
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
        planned_meals =
          Planning.list_planned_meals(
            socket.assigns.household.id,
            socket.assigns.calendar_start,
            socket.assigns.calendar_end
          )

        {:noreply,
         socket
         |> assign(:planned_meals, planned_meals)
         |> assign(:show_add_modal, false)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("remove_meal", %{"id" => id}, socket) do
    planned_meal = Planning.get_planned_meal!(id)
    {:ok, _} = Planning.delete_planned_meal(planned_meal)

    planned_meals =
      Planning.list_planned_meals(
        socket.assigns.household.id,
        socket.assigns.calendar_start,
        socket.assigns.calendar_end
      )

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
            <%= live_redirect to: "/calendar", class: "flex items-center gap-2 text-gray-400 hover:text-white transition-colors" do %>
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
              </svg>
              <span class="text-sm">Week View</span>
            <% end %>
            <h1 class="text-2xl font-bold text-white">
              Full Calendar
            </h1>
            <div class="w-20"></div>
          </div>
        </div>
      </header>

      <main class="max-w-7xl mx-auto px-4 py-6">
        <!-- Month Navigation -->
        <div class="flex items-center justify-between mb-6">
          <button
            phx-click="prev_month"
            class="p-2 hover:bg-gray-800 rounded-lg transition-colors"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
            </svg>
          </button>

          <h2 class="text-xl font-semibold">
            <%= Calendar.strftime(@current_month, "%B %Y") %>
          </h2>

          <button
            phx-click="next_month"
            class="p-2 hover:bg-gray-800 rounded-lg transition-colors"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
            </svg>
          </button>
        </div>

        <!-- Calendar Grid -->
        <div class="bg-gray-900 rounded-xl border border-gray-800 overflow-hidden">
          <!-- Day names -->
          <div class="grid grid-cols-7 bg-gray-800 border-b border-gray-700">
            <%= for day_name <- ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"] do %>
              <div class="py-3 text-center text-sm font-semibold text-gray-400">
                <%= day_name %>
              </div>
            <% end %>
          </div>

          <!-- Calendar days -->
          <div class="grid grid-cols-7">
            <%= for date <- get_calendar_dates(@calendar_start, @calendar_end) do %>
              <% is_current_month = date.month == @current_month.month %>
              <% is_today = date == Date.utc_today() %>
              <% day_meals = get_meals_for_date(@planned_meals, date) %>

              <div class={"border-r border-b border-gray-800 last:border-r-0 p-2 min-h-[120px] #{if is_today, do: "bg-blue-900/20", else: if(is_current_month, do: "bg-gray-900", else: "bg-gray-900/30")}"}>
                <div class="flex items-center justify-between mb-2">
                  <span class={"text-sm font-semibold #{if is_today, do: "text-blue-500", else: if(is_current_month, do: "text-white", else: "text-gray-600")}"}>
                    <%= Calendar.strftime(date, "%d") %>
                  </span>
                  <button
                    phx-click="open_add_modal"
                    phx-value-date={Date.to_iso8601(date)}
                    phx-value-meal-type="dinner"
                    class="opacity-0 hover:opacity-100 p-1 hover:bg-blue-600 rounded transition-all"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                    </svg>
                  </button>
                </div>

                <div class="space-y-1">
                  <%= for {meal_type, meals} <- Enum.group_by(day_meals, & &1.meal_type) do %>
                    <%= for meal <- meals do %>
                      <div class="group relative bg-gray-800/50 rounded px-2 py-1 hover:bg-gray-700 transition-colors">
                        <div class="text-xs text-blue-500 capitalize"><%= meal_type %></div>
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
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
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
                  <%= live_redirect to: "/", class: "text-blue-500 hover:text-blue-400" do %>
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
                        <div class="w-16 h-16 bg-gradient-to-br from-blue-600 to-blue-400 rounded-lg flex items-center justify-center text-2xl">
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
        {:ok, household} = Households.create_household(%{name: "#{user.email}'s Household"})
        {:ok, _membership} = Households.add_member(household.id, user.id, "admin")
        household

      [household | _] ->
        household
    end
  end

  defp get_calendar_dates(start_date, end_date) do
    Date.range(start_date, end_date) |> Enum.to_list()
  end

  defp get_meals_for_date(planned_meals, date) do
    Enum.filter(planned_meals, fn meal ->
      Date.compare(meal.scheduled_date, date) == :eq
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
          <%= live_redirect to: "/calendar", class: "flex flex-col items-center gap-1 text-blue-500 transition-colors" do %>
            <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clip-rule="evenodd"/>
            </svg>
            <span class="text-xs font-medium">Calendar</span>
          <% end %>
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
