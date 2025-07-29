defmodule QuranSrsPhoenix.Repo.Migrations.CreateHafizs do
  use Ecto.Migration

  def change do
    create table(:hafizs) do
      add :name, :string
      add :daily_capacity, :integer
      add :effective_date, :date
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:hafizs, [:user_id])
  end
end
