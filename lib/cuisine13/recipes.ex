defmodule Cuisine13.Recipes do
  @moduledoc """
  The Recipes context.
  """

  import Ecto.Query, warn: false
  alias Cuisine13.Repo

  alias Cuisine13.Recipes.{Recipe, Ingredient, Instruction, PrepTask, RecipeLike, RecipeVersion}

  @doc """
  Returns a paginated list of recipes for the feed with optional search, sort, and filters.
  """
  def list_recipes(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)
    search = Keyword.get(opts, :search, "")
    sort_by = Keyword.get(opts, :sort_by, "newest")
    difficulty = Keyword.get(opts, :difficulty)

    query = from(r in Recipe, preload: [:ingredients, :instructions, :prep_tasks])

    # Apply search filter
    query =
      if search != "" do
        search_term = "%#{search}%"
        from r in query,
          where:
            ilike(r.title, ^search_term) or
            ilike(r.description, ^search_term)
      else
        query
      end

    # Apply difficulty filter
    query =
      if difficulty do
        from r in query, where: r.difficulty == ^difficulty
      else
        query
      end

    # Apply sorting
    query =
      case sort_by do
        "newest" -> from r in query, order_by: [desc: r.inserted_at]
        "oldest" -> from r in query, order_by: [asc: r.inserted_at]
        "quickest" -> from r in query, order_by: [asc: r.total_time_minutes]
        "longest" -> from r in query, order_by: [desc: r.total_time_minutes]
        _ -> from r in query, order_by: [desc: r.inserted_at]
      end

    # Apply pagination
    query
    |> limit(^limit)
    |> offset(^offset)
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
  Gets a single recipe with all associations, returns nil if not found.
  """
  def get_recipe(id) do
    case Repo.get(Recipe, id) do
      nil -> nil
      recipe -> Repo.preload(recipe, [:ingredients, :instructions, :prep_tasks])
    end
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
  Creates a recipe with ingredients and instructions from AI-generated data.
  Expects attrs with keys: ingredients (list of maps), instructions (list of strings), and recipe fields.
  """
  def create_recipe_with_details(attrs) do
    # Extract nested data
    {ingredients_data, recipe_attrs} = Map.pop(attrs, "ingredients", [])
    {instructions_data, recipe_attrs} = Map.pop(recipe_attrs, "instructions", [])

    # Convert string keys to atoms for the changeset
    recipe_attrs = for {k, v} <- recipe_attrs, into: %{}, do: {String.to_atom(k), v}

    # Create the recipe
    case create_recipe(recipe_attrs) do
      {:ok, recipe} ->
        # Insert ingredients
        now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

        ingredients =
          ingredients_data
          |> Enum.with_index(1)
          |> Enum.map(fn {ing, index} ->
            # Parse quantity - handle both strings and numbers
            quantity =
              case ing["amount"] do
                amount when is_binary(amount) ->
                  case Float.parse(amount) do
                    {num, _} -> num
                    :error -> 1.0
                  end

                amount when is_number(amount) ->
                  amount * 1.0

                _ ->
                  1.0
              end

            %{
              recipe_id: recipe.id,
              name: ing["name"],
              quantity: quantity,
              unit: ing["unit"] || "",
              category: "other",
              allergens: [],
              order: index,
              inserted_at: now,
              updated_at: now
            }
          end)

        if ingredients != [] do
          Repo.insert_all(Ingredient, ingredients)
        end

        # Insert instructions
        instructions =
          instructions_data
          |> Enum.with_index(1)
          |> Enum.map(fn {inst, index} ->
            %{
              recipe_id: recipe.id,
              step_number: index,
              description: inst,
              inserted_at: now,
              updated_at: now
            }
          end)

        if instructions != [] do
          Repo.insert_all(Instruction, instructions)
        end

        # Reload with associations
        {:ok, get_recipe!(recipe.id)}

      error ->
        error
    end
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

  # Recipe Version functions

  @doc """
  Creates a new version snapshot of a recipe.
  Automatically increments version number for household-specific versions.
  """
  def create_recipe_version(recipe, attrs \\ %{}) do
    recipe = Repo.preload(recipe, [:ingredients, :instructions, :prep_tasks])

    version_number =
      case attrs[:household_id] do
        nil -> 1
        household_id -> get_next_version_number(recipe.id, household_id)
      end

    RecipeVersion.from_recipe(recipe, Map.put(attrs, :version_number, version_number))
    |> Repo.insert()
  end

  @doc """
  Lists all versions for a recipe, optionally filtered by household.
  """
  def list_recipe_versions(recipe_id, household_id \\ nil) do
    query = from(v in RecipeVersion,
      where: v.recipe_id == ^recipe_id,
      order_by: [desc: v.version_number]
    )

    query = if household_id do
      from v in query, where: v.household_id == ^household_id
    else
      query
    end

    Repo.all(query)
  end

  @doc """
  Gets a specific version by recipe_id, household_id, and version_number.
  """
  def get_recipe_version(recipe_id, household_id, version_number) do
    Repo.get_by(RecipeVersion,
      recipe_id: recipe_id,
      household_id: household_id,
      version_number: version_number
    )
  end

  @doc """
  Gets the latest version for a household.
  """
  def get_latest_version(recipe_id, household_id) do
    from(v in RecipeVersion,
      where: v.recipe_id == ^recipe_id and v.household_id == ^household_id,
      order_by: [desc: v.version_number],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Applies a version to a recipe, updating it with the version's data.
  Optionally creates a new version before applying (to preserve current state).
  """
  def apply_version_to_recipe(recipe_id, version_id, create_backup \\ true) do
    recipe = get_recipe!(recipe_id)
    version = Repo.get!(RecipeVersion, version_id)

    # Optionally create backup of current state
    if create_backup do
      create_recipe_version(recipe, %{
        household_id: version.household_id,
        created_by_id: version.created_by_id,
        change_description: "Auto-backup before applying version #{version.version_number}"
      })
    end

    # Apply version data to recipe
    recipe_attrs = %{
      title: version.title,
      description: version.description,
      image_url: version.image_url,
      video_url: version.video_url,
      thumbnail_url: version.thumbnail_url,
      prep_time_minutes: version.prep_time_minutes,
      cook_time_minutes: version.cook_time_minutes,
      total_time_minutes: version.total_time_minutes,
      servings: version.servings,
      difficulty: version.difficulty,
      source_url: version.source_url,
      source_attribution: version.source_attribution,
      user_notes: version.user_notes
    }

    update_recipe(recipe, recipe_attrs)
  end

  @doc """
  Compares two versions and returns the differences.
  """
  def compare_versions(version1_id, version2_id) do
    v1 = Repo.get!(RecipeVersion, version1_id)
    v2 = Repo.get!(RecipeVersion, version2_id)

    fields = [
      :title, :description, :servings, :difficulty,
      :prep_time_minutes, :cook_time_minutes, :total_time_minutes,
      :user_notes
    ]

    Enum.reduce(fields, %{}, fn field, acc ->
      v1_val = Map.get(v1, field)
      v2_val = Map.get(v2, field)

      if v1_val != v2_val do
        Map.put(acc, field, %{from: v1_val, to: v2_val})
      else
        acc
      end
    end)
  end

  defp get_next_version_number(recipe_id, household_id) do
    query = from v in RecipeVersion,
      where: v.recipe_id == ^recipe_id and v.household_id == ^household_id,
      select: max(v.version_number)

    case Repo.one(query) do
      nil -> 1
      max_version -> max_version + 1
    end
  end
end
