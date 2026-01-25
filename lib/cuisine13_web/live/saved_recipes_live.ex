defmodule Cuisine13Web.SavedRecipesLive do
  use Cuisine13Web, :live_view

  alias Cuisine13.{Recipes, Households}

  on_mount {Cuisine13Web.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    household = get_household(current_user)

    # Use household-based liked recipes if available, otherwise fall back to user-based
    recipes =
      if household do
        Recipes.list_household_liked_recipes(household.id)
      else
        Recipes.list_liked_recipes(current_user.id)
      end

    socket =
      socket
      |> assign(:recipes, recipes)
      |> assign(:household, household)
      |> assign(:page_title, "Saved Recipes")

    {:ok, socket}
  end

  defp get_household(user) do
    case Households.list_households_for_user(user.id) do
      [household | _] -> household
      [] -> nil
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-950 text-white">
      <!-- Header with iOS safe area -->
      <header class="mobile-header bg-gray-900/95 backdrop-blur-sm border-b border-gray-800">
        <div class="max-w-7xl mx-auto px-4 py-3">
          <div class="flex items-center justify-between">
            <h1 class="text-2xl font-bold bg-gradient-to-r from-purple-400 to-pink-500 bg-clip-text text-transparent">
              Saved Recipes
            </h1>
          </div>
        </div>
      </header>

      <!-- Content -->
      <main class="max-w-7xl mx-auto px-4 py-6 mobile-content">
        <%= if Enum.empty?(@recipes) do %>
          <div class="flex flex-col items-center justify-center py-20">
            <svg class="w-20 h-20 text-gray-600 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/>
            </svg>
            <h2 class="text-2xl font-semibold mb-2 text-gray-300">No Saved Recipes</h2>
            <p class="text-gray-500 mb-6">Like recipes to save them here</p>
            <%= live_redirect to: "/", class: "px-6 py-3 bg-purple-600 hover:bg-purple-500 text-white font-semibold rounded-lg transition-colors" do %>
              Browse Recipes
            <% end %>
          </div>
        <% else %>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <%= for recipe <- @recipes do %>
              <%= live_redirect to: "/recipes/#{recipe.id}", class: "block group" do %>
                <div class="relative bg-gray-900 rounded-2xl overflow-hidden shadow-lg hover:shadow-2xl transition-all duration-300 border border-gray-800 hover:border-purple-500/50">
                  <div class="relative h-48 overflow-hidden">
                    <%= if recipe.image_url do %>
                      <img src={recipe.image_url} alt={recipe.title} class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
                    <% else %>
                      <div class="w-full h-full bg-gradient-to-br from-purple-600 to-pink-600 flex items-center justify-center">
                        <span class="text-5xl">🍽️</span>
                      </div>
                    <% end %>
                    <div class="absolute inset-0 bg-gradient-to-t from-gray-900 via-gray-900/50 to-transparent"></div>
                  </div>
                  <div class="p-4">
                    <h3 class="text-lg font-semibold mb-2 text-white group-hover:text-purple-400 transition-colors"><%= recipe.title %></h3>
                    <div class="flex items-center gap-3 text-sm text-gray-400">
                      <%= if recipe.total_time_minutes do %>
                        <span><%= recipe.total_time_minutes %> min</span>
                      <% end %>
                      <%= if recipe.servings do %>
                        <span><%= recipe.servings %> servings</span>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        <% end %>
      </main>

      <%= render_nav(assigns) %>
    </div>
    """
  end

  defp render_nav(assigns) do
    ~H"""
    <nav class="mobile-nav bg-gray-900/95 backdrop-blur-lg border-t border-gray-800">
      <div class="max-w-7xl mx-auto px-4">
        <div class="flex items-center justify-around pt-2 pb-1">
          <%= live_redirect to: "/", class: "flex flex-col items-center gap-1 text-gray-400 hover:text-white transition-colors" do %>
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
            </svg>
            <span class="text-xs font-medium">Feed</span>
          <% end %>
          <a href="/recipes/saved" class="flex flex-col items-center gap-1 text-purple-400 transition-colors">
            <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" clip-rule="evenodd"/>
            </svg>
            <span class="text-xs font-medium">Saved</span>
          </a>
          <%= live_redirect to: "/calendar", class: "flex flex-col items-center gap-1 text-gray-400 hover:text-white transition-colors" do %>
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
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
