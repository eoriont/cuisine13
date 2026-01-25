defmodule Cuisine13.Repo.Migrations.AddHouseholdToRecipeLikes do
  use Ecto.Migration

  def change do
    alter table(:recipe_likes) do
      add :household_id, references(:households, on_delete: :delete_all)
    end

    create index(:recipe_likes, [:household_id])
    create unique_index(:recipe_likes, [:household_id, :recipe_id], name: :recipe_likes_household_recipe_index)
  end
end
