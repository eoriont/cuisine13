defmodule Cuisine13.Repo.Migrations.CreateRecipes do
  use Ecto.Migration

  def change do
    create table(:recipes) do
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

      timestamps()
    end

    create index(:recipes, [:difficulty])

    create table(:ingredients) do
      add :recipe_id, references(:recipes, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :quantity, :decimal
      add :unit, :string
      add :category, :string
      add :allergens, {:array, :string}, default: []
      add :notes, :string
      add :order, :integer, null: false

      timestamps()
    end

    create index(:ingredients, [:recipe_id])

    create table(:instructions) do
      add :recipe_id, references(:recipes, on_delete: :delete_all), null: false
      add :step_number, :integer, null: false
      add :description, :text, null: false
      add :duration_minutes, :integer

      timestamps()
    end

    create index(:instructions, [:recipe_id])

    create table(:prep_tasks) do
      add :recipe_id, references(:recipes, on_delete: :delete_all), null: false
      add :task_type, :string, null: false
      add :description, :text, null: false
      add :hours_before, :integer, null: false
      add :duration_minutes, :integer

      timestamps()
    end

    create index(:prep_tasks, [:recipe_id])

    create table(:recipe_likes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :recipe_id, references(:recipes, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:recipe_likes, [:user_id])
    create index(:recipe_likes, [:recipe_id])
    create unique_index(:recipe_likes, [:user_id, :recipe_id])
  end
end
