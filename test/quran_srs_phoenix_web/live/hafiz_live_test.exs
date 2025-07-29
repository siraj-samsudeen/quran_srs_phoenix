defmodule QuranSrsPhoenixWeb.HafizLiveTest do
  use QuranSrsPhoenixWeb.ConnCase

  import Phoenix.LiveViewTest
  import QuranSrsPhoenix.AccountsFixtures

  @create_attrs %{name: "some name", daily_capacity: 42, effective_date: "2025-07-28"}
  @update_attrs %{name: "some updated name", daily_capacity: 43, effective_date: "2025-07-29"}
  @invalid_attrs %{name: nil, daily_capacity: nil, effective_date: nil}

  setup :register_and_log_in_user

  defp create_hafiz(%{scope: scope}) do
    hafiz = hafiz_fixture(scope)

    %{hafiz: hafiz}
  end

  describe "Index" do
    setup [:create_hafiz]

    test "lists all hafizs", %{conn: conn, hafiz: hafiz} do
      {:ok, _index_live, html} = live(conn, ~p"/hafizs")

      assert html =~ "Listing Hafizs"
      assert html =~ hafiz.name
    end

    test "saves new hafiz", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/hafizs")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Hafiz")
               |> render_click()
               |> follow_redirect(conn, ~p"/hafizs/new")

      assert render(form_live) =~ "New Hafiz"

      assert form_live
             |> form("#hafiz-form", hafiz: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#hafiz-form", hafiz: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/hafizs")

      html = render(index_live)
      assert html =~ "Hafiz created successfully"
      assert html =~ "some name"
    end

    test "updates hafiz in listing", %{conn: conn, hafiz: hafiz} do
      {:ok, index_live, _html} = live(conn, ~p"/hafizs")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#hafizs-#{hafiz.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/hafizs/#{hafiz}/edit")

      assert render(form_live) =~ "Edit Hafiz"

      assert form_live
             |> form("#hafiz-form", hafiz: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#hafiz-form", hafiz: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/hafizs")

      html = render(index_live)
      assert html =~ "Hafiz updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes hafiz in listing", %{conn: conn, hafiz: hafiz} do
      {:ok, index_live, _html} = live(conn, ~p"/hafizs")

      assert index_live |> element("#hafizs-#{hafiz.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#hafizs-#{hafiz.id}")
    end
  end

  describe "Show" do
    setup [:create_hafiz]

    test "displays hafiz", %{conn: conn, hafiz: hafiz} do
      {:ok, _show_live, html} = live(conn, ~p"/hafizs/#{hafiz}")

      assert html =~ "Show Hafiz"
      assert html =~ hafiz.name
    end

    test "updates hafiz and returns to show", %{conn: conn, hafiz: hafiz} do
      {:ok, show_live, _html} = live(conn, ~p"/hafizs/#{hafiz}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/hafizs/#{hafiz}/edit?return_to=show")

      assert render(form_live) =~ "Edit Hafiz"

      assert form_live
             |> form("#hafiz-form", hafiz: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#hafiz-form", hafiz: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/hafizs/#{hafiz}")

      html = render(show_live)
      assert html =~ "Hafiz updated successfully"
      assert html =~ "some updated name"
    end
  end
end
