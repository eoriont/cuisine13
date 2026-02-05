defmodule Cuisine13Web.RecipeDetailLive do
  use Cuisine13Web, :live_view

  alias Cuisine13.{Recipes, Households}

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
        current_user = socket.assigns.current_user
        household = get_household(current_user)

        is_liked =
          if household do
            Recipes.household_liked?(recipe.id, household.id)
          else
            Recipes.liked?(recipe.id, current_user.id)
          end

        # Load version history for household
        versions =
          if household do
            Recipes.list_recipe_versions(recipe.id, household.id)
          else
            []
          end

        socket =
          socket
          |> assign(:recipe, recipe)
          |> assign(:page_title, recipe.title)
          |> assign(:household, household)
          |> assign(:is_liked, is_liked)
          |> assign(:original_servings, recipe.servings || 4)
          |> assign(:current_servings, recipe.servings || 4)
          |> assign(:editing_notes, false)
          |> assign(:notes_draft, recipe.user_notes || "")
          |> assign(:versions, versions)
          |> assign(:show_versions, false)

        {:ok, socket}
    end
  end

  defp get_household(user) do
    case Households.list_households_for_user(user.id) do
      [household | _] -> household
      [] -> nil
    end
  end

  defp scale_quantity(quantity, original_servings, current_servings) when is_number(quantity) do
    multiplier = current_servings / original_servings
    scaled = quantity * multiplier

    # Format nicely
    cond do
      scaled == Float.round(scaled) ->
        trunc(scaled)
      abs(scaled - 0.25) < 0.01 -> "¼"
      abs(scaled - 0.33) < 0.02 -> "⅓"
      abs(scaled - 0.5) < 0.01 -> "½"
      abs(scaled - 0.67) < 0.02 -> "⅔"
      abs(scaled - 0.75) < 0.01 -> "¾"
      scaled > 1 ->
        whole = trunc(scaled)
        fraction = scaled - whole
        cond do
          abs(fraction - 0.25) < 0.01 -> "#{whole}¼"
          abs(fraction - 0.33) < 0.02 -> "#{whole}⅓"
          abs(fraction - 0.5) < 0.01 -> "#{whole}½"
          abs(fraction - 0.67) < 0.02 -> "#{whole}⅔"
          abs(fraction - 0.75) < 0.01 -> "#{whole}¾"
          fraction < 0.05 -> to_string(whole)
          true -> Float.round(scaled, 1)
        end
      true -> Float.round(scaled, 1)
    end
  end

  defp scale_quantity(quantity, _, _), do: quantity

  @impl true
  def handle_event("adjust_servings", %{"change" => change}, socket) do
    current = socket.assigns.current_servings
    new_servings = case change do
      "increase" -> min(current + 1, 20)  # Max 20 servings
      "decrease" -> max(current - 1, 1)   # Min 1 serving
      _ -> current
    end

    {:noreply, assign(socket, :current_servings, new_servings)}
  end

  @impl true
  def handle_event("reset_servings", _params, socket) do
    {:noreply, assign(socket, :current_servings, socket.assigns.original_servings)}
  end

  @impl true
  def handle_event("edit_notes", _params, socket) do
    {:noreply, assign(socket, :editing_notes, true)}
  end

  @impl true
  def handle_event("cancel_notes", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_notes, false)
     |> assign(:notes_draft, socket.assigns.recipe.user_notes || "")}
  end

  @impl true
  def handle_event("update_notes_draft", %{"value" => value}, socket) do
    {:noreply, assign(socket, :notes_draft, value)}
  end

  @impl true
  def handle_event("save_notes", _params, socket) do
    case Recipes.update_recipe(socket.assigns.recipe, %{user_notes: socket.assigns.notes_draft}) do
      {:ok, updated_recipe} ->
        # Create a version snapshot after saving notes
        household = socket.assigns.household
        current_user = socket.assigns.current_user

        if household do
          Recipes.create_recipe_version(updated_recipe, %{
            household_id: household.id,
            created_by_id: current_user.id,
            change_description: "Updated recipe notes"
          })
        end

        {:noreply,
         socket
         |> assign(:recipe, updated_recipe)
         |> assign(:editing_notes, false)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_versions", _params, socket) do
    {:noreply, assign(socket, :show_versions, !socket.assigns.show_versions)}
  end

  @impl true
  def handle_event("save_version", %{"description" => description}, socket) do
    recipe = socket.assigns.recipe
    household = socket.assigns.household
    current_user = socket.assigns.current_user

    if household do
      case Recipes.create_recipe_version(recipe, %{
        household_id: household.id,
        created_by_id: current_user.id,
        change_description: description
      }) do
        {:ok, _version} ->
          versions = Recipes.list_recipe_versions(recipe.id, household.id)

          {:noreply,
           socket
           |> assign(:versions, versions)
           |> put_flash(:info, "Recipe version saved!")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to save version")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_like", _params, socket) do
    recipe = socket.assigns.recipe
    current_user = socket.assigns.current_user
    household = socket.assigns.household
    is_liked = socket.assigns.is_liked

    if is_liked do
      # Unlike
      if household do
        Recipes.unlike_recipe_for_household(recipe.id, household.id)
      else
        Recipes.unlike_recipe(recipe.id, current_user.id)
      end

      {:noreply, assign(socket, :is_liked, false)}
    else
      # Like
      if household do
        Recipes.like_recipe_for_household(recipe.id, current_user.id, household.id)
      else
        Recipes.like_recipe(recipe.id, current_user.id)
      end

      {:noreply, assign(socket, :is_liked, true)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-950 text-white">
      <!-- Header -->
      <header class="bg-gray-900/95 backdrop-blur-sm border-b border-gray-800" style="padding-top: max(1rem, env(safe-area-inset-top))">
        <div class="max-w-7xl mx-auto px-4 py-3">
          <div class="flex items-center gap-4">
            <%= live_redirect to: "/", class: "text-gray-400 hover:text-white transition-colors p-1" do %>
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
              </svg>
            <% end %>
            <h1 class="text-xl font-semibold flex-1 truncate"><%= @recipe.title %></h1>
            <%= live_redirect to: "/recipes/#{@recipe.id}/edit", class: "p-2 rounded-lg transition-colors min-w-[44px] min-h-[44px] flex items-center justify-center hover:bg-gray-800" do %>
              <svg class="w-6 h-6 text-gray-400 hover:text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
              </svg>
            <% end %>
            <button
              phx-click="toggle_like"
              class="p-2 rounded-lg transition-colors min-w-[44px] min-h-[44px] flex items-center justify-center"
            >
              <%= if @is_liked do %>
                <svg class="w-7 h-7 text-pink-500" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" clip-rule="evenodd"/>
                </svg>
              <% else %>
                <svg class="w-7 h-7 text-gray-400 hover:text-pink-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/>
                </svg>
              <% end %>
            </button>
          </div>
        </div>
      </header>

      <main class="max-w-4xl mx-auto px-4 py-6 pb-24">
        <!-- Recipe Image -->
        <div class="relative h-72 rounded-2xl overflow-hidden mb-6 shadow-2xl">
          <%= if @recipe.image_url do %>
            <img src={@recipe.image_url} alt={@recipe.title} class="w-full h-full object-cover" />
          <% else %>
            <div class="w-full h-full bg-gradient-to-br from-blue-600 to-blue-400 flex items-center justify-center">
              <span class="text-8xl">🍽️</span>
            </div>
          <% end %>
        </div>

        <!-- Recipe Info Cards -->
        <div class="grid grid-cols-3 gap-4 mb-8">
          <%= if @recipe.total_time_minutes do %>
            <div class="bg-gray-900 rounded-xl p-4 border border-gray-800 text-center">
              <div class="text-3xl font-bold text-blue-500 mb-1"><%= @recipe.total_time_minutes %></div>
              <div class="text-sm text-gray-400">minutes</div>
            </div>
          <% end %>
          <%= if @recipe.servings do %>
            <div class="bg-gray-900 rounded-xl p-4 border border-gray-800">
              <div class="text-center mb-3">
                <div class="text-3xl font-bold text-blue-500 mb-1"><%= @current_servings %></div>
                <div class="text-sm text-gray-400">servings</div>
              </div>
              <div class="flex items-center justify-center gap-2">
                <button
                  phx-click="adjust_servings"
                  phx-value-change="decrease"
                  class={"p-1.5 rounded-lg transition-colors min-w-[36px] min-h-[36px] flex items-center justify-center " <>
                         if(@current_servings <= 1, do: "bg-gray-800 text-gray-600 cursor-not-allowed", else: "bg-gray-800 hover:bg-gray-700 text-white")}
                  disabled={@current_servings <= 1}
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 12H4"/>
                  </svg>
                </button>
                <button
                  phx-click="adjust_servings"
                  phx-value-change="increase"
                  class={"p-1.5 rounded-lg transition-colors min-w-[36px] min-h-[36px] flex items-center justify-center " <>
                         if(@current_servings >= 20, do: "bg-gray-800 text-gray-600 cursor-not-allowed", else: "bg-gray-800 hover:bg-gray-700 text-white")}
                  disabled={@current_servings >= 20}
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
                  </svg>
                </button>
              </div>
              <%= if @current_servings != @original_servings do %>
                <button
                  phx-click="reset_servings"
                  class="mt-2 w-full text-xs text-blue-500 hover:text-blue-400 transition-colors"
                >
                  Reset to <%= @original_servings %>
                </button>
              <% end %>
            </div>
          <% end %>
          <%= if @recipe.difficulty do %>
            <div class="bg-gray-900 rounded-xl p-4 border border-gray-800 text-center">
              <div class="text-3xl font-bold text-blue-500 capitalize mb-1"><%= String.slice(@recipe.difficulty, 0..2) %></div>
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
            <svg class="w-6 h-6 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
            </svg>
            Ingredients
          </h2>
          <div class="space-y-3">
            <%= for ingredient <- @recipe.ingredients do %>
              <% scaled_qty = scale_quantity(ingredient.quantity, @original_servings, @current_servings) %>
              <div class="flex items-start gap-3 p-3 rounded-lg hover:bg-gray-800/50 transition-colors">
                <div class="w-2 h-2 rounded-full bg-blue-500 mt-2 flex-shrink-0"></div>
                <div class="flex-1">
                  <span class="text-gray-200">
                    <%= if ingredient.quantity do %>
                      <span class={"font-semibold " <> if(@current_servings != @original_servings, do: "text-blue-400", else: "text-white")}><%= scaled_qty %></span>
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
            <svg class="w-6 h-6 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
            </svg>
            Instructions
          </h2>
          <div class="space-y-6">
            <%= for instruction <- @recipe.instructions do %>
              <div class="flex gap-4">
                <div class="flex-shrink-0">
                  <div class="w-10 h-10 rounded-full bg-blue-600 flex items-center justify-center font-bold text-lg">
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

        <!-- Recipe Notes Section -->
        <div class="bg-gray-900 rounded-2xl p-6 mb-6 border border-gray-800">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-2xl font-bold flex items-center gap-2">
              <svg class="w-6 h-6 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
              </svg>
              My Notes
            </h2>
            <%= if !@editing_notes do %>
              <button
                phx-click="edit_notes"
                class="px-4 py-2 text-sm bg-gray-800 hover:bg-gray-700 text-white rounded-lg transition-colors"
              >
                <%= if @recipe.user_notes, do: "Edit", else: "Add Notes" %>
              </button>
            <% end %>
          </div>

          <%= if @editing_notes do %>
            <div class="space-y-4">
              <textarea
                phx-change="update_notes_draft"
                phx-value-value={@notes_draft}
                name="notes"
                rows="6"
                class="w-full px-4 py-3 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 resize-none"
                placeholder="Add your cooking notes, modifications, or tips here..."
              ><%= @notes_draft %></textarea>
              <div class="flex gap-3">
                <button
                  phx-click="save_notes"
                  class="flex-1 py-2 px-4 bg-blue-600 hover:bg-blue-500 text-white font-semibold rounded-lg transition-colors"
                >
                  Save
                </button>
                <button
                  phx-click="cancel_notes"
                  class="flex-1 py-2 px-4 bg-gray-800 hover:bg-gray-700 text-white font-semibold rounded-lg transition-colors"
                >
                  Cancel
                </button>
              </div>
            </div>
          <% else %>
            <%= if @recipe.user_notes && String.trim(@recipe.user_notes) != "" do %>
              <div class="prose prose-invert max-w-none">
                <p class="text-gray-300 whitespace-pre-wrap"><%= @recipe.user_notes %></p>
              </div>
            <% else %>
              <p class="text-gray-500 italic">No notes yet. Add your own tips, modifications, or cooking notes!</p>
            <% end %>
          <% end %>
        </div>

        <!-- Version History Section -->
        <%= if @household do %>
          <div class="bg-gray-900 rounded-2xl p-6 mb-6 border border-gray-800">
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-2xl font-bold flex items-center gap-2">
                <svg class="w-6 h-6 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
                Version History
                <%= if length(@versions) > 0 do %>
                  <span class="text-sm font-normal text-gray-500">(<%= length(@versions) %> versions)</span>
                <% end %>
              </h2>
              <button
                phx-click="toggle_versions"
                class="px-4 py-2 text-sm bg-gray-800 hover:bg-gray-700 text-white rounded-lg transition-colors flex items-center gap-2"
              >
                <%= if @show_versions do %>
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7"/>
                  </svg>
                  Hide
                <% else %>
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
                  </svg>
                  Show
                <% end %>
              </button>
            </div>

            <%= if @show_versions do %>
              <%= if length(@versions) > 0 do %>
                <div class="space-y-3">
                  <%= for version <- @versions do %>
                    <div class="p-4 bg-gray-800/50 rounded-lg border border-gray-700">
                      <div class="flex items-start justify-between mb-2">
                        <div class="flex-1">
                          <div class="flex items-center gap-2 mb-1">
                            <span class="font-semibold text-blue-400">Version <%= version.version_number %></span>
                            <span class="text-xs text-gray-500">
                              <%= Calendar.strftime(version.inserted_at, "%b %d, %Y at %I:%M %p") %>
                            </span>
                          </div>
                          <%= if version.change_description do %>
                            <p class="text-sm text-gray-400"><%= version.change_description %></p>
                          <% end %>
                        </div>
                      </div>
                      <div class="flex gap-2 mt-3">
                        <button class="text-xs px-3 py-1.5 bg-blue-600 hover:bg-blue-500 text-white rounded transition-colors">
                          View Details
                        </button>
                        <button class="text-xs px-3 py-1.5 bg-gray-700 hover:bg-gray-600 text-white rounded transition-colors">
                          Restore
                        </button>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% else %>
                <p class="text-gray-500 italic text-center py-6">No version history yet. Your household customizations will be saved here.</p>
              <% end %>
            <% end %>
          </div>
        <% end %>

        <!-- Action Buttons -->
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <!-- Start Cooking Mode -->
          <%= live_redirect to: "/recipes/#{@recipe.id}/cook",
            class: "relative overflow-hidden py-5 bg-gradient-to-r from-orange-600 to-red-600 hover:from-orange-500 hover:to-red-500 text-white font-bold rounded-2xl transition-all flex items-center justify-center gap-3 shadow-2xl hover:scale-[1.02] active:scale-[0.98]" do %>
            <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
              <path d="M11 3a1 1 0 10-2 0v1a1 1 0 102 0V3zM15.657 5.757a1 1 0 00-1.414-1.414l-.707.707a1 1 0 001.414 1.414l.707-.707zM18 10a1 1 0 01-1 1h-1a1 1 0 110-2h1a1 1 0 011 1zM5.05 6.464A1 1 0 106.464 5.05l-.707-.707a1 1 0 00-1.414 1.414l.707.707zM5 10a1 1 0 01-1 1H3a1 1 0 110-2h1a1 1 0 011 1zM8 16v-1h4v1a2 2 0 11-4 0zM12 14c.015-.34.208-.646.477-.859a4 4 0 10-4.954 0c.27.213.462.519.476.859h4.002z"/>
            </svg>
            <span>Start Cooking Mode</span>
          <% end %>

          <!-- Add to Calendar -->
          <button class="py-5 bg-blue-600 hover:bg-blue-500 text-white font-semibold rounded-2xl transition-all flex items-center justify-center gap-3 shadow-lg hover:scale-[1.02] active:scale-[0.98]">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
            </svg>
            <span>Add to Calendar</span>
          </button>
        </div>
      </main>
    </div>
    """
  end
end
