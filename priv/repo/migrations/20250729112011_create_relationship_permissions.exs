defmodule QuranSrsPhoenix.Repo.Migrations.CreateRelationshipPermissions do
  use Ecto.Migration

  def change do
    create table(:relationship_permissions) do
      add :relationship, :string, null: false
      add :can_view_progress, :boolean, default: true, null: false
      add :can_edit_details, :boolean, default: false, null: false
      add :can_manage_users, :boolean, default: false, null: false
      add :can_delete_hafiz, :boolean, default: false, null: false
      add :can_edit_preferences, :boolean, default: false, null: false
      add :user_id, references(:users, type: :id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:relationship_permissions, [:user_id])
    create unique_index(:relationship_permissions, [:relationship, :user_id])
  end
end
