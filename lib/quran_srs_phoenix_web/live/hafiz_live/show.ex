defmodule QuranSrsPhoenixWeb.HafizLive.Show do
  use QuranSrsPhoenixWeb, :live_view

  alias QuranSrsPhoenix.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Hafiz {@hafiz.id}
        <:subtitle>This is a hafiz record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/hafizs"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/hafizs/#{@hafiz}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit hafiz
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@hafiz.name}</:item>
        <:item title="Daily capacity">{@hafiz.daily_capacity}</:item>
        <:item title="Effective date">{@hafiz.effective_date}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Accounts.subscribe_hafizs(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Hafiz")
     |> assign(:hafiz, Accounts.get_hafiz!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %QuranSrsPhoenix.Accounts.Hafiz{id: id} = hafiz},
        %{assigns: %{hafiz: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :hafiz, hafiz)}
  end

  def handle_info(
        {:deleted, %QuranSrsPhoenix.Accounts.Hafiz{id: id}},
        %{assigns: %{hafiz: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current hafiz was deleted.")
     |> push_navigate(to: ~p"/hafizs")}
  end

  def handle_info({type, %QuranSrsPhoenix.Accounts.Hafiz{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
