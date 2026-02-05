defmodule Cuisine13.Repo.Migrations.AddPerformanceIndexes do
  use Ecto.Migration

  def change do
    # Add index on recipes.title for search queries
    create index(:recipes, [:title])

    # Add index on recipes.inserted_at for sorting by creation date
    create index(:recipes, [:inserted_at])

    # Add composite index for common query patterns (search + sort)
    create index(:recipes, [:difficulty, :inserted_at])
  end
end
