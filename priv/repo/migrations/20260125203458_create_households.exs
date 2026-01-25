defmodule Cuisine13.Repo.Migrations.CreateHouseholds do
  use Ecto.Migration

  def change do
    create table(:households) do
      add :name, :string, null: false

      timestamps()
    end

    create table(:household_memberships) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :household_id, references(:households, on_delete: :delete_all), null: false
      add :role, :string, null: false, default: "member"

      timestamps()
    end

    create index(:household_memberships, [:user_id])
    create index(:household_memberships, [:household_id])
    create unique_index(:household_memberships, [:user_id, :household_id])
  end
end
