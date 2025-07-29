defmodule QuranSrsPhoenixWeb.RelationshipPermissionLive.Index do
  use QuranSrsPhoenixWeb, :live_view

  alias QuranSrsPhoenix.Permissions

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Permission Configuration
        <:subtitle>Configure what different relationship types can do with your Hafiz profiles</:subtitle>
        <:actions>
          <.button variant="primary" navigate={~p"/permissions/new"}>
            <.icon name="hero-plus" /> Add Permission
          </.button>
        </:actions>
      </.header>

      <div class="space-y-6">
        <div :for={{_id, permission} <- @streams.relationship_permissions} 
             id={"permission-#{permission.id}"}
             class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <div class="flex justify-between items-center mb-4">
              <div>
                <h2 class="card-title capitalize text-lg">
                  <.icon name={relationship_icon(permission.relationship)} class="w-5 h-5 mr-2" />
                  {permission.relationship}
                </h2>
                <p class="text-sm text-base-content/70">
                  {relationship_description(permission.relationship)}
                </p>
              </div>
              <div class="flex gap-2">
                <.button size="sm" variant="outline" navigate={~p"/permissions/#{permission}/edit"}>
                  <.icon name="hero-pencil" class="w-4 h-4" />
                  Edit
                </.button>
                <.button 
                  size="sm" 
                  variant="error" 
                  phx-click={JS.push("delete", value: %{id: permission.id}) |> hide("#permission-#{permission.id}")}
                  data-confirm="Are you sure you want to delete this permission configuration?"
                >
                  <.icon name="hero-trash" class="w-4 h-4" />
                </.button>
              </div>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <.permission_badge 
                label="View Progress" 
                icon="hero-eye" 
                enabled={permission.can_view_progress} 
              />
              <.permission_badge 
                label="Edit Details" 
                icon="hero-pencil-square" 
                enabled={permission.can_edit_details} 
              />
              <.permission_badge 
                label="Manage Users" 
                icon="hero-users" 
                enabled={permission.can_manage_users} 
              />
              <.permission_badge 
                label="Delete Hafiz" 
                icon="hero-trash" 
                enabled={permission.can_delete_hafiz} 
              />
              <.permission_badge 
                label="Edit Preferences" 
                icon="hero-cog-6-tooth" 
                enabled={permission.can_edit_preferences} 
              />
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Permissions.subscribe_relationship_permissions(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Relationship permissions")
     |> stream(:relationship_permissions, Permissions.list_relationship_permissions(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    relationship_permission = Permissions.get_relationship_permission!(socket.assigns.current_scope, id)
    {:ok, _} = Permissions.delete_relationship_permission(socket.assigns.current_scope, relationship_permission)

    {:noreply, stream_delete(socket, :relationship_permissions, relationship_permission)}
  end

  @impl true
  def handle_info({type, %QuranSrsPhoenix.Permissions.RelationshipPermission{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :relationship_permissions, Permissions.list_relationship_permissions(socket.assigns.current_scope), reset: true)}
  end

  # UI Helper Functions
  defp relationship_icon(:parent), do: "hero-heart"
  defp relationship_icon(:teacher), do: "hero-academic-cap"
  defp relationship_icon(:student), do: "hero-user"
  defp relationship_icon(:family), do: "hero-home"

  defp relationship_description(:parent), do: "Parent or guardian with oversight responsibilities"
  defp relationship_description(:teacher), do: "Educational supervisor with teaching authority"
  defp relationship_description(:student), do: "Learning participant in the memorization program"
  defp relationship_description(:family), do: "Family member with supportive access"

  # Permission Badge Component
  defp permission_badge(assigns) do
    ~H"""
    <div class={[
      "flex items-center px-3 py-2 rounded-lg text-sm font-medium",
      if(@enabled, do: "bg-success/20 text-success border border-success/30", else: "bg-base-200 text-base-content/60 border border-base-300")
    ]}>
      <.icon name={@icon} class={[
        "w-4 h-4 mr-2",
        if(@enabled, do: "text-success", else: "text-base-content/40")
      ]} />
      {@label}
      <div class={[
        "ml-auto w-2 h-2 rounded-full",
        if(@enabled, do: "bg-success", else: "bg-base-content/20")
      ]}></div>
    </div>
    """
  end
end
