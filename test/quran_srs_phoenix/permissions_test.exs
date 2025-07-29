defmodule QuranSrsPhoenix.PermissionsTest do
  use QuranSrsPhoenix.DataCase

  alias QuranSrsPhoenix.Permissions

  describe "relationship_permissions" do
    alias QuranSrsPhoenix.Permissions.RelationshipPermission

    import QuranSrsPhoenix.AccountsFixtures, only: [user_scope_fixture: 0]
    import QuranSrsPhoenix.PermissionsFixtures

    @invalid_attrs %{relationship: nil, can_view_progress: nil, can_edit_details: nil, can_manage_users: nil, can_delete_hafiz: nil, can_edit_preferences: nil}

    test "list_relationship_permissions/1 returns all scoped relationship_permissions" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      relationship_permission = relationship_permission_fixture(scope)
      other_relationship_permission = relationship_permission_fixture(other_scope)
      assert Permissions.list_relationship_permissions(scope) == [relationship_permission]
      assert Permissions.list_relationship_permissions(other_scope) == [other_relationship_permission]
    end

    test "get_relationship_permission!/2 returns the relationship_permission with given id" do
      scope = user_scope_fixture()
      relationship_permission = relationship_permission_fixture(scope)
      other_scope = user_scope_fixture()
      assert Permissions.get_relationship_permission!(scope, relationship_permission.id) == relationship_permission
      assert_raise Ecto.NoResultsError, fn -> Permissions.get_relationship_permission!(other_scope, relationship_permission.id) end
    end

    test "create_relationship_permission/2 with valid data creates a relationship_permission" do
      valid_attrs = %{relationship: :parent, can_view_progress: true, can_edit_details: true, can_manage_users: true, can_delete_hafiz: true, can_edit_preferences: true}
      scope = user_scope_fixture()

      assert {:ok, %RelationshipPermission{} = relationship_permission} = Permissions.create_relationship_permission(scope, valid_attrs)
      assert relationship_permission.relationship == :parent
      assert relationship_permission.can_view_progress == true
      assert relationship_permission.can_edit_details == true
      assert relationship_permission.can_manage_users == true
      assert relationship_permission.can_delete_hafiz == true
      assert relationship_permission.can_edit_preferences == true
      assert relationship_permission.user_id == scope.user.id
    end

    test "create_relationship_permission/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Permissions.create_relationship_permission(scope, @invalid_attrs)
    end

    test "update_relationship_permission/3 with valid data updates the relationship_permission" do
      scope = user_scope_fixture()
      relationship_permission = relationship_permission_fixture(scope)
      update_attrs = %{relationship: :teacher, can_view_progress: false, can_edit_details: false, can_manage_users: false, can_delete_hafiz: false, can_edit_preferences: false}

      assert {:ok, %RelationshipPermission{} = relationship_permission} = Permissions.update_relationship_permission(scope, relationship_permission, update_attrs)
      assert relationship_permission.relationship == :teacher
      assert relationship_permission.can_view_progress == false
      assert relationship_permission.can_edit_details == false
      assert relationship_permission.can_manage_users == false
      assert relationship_permission.can_delete_hafiz == false
      assert relationship_permission.can_edit_preferences == false
    end

    test "update_relationship_permission/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      relationship_permission = relationship_permission_fixture(scope)

      assert_raise MatchError, fn ->
        Permissions.update_relationship_permission(other_scope, relationship_permission, %{})
      end
    end

    test "update_relationship_permission/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      relationship_permission = relationship_permission_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Permissions.update_relationship_permission(scope, relationship_permission, @invalid_attrs)
      assert relationship_permission == Permissions.get_relationship_permission!(scope, relationship_permission.id)
    end

    test "delete_relationship_permission/2 deletes the relationship_permission" do
      scope = user_scope_fixture()
      relationship_permission = relationship_permission_fixture(scope)
      assert {:ok, %RelationshipPermission{}} = Permissions.delete_relationship_permission(scope, relationship_permission)
      assert_raise Ecto.NoResultsError, fn -> Permissions.get_relationship_permission!(scope, relationship_permission.id) end
    end

    test "delete_relationship_permission/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      relationship_permission = relationship_permission_fixture(scope)
      assert_raise MatchError, fn -> Permissions.delete_relationship_permission(other_scope, relationship_permission) end
    end

    test "change_relationship_permission/2 returns a relationship_permission changeset" do
      scope = user_scope_fixture()
      relationship_permission = relationship_permission_fixture(scope)
      assert %Ecto.Changeset{} = Permissions.change_relationship_permission(scope, relationship_permission)
    end
  end

  describe "permission helpers" do
    import QuranSrsPhoenix.AccountsFixtures, only: [user_scope_fixture: 0]
    test "get_default_permissions/1 returns correct defaults" do
      parent_defaults = Permissions.get_default_permissions(:parent)
      assert parent_defaults.can_view_progress == true
      assert parent_defaults.can_edit_details == true
      assert parent_defaults.can_edit_preferences == true
      assert parent_defaults.can_manage_users == false

      teacher_defaults = Permissions.get_default_permissions(:teacher)
      assert teacher_defaults.can_view_progress == true
      assert teacher_defaults.can_edit_details == true
      assert teacher_defaults.can_edit_preferences == true

      student_defaults = Permissions.get_default_permissions(:student)
      assert student_defaults.can_view_progress == true
      assert student_defaults.can_edit_details == false
      assert student_defaults.can_edit_preferences == true

      family_defaults = Permissions.get_default_permissions(:family)
      assert family_defaults.can_view_progress == true
      assert family_defaults.can_edit_details == false
      assert family_defaults.can_edit_preferences == false
    end

    test "get_relationship_permission/2 returns default when not configured" do
      scope = user_scope_fixture()
      
      permission = Permissions.get_relationship_permission(scope, :parent)
      assert permission.relationship == :parent
      assert permission.can_view_progress == true
      assert permission.can_edit_details == true
    end

    test "get_relationship_permission/2 returns configured permission when exists" do
      scope = user_scope_fixture()
      attrs = %{
        relationship: :parent,
        can_view_progress: false,
        can_edit_details: false,
        can_manage_users: true,
        can_delete_hafiz: true,
        can_edit_preferences: false
      }
      
      {:ok, created_permission} = Permissions.create_relationship_permission(scope, attrs)
      
      permission = Permissions.get_relationship_permission(scope, :parent)
      assert permission.id == created_permission.id
      assert permission.can_view_progress == false
      assert permission.can_edit_details == false
      assert permission.can_manage_users == true
    end

    test "ensure_user_permissions/1 creates missing default permissions" do
      scope = user_scope_fixture()
      
      # Initially no permissions configured
      assert Permissions.list_relationship_permissions(scope) == []
      
      # Ensure permissions creates all defaults
      permissions = Permissions.ensure_user_permissions(scope)
      assert length(permissions) == 4
      
      relationships = Enum.map(permissions, & &1.relationship) |> Enum.sort()
      assert relationships == [:family, :parent, :student, :teacher]
      
      # Check that defaults were applied correctly
      parent_perm = Enum.find(permissions, & &1.relationship == :parent)
      assert parent_perm.can_edit_details == true
      
      family_perm = Enum.find(permissions, & &1.relationship == :family)
      assert family_perm.can_edit_details == false
    end
  end
end
