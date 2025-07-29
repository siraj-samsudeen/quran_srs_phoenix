defmodule QuranSrsPhoenix.Permissions.RelationshipPermission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "relationship_permissions" do
    field :relationship, Ecto.Enum, values: [:parent, :teacher, :student, :family]
    field :can_view_progress, :boolean, default: true
    field :can_edit_details, :boolean, default: false
    field :can_manage_users, :boolean, default: false
    field :can_delete_hafiz, :boolean, default: false
    field :can_edit_preferences, :boolean, default: false
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(relationship_permission, attrs, user_scope) do
    relationship_permission
    |> cast(attrs, [:relationship, :can_view_progress, :can_edit_details, :can_manage_users, :can_delete_hafiz, :can_edit_preferences])
    |> validate_required([:relationship])
    |> put_change(:user_id, user_scope.user.id)
    |> unique_constraint([:relationship, :user_id], message: "Permission for this relationship type already exists")
  end
end
