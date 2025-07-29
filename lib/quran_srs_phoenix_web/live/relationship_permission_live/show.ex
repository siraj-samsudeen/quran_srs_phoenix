defmodule QuranSrsPhoenixWeb.RelationshipPermissionLive.Show do
  use QuranSrsPhoenixWeb, :live_view

  alias QuranSrsPhoenix.Permissions

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Permission Details
        <:subtitle>View configuration for {@relationship_permission.relationship} relationship type</:subtitle>
        <:actions>
          <.button variant="outline" navigate={~p"/permissions"}>
            <.icon name="hero-arrow-left" class="w-4 h-4 mr-2" />
            Back to Permissions
          </.button>
          <.button variant="primary" navigate={~p"/permissions/#{@relationship_permission}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" class="w-4 h-4 mr-2" />
            Edit Configuration
          </.button>
        </:actions>
      </.header>

      <div class="max-w-2xl">
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <div class="flex items-center mb-6">
              <.icon name={relationship_icon(@relationship_permission.relationship)} class="w-8 h-8 mr-4 text-primary" />
              <div>
                <h2 class="card-title text-2xl capitalize">{@relationship_permission.relationship}</h2>
                <p class="text-base-content/70">{relationship_description(@relationship_permission.relationship)}</p>
              </div>
            </div>
            
            <div class="divider">Configured Permissions</div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <.permission_status_card 
                label="View Progress" 
                icon="hero-eye" 
                enabled={@relationship_permission.can_view_progress}
                description="Can see memorization progress and statistics"
              />
              <.permission_status_card 
                label="Edit Details" 
                icon="hero-pencil-square" 
                enabled={@relationship_permission.can_edit_details}
                description="Can modify Hafiz profile information"
              />
              <.permission_status_card 
                label="Manage Users" 
                icon="hero-users" 
                enabled={@relationship_permission.can_manage_users}
                description="Can add or remove users from the Hafiz"
              />
              <.permission_status_card 
                label="Delete Hafiz" 
                icon="hero-trash" 
                enabled={@relationship_permission.can_delete_hafiz}
                description="Can permanently delete the Hafiz profile"
              />
              <.permission_status_card 
                label="Edit Preferences" 
                icon="hero-cog-6-tooth" 
                enabled={@relationship_permission.can_edit_preferences}
                description="Can change settings and preferences"
              />
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Permissions.subscribe_relationship_permissions(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Relationship permission")
     |> assign(:relationship_permission, Permissions.get_relationship_permission!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %QuranSrsPhoenix.Permissions.RelationshipPermission{id: id} = relationship_permission},
        %{assigns: %{relationship_permission: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :relationship_permission, relationship_permission)}
  end

  def handle_info(
        {:deleted, %QuranSrsPhoenix.Permissions.RelationshipPermission{id: id}},
        %{assigns: %{relationship_permission: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current relationship_permission was deleted.")
     |> push_navigate(to: ~p"/permissions")}
  end

  def handle_info({type, %QuranSrsPhoenix.Permissions.RelationshipPermission{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
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

  # Permission Status Card Component
  defp permission_status_card(assigns) do
    ~H"""
    <div class={[
      "border-2 rounded-xl p-4",
      if(@enabled, do: "border-success bg-success/10", else: "border-base-300 bg-base-100")
    ]}>
      <div class="flex items-start">
        <.icon name={@icon} class={[
          "w-6 h-6 mr-3 mt-0.5",
          if(@enabled, do: "text-success", else: "text-base-content/40")
        ]} />
        <div class="flex-1">
          <div class="flex items-center justify-between mb-2">
            <h3 class={[
              "font-semibold text-base",
              if(@enabled, do: "text-success", else: "text-base-content")
            ]}>
              {@label}
            </h3>
            <div class={[
              "badge badge-sm",
              if(@enabled, do: "badge-success", else: "badge-ghost")
            ]}>
              {if @enabled, do: "Enabled", else: "Disabled"}
            </div>
          </div>
          <p class={[
            "text-sm leading-relaxed",
            if(@enabled, do: "text-success/80", else: "text-base-content/60")
          ]}>
            {@description}
          </p>
        </div>
      </div>
    </div>
    """
  end
end
