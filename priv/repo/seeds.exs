# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Cuisine13.Repo.insert!(%Cuisine13.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Cuisine13.Repo
alias Cuisine13.Recipes.{Recipe, Ingredient, Instruction, PrepTask}
alias Cuisine13.Planning.PlannedMeal
alias Cuisine13.Groceries.GroceryItem

# Clear existing data (optional, comment out if you don't want to reset)
# Delete in order of foreign key dependencies
Repo.delete_all(GroceryItem)
Repo.delete_all(PlannedMeal)
Repo.delete_all(Instruction)
Repo.delete_all(Ingredient)
Repo.delete_all(PrepTask)
Repo.delete_all(Recipe)

IO.puts("Creating sample recipes...")

# Recipe 1: Spaghetti Carbonara
{:ok, carbonara} =
  %Recipe{}
  |> Recipe.changeset(%{
    title: "Spaghetti Carbonara",
    description: "Classic Italian pasta dish with eggs, cheese, and pancetta",
    image_url: "https://images.unsplash.com/photo-1612874742237-6526221588e3?w=800",
    prep_time_minutes: 10,
    cook_time_minutes: 20,
    total_time_minutes: 30,
    servings: 4,
    difficulty: "medium",
    source_attribution: "Traditional Italian Recipe"
  })
  |> Repo.insert()

Repo.insert_all(Ingredient, [
  %{
    recipe_id: carbonara.id,
    name: "spaghetti",
    quantity: 400,
    unit: "g",
    category: "pantry",
    order: 1,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: carbonara.id,
    name: "eggs",
    quantity: 4,
    unit: "whole",
    category: "dairy",
    allergens: ["eggs"],
    order: 2,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: carbonara.id,
    name: "parmesan cheese",
    quantity: 100,
    unit: "g",
    category: "dairy",
    allergens: ["dairy"],
    order: 3,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: carbonara.id,
    name: "pancetta",
    quantity: 200,
    unit: "g",
    category: "meat",
    order: 4,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  }
])

Repo.insert_all(Instruction, [
  %{
    recipe_id: carbonara.id,
    step_number: 1,
    description:
      "Bring a large pot of salted water to boil and cook spaghetti according to package directions.",
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: carbonara.id,
    step_number: 2,
    description: "While pasta cooks, dice pancetta and cook in a large skillet until crispy.",
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: carbonara.id,
    step_number: 3,
    description: "Whisk eggs and parmesan cheese together in a bowl.",
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: carbonara.id,
    step_number: 4,
    description:
      "Drain pasta, reserving 1 cup of pasta water. Toss hot pasta with pancetta, then remove from heat and quickly stir in egg mixture, adding pasta water as needed.",
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  }
])

# Recipe 2: Chicken Tikka Masala
{:ok, tikka} =
  %Recipe{}
  |> Recipe.changeset(%{
    title: "Chicken Tikka Masala",
    description: "Creamy and flavorful Indian curry with tender chicken",
    image_url: "https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=800",
    prep_time_minutes: 30,
    cook_time_minutes: 40,
    total_time_minutes: 70,
    servings: 6,
    difficulty: "medium",
    source_attribution: "Indian Cuisine Classic"
  })
  |> Repo.insert()

Repo.insert_all(Ingredient, [
  %{
    recipe_id: tikka.id,
    name: "chicken breast",
    quantity: 800,
    unit: "g",
    category: "meat",
    order: 1,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: tikka.id,
    name: "yogurt",
    quantity: 1,
    unit: "cup",
    category: "dairy",
    allergens: ["dairy"],
    order: 2,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: tikka.id,
    name: "heavy cream",
    quantity: 1,
    unit: "cup",
    category: "dairy",
    allergens: ["dairy"],
    order: 3,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: tikka.id,
    name: "tomato sauce",
    quantity: 2,
    unit: "cups",
    category: "pantry",
    order: 4,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: tikka.id,
    name: "garam masala",
    quantity: 2,
    unit: "tbsp",
    category: "pantry",
    order: 5,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  }
])

Repo.insert_all(Instruction, [
  %{
    recipe_id: tikka.id,
    step_number: 1,
    description:
      "Cut chicken into bite-sized pieces and marinate in yogurt and half the spices for at least 2 hours.",
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: tikka.id,
    step_number: 2,
    description: "Grill or broil marinated chicken until cooked through and slightly charred.",
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: tikka.id,
    step_number: 3,
    description:
      "In a large pan, combine tomato sauce, cream, and remaining spices. Simmer for 10 minutes.",
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: tikka.id,
    step_number: 4,
    description:
      "Add grilled chicken to sauce and simmer for 10 more minutes. Serve with rice or naan.",
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  }
])

%PrepTask{}
|> PrepTask.changeset(%{
  recipe_id: tikka.id,
  task_type: "marinate",
  description: "Marinate chicken in yogurt and spices",
  hours_before: 2,
  duration_minutes: 10
})
|> Repo.insert!()

# Recipe 3: Avocado Toast
{:ok, avocado_toast} =
  %Recipe{}
  |> Recipe.changeset(%{
    title: "Perfect Avocado Toast",
    description: "Simple and delicious breakfast with creamy avocado on crispy toast",
    image_url: "https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?w=800",
    prep_time_minutes: 5,
    cook_time_minutes: 5,
    total_time_minutes: 10,
    servings: 2,
    difficulty: "easy",
    source_attribution: "Modern Breakfast Classic"
  })
  |> Repo.insert()

Repo.insert_all(Ingredient, [
  %{
    recipe_id: avocado_toast.id,
    name: "sourdough bread",
    quantity: 2,
    unit: "slices",
    category: "pantry",
    allergens: ["gluten"],
    order: 1,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: avocado_toast.id,
    name: "avocado",
    quantity: 1,
    unit: "whole",
    category: "produce",
    order: 2,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: avocado_toast.id,
    name: "lemon juice",
    quantity: 1,
    unit: "tsp",
    category: "produce",
    order: 3,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: avocado_toast.id,
    name: "eggs",
    quantity: 2,
    unit: "whole",
    category: "dairy",
    allergens: ["eggs"],
    notes: "optional",
    order: 4,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  }
])

Repo.insert_all(Instruction, [
  %{
    recipe_id: avocado_toast.id,
    step_number: 1,
    description: "Toast bread until golden and crispy.",
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: avocado_toast.id,
    step_number: 2,
    description: "Mash avocado with lemon juice, salt, and pepper.",
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: avocado_toast.id,
    step_number: 3,
    description: "Spread avocado mixture on toast. Top with fried egg if desired.",
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  }
])

# Recipe 4: Thai Green Curry
{:ok, thai_curry} =
  %Recipe{}
  |> Recipe.changeset(%{
    title: "Thai Green Curry",
    description: "Aromatic and spicy Thai curry with vegetables and coconut milk",
    image_url: "https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=800",
    prep_time_minutes: 15,
    cook_time_minutes: 25,
    total_time_minutes: 40,
    servings: 4,
    difficulty: "easy",
    source_attribution: "Thai Traditional"
  })
  |> Repo.insert()

Repo.insert_all(Ingredient, [
  %{
    recipe_id: thai_curry.id,
    name: "coconut milk",
    quantity: 400,
    unit: "ml",
    category: "pantry",
    allergens: ["coconut"],
    order: 1,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: thai_curry.id,
    name: "green curry paste",
    quantity: 3,
    unit: "tbsp",
    category: "pantry",
    order: 2,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: thai_curry.id,
    name: "bell peppers",
    quantity: 2,
    unit: "whole",
    category: "produce",
    order: 3,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: thai_curry.id,
    name: "bamboo shoots",
    quantity: 1,
    unit: "cup",
    category: "produce",
    order: 4,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: thai_curry.id,
    name: "chicken or tofu",
    quantity: 400,
    unit: "g",
    category: "meat",
    notes: "optional",
    order: 5,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  }
])

Repo.insert_all(Instruction, [
  %{
    recipe_id: thai_curry.id,
    step_number: 1,
    description: "Heat a large pot and add curry paste, stirring for 1 minute until fragrant.",
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: thai_curry.id,
    step_number: 2,
    description: "Add coconut milk and bring to a simmer.",
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: thai_curry.id,
    step_number: 3,
    description: "Add vegetables and protein, simmer for 15-20 minutes until cooked through.",
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: thai_curry.id,
    step_number: 4,
    description: "Serve with jasmine rice and fresh basil.",
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  }
])

# Recipe 5: Chocolate Chip Cookies
{:ok, cookies} =
  %Recipe{}
  |> Recipe.changeset(%{
    title: "Classic Chocolate Chip Cookies",
    description: "Soft and chewy homemade cookies with melty chocolate chips",
    image_url: "https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=800",
    prep_time_minutes: 15,
    cook_time_minutes: 12,
    total_time_minutes: 27,
    servings: 24,
    difficulty: "easy",
    source_attribution: "American Classic"
  })
  |> Repo.insert()

Repo.insert_all(Ingredient, [
  %{
    recipe_id: cookies.id,
    name: "all-purpose flour",
    quantity: 2.25,
    unit: "cups",
    category: "pantry",
    allergens: ["gluten"],
    order: 1,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: cookies.id,
    name: "butter",
    quantity: 1,
    unit: "cup",
    category: "dairy",
    allergens: ["dairy"],
    order: 2,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: cookies.id,
    name: "chocolate chips",
    quantity: 2,
    unit: "cups",
    category: "pantry",
    allergens: ["dairy"],
    order: 3,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: cookies.id,
    name: "eggs",
    quantity: 2,
    unit: "whole",
    category: "dairy",
    allergens: ["eggs"],
    order: 4,
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  }
])

Repo.insert_all(Instruction, [
  %{
    recipe_id: cookies.id,
    step_number: 1,
    description: "Preheat oven to 375°F (190°C).",
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: cookies.id,
    step_number: 2,
    description: "Cream together butter and sugars until fluffy. Beat in eggs and vanilla.",
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: cookies.id,
    step_number: 3,
    description: "Mix in flour, baking soda, and salt. Fold in chocolate chips.",
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  },
  %{
    recipe_id: cookies.id,
    step_number: 4,
    description:
      "Drop rounded tablespoons of dough onto baking sheets. Bake for 10-12 minutes until golden.",
    inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  }
])

%PrepTask{}
|> PrepTask.changeset(%{
  recipe_id: cookies.id,
  task_type: "chill",
  description: "Chill cookie dough for better texture",
  hours_before: 1,
  duration_minutes: 5
})
|> Repo.insert!()

IO.puts("✅ Created #{Repo.aggregate(Recipe, :count)} recipes with ingredients and instructions!")
