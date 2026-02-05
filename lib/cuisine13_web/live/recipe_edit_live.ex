defmodule Cuisine13Web.RecipeEditLive do
  use Cuisine13Web, :live_view
  alias Cuisine13.Recipes

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    recipe = Recipes.get_recipe!(id)
    changeset = Recipes.change_recipe(recipe)

    {:ok,
     socket
     |> assign(:recipe, recipe)
     |> assign(:page_title, "Edit Recipe")
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"recipe" => recipe_params}, socket) do
    changeset =
      socket.assigns.recipe
      |> Recipes.change_recipe(recipe_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"recipe" => recipe_params}, socket) do
    case Recipes.update_recipe(socket.assigns.recipe, recipe_params) do
      {:ok, recipe} ->
        {:noreply,
         socket
         |> put_flash(:info, "Recipe updated successfully")
         |> push_redirect(to: "/recipes/#{recipe.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div class="min-h-screen bg-gray-950 text-white">
      <!-- Header -->
      <header class="bg-gray-900/95 backdrop-blur-sm border-b border-gray-800" style="padding-top: max(1rem, env(safe-area-inset-top))">
        <div class="max-w-7xl mx-auto px-4 py-3">
          <div class="flex items-center gap-4">
            <%= live_redirect to: "/recipes/#{@recipe.id}", class: "text-gray-400 hover:text-white transition-colors p-1" do %>
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
              </svg>
            <% end %>
            <h1 class="text-xl font-semibold flex-1">Edit Recipe</h1>
          </div>
        </div>
      </header>

      <main class="max-w-2xl mx-auto px-4 py-6 pb-24">
        <%= f = form_for @changeset, "#", [phx_change: "validate", phx_submit: "save", class: "space-y-6"] %>
          <div class="bg-gray-900 rounded-2xl p-6 border border-gray-800 space-y-6">
            <div>
              <%= label f, :title, class: "block text-sm font-medium text-gray-300 mb-2" %>
              <%= text_input f, :title,
                class: "w-full px-4 py-3 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500" %>
              <%= error_tag f, :title %>
            </div>

            <div>
              <%= label f, :description, class: "block text-sm font-medium text-gray-300 mb-2" %>
              <%= textarea f, :description,
                class: "w-full px-4 py-3 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500",
                rows: 4 %>
              <%= error_tag f, :description %>
            </div>

            <div class="grid grid-cols-3 gap-4">
              <div>
                <%= label f, :servings, class: "block text-sm font-medium text-gray-300 mb-2" %>
                <%= number_input f, :servings, min: 1,
                  class: "w-full px-4 py-3 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500" %>
                <%= error_tag f, :servings %>
              </div>

              <div>
                <%= label f, :prep_time, "Prep Time (min)", class: "block text-sm font-medium text-gray-300 mb-2" %>
                <%= number_input f, :prep_time, min: 0,
                  class: "w-full px-4 py-3 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500" %>
                <%= error_tag f, :prep_time %>
              </div>

              <div>
                <%= label f, :cook_time, "Cook Time (min)", class: "block text-sm font-medium text-gray-300 mb-2" %>
                <%= number_input f, :cook_time, min: 0,
                  class: "w-full px-4 py-3 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500" %>
                <%= error_tag f, :cook_time %>
              </div>
            </div>

            <div>
              <%= label f, :image_url, class: "block text-sm font-medium text-gray-300 mb-2" %>
              <%= text_input f, :image_url,
                class: "w-full px-4 py-3 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500" %>
              <%= error_tag f, :image_url %>
            </div>

            <div class="flex gap-4 pt-4">
              <%= submit "Save Recipe",
                phx_disable_with: "Saving...",
                class: "flex-1 py-3 px-4 bg-blue-600 hover:bg-blue-500 text-white font-semibold rounded-lg transition-colors" %>
              <%= live_redirect "Cancel", to: "/recipes/#{@recipe.id}",
                class: "flex-1 py-3 px-4 bg-gray-800 hover:bg-gray-700 text-white font-semibold rounded-lg transition-colors text-center" %>
            </div>
          </div>
        </form>
      </main>
    </div>
    """
  end
end
