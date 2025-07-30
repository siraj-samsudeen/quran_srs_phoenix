defmodule QuranSrsPhoenix.Permissions do
  @moduledoc """
  The Permissions context.
  """

  import Ecto.Query, warn: false
  alias QuranSrsPhoenix.Repo

  alias QuranSrsPhoenix.Permissions.RelationshipPermission
  alias QuranSrsPhoenix.Accounts.Scope

  # Default permission configurations
  @default_permissions %{
    parent: %{
      can_view_progress: true,
      can_edit_details: true,
      can_manage_users: false,
      can_delete_hafiz: false,
      can_edit_preferences: true
    },
    teacher: %{
      can_view_progress: true,
      can_edit_details: true,
      can_manage_users: false,
      can_delete_hafiz: false,
      can_edit_preferences: true
    },
    student: %{
      can_view_progress: true,
      can_edit_details: false,
      can_manage_users: false,
      can_delete_hafiz: false,
      can_edit_preferences: true
    },
    family: %{
      can_view_progress: true,
      can_edit_details: false,
      can_manage_users: false,
      can_delete_hafiz: false,
      can_edit_preferences: false
    }
  }

  @doc """
  Gets default permissions for a relationship type.
  Used when creating permission configurations for new users.
  """
  def get_default_permissions(relationship) when relationship in [:parent, :teacher, :student, :family] do
    Map.get(@default_permissions, relationship)
  end

  @doc """
  Gets all default permissions.
  """
  def get_all_default_permissions, do: @default_permissions

  @doc """
  Ensures a user has permission configurations for all relationship types.
  Creates missing ones with default values.
  """
  def ensure_user_permissions(%Scope{} = scope) do
    existing_relationships = 
      scope
      |> list_relationship_permissions()
      |> Enum.map(& &1.relationship)
      |> MapSet.new()

    all_relationships = MapSet.new([:parent, :teacher, :student, :family])
    missing_relationships = MapSet.difference(all_relationships, existing_relationships)

    for relationship <- missing_relationships do
      default_attrs = get_default_permissions(relationship)
      attrs = Map.put(default_attrs, :relationship, relationship)
      create_relationship_permission(scope, attrs)
    end

    list_relationship_permissions(scope)
  end

  @doc """
  Gets permission configuration for a specific relationship type for the current user.
  Returns default if not configured.
  """
  def get_relationship_permission(%Scope{} = scope, relationship) do
    case relationship do
      :owner ->
        # Owner has all permissions by default - no database lookup needed
        %RelationshipPermission{
          relationship: :owner,
          can_view_progress: true,
          can_edit_details: true,
          can_manage_users: true,
          can_delete_hafiz: true,
          can_edit_preferences: true
        }
      _ ->
        case Repo.get_by(RelationshipPermission, user_id: scope.user.id, relationship: relationship) do
          nil -> 
            # Return struct with default permissions
            default = get_default_permissions(relationship)
            struct(RelationshipPermission, Map.put(default, :relationship, relationship))
          permission -> permission
        end
    end
  end

  @doc """
  Subscribes to scoped notifications about any relationship_permission changes.

  The broadcasted messages match the pattern:

    * {:created, %RelationshipPermission{}}
    * {:updated, %RelationshipPermission{}}
    * {:deleted, %RelationshipPermission{}}

  """
  def subscribe_relationship_permissions(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(QuranSrsPhoenix.PubSub, "user:#{key}:relationship_permissions")
  end

  defp broadcast(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(QuranSrsPhoenix.PubSub, "user:#{key}:relationship_permissions", message)
  end

  @doc """
  Returns the list of relationship_permissions.

  ## Examples

      iex> list_relationship_permissions(scope)
      [%RelationshipPermission{}, ...]

  """
  def list_relationship_permissions(%Scope{} = scope) do
    Repo.all_by(RelationshipPermission, user_id: scope.user.id)
  end

  @doc """
  Gets a single relationship_permission.

  Raises `Ecto.NoResultsError` if the Relationship permission does not exist.

  ## Examples

      iex> get_relationship_permission!(123)
      %RelationshipPermission{}

      iex> get_relationship_permission!(456)
      ** (Ecto.NoResultsError)

  """
  def get_relationship_permission!(%Scope{} = scope, id) do
    Repo.get_by!(RelationshipPermission, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a relationship_permission.

  ## Examples

      iex> create_relationship_permission(%{field: value})
      {:ok, %RelationshipPermission{}}

      iex> create_relationship_permission(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_relationship_permission(%Scope{} = scope, attrs) do
    with {:ok, relationship_permission = %RelationshipPermission{}} <-
           %RelationshipPermission{}
           |> RelationshipPermission.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast(scope, {:created, relationship_permission})
      {:ok, relationship_permission}
    end
  end

  @doc """
  Updates a relationship_permission.

  ## Examples

      iex> update_relationship_permission(relationship_permission, %{field: new_value})
      {:ok, %RelationshipPermission{}}

      iex> update_relationship_permission(relationship_permission, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_relationship_permission(%Scope{} = scope, %RelationshipPermission{} = relationship_permission, attrs) do
    true = relationship_permission.user_id == scope.user.id

    with {:ok, relationship_permission = %RelationshipPermission{}} <-
           relationship_permission
           |> RelationshipPermission.changeset(attrs, scope)
           |> Repo.update() do
      broadcast(scope, {:updated, relationship_permission})
      {:ok, relationship_permission}
    end
  end

  @doc """
  Deletes a relationship_permission.

  ## Examples

      iex> delete_relationship_permission(relationship_permission)
      {:ok, %RelationshipPermission{}}

      iex> delete_relationship_permission(relationship_permission)
      {:error, %Ecto.Changeset{}}

  """
  def delete_relationship_permission(%Scope{} = scope, %RelationshipPermission{} = relationship_permission) do
    true = relationship_permission.user_id == scope.user.id

    with {:ok, relationship_permission = %RelationshipPermission{}} <-
           Repo.delete(relationship_permission) do
      broadcast(scope, {:deleted, relationship_permission})
      {:ok, relationship_permission}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking relationship_permission changes.

  ## Examples

      iex> change_relationship_permission(relationship_permission)
      %Ecto.Changeset{data: %RelationshipPermission{}}

  """
  def change_relationship_permission(%Scope{} = scope, %RelationshipPermission{} = relationship_permission, attrs \\ %{}) do
    true = relationship_permission.user_id == scope.user.id

    RelationshipPermission.changeset(relationship_permission, attrs, scope)
  end
end
