defmodule QuranSrsPhoenixWeb.RelationshipPermissionLiveTest do
  use QuranSrsPhoenixWeb.ConnCase

  import Phoenix.LiveViewTest
  import QuranSrsPhoenix.PermissionsFixtures

  @create_attrs %{relationship: :teacher, can_view_progress: true, can_edit_details: true, can_manage_users: true, can_delete_hafiz: true, can_edit_preferences: true}
  @update_attrs %{relationship: :student, can_view_progress: false, can_edit_details: false, can_manage_users: false, can_delete_hafiz: false, can_edit_preferences: false}
  @invalid_attrs %{relationship: nil, can_view_progress: false, can_edit_details: false, can_manage_users: false, can_delete_hafiz: false, can_edit_preferences: false}

  setup :register_and_log_in_user

  defp create_relationship_permission(%{scope: scope}) do
    relationship_permission = relationship_permission_fixture(scope)

    %{relationship_permission: relationship_permission}
  end

  describe "Index" do
    setup [:create_relationship_permission]

    test "lists all relationship_permissions", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/permissions")

      assert html =~ "Listing Relationship permissions"
    end

    test "saves new relationship_permission", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/permissions")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "Add Permission")
               |> render_click()
               |> follow_redirect(conn, ~p"/permissions/new")

      assert render(form_live) =~ "New Relationship permission"

      assert form_live
             |> form("#relationship_permission-form", relationship_permission: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      # For LiveView, test the navigation result
      form_live
      |> form("#relationship_permission-form", relationship_permission: @create_attrs)
      |> render_submit()

      # Since push_navigate is used, we should get an index page back
      {:ok, index_live, _html} = live(conn, ~p"/permissions")
      html = render(index_live)
      assert html =~ "teacher"  # Check that the new permission shows up
    end

    test "updates relationship_permission in listing", %{conn: conn, relationship_permission: relationship_permission} do
      {:ok, index_live, _html} = live(conn, ~p"/permissions")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#permission-#{relationship_permission.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/permissions/#{relationship_permission}/edit")

      assert render(form_live) =~ "Edit Relationship permission"

      assert form_live
             |> form("#relationship_permission-form", relationship_permission: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      # For LiveView, test the navigation result  
      form_live
      |> form("#relationship_permission-form", relationship_permission: @update_attrs)
      |> render_submit()

      # Check that the change was applied by re-accessing the index
      {:ok, index_live, _html} = live(conn, ~p"/permissions")
      html = render(index_live)
      assert html =~ "student"  # Check that the updated relationship shows up
    end

    test "deletes relationship_permission in listing", %{conn: conn, relationship_permission: relationship_permission} do
      {:ok, index_live, _html} = live(conn, ~p"/permissions")

      assert index_live |> element("#permission-#{relationship_permission.id} button[phx-click*='delete']") |> render_click()
      refute has_element?(index_live, "#permission-#{relationship_permission.id}")
    end
  end

  describe "Show" do
    setup [:create_relationship_permission]

    test "displays relationship_permission", %{conn: conn, relationship_permission: relationship_permission} do
      {:ok, _show_live, html} = live(conn, ~p"/permissions/#{relationship_permission}")

      assert html =~ "Show Relationship permission"
    end

    test "updates relationship_permission and returns to show", %{conn: conn, relationship_permission: relationship_permission} do
      {:ok, show_live, _html} = live(conn, ~p"/permissions/#{relationship_permission}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/permissions/#{relationship_permission}/edit?return_to=show")

      assert render(form_live) =~ "Edit Relationship permission"

      assert form_live
             |> form("#relationship_permission-form", relationship_permission: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      # For LiveView, test the navigation result
      form_live
      |> form("#relationship_permission-form", relationship_permission: @update_attrs)
      |> render_submit()

      # Check that the change was applied by re-accessing the show page
      {:ok, show_live, _html} = live(conn, ~p"/permissions/#{relationship_permission}")
      html = render(show_live)
      assert html =~ "student"  # Check that the updated relationship shows up
    end
  end
end
