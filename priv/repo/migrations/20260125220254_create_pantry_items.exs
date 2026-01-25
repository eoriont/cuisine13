defmodule Cuisine13.Repo.Migrations.CreatePantryItems do
  use Ecto.Migration

  def change do
    create table(:pantry_items) do
      add :household_id, references(:households, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :quantity, :decimal
      add :unit, :string
      add :category, :string
      add :added_by_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create index(:pantry_items, [:household_id])
    create index(:pantry_items, [:category])
  end
end
