defmodule Cuisine13.Repo.Migrations.AddApiKeysToHouseholds do
  use Ecto.Migration

  def change do
    alter table(:households) do
      add :anthropic_api_key, :text
      add :yelp_api_key, :text
      add :google_places_api_key, :text
    end
  end
end
