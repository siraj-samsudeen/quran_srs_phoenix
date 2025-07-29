defmodule QuranSrsPhoenix.Repo.Migrations.CreateHafizUsers do
  use Ecto.Migration

  def change do
    create table(:hafiz_users) do
      add :relationship, :string
      add :user_id, references(:users, on_delete: :delete_all)
      add :hafiz_id, references(:hafizs, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:hafiz_users, [:user_id])
    create index(:hafiz_users, [:hafiz_id])
  end
end
