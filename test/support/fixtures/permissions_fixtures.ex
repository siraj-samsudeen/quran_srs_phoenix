defmodule QuranSrsPhoenix.PermissionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `QuranSrsPhoenix.Permissions` context.
  """

  @doc """
  Generate a relationship_permission.
  """
  def relationship_permission_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        can_delete_hafiz: true,
        can_edit_details: true,
        can_edit_preferences: true,
        can_manage_users: true,
        can_view_progress: true,
        relationship: :parent
      })

    {:ok, relationship_permission} = QuranSrsPhoenix.Permissions.create_relationship_permission(scope, attrs)
    relationship_permission
  end
end
