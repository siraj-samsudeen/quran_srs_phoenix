defmodule QuranSrsPhoenix.Repo.Migrations.AddDefaultToHafizEffectiveDate do
  use Ecto.Migration

  def change do
    alter table(:hafizs) do
      modify :effective_date, :date, default: fragment("CURRENT_DATE")
    end
  end
end
