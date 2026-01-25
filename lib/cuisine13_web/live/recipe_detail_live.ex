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
    <div class="min-h-screen bg-gray-900 text-white pb-20">
      <div class="max-w-2xl mx-auto">
        <!-- Header with Back Button -->
        <div class="sticky top-0 z-10 bg-gray-900/95 backdrop-blur-lg px-4 py-4 flex items-center gap-4">
          <%= live_redirect to: "/", class: "text-gray-400 hover:text-white" do %>
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
            </svg>
          <% end %>
          <h1 class="text-xl font-semibold flex-1 truncate"><%= @recipe.title %></h1>
        </div>

        <!-- Recipe Image -->
        <div class="w-full h-64 bg-gradient-to-br from-purple-500 to-pink-500">
          <%= if @recipe.image_url do %>
            <img src={@recipe.image_url} alt={@recipe.title} class="w-full h-full object-cover" />
          <% else %>
            <div class="w-full h-full flex items-center justify-center">
              <span class="text-8xl">🍽️</span>
            </div>
          <% end %>
        </div>

        <div class="px-6 py-6">
          <!-- Recipe Stats -->
          <div class="flex items-center gap-6 mb-6 text-sm">
            <%= if @recipe.total_time_minutes do %>
              <div class="flex flex-col items-center">
                <span class="text-2xl font-bold text-purple-400"><%= @recipe.total_time_minutes %></span>
                <span class="text-gray-400">minutes</span>
              </div>
            <% end %>
            <%= if @recipe.servings do %>
              <div class="flex flex-col items-center">
                <span class="text-2xl font-bold text-purple-400"><%= @recipe.servings %></span>
                <span class="text-gray-400">servings</span>
              </div>
            <% end %>
            <%= if @recipe.difficulty do %>
              <div class="flex flex-col items-center">
                <span class="text-2xl font-bold text-purple-400 capitalize"><%= @recipe.difficulty %></span>
                <span class="text-gray-400">difficulty</span>
              </div>
            <% end %>
          </div>

          <!-- Description -->
          <%= if @recipe.description do %>
            <div class="mb-6">
              <p class="text-gray-300"><%= @recipe.description %></p>
            </div>
          <% end %>

          <!-- Ingredients -->
          <div class="mb-6">
            <h2 class="text-2xl font-bold mb-4">Ingredients</h2>
            <div class="space-y-2">
              <%= for ingredient <- @recipe.ingredients do %>
                <div class="flex items-start gap-3 py-2">
                  <div class="w-2 h-2 rounded-full bg-purple-400 mt-2 flex-shrink-0"></div>
                  <div class="flex-1">
                    <span class="text-gray-200">
                      <%= if ingredient.quantity, do: "#{ingredient.quantity} ", else: "" %>
                      <%= if ingredient.unit, do: "#{ingredient.unit} ", else: "" %>
                      <%= ingredient.name %>
                    </span>
                    <%= if ingredient.notes do %>
                      <span class="text-gray-500 text-sm ml-2">(<%= ingredient.notes %>)</span>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Instructions -->
          <div class="mb-6">
            <h2 class="text-2xl font-bold mb-4">Instructions</h2>
            <div class="space-y-4">
              <%= for instruction <- @recipe.instructions do %>
                <div class="flex gap-4">
                  <div class="w-8 h-8 rounded-full bg-purple-500 flex items-center justify-center flex-shrink-0">
                    <span class="font-bold"><%= instruction.step_number %></span>
                  </div>
                  <p class="text-gray-300 flex-1 pt-1"><%= instruction.description %></p>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Add to Calendar Button -->
          <button class="w-full py-4 bg-purple-500 text-white font-semibold rounded-lg hover:bg-purple-600 transition-colors">
            Add to Calendar
          </button>
        </div>
      </div>
    </div>
    """
  end
end
