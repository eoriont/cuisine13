defmodule Cuisine13.Repo.Migrations.CreateGroceryItems do
  use Ecto.Migration

  def change do
    create table(:grocery_items) do
      add :household_id, references(:households, on_delete: :delete_all), null: false
      add :ingredient_id, references(:ingredients, on_delete: :nilify_all)
      add :name, :string, null: false
      add :quantity, :decimal
      add :unit, :string
      add :category, :string
      add :needed_by_date, :date
      add :is_purchased, :boolean, default: false, null: false
      add :purchased_at, :naive_datetime
      add :purchased_by_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create index(:grocery_items, [:household_id])
    create index(:grocery_items, [:ingredient_id])
    create index(:grocery_items, [:category])
    create index(:grocery_items, [:needed_by_date])
  end
end
