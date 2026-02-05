defmodule Cuisine13.Repo.Migrations.AddNotesToRecipes do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      add :user_notes, :text
    end
  end
end
