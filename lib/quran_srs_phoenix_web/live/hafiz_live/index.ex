defmodule QuranSrsPhoenixWeb.HafizLive.Index do
  use QuranSrsPhoenixWeb, :live_view

  alias QuranSrsPhoenix.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Hafizs
        <:actions>
          <.button variant="primary" navigate={~p"/hafizs/new"}>
            <.icon name="hero-plus" /> New Hafiz
          </.button>
        </:actions>
      </.header>

      <.table
        id="hafizs"
        rows={@streams.hafizs}
        row_click={fn {_id, hafiz} -> JS.navigate(~p"/hafizs/#{hafiz}") end}
      >
        <:col :let={{_id, hafiz}} label="Name">{hafiz.name}</:col>
        <:col :let={{_id, hafiz}} label="Daily capacity">{hafiz.daily_capacity}</:col>
        <:col :let={{_id, hafiz}} label="Effective date">{hafiz.effective_date}</:col>
        <:action :let={{_id, hafiz}}>
          <div class="sr-only">
            <.link navigate={~p"/hafizs/#{hafiz}"}>Show</.link>
          </div>
          <.link navigate={~p"/hafizs/#{hafiz}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, hafiz}}>
          <.link
            phx-click={JS.push("delete", value: %{id: hafiz.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Accounts.subscribe_hafizs(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Hafizs")
     |> stream(:hafizs, Accounts.list_hafizs(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    hafiz = Accounts.get_hafiz!(socket.assigns.current_scope, id)
    {:ok, _} = Accounts.delete_hafiz(socket.assigns.current_scope, hafiz)

    {:noreply, stream_delete(socket, :hafizs, hafiz)}
  end

  @impl true
  def handle_info({type, %QuranSrsPhoenix.Accounts.Hafiz{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :hafizs, Accounts.list_hafizs(socket.assigns.current_scope), reset: true)}
  end
end
