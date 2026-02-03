defmodule Cuisine13.Repo.Migrations.AddPreparedToPlannedMeals do
  use Ecto.Migration

  def change do
    alter table(:planned_meals) do
      add :is_prepared, :boolean, default: false, null: false
      add :prepared_at, :naive_datetime
      add :prepared_by_id, references(:users, on_delete: :nilify_all)
    end

    create index(:planned_meals, [:prepared_by_id])
    create index(:planned_meals, [:is_prepared])
  end
end
