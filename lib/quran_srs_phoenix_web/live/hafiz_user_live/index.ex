defmodule QuranSrsPhoenixWeb.HafizUserLive.Index do
  use QuranSrsPhoenixWeb, :live_view

  alias QuranSrsPhoenix.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Managing Access for "<%= @hafiz.name %>"
        <:subtitle>
          Users who can access this hafiz profile and their relationship types
        </:subtitle>
        <:actions>
          <.button variant="primary" navigate={~p"/hafizs/#{@hafiz.id}/users/new"}>
            <.icon name="hero-plus" /> Add User
          </.button>
          <.button variant="outline" navigate={~p"/hafizs/#{@hafiz.id}"}>
            <.icon name="hero-arrow-left" /> Back to Hafiz
          </.button>
        </:actions>
      </.header>

      <div class="grid gap-4">
        <div :for={{id, hafiz_user} <- @streams.hafiz_users} id={id} class="card bg-base-100 shadow-md">
          <div class="card-body">
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-4">
                <div class="avatar placeholder">
                  <div class="bg-neutral text-neutral-content rounded-full w-12">
                    <span class="text-xl"><%= String.first(hafiz_user.user.email) |> String.upcase() %></span>
                  </div>
                </div>
                <div>
                  <h3 class="font-semibold text-lg"><%= hafiz_user.user.email %></h3>
                  <div class="flex items-center gap-2">
                    <.relationship_icon relationship={hafiz_user.relationship} />
                    <span class="badge badge-success"><%= String.capitalize(to_string(hafiz_user.relationship)) %></span>
                  </div>
                </div>
              </div>
              
              <div class="flex gap-2">
                <.link 
                  navigate={~p"/hafizs/#{@hafiz.id}/users/#{hafiz_user}/edit"} 
                  class="btn btn-sm btn-outline"
                >
                  <.icon name="hero-pencil" /> Edit
                </.link>
                <.link
                  phx-click={JS.push("delete", value: %{id: hafiz_user.id}) |> hide("##{id}")}
                  data-confirm="Are you sure you want to remove this user's access?"
                  class="btn btn-sm btn-error btn-outline"
                >
                  <.icon name="hero-trash" /> Remove
                </.link>
              </div>
            </div>
          </div>
        </div>
        
        <div :if={@hafiz_users_count == 0} class="card bg-base-100 shadow-md">
          <div class="card-body text-center">
            <.icon name="hero-users" class="w-16 h-16 mx-auto text-base-300" />
            <h3 class="text-lg font-semibold">No users have access yet</h3>
            <p class="text-base-content/70">Add users to share this hafiz profile with parents, teachers, or family members.</p>
            <.button variant="primary" navigate={~p"/hafizs/#{@hafiz.id}/users/new"}>
              <.icon name="hero-plus" /> Add First User
            </.button>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp relationship_icon(%{relationship: :parent} = assigns) do
    ~H"""
    <.icon name="hero-heart" class="w-5 h-5 text-red-500" />
    """
  end

  defp relationship_icon(%{relationship: :teacher} = assigns) do
    ~H"""
    <.icon name="hero-academic-cap" class="w-5 h-5 text-blue-500" />
    """
  end

  defp relationship_icon(%{relationship: :student} = assigns) do
    ~H"""
    <.icon name="hero-user" class="w-5 h-5 text-green-500" />
    """
  end

  defp relationship_icon(%{relationship: :family} = assigns) do
    ~H"""
    <.icon name="hero-home" class="w-5 h-5 text-purple-500" />
    """
  end

  defp relationship_icon(assigns) do
    ~H"""
    <.icon name="hero-user-group" class="w-5 h-5 text-gray-500" />
    """
  end

  @impl true
  def mount(%{"hafiz_id" => hafiz_id}, _session, socket) do
    scope = socket.assigns.current_scope
    hafiz = Accounts.get_hafiz!(scope, hafiz_id)
    hafiz_users = Accounts.list_hafiz_relationships(scope, hafiz_id)
    
    if connected?(socket) do
      Accounts.subscribe_hafiz_users(scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Managing Access - #{hafiz.name}")
     |> assign(:hafiz, hafiz)
     |> assign(:hafiz_users_count, length(hafiz_users))
     |> stream(:hafiz_users, hafiz_users)}
  end

  @impl true  
  def mount(_params, _session, socket) do
    # Redirect to hafiz index if no hafiz_id provided
    {:ok, push_navigate(socket, to: ~p"/hafizs")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    hafiz_user = Accounts.get_hafiz_user!(socket.assigns.current_scope, id)
    {:ok, _} = Accounts.delete_hafiz_user(socket.assigns.current_scope, hafiz_user)

    {:noreply, stream_delete(socket, :hafiz_users, hafiz_user)}
  end

  @impl true
  def handle_info({type, %QuranSrsPhoenix.Accounts.HafizUser{}}, socket)
      when type in [:created, :updated, :deleted] do
    scope = socket.assigns.current_scope
    hafiz_id = socket.assigns.hafiz.id
    hafiz_users = Accounts.list_hafiz_relationships(scope, hafiz_id)
    
    {:noreply, 
     socket
     |> assign(:hafiz_users_count, length(hafiz_users))
     |> stream(:hafiz_users, hafiz_users, reset: true)}
  end
end
