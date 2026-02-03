defmodule Cuisine13Web.RecipeEditLive do
  use Cuisine13Web, :live_view

  alias Cuisine13.Recipes

  on_mount {Cuisine13Web.UserAuth, :ensure_authenticated}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Recipes.get_recipe(id) do
      nil ->
        socket =
          socket
          |> put_flash(:error, "Recipe not found")
          |> redirect(to: "/")

        {:ok, socket}

      recipe ->
        changeset = Recipes.change_recipe(recipe)

        socket =
          socket
          |> assign(:recipe, recipe)
          |> assign(:page_title, "Edit Recipe")
          |> assign(:form, to_form(changeset))

        {:ok, socket}
    end
  end

  @impl true
  def handle_event("validate", %{"recipe" => recipe_params}, socket) do
    changeset =
      socket.assigns.recipe
      |> Recipes.change_recipe(recipe_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"recipe" => recipe_params}, socket) do
    case Recipes.update_recipe(socket.assigns.recipe, recipe_params) do
      {:ok, recipe} ->
        socket =
          socket
          |> put_flash(:info, "Recipe updated successfully")
          |> redirect(to: "/recipes/#{recipe.id}")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    socket =
      socket
      |> redirect(to: "/recipes/#{socket.assigns.recipe.id}")

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-950 text-white">
      <!-- Header -->
      <header class="mobile-header bg-gray-900/95 backdrop-blur-sm border-b border-gray-800">
        <div class="max-w-7xl mx-auto px-4 py-3">
          <div class="flex items-center gap-4">
            <button
              phx-click="cancel"
              class="text-gray-400 hover:text-white transition-colors p-1"
            >
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
              </svg>
            </button>
            <h1 class="text-xl font-semibold flex-1 truncate">Edit Recipe</h1>
          </div>
        </div>
      </header>

      <main class="max-w-4xl mx-auto px-4 py-6 mobile-content">
        <.form
          for={@form}
          phx-change="validate"
          phx-submit="save"
          class="space-y-6"
        >
          <!-- Title -->
          <div class="bg-gray-900 rounded-2xl p-6 border border-gray-800">
            <label class="block text-sm font-medium text-gray-400 mb-2">
              Recipe Title
            </label>
            <.input
              field={@form[:title]}
              type="text"
              placeholder="Enter recipe title"
              class="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 text-white placeholder-gray-500 focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
            />
          </div>

          <!-- Description -->
          <div class="bg-gray-900 rounded-2xl p-6 border border-gray-800">
            <label class="block text-sm font-medium text-gray-400 mb-2">
              Description
            </label>
            <.input
              field={@form[:description]}
              type="textarea"
              placeholder="Enter recipe description"
              rows="4"
              class="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 text-white placeholder-gray-500 focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
            />
          </div>

          <!-- Time and Servings -->
          <div class="bg-gray-900 rounded-2xl p-6 border border-gray-800">
            <h2 class="text-lg font-semibold mb-4">Recipe Info</h2>
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-400 mb-2">
                  Prep Time (minutes)
                </label>
                <.input
                  field={@form[:prep_time_minutes]}
                  type="number"
                  placeholder="30"
                  class="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 text-white placeholder-gray-500 focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-400 mb-2">
                  Cook Time (minutes)
                </label>
                <.input
                  field={@form[:cook_time_minutes]}
                  type="number"
                  placeholder="45"
                  class="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 text-white placeholder-gray-500 focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-400 mb-2">
                  Servings
                </label>
                <.input
                  field={@form[:servings]}
                  type="number"
                  placeholder="4"
                  class="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 text-white placeholder-gray-500 focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-400 mb-2">
                  Difficulty
                </label>
                <.input
                  field={@form[:difficulty]}
                  type="select"
                  options={[{"Easy", "easy"}, {"Medium", "medium"}, {"Hard", "hard"}]}
                  class="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 text-white focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
                />
              </div>
            </div>
          </div>

          <!-- Image URL -->
          <div class="bg-gray-900 rounded-2xl p-6 border border-gray-800">
            <label class="block text-sm font-medium text-gray-400 mb-2">
              Image URL
            </label>
            <.input
              field={@form[:image_url]}
              type="text"
              placeholder="https://example.com/image.jpg"
              class="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 text-white placeholder-gray-500 focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
            />
          </div>

          <!-- Action Buttons -->
          <div class="flex gap-4">
            <button
              type="button"
              phx-click="cancel"
              class="flex-1 py-4 bg-gray-800 hover:bg-gray-700 text-white font-semibold rounded-xl transition-colors border border-gray-700"
            >
              Cancel
            </button>
            <button
              type="submit"
              class="flex-1 py-4 bg-blue-600 hover:bg-blue-500 text-white font-semibold rounded-xl transition-colors shadow-lg"
            >
              Save Changes
            </button>
          </div>
        </.form>

        <div class="mt-4 text-center text-sm text-gray-500">
          Note: Editing ingredients and instructions coming soon
        </div>
      </main>
    </div>
    """
  end
end
