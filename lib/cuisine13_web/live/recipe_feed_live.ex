defmodule Cuisine13Web.RecipeFeedLive do
  use Cuisine13Web, :live_view

  alias Cuisine13.Recipes

  on_mount {Cuisine13Web.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    recipes = Recipes.list_recipes(limit: 20, offset: 0)

    socket =
      socket
      |> assign(:recipes, recipes)
      |> assign(:current_index, 0)
      |> assign(:page_title, "Discover Recipes")

    {:ok, socket}
  end

  @impl true
  def handle_event("like_recipe", %{"recipe-id" => recipe_id}, socket) do
    recipe_id = String.to_integer(recipe_id)
    current_user = socket.assigns.current_user

    case Recipes.like_recipe(recipe_id, current_user.id) do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, "Recipe saved!")}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("unlike_recipe", %{"recipe-id" => recipe_id}, socket) do
    recipe_id = String.to_integer(recipe_id)
    current_user = socket.assigns.current_user

    Recipes.unlike_recipe(recipe_id, current_user.id)
    {:noreply, put_flash(socket, :info, "Recipe removed")}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    current_recipes = socket.assigns.recipes
    offset = length(current_recipes)

    new_recipes = Recipes.list_recipes(limit: 10, offset: offset)

    socket = assign(socket, :recipes, current_recipes ++ new_recipes)

    {:noreply, socket}
  end

  defp recipe_liked?(recipe_id, user_id) do
    Recipes.liked?(recipe_id, user_id)
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
end
