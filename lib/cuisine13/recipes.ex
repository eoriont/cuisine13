defmodule Cuisine13.Recipes do
  @moduledoc """
  The Recipes context.
  """

  import Ecto.Query, warn: false
  alias Cuisine13.Repo

  alias Cuisine13.Recipes.{Recipe, Ingredient, Instruction, PrepTask, RecipeLike}

  @doc """
  Returns a paginated list of recipes for the feed.
  """
  def list_recipes(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    from(r in Recipe,
      order_by: [desc: r.inserted_at],
      limit: ^limit,
      offset: ^offset,
      preload: [:ingredients, :instructions, :prep_tasks]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single recipe with all associations.
  """
  def get_recipe!(id) do
    Repo.get!(Recipe, id)
    |> Repo.preload([:ingredients, :instructions, :prep_tasks])
  end

  @doc """
  Creates a recipe.
  """
  def create_recipe(attrs \\ %{}) do
    %Recipe{}
    |> Recipe.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a recipe.
  """
  def update_recipe(%Recipe{} = recipe, attrs) do
    recipe
    |> Recipe.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a recipe.
  """
  def delete_recipe(%Recipe{} = recipe) do
    Repo.delete(recipe)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking recipe changes.
  """
  def change_recipe(%Recipe{} = recipe, attrs \\ %{}) do
    Recipe.changeset(recipe, attrs)
  end

  @doc """
  Returns the list of liked recipes for a user.
  """
  def list_liked_recipes(user_id) do
    from(r in Recipe,
      join: rl in RecipeLike,
      on: rl.recipe_id == r.id,
      where: rl.user_id == ^user_id,
      order_by: [desc: rl.inserted_at],
      preload: [:ingredients, :instructions, :prep_tasks]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of liked recipes for a household.
  All household members share the same saved recipes.
  """
  def list_household_liked_recipes(household_id) do
    from(r in Recipe,
      join: rl in RecipeLike,
      on: rl.recipe_id == r.id,
      where: rl.household_id == ^household_id,
      order_by: [desc: rl.inserted_at],
      preload: [:ingredients, :instructions, :prep_tasks]
    )
    |> Repo.all()
  end

  @doc """
  Checks if a user has liked a recipe.
  """
  def liked?(recipe_id, user_id) do
    Repo.exists?(
      from rl in RecipeLike,
        where: rl.recipe_id == ^recipe_id and rl.user_id == ^user_id
    )
  end

  @doc """
  Checks if a household has saved a recipe.
  """
  def household_liked?(recipe_id, household_id) do
    Repo.exists?(
      from rl in RecipeLike,
        where: rl.recipe_id == ^recipe_id and rl.household_id == ^household_id
    )
  end

  @doc """
  Likes a recipe.
  """
  def like_recipe(recipe_id, user_id) do
    %RecipeLike{}
    |> RecipeLike.changeset(%{recipe_id: recipe_id, user_id: user_id})
    |> Repo.insert()
  end

  @doc """
  Likes a recipe for a household (shared across all members).
  """
  def like_recipe_for_household(recipe_id, user_id, household_id) do
    %RecipeLike{}
    |> RecipeLike.changeset(%{recipe_id: recipe_id, user_id: user_id, household_id: household_id})
    |> Repo.insert()
  end

  @doc """
  Unlikes a recipe.
  """
  def unlike_recipe(recipe_id, user_id) do
    from(rl in RecipeLike,
      where: rl.recipe_id == ^recipe_id and rl.user_id == ^user_id
    )
    |> Repo.delete_all()
  end

  @doc """
  Unlikes a recipe for a household.
  """
  def unlike_recipe_for_household(recipe_id, household_id) do
    from(rl in RecipeLike,
      where: rl.recipe_id == ^recipe_id and rl.household_id == ^household_id
    )
    |> Repo.delete_all()
  end

  @doc """
  Checks if a recipe contains any allergens from the given list.
  """
  def contains_allergens?(recipe_id, allergens) when is_list(allergens) do
    recipe = get_recipe!(recipe_id)

    Enum.any?(recipe.ingredients, fn ingredient ->
      Enum.any?(allergens, fn allergen ->
        allergen in ingredient.allergens
      end)
    end)
  end

  @doc """
  Returns a list of allergens found in a recipe that match the user's allergens.
  """
  def get_matching_allergens(recipe_id, user_allergens) when is_list(user_allergens) do
    recipe = get_recipe!(recipe_id)

    recipe.ingredients
    |> Enum.flat_map(& &1.allergens)
    |> Enum.filter(&(&1 in user_allergens))
    |> Enum.uniq()
  end

  # Ingredient functions

  @doc """
  Creates an ingredient.
  """
  def create_ingredient(attrs \\ %{}) do
    %Ingredient{}
    |> Ingredient.changeset(attrs)
    |> Repo.insert()
  end

  # Instruction functions

  @doc """
  Creates an instruction.
  """
  def create_instruction(attrs \\ %{}) do
    %Instruction{}
    |> Instruction.changeset(attrs)
    |> Repo.insert()
  end

  # PrepTask functions

  @doc """
  Creates a prep task.
  """
  def create_prep_task(attrs \\ %{}) do
    %PrepTask{}
    |> PrepTask.changeset(attrs)
    |> Repo.insert()
  end
end
