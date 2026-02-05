defmodule Cuisine13.Repo.Migrations.CreateRecipeVersions do
  use Ecto.Migration

  def change do
    create table(:recipe_versions) do
      add :recipe_id, references(:recipes, on_delete: :delete_all), null: false
      add :household_id, references(:households, on_delete: :delete_all)
      add :created_by_id, references(:users, on_delete: :nilify_all)

      # Version tracking
      add :version_number, :integer, null: false
      add :change_description, :text

      # Recipe data snapshot (all customizable fields)
      add :title, :string, null: false
      add :description, :text
      add :image_url, :string
      add :video_url, :string
      add :thumbnail_url, :string
      add :prep_time_minutes, :integer
      add :cook_time_minutes, :integer
      add :total_time_minutes, :integer
      add :servings, :integer, null: false
      add :difficulty, :string
      add :source_url, :string
      add :source_attribution, :string
      add :user_notes, :string

      # Store ingredients and instructions as JSONB for snapshot
      add :ingredients_snapshot, :map
      add :instructions_snapshot, :map
      add :prep_tasks_snapshot, :map

      timestamps(updated_at: false)
    end

    create index(:recipe_versions, [:recipe_id])
    create index(:recipe_versions, [:household_id])
    create index(:recipe_versions, [:recipe_id, :version_number])
    create unique_index(:recipe_versions, [:recipe_id, :household_id, :version_number],
      name: :recipe_versions_unique_version,
      where: "household_id IS NOT NULL"
    )
  end
end
