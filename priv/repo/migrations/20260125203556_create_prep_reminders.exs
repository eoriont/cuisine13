defmodule Cuisine13.Repo.Migrations.CreatePrepReminders do
  use Ecto.Migration

  def change do
    create table(:prep_reminders) do
      add :planned_meal_id, references(:planned_meals, on_delete: :delete_all), null: false
      add :prep_task_id, references(:prep_tasks, on_delete: :delete_all), null: false
      add :household_id, references(:households, on_delete: :delete_all), null: false
      add :due_at, :naive_datetime, null: false
      add :is_completed, :boolean, default: false, null: false
      add :completed_at, :naive_datetime
      add :completed_by_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create index(:prep_reminders, [:planned_meal_id])
    create index(:prep_reminders, [:household_id])
    create index(:prep_reminders, [:due_at])
    create index(:prep_reminders, [:is_completed])
  end
end
