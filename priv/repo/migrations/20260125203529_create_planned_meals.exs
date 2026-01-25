defmodule Cuisine13.Repo.Migrations.CreatePlannedMeals do
  use Ecto.Migration

  def change do
    create table(:planned_meals) do
      add :household_id, references(:households, on_delete: :delete_all), null: false
      add :recipe_id, references(:recipes, on_delete: :restrict), null: false
      add :added_by_id, references(:users, on_delete: :nilify_all)
      add :scheduled_date, :date, null: false
      add :meal_type, :string, null: false
      add :servings, :integer, null: false
      add :notes, :text
      add :is_leftover, :boolean, default: false, null: false
      add :leftover_from_id, references(:planned_meals, on_delete: :nilify_all)

      timestamps()
    end

    create index(:planned_meals, [:household_id])
    create index(:planned_meals, [:recipe_id])
    create index(:planned_meals, [:scheduled_date])
    create index(:planned_meals, [:added_by_id])
  end
end
