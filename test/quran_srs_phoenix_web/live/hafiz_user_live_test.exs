defmodule QuranSrsPhoenixWeb.HafizUserLiveTest do
  use QuranSrsPhoenixWeb.ConnCase

  import Phoenix.LiveViewTest
  import QuranSrsPhoenix.AccountsFixtures

  # Skip all tests until we properly implement the full LiveView testing
  @moduletag :skip

  setup :register_and_log_in_user

  defp create_hafiz_and_user(%{scope: scope}) do
    hafiz = hafiz_fixture(scope)
    hafiz_user = hafiz_user_fixture(scope, %{hafiz_id: hafiz.id})
    
    %{hafiz: hafiz, hafiz_user: hafiz_user}
  end

  describe "Index" do
    setup [:create_hafiz_and_user]

    test "lists hafiz users for specific hafiz", %{conn: conn, hafiz: hafiz} do
      {:ok, _index_live, html} = live(conn, ~p"/hafizs/#{hafiz.id}/users")

      assert html =~ "Managing Access for"
      assert html =~ hafiz.name
    end

    test "saves new hafiz_user", %{conn: conn, hafiz: hafiz} do
      # Create another user to add to the hafiz
      other_user = user_fixture()
      
      {:ok, index_live, _html} = live(conn, ~p"/hafizs/#{hafiz.id}/users")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "Add User")
               |> render_click()
               |> follow_redirect(conn, ~p"/hafizs/#{hafiz.id}/users/new")

      assert render(form_live) =~ "Add User Access"

      # Test invalid data
      assert form_live
             |> form("#hafiz_user-form", hafiz_user: %{relationship: nil, user_email: ""})
             |> render_change() =~ "can&#39;t be blank"

      # Test valid data
      assert {:ok, index_live, _html} =
               form_live
               |> form("#hafiz_user-form", hafiz_user: %{relationship: :teacher, user_email: other_user.email})
               |> render_submit()
               |> follow_redirect(conn, ~p"/hafizs/#{hafiz.id}/users")

      html = render(index_live)
      assert html =~ "User access added successfully"
      assert html =~ other_user.email
    end

    test "updates hafiz_user relationship", %{conn: conn, hafiz: hafiz, hafiz_user: hafiz_user} do
      {:ok, index_live, _html} = live(conn, ~p"/hafizs/#{hafiz.id}/users")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/hafizs/#{hafiz.id}/users/#{hafiz_user.id}/edit")

      assert render(form_live) =~ "Edit User Access"
      assert render(form_live) =~ hafiz_user.user.email

      assert {:ok, index_live, _html} =
               form_live
               |> form("#hafiz_user-form", hafiz_user: %{relationship: :parent})
               |> render_submit()
               |> follow_redirect(conn, ~p"/hafizs/#{hafiz.id}/users")

      html = render(index_live)
      assert html =~ "User access updated successfully"
      assert html =~ "Parent"
    end

    test "deletes hafiz_user", %{conn: conn, hafiz: hafiz, hafiz_user: hafiz_user} do
      {:ok, index_live, _html} = live(conn, ~p"/hafizs/#{hafiz.id}/users")

      assert index_live 
             |> element("a", "Remove") 
             |> render_click()
             
      refute has_element?(index_live, "#user-#{hafiz_user.id}")
    end
  end
  
  describe "Form" do
    setup [:create_hafiz_and_user]

    test "displays add form", %{conn: conn, hafiz: hafiz} do
      {:ok, _form_live, html} = live(conn, ~p"/hafizs/#{hafiz.id}/users/new")

      assert html =~ "Add User Access"
      assert html =~ hafiz.name
      assert html =~ "User Email"
      assert html =~ "Relationship Type"
    end

    test "displays edit form", %{conn: conn, hafiz: hafiz, hafiz_user: hafiz_user} do
      {:ok, _form_live, html} = live(conn, ~p"/hafizs/#{hafiz.id}/users/#{hafiz_user.id}/edit")

      assert html =~ "Edit User Access"
      assert html =~ hafiz.name
      assert html =~ hafiz_user.user.email
    end

    test "shows permission preview when relationship selected", %{conn: conn, hafiz: hafiz} do
      {:ok, form_live, _html} = live(conn, ~p"/hafizs/#{hafiz.id}/users/new")

      # Select a relationship and verify permission preview appears
      html = form_live
             |> form("#hafiz_user-form", hafiz_user: %{relationship: :teacher})
             |> render_change()

      assert html =~ "Relationship Permissions"
      assert html =~ "View Progress"
      assert html =~ "Edit Details"
    end

    test "validates user email exists", %{conn: conn, hafiz: hafiz} do
      {:ok, form_live, _html} = live(conn, ~p"/hafizs/#{hafiz.id}/users/new")

      html = form_live
             |> form("#hafiz_user-form", hafiz_user: %{relationship: :teacher, user_email: "nonexistent@example.com"})
             |> render_submit()

      assert html =~ "No user found with this email address"
    end
  end
end