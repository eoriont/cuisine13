defmodule Cuisine13.Repo.Migrations.AddInviteCodeToHouseholds do
  use Ecto.Migration

  def change do
    alter table(:households) do
      add :invite_code, :string
    end

    create unique_index(:households, [:invite_code])
  end
end
