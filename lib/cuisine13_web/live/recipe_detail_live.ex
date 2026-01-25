defmodule Cuisine13Web.RecipeDetailLive do
  use Cuisine13Web, :live_view

  alias Cuisine13.Recipes

  on_mount {Cuisine13Web.UserAuth, :ensure_authenticated}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    recipe = Recipes.get_recipe!(id)

    socket =
      socket
      |> assign(:recipe, recipe)
      |> assign(:page_title, recipe.title)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-950 text-white pb-20">
      <!-- Header -->
      <header class="sticky top-0 z-20 bg-gray-900/95 backdrop-blur-sm border-b border-gray-800">
        <div class="max-w-7xl mx-auto px-4 py-4">
          <div class="flex items-center gap-4">
            <%= live_redirect to: "/", class: "text-gray-400 hover:text-white transition-colors" do %>
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
              </svg>
            <% end %>
            <h1 class="text-xl font-semibold flex-1 truncate"><%= @recipe.title %></h1>
          </div>
        </div>
      </header>

      <main class="max-w-4xl mx-auto px-4 py-6">
        <!-- Recipe Image -->
        <div class="relative h-72 rounded-2xl overflow-hidden mb-6 shadow-2xl">
          <%= if @recipe.image_url do %>
            <img src={@recipe.image_url} alt={@recipe.title} class="w-full h-full object-cover" />
          <% else %>
            <div class="w-full h-full bg-gradient-to-br from-purple-600 to-pink-600 flex items-center justify-center">
              <span class="text-8xl">🍽️</span>
            </div>
          <% end %>
        </div>

        <!-- Recipe Info Cards -->
        <div class="grid grid-cols-3 gap-4 mb-8">
          <%= if @recipe.total_time_minutes do %>
            <div class="bg-gray-900 rounded-xl p-4 border border-gray-800 text-center">
              <div class="text-3xl font-bold text-purple-400 mb-1"><%= @recipe.total_time_minutes %></div>
              <div class="text-sm text-gray-400">minutes</div>
            </div>
          <% end %>
          <%= if @recipe.servings do %>
            <div class="bg-gray-900 rounded-xl p-4 border border-gray-800 text-center">
              <div class="text-3xl font-bold text-purple-400 mb-1"><%= @recipe.servings %></div>
              <div class="text-sm text-gray-400">servings</div>
            </div>
          <% end %>
          <%= if @recipe.difficulty do %>
            <div class="bg-gray-900 rounded-xl p-4 border border-gray-800 text-center">
              <div class="text-3xl font-bold text-purple-400 capitalize mb-1"><%= String.slice(@recipe.difficulty, 0..2) %></div>
              <div class="text-sm text-gray-400">difficulty</div>
            </div>
          <% end %>
        </div>

        <!-- Description -->
        <%= if @recipe.description do %>
          <div class="mb-8">
            <p class="text-gray-300 text-lg"><%= @recipe.description %></p>
          </div>
        <% end %>

        <!-- Ingredients Section -->
        <div class="bg-gray-900 rounded-2xl p-6 mb-6 border border-gray-800">
          <h2 class="text-2xl font-bold mb-6 flex items-center gap-2">
            <svg class="w-6 h-6 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
            </svg>
            Ingredients
          </h2>
          <div class="space-y-3">
            <%= for ingredient <- @recipe.ingredients do %>
              <div class="flex items-start gap-3 p-3 rounded-lg hover:bg-gray-800/50 transition-colors">
                <div class="w-2 h-2 rounded-full bg-purple-400 mt-2 flex-shrink-0"></div>
                <div class="flex-1">
                  <span class="text-gray-200">
                    <%= if ingredient.quantity do %>
                      <span class="font-semibold text-white"><%= ingredient.quantity %></span>
                    <% end %>
                    <%= if ingredient.unit, do: " #{ingredient.unit} ", else: " " %>
                    <span class="font-medium"><%= ingredient.name %></span>
                  </span>
                  <%= if ingredient.notes do %>
                    <span class="text-gray-500 text-sm ml-2">(<%= ingredient.notes %>)</span>
                  <% end %>
                  <%= if ingredient.allergens && length(ingredient.allergens) > 0 do %>
                    <div class="mt-1">
                      <span class="text-xs px-2 py-0.5 bg-red-500/20 text-red-300 rounded-full">
                        <%= Enum.join(ingredient.allergens, ", ") %>
                      </span>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Instructions Section -->
        <div class="bg-gray-900 rounded-2xl p-6 mb-6 border border-gray-800">
          <h2 class="text-2xl font-bold mb-6 flex items-center gap-2">
            <svg class="w-6 h-6 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
            </svg>
            Instructions
          </h2>
          <div class="space-y-6">
            <%= for instruction <- @recipe.instructions do %>
              <div class="flex gap-4">
                <div class="flex-shrink-0">
                  <div class="w-10 h-10 rounded-full bg-purple-600 flex items-center justify-center font-bold text-lg">
                    <%= instruction.step_number %>
                  </div>
                </div>
                <div class="flex-1 pt-1.5">
                  <p class="text-gray-300 leading-relaxed"><%= instruction.description %></p>
                  <%= if instruction.duration_minutes do %>
                    <div class="mt-2 text-sm text-gray-500 flex items-center gap-1">
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
                      </svg>
                      <%= instruction.duration_minutes %> min
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Add to Calendar Button -->
        <button class="w-full py-4 bg-purple-600 hover:bg-purple-500 text-white font-semibold rounded-xl transition-colors flex items-center justify-center gap-2 shadow-lg">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
          </svg>
          <span>Add to Calendar</span>
        </button>
      </main>
    </div>
    """
  end
end
