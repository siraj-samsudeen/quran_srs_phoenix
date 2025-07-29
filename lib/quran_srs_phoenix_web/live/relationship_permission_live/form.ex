defmodule QuranSrsPhoenixWeb.RelationshipPermissionLive.Form do
  use QuranSrsPhoenixWeb, :live_view

  alias QuranSrsPhoenix.Permissions
  alias QuranSrsPhoenix.Permissions.RelationshipPermission

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage relationship_permission records in your database.</:subtitle>
      </.header>

      <div class="max-w-3xl mx-auto space-y-6">
        <.form for={@form} id="relationship_permission-form" phx-change="validate" phx-submit="save">
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h3 class="card-title mb-6">
                <.icon name="hero-identification" class="w-6 h-6" />
                Relationship Type
              </h3>
              <.input
                field={@form[:relationship]}
                type="select"
                label="Select Relationship"
                prompt="Choose a relationship type"
                options={Ecto.Enum.values(QuranSrsPhoenix.Permissions.RelationshipPermission, :relationship)}
                class="select select-bordered w-full max-w-md"
              />
            </div>
          </div>

          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h3 class="card-title mb-6">
                <.icon name="hero-shield-check" class="w-6 h-6" />
                Permissions Configuration
              </h3>
              <p class="text-base text-base-content/70 mb-8">Configure what this relationship type can do with Hafiz profiles</p>
          
              <div class="space-y-4">
                <.permission_toggle 
                  field={@form[:can_view_progress]}
                  label="View Progress" 
                  icon="hero-eye"
                  description="Can see memorization progress and statistics"
                />
                <.permission_toggle 
                  field={@form[:can_edit_details]}
                  label="Edit Details" 
                  icon="hero-pencil-square"
                  description="Can modify Hafiz profile information"
                />
                <.permission_toggle 
                  field={@form[:can_manage_users]}
                  label="Manage Users" 
                  icon="hero-users"
                  description="Can add or remove users from the Hafiz"
                />
                <.permission_toggle 
                  field={@form[:can_delete_hafiz]}
                  label="Delete Hafiz" 
                  icon="hero-trash"
                  description="Can permanently delete the Hafiz profile"
                />
                <.permission_toggle 
                  field={@form[:can_edit_preferences]}
                  label="Edit Preferences" 
                  icon="hero-cog-6-tooth"
                  description="Can change settings and preferences"
                />
              </div>
              
              <footer class="flex justify-end gap-3 pt-6 mt-8 border-t border-base-300">
                <.button navigate={return_path(@current_scope, @return_to, @relationship_permission)} variant="outline">
                  Cancel
                </.button>
                <.button phx-disable-with="Saving..." variant="primary">
                  <.icon name="hero-check" class="w-4 h-4 mr-2" />
                  Save Permission
                </.button>
              </footer>
            </div>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    relationship_permission = Permissions.get_relationship_permission!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Relationship permission")
    |> assign(:relationship_permission, relationship_permission)
    |> assign(:form, to_form(Permissions.change_relationship_permission(socket.assigns.current_scope, relationship_permission)))
  end

  defp apply_action(socket, :new, _params) do
    relationship_permission = %RelationshipPermission{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Relationship permission")
    |> assign(:relationship_permission, relationship_permission)
    |> assign(:form, to_form(Permissions.change_relationship_permission(socket.assigns.current_scope, relationship_permission)))
  end

  @impl true
  def handle_event("validate", %{"relationship_permission" => relationship_permission_params}, socket) do
    changeset = Permissions.change_relationship_permission(socket.assigns.current_scope, socket.assigns.relationship_permission, relationship_permission_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"relationship_permission" => relationship_permission_params}, socket) do
    save_relationship_permission(socket, socket.assigns.live_action, relationship_permission_params)
  end

  defp save_relationship_permission(socket, :edit, relationship_permission_params) do
    case Permissions.update_relationship_permission(socket.assigns.current_scope, socket.assigns.relationship_permission, relationship_permission_params) do
      {:ok, relationship_permission} ->
        {:noreply,
         socket
         |> put_flash(:info, "Relationship permission updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, relationship_permission)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_relationship_permission(socket, :new, relationship_permission_params) do
    case Permissions.create_relationship_permission(socket.assigns.current_scope, relationship_permission_params) do
      {:ok, relationship_permission} ->
        {:noreply,
         socket
         |> put_flash(:info, "Relationship permission created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, relationship_permission)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _relationship_permission), do: ~p"/permissions"
  defp return_path(_scope, "show", relationship_permission), do: ~p"/permissions/#{relationship_permission}"

  # Permission Toggle Component
  defp permission_toggle(assigns) do
    field = assigns.field
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []
    checked = Phoenix.HTML.Form.normalize_value("checkbox", field.value)
    
    assigns = assign(assigns, :checked, checked)
    assigns = assign(assigns, :errors, Enum.map(errors, &QuranSrsPhoenixWeb.CoreComponents.translate_error(&1)))

    ~H"""
    <div class="form-control">
      <label class={[
        "cursor-pointer border-2 rounded-lg p-4 transition-all duration-200 hover:shadow-md flex items-center justify-between",
        if(@checked, do: "border-success bg-success/10", else: "border-base-300 bg-base-100 hover:border-base-400")
      ]}>
        <div class="flex items-center flex-1">
          <.icon name={@icon} class={[
            "w-5 h-5 mr-3",
            if(@checked, do: "text-success", else: "text-base-content/60")
          ]} />
          <div>
            <div class={[
              "font-medium text-base",
              if(@checked, do: "text-success", else: "text-base-content")
            ]}>
              {@label}
            </div>
            <div class={[
              "text-sm mt-1",
              if(@checked, do: "text-success/70", else: "text-base-content/60")
            ]}>
              {@description}
            </div>
          </div>
        </div>
        
        <div class="ml-4">
          <input type="hidden" name={@field.name} value="false" />
          <input
            type="checkbox"
            id={@field.id}
            name={@field.name}
            value="true"
            checked={@checked}
            class="toggle toggle-success"
          />
        </div>
      </label>
      <div :for={msg <- @errors} class="mt-1.5 flex gap-2 items-center text-sm text-error">
        <.icon name="hero-exclamation-circle" class="size-4" />
        {msg}
      </div>
    </div>
    """
  end
end
