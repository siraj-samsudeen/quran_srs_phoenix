# NOTE: This show page needs to be rewritten for the new route structure /hafizs/:hafiz_id/users/:id
# For now, redirecting to index since show functionality is not essential for core relationship management
defmodule QuranSrsPhoenixWeb.HafizUserLive.Show do
  use QuranSrsPhoenixWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="text-center py-12">
        <.icon name="hero-arrow-path" class="w-8 h-8 mx-auto animate-spin" />
        <p class="mt-2">Redirecting...</p>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"hafiz_id" => hafiz_id}, _session, socket) do
    {:ok, push_navigate(socket, to: ~p"/hafizs/#{hafiz_id}/users")}
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, push_navigate(socket, to: ~p"/hafizs")}
  end
end
