defmodule Cuisine13.Repo.Migrations.AddCalendarFeedTokenToHouseholds do
  use Ecto.Migration

  def change do
    alter table(:households) do
      add :calendar_feed_token, :string
    end

    create unique_index(:households, [:calendar_feed_token])
  end
end
